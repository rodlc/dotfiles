#!/usr/bin/env python3
"""
Finalise les opérations MCP Memory en utilisant les batches préparés
"""

import json
import subprocess
import sys
from pathlib import Path

BULK_BATCH_DIR = Path("/tmp")
DELETE_OPS_FILE = Path("/tmp/delete-ops.json")

def load_batches():
    """Charge tous les bulk-batch-*.json"""
    batches = sorted(BULK_BATCH_DIR.glob("bulk-batch-*.json"))
    return [json.loads(b.read_text()) for b in batches]

def load_delete_ops():
    """Charge les opérations delete"""
    if DELETE_OPS_FILE.exists():
        return json.loads(DELETE_OPS_FILE.read_text())
    return []

def format_mcp_store_call(operation):
    """Formate un appel mcp__memory-service__store_memory pour Claude Code"""
    return {
        "tool": "mcp__memory-service__store_memory",
        "parameters": {
            "content": operation["content"],
            "tags": operation["tags"]
        }
    }

def format_mcp_delete_call(operation):
    """Formate un appel mcp__memory-service__delete_memory pour Claude Code"""
    return {
        "tool": "mcp__memory-service__delete_memory",
        "parameters": {
            "content_hash": operation["content_hash"]
        }
    }

def print_summary():
    """Affiche résumé des opérations restantes"""
    batches = load_batches()
    delete_ops = load_delete_ops()

    total_store = sum(len(b) for b in batches)

    print("╔════════════════════════════════════════════════════════════════════╗")
    print("║ Résumé opérations MCP Memory restantes                            ║")
    print("╚════════════════════════════════════════════════════════════════════╝\n")

    print(f"► Store operations restantes:")
    print(f"  Batches: {len(batches)}")
    print(f"  Total ops: {total_store}")
    print()

    print(f"► Delete operations:")
    print(f"  Total ops: {len(delete_ops)}")
    print()

    print("► Commandes nécessaires:")
    print(f"  Store:  {total_store} appels mcp__memory-service__store_memory")
    print(f"  Delete: {len(delete_ops)} appels mcp__memory-service__delete_memory")
    print()

    # Exporter format utilisable par Claude Code
    output_file = Path("/tmp/mcp-operations-remaining.json")
    output_data = {
        "store_batches": batches,
        "delete_ops": delete_ops,
        "summary": {
            "store_total": total_store,
            "delete_total": len(delete_ops),
            "status": "ready_to_apply"
        }
    }

    output_file.write_text(json.dumps(output_data, indent=2))
    print(f"✓ Opérations exportées → {output_file}")

if __name__ == '__main__':
    print_summary()
