---
runMode: always
invokedByUser: true
location: user
---

# Consolidate Memory - Manual Trigger

Lance manuellement la consolidation MCP Memory et affiche le statut du système.

## Usage

```
/consolidate-memory [time_horizon]
```

**Paramètres:**
- `time_horizon` (optionnel): daily, weekly, monthly, quarterly, yearly. Défaut: daily

## Actions

1. **Afficher le statut actuel**
   - `scheduler_status`: Horaires configurés, jobs exécutés
   - `check_database_health`: Version, nb memories, taille DB, performance

2. **Lancer la consolidation**
   - `trigger_consolidation`: Lance immédiatement pour le time_horizon spécifié
   - Confirme l'exécution

3. **Afficher les recommandations**
   - `consolidation_recommendations`: Suggestions basées sur l'état actuel

## Workflow

```
Status check → Database health → Trigger consolidation → Recommendations
```

## Notes

- **Scheduler automatique:** La consolidation se lance automatiquement à 14:00
  - Daily: tous les jours à 14:00
  - Weekly: dimanche 14:00
  - Monthly: 1er du mois 14:00
- **Usage manuel:** Pour forcer une consolidation immédiate ou debug
- **Horaires:** Configurés dans ~/.zshrc (MCP_CONSOLIDATION_SCHEDULE_*)

## Exemple

```
/consolidate-memory weekly
→ Affiche status
→ Lance consolidation weekly
→ Affiche recommandations
```
