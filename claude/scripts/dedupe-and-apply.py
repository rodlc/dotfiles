#!/usr/bin/env python3
"""
Déduplique les stubs et génère liste unique à créer
"""

import json
import hashlib
from pathlib import Path
from collections import defaultdict

def content_hash(content):
    """Hash du contenu pour déduplication"""
    return hashlib.sha256(content.encode()).hexdigest()[:16]

def main():
    # Charger toutes les opérations store
    operations_file = Path("/tmp/mcp-operations-remaining.json")
    with open(operations_file) as f:
        data = json.load(f)

    all_store_ops = []
    for batch in data['store_batches']:
        all_store_ops.extend(batch)

    print("╔════════════════════════════════════════════════════════════════════╗")
    print("║ Déduplication des stubs                                           ║")
    print("╚════════════════════════════════════════════════════════════════════╝\n")

    print(f"► Total opérations store: {len(all_store_ops)}")

    # Dédupliquer par contenu
    seen = {}
    unique_ops = []
    duplicates = 0

    for op in all_store_ops:
        h = content_hash(op['content'])
        if h not in seen:
            seen[h] = True
            unique_ops.append(op)
        else:
            duplicates += 1

    print(f"► Après déduplication: {len(unique_ops)} uniques")
    print(f"► Duplicatas éliminés: {duplicates}\n")

    # Sauvegarder opérations uniques
    output_file = Path("/tmp/unique-store-ops.json")
    with open(output_file, 'w') as f:
        json.dump(unique_ops, f, indent=2)

    print(f"✓ Opérations uniques → {output_file}")

    # Statistiques par projet
    projects = defaultdict(int)
    for op in unique_ops:
        content = op['content']
        if 'Plan:' in content:
            plan = content.split('Plan:')[1].split('\n')[0].strip()
            plan_name = Path(plan).stem
            projects[plan_name] += 1

    print(f"\n► Distribution par plan (top 10):")
    for plan, count in sorted(projects.items(), key=lambda x: x[1], reverse=True)[:10]:
        print(f"  {plan:40} {count:3}")

    # Sauvegarder aussi les deletes originaux
    delete_ops = data['delete_ops']
    delete_file = Path("/tmp/unique-delete-ops.json")
    with open(delete_file, 'w') as f:
        json.dump(delete_ops, f, indent=2)

    print(f"\n✓ {len(delete_ops)} delete ops → {delete_file}")

    print("\n╔════════════════════════════════════════════════════════════════════╗")
    print("║ PRÊT POUR APPLICATION FINALE                                       ║")
    print("╚════════════════════════════════════════════════════════════════════╝")
    print(f"  Stubs uniques à créer:      {len(unique_ops)}")
    print(f"  Mémoires à supprimer:       {len(delete_ops)}")
    print()

if __name__ == '__main__':
    main()
