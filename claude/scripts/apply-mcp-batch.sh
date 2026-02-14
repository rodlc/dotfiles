#!/bin/bash
# Applique les commandes MCP par batch de 10

COMMANDS_FILE="/tmp/cleanup-mcp-commands.json"
OUTPUT_DIR="/tmp/cleanup-mcp-output"

mkdir -p "$OUTPUT_DIR"

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║ Application commandes MCP (mode batch)                            ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo

# Extraire liste des stubs et deletes
jq -r '.store[] | @json' "$COMMANDS_FILE" > "$OUTPUT_DIR/store_commands.jsonl"
jq -r '.delete[] | @json' "$COMMANDS_FILE" > "$OUTPUT_DIR/delete_commands.jsonl"

TOTAL_STORE=$(wc -l < "$OUTPUT_DIR/store_commands.jsonl" | tr -d ' ')
TOTAL_DELETE=$(wc -l < "$OUTPUT_DIR/delete_commands.jsonl" | tr -d ' ')

echo "► Commandes préparées:"
echo "  Store:  $TOTAL_STORE"
echo "  Delete: $TOTAL_DELETE"
echo

# Sauvegarder pour application via Claude Code
cat > "$OUTPUT_DIR/apply-instructions.txt" <<EOF
Les commandes sont prêtes dans:
- Store:  $OUTPUT_DIR/store_commands.jsonl ($TOTAL_STORE lignes)
- Delete: $OUTPUT_DIR/delete_commands.jsonl ($TOTAL_DELETE lignes)

Pour appliquer avec Claude Code, utiliser les outils MCP Memory:
- mcp__memory-service__store_memory (pour chaque ligne de store_commands.jsonl)
- mcp__memory-service__delete_memory (pour chaque ligne de delete_commands.jsonl)

Format JSONL: une commande par ligne
EOF

echo "✓ Instructions sauvegardées → $OUTPUT_DIR/apply-instructions.txt"
echo
echo "► Prêt pour application via Claude Code"
echo "  Les fichiers JSONL peuvent être traités ligne par ligne"
echo
