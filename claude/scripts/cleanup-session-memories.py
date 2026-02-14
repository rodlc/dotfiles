#!/usr/bin/env python3
"""
Analyse et cleanup des mémoires session-consolidation
Phase 1: Identifier mémoires pauvres (<200 chars)
Phase 2: Matching hybride Memory → Plan → Notion
"""

import json
import re
from datetime import datetime, timedelta
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Optional, Tuple

# ═══════════════════════════════════════════════════════════════════════════
# CONSTANTS
# ═══════════════════════════════════════════════════════════════════════════

PLANS_DIR = Path.home() / ".claude" / "plans"
MEMORY_RESULT_FILE = Path.home() / ".claude/projects/-Users-rodmagic-Code/1a488232-13e7-46a2-b821-1b8dd706734f/tool-results/mcp-memory-service-search_by_tag-1770225139594.txt"

TIMESTAMP_THRESHOLD = 7200  # ±2h en secondes
KEYWORD_THRESHOLD = 172800  # ±48h en secondes

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 1: Identifier mémoires pauvres
# ═══════════════════════════════════════════════════════════════════════════

def load_memories() -> List[Dict]:
    """Charge les mémoires depuis le fichier résultat"""
    with open(MEMORY_RESULT_FILE, 'r') as f:
        data = json.load(f)

    # Format: [{type: "text", text: "{\"results\": [...]}"}]
    wrapper = data[0]
    results_json = json.loads(wrapper['text'])
    memories = results_json['results']

    return memories

def is_poor_quality(memory: Dict) -> bool:
    """Détermine si une mémoire est pauvre (<200 chars, pas de sections)"""
    content = memory.get('content', '')

    # Critère 1: moins de 200 caractères
    if len(content) < 200:
        # Critère 2: pas de sections substantielles (##, listes, etc.)
        has_sections = bool(re.search(r'##\s+\w+|^[-*]\s+\w+', content, re.MULTILINE))
        if not has_sections:
            return True

    return False

def analyze_quality(memories: List[Dict]) -> Dict:
    """Analyse la qualité des mémoires"""
    stats = {
        'poor': [],      # <200 chars, no sections
        'medium': [],    # 200-500 chars
        'rich': []       # >500 chars
    }

    for mem in memories:
        content = mem.get('content', '')
        length = len(content)

        if is_poor_quality(mem):
            stats['poor'].append(mem)
        elif length < 500:
            stats['medium'].append(mem)
        else:
            stats['rich'].append(mem)

    return stats

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 2.1: Construire index Plan → Notion
# ═══════════════════════════════════════════════════════════════════════════

def parse_plan_markers() -> Dict[str, Dict]:
    """
    Parse tous les markers notion:posted dans les plans
    Returns: {plan_path: {page_id, mtime, title}}
    """
    plan_index = {}

    for plan_file in PLANS_DIR.glob("*.md"):
        with open(plan_file, 'r') as f:
            content = f.read()

        # Chercher marker notion:posted
        match = re.search(r'notion:posted:([^:]+):mtime:(\d+)', content)
        if match:
            page_id = match.group(1)
            mtime = int(match.group(2))

            # Extraire titre du plan (première ligne # ...)
            title_match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
            title = title_match.group(1) if title_match else plan_file.stem

            plan_index[str(plan_file)] = {
                'page_id': page_id,
                'mtime': mtime,
                'title': title,
                'content': content
            }

    return plan_index

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 2.2: Matching hybride
# ═══════════════════════════════════════════════════════════════════════════

def parse_memory_timestamp(memory: Dict) -> Optional[int]:
    """Extrait timestamp Unix de la mémoire"""
    created_at = memory.get('created_at')
    if not created_at:
        return None

    # Parser ISO format
    try:
        dt = datetime.fromisoformat(created_at.replace('Z', '+00:00'))
        return int(dt.timestamp())
    except:
        return None

def extract_keywords(content: str) -> List[str]:
    """Extrait mots-clés du contenu pour matching"""
    # Extraire topics/tags
    topics = re.findall(r'Topics[^:]*:\s*([^\n]+)', content, re.IGNORECASE)
    if topics:
        keywords = re.findall(r'\w+', topics[0])
        return [k.lower() for k in keywords if len(k) > 3]

    # Fallback: mots fréquents
    words = re.findall(r'\b[a-z]{4,}\b', content.lower())
    freq = defaultdict(int)
    for w in words:
        freq[w] += 1

    # Top 5 mots les plus fréquents
    return sorted(freq.keys(), key=lambda k: freq[k], reverse=True)[:5]

def match_by_timestamp(memory: Dict, plan_index: Dict) -> Optional[Tuple[str, Dict]]:
    """Match par timestamp ±2h"""
    mem_ts = parse_memory_timestamp(memory)
    if not mem_ts:
        return None

    matches = []
    for plan_path, plan_data in plan_index.items():
        if abs(plan_data['mtime'] - mem_ts) < TIMESTAMP_THRESHOLD:
            matches.append((plan_path, plan_data))

    # Retourner match unique seulement
    return matches[0] if len(matches) == 1 else None

def match_by_keywords(memory: Dict, plan_index: Dict) -> Optional[Tuple[str, Dict]]:
    """Match par keywords ±48h"""
    mem_ts = parse_memory_timestamp(memory)
    if not mem_ts:
        return None

    keywords = extract_keywords(memory.get('content', ''))
    if not keywords:
        return None

    matches = []
    for plan_path, plan_data in plan_index.items():
        # Filtrer par date ±48h
        if abs(plan_data['mtime'] - mem_ts) > KEYWORD_THRESHOLD:
            continue

        # Chercher keywords dans contenu plan
        plan_content_lower = plan_data['content'].lower()
        score = sum(1 for kw in keywords if kw in plan_content_lower)

        if score >= 2:  # Au moins 2 keywords trouvés
            matches.append((plan_path, plan_data, score))

    if not matches:
        return None

    # Retourner meilleur match
    matches.sort(key=lambda x: x[2], reverse=True)
    return (matches[0][0], matches[0][1])

def match_memory_to_plan(memory: Dict, plan_index: Dict) -> Optional[Tuple[str, Dict, str]]:
    """
    Matching hybride (priorité décroissante)
    Returns: (plan_path, plan_data, match_type) ou None si orphelin
    """
    # 1. Timestamp direct
    match = match_by_timestamp(memory, plan_index)
    if match:
        return (*match, 'timestamp')

    # 2. Keywords
    match = match_by_keywords(memory, plan_index)
    if match:
        return (*match, 'keywords')

    # 3. Orphelin
    return None

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 2.3: Générer stubs et backfill plans
# ═══════════════════════════════════════════════════════════════════════════

def extract_title(memory: Dict) -> str:
    """Extrait titre de la mémoire"""
    content = memory.get('content', '')

    # Chercher Project: ...
    project_match = re.search(r'Project:\s*([^\n]+)', content)
    if project_match:
        return project_match.group(1).strip()

    # Fallback: première ligne
    lines = content.split('\n')
    for line in lines:
        line = line.strip().strip('#').strip()
        if line:
            return line[:60]

    return "Session Summary"

def extract_topics(memory: Dict) -> List[str]:
    """Extrait tags/topics de la mémoire"""
    content = memory.get('content', '')

    # Chercher section "Topics Discussed"
    topics_match = re.search(r'##\s+.*Topics.*?\n((?:[-•]\s+\w+\s*\n)+)', content, re.IGNORECASE | re.MULTILINE)
    if topics_match:
        topics_text = topics_match.group(1)
        topics = re.findall(r'[-•]\s+(\w+)', topics_text)
        return [t for t in topics if len(t) > 2][:5]  # Top 5, min 3 chars

    # Fallback: chercher "Topics:" inline
    topics = re.findall(r'Topics[^:]*:\s*([^\n]+)', content, re.IGNORECASE)
    if topics:
        words = re.findall(r'\b[a-z]{3,}\b', topics[0].lower())
        return words[:5]

    return []

def extract_outcome(memory: Dict) -> str:
    """Extrait outcome/status de la mémoire"""
    content = memory.get('content', '')

    # Chercher indicateurs de status
    if re.search(r'completed?|done|success|✓|✅', content, re.IGNORECASE):
        return '✅'
    elif re.search(r'blocked|failed|error|✗', content, re.IGNORECASE):
        return '❌'
    else:
        return '📋'

def create_stub_content(memory: Dict, plan_path: str, notion_url: Optional[str], match_type: str) -> str:
    """Génère contenu du stub"""
    title = extract_title(memory)
    topics = extract_topics(memory)
    outcome = extract_outcome(memory)

    created_at = memory.get('created_at', '')
    date = created_at.split('T')[0] if 'T' in created_at else 'unknown'

    stub = f"[session-stub] {title}\n"
    stub += f"Date: {date}\n"
    stub += f"Plan: {plan_path}\n"

    if notion_url:
        stub += f"Notion: {notion_url}\n"

    if topics:
        stub += f"Topics: {', '.join(topics[:5])}\n"

    stub += f"Outcome: {outcome}\n"
    stub += f"Match: {match_type}\n"

    return stub

def create_backfill_plan(memory: Dict) -> str:
    """Crée un plan backfill pour mémoire orpheline"""
    title = extract_title(memory)
    created_at = memory.get('created_at', '')
    date = created_at.split('T')[0] if 'T' in created_at else 'unknown'

    # Nom du fichier backfill
    date_slug = date.replace('-', '')
    title_slug = re.sub(r'[^a-z0-9]+', '-', title.lower())[:30].strip('-')
    backfill_name = f"backfill-{date_slug}-{title_slug}.md"
    backfill_path = PLANS_DIR / backfill_name

    # Contenu du plan backfill
    content = f"# {title}\n\n"
    content += f"**Backfill Plan** - Créé depuis mémoire orpheline\n\n"
    content += f"Date: {date}\n\n"
    content += "## Contexte (depuis Memory)\n\n"
    content += memory.get('content', '')
    content += "\n\n---\n"
    content += "<!-- backfill:created -->\n"

    return str(backfill_path), content

def notion_url_from_page_id(page_id: str) -> str:
    """Convertit page_id en URL Notion"""
    clean_id = page_id.replace('-', '')
    return f"https://notion.so/{clean_id}"

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

def main():
    print("╔════════════════════════════════════════════════════════════════════╗")
    print("║ Cleanup + Linking mémoires session-consolidation                   ║")
    print("╚════════════════════════════════════════════════════════════════════╝\n")

    # Charger mémoires
    print("► Chargement mémoires...")
    memories = load_memories()
    print(f"  {len(memories)} mémoires chargées\n")

    # Phase 1: Analyser qualité
    print("► Phase 1: Analyse qualité")
    stats = analyze_quality(memories)

    print(f"┌─────────────────────────┬───────┬─────────┐")
    print(f"│ Qualité                 │ Count │ %       │")
    print(f"├─────────────────────────┼───────┼─────────┤")

    total = len(memories)
    for label, key in [('Pauvres (<200 chars)', 'poor'),
                        ('Moyennes (200-500)', 'medium'),
                        ('Riches (>500)', 'rich')]:
        count = len(stats[key])
        pct = f"{count*100//total}%" if total > 0 else "0%"
        print(f"│ {label:23} │ {count:5} │ {pct:7} │")

    print(f"└─────────────────────────┴───────┴─────────┘\n")

    # Sauvegarder hashes à supprimer (Phase 1)
    poor_hashes = [m.get('content_hash', '') for m in stats['poor'] if m.get('content_hash')]
    with open('/tmp/cleanup-poor-hashes.txt', 'w') as f:
        f.write('\n'.join(poor_hashes))

    print(f"✓ {len(poor_hashes)} hashes pauvres → /tmp/cleanup-poor-hashes.txt\n")

    # Phase 2.1: Construire index
    print("► Phase 2.1: Construction index Plan → Notion")
    plan_index = parse_plan_markers()
    print(f"  {len(plan_index)} plans avec markers notion:posted\n")

    # Phase 2.2: Matching hybride
    print("► Phase 2.2: Matching hybride")

    to_convert = stats['medium'] + stats['rich']
    matches = {
        'timestamp': [],
        'keywords': [],
        'orphan': []
    }

    for memory in to_convert:
        match = match_memory_to_plan(memory, plan_index)

        if match:
            plan_path, plan_data, match_type = match
            matches[match_type].append({
                'memory': memory,
                'plan_path': plan_path,
                'plan_data': plan_data
            })
        else:
            matches['orphan'].append({'memory': memory})

    print(f"  Timestamp (±2h):  {len(matches['timestamp'])}")
    print(f"  Keywords (±48h):  {len(matches['keywords'])}")
    print(f"  Orphelins:        {len(matches['orphan'])}\n")

    # Phase 2.3: Générer stubs et backfills
    print("► Phase 2.3: Génération stubs et backfills\n")

    stubs = []
    backfills = []

    # Stubs avec liens Plan/Notion
    for match_type in ['timestamp', 'keywords']:
        for item in matches[match_type]:
            memory = item['memory']
            plan_path = item['plan_path']
            plan_data = item['plan_data']

            notion_url = notion_url_from_page_id(plan_data['page_id'])
            stub_content = create_stub_content(memory, plan_path, notion_url, match_type)

            stubs.append({
                'content': stub_content,
                'old_hash': memory.get('content_hash'),
                'tags': ['session-stub'] + extract_topics(memory)
            })

    # Stubs orphelins avec backfill plans
    for item in matches['orphan']:
        memory = item['memory']
        backfill_path, backfill_content = create_backfill_plan(memory)

        stub_content = create_stub_content(memory, backfill_path, None, 'backfill')

        backfills.append({
            'path': backfill_path,
            'content': backfill_content
        })

        stubs.append({
            'content': stub_content,
            'old_hash': memory.get('content_hash'),
            'tags': ['session-stub'] + extract_topics(memory)
        })

    # Sauvegarder résultats
    with open('/tmp/cleanup-stubs.json', 'w') as f:
        json.dump(stubs, f, indent=2)

    with open('/tmp/cleanup-backfills.json', 'w') as f:
        json.dump(backfills, f, indent=2)

    print(f"✓ {len(stubs)} stubs → /tmp/cleanup-stubs.json")
    print(f"✓ {len(backfills)} backfills → /tmp/cleanup-backfills.json\n")

    # Résumé
    print("╔════════════════════════════════════════════════════════════════════╗")
    print("║ RÉSUMÉ                                                             ║")
    print("╚════════════════════════════════════════════════════════════════════╝")
    print(f"  Mémoires pauvres à supprimer:     {len(poor_hashes)}")
    print(f"  Mémoires à convertir en stubs:    {len(stubs)}")
    print(f"  Plans backfill à créer:           {len(backfills)}")
    print(f"  Total après cleanup:              ~{total - len(poor_hashes)} mémoires")
    print()

if __name__ == '__main__':
    main()
