#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# Cleanup Login Items & Background Tasks
# Créé: 2026-01-29
# ══════════════════════════════════════════════════════════════════════════════

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  CLEANUP LOGIN ITEMS & BACKGROUND TASKS                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ── 1. RENOMMER PYTHON → MCP MEMORY ────────────────────────────────────────────
echo "► [1/3] Renommage LaunchAgent python → MCP Memory..."

# Le nom affiché dans System Settings vient du ProcessType et de l'exécutable
# Pour avoir "MCP Memory" au lieu de "python", on peut créer un wrapper
WRAPPER_DIR="$HOME/.local/bin"
WRAPPER_SCRIPT="$WRAPPER_DIR/mcp-memory-http"
PLIST="$HOME/Library/LaunchAgents/com.rodlecoent.mcp-memory-http.plist"

mkdir -p "$WRAPPER_DIR"

# Créer un wrapper script avec le bon nom
cat > "$WRAPPER_SCRIPT" << 'WRAPPER'
#!/bin/bash
# MCP Memory HTTP Server wrapper
exec "$HOME/Code/rodlc/workspace/mcp-servers/mcp-memory-service/venv/bin/python" \
    "$HOME/Code/rodlc/workspace/mcp-servers/mcp-memory-service/scripts/server/run_http_server.py" "$@"
WRAPPER
chmod +x "$WRAPPER_SCRIPT"
echo "  ✓ Wrapper créé: $WRAPPER_SCRIPT"

# Mettre à jour le plist pour utiliser le wrapper
if [ -f "$PLIST" ]; then
    # Backup
    cp "$PLIST" "$PLIST.bak"

    # Modifier pour utiliser le wrapper
    /usr/libexec/PlistBuddy -c "Set :ProgramArguments:0 $WRAPPER_SCRIPT" "$PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Delete :ProgramArguments:1" "$PLIST" 2>/dev/null || true

    echo "  ✓ Plist mis à jour"

    # Recharger le service
    launchctl unload "$PLIST" 2>/dev/null || true
    launchctl load "$PLIST"
    echo "  ✓ Service rechargé"
else
    echo "  ⚠ Plist non trouvé: $PLIST"
fi

echo ""

# ── 2. DÉSACTIVER FIGMA AGENT ──────────────────────────────────────────────────
echo "► [2/3] Désactivation FigmaAgent (usage non régulier)..."

# FigmaAgent est un login item, pas un LaunchAgent
# On peut le désactiver via la commande osascript
FIGMA_AGENT="$HOME/Library/Application Support/Figma/FigmaAgent.app"

if [ -d "$FIGMA_AGENT" ]; then
    # Tuer le process
    pkill -f "FigmaAgent" 2>/dev/null || true
    echo "  ✓ FigmaAgent arrêté"
    echo "  ℹ Pour désactiver au login: System Settings → General → Login Items"
    echo "    Décocher 'FigmaAgent' dans la section Login Items"
else
    echo "  - FigmaAgent non installé"
fi

echo ""

# ── 3. VÉRIFICATION BATTERY ────────────────────────────────────────────────────
echo "► [3/3] Vérification Battery..."

if pgrep -f "battery maintain" > /dev/null; then
    echo "  ✓ Battery daemon actif"
    /usr/local/bin/battery status 2>/dev/null || true
else
    echo "  ⚠ Battery daemon non actif, tentative de démarrage..."
    launchctl load "$HOME/Library/LaunchAgents/battery.plist" 2>/dev/null || true
    sleep 2
    if pgrep -f "battery maintain" > /dev/null; then
        echo "  ✓ Battery démarré avec succès"
    else
        echo "  ✗ Échec du démarrage de Battery"
    fi
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "ACTIONS MANUELLES REQUISES:"
echo "────────────────────────────────────────────────────────────────"
echo ""
echo "1. FigmaAgent: System Settings → General → Login Items"
echo "   → Décocher 'FigmaAgent' dans 'Open at Login'"
echo ""
echo "2. Pour vérifier le nouveau nom 'MCP Memory':"
echo "   → Redémarrer ou se déconnecter/reconnecter"
echo "   → System Settings → General → Login Items → Allow in Background"
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✓ Script terminé"
