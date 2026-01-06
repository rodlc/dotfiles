---
description: Extract metadata to MCP Memory
---

Extract metadata reusable across sessions, using tier-based storage.

## Tiers de stockage

| Tier | Tags | TTL | Critères |
|------|------|-----|----------|
| T1 Core | `reference`, `identity` | ∞ | IDs, paths critiques, jamais obsolète |
| T2 Stable | `convention`, `preference` | 12 mois | Workflows, règles établies |
| T3 Tooling | `tooling`, `project` | 6 mois | Commandes, contexte projet actif |
| T4 Ephemeral | `temp`, `session` | 1 mois | Infos jetables, contexte immédiat |

**Stocker directement** avec tag approprié. Le decay gère l'obsolescence.

## Anti-patterns (ne PAS stocker)

- ❌ Bugfixes techniques → code source = référence
- ❌ Commandes CLI standard → découvrables via --help
- ❌ Contenu de fichiers config → déjà persisté sur disque
- ❌ Listes qui changent souvent → vite obsolète
- ❌ Décisions projet-specific → /notion

## Workflow

1. Scan session pour candidats metadata
2. Appliquer test de valeur (3 questions)
3. Check duplicates via retrieve_memory
4. Présenter avec justification OU conclure "Aucune"

## Output

### Si metadata trouvée :
```
## Proposed Memories

**[tag] Titre**
Contenu concis
Justification: Pourquoi stockage permanent ?

Store? (yes/no/numbers)
```

### Si rien de pertinent :
```
## Aucune metadata

Raison: [explication courte]
```
