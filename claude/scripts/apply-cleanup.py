#!/usr/bin/env python3
"""
Applique le cleanup: crée stubs, backfills, supprime originaux
"""

import json
import sys
from pathlib import Path

STUBS_FILE = Path("/tmp/cleanup-stubs.json")
BACKFILLS_FILE = Path("/tmp/cleanup-backfills.json")

def main():
    # Charger données
    with open(STUBS_FILE) as f:
        stubs = json.load(f)

    with open(BACKFILLS_FILE) as f:
        backfills = json.load(f)

    print("╔════════════════════════════════════════════════════════════════════╗")
    print("║ Application du cleanup                                            ║")
    print("╚════════════════════════════════════════════════════════════════════╝\n")

    # 1. Créer backfill plans
    print(f"► Création de {len(backfills)} plans backfill...")
    for bf in backfills:
        path = Path(bf['path'])
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(bf['content'])
        print(f"  ✓ {path.name}")

    print()

    # 2. Préparer commandes pour MCP Memory
    print("► Génération commandes MCP...")

    # Créer stubs
    store_commands = []
    for stub in stubs:
        cmd = {
            'action': 'store_memory',
            'content': stub['content'],
            'tags': stub['tags']
        }
        store_commands.append(cmd)

    # Supprimer originaux
    delete_commands = []
    for stub in stubs:
        if stub.get('old_hash'):
            cmd = {
                'action': 'delete_memory',
                'content_hash': stub['old_hash']
            }
            delete_commands.append(cmd)

    # Sauvegarder commandes
    commands_file = Path('/tmp/cleanup-mcp-commands.json')
    with open(commands_file, 'w') as f:
        json.dump({
            'store': store_commands,
            'delete': delete_commands
        }, f, indent=2)

    print(f"  ✓ {len(store_commands)} commandes store_memory")
    print(f"  ✓ {len(delete_commands)} commandes delete_memory")
    print(f"  ✓ Sauvegardé → {commands_file}\n")

    print("╔════════════════════════════════════════════════════════════════════╗")
    print("║ PRÊT À APPLIQUER                                                   ║")
    print("╚════════════════════════════════════════════════════════════════════╝")
    print(f"  Plans backfill créés:     {len(backfills)}")
    print(f"  Stubs à créer:            {len(store_commands)}")
    print(f"  Mémoires à supprimer:     {len(delete_commands)}")
    print()
    print("► Prochaine étape: Appliquer les commandes MCP")
    print("  (via Claude Code avec outils MCP Memory)\n")

if __name__ == '__main__':
    main()
