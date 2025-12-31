---
runMode: always
invokedByUser: true
location: user
---

# Playwright MCP - Session Toggle

Activer Playwright MCP pour cette session uniquement.

## Actions

1. Vérifier si Playwright est déjà actif dans ce projet
2. Si inactif, l'activer via `claude mcp add`
3. Confirmer l'activation à l'utilisateur
4. Rappeler que Playwright sera désactivé à la fin de la session

## Implémentation

```bash
# Vérifier si playwright est dans la config du projet
if claude mcp list 2>&1 | grep -q "playwright"; then
  echo "✅ Playwright MCP déjà actif pour cette session"
else
  echo "🔄 Activation de Playwright MCP pour cette session..."
  claude mcp add playwright -- npx @playwright/mcp@latest
  echo "✅ Playwright MCP activé"
  echo "⚠️  Sera désactivé à la fin de cette session"
fi
```

## Notes

- Playwright reste désactivé globalement
- Activation manuelle par session pour économiser ressources
- Utile pour: tests UI, automation navigateur, screenshots
