---
description: Monthly portfolio update in Notion Budget page
argument-hint: "<YYYYMM>"
---

<budget-goals-command>

# Command `/budget-goals` — Automatisation mensuelle Budget Goals

## Usage

```
/budget-goals 202602
```

Met à jour la page Notion "Budget-{YYYYMM}" avec les nouvelles valeurs du portefeuille.

## Workflow

### Phase 1 — LOAD (automatique)

**Objectif** : Charger la page cible et la référence M-1 (ou M-2, M-3).

**Actions** :
1. **Rechercher page cible** : `notion_search` avec query `"Budget-{YYYYMM}"` ou `"{YYYYMM} Goals"`
2. **Rechercher page référence** : M-1 par défaut, fallback M-2 puis M-3 si inexistante
3. **Extraire block IDs** : `notion_retrieve_block_children(page_id, json)` → identifier :
   - Table répartition (4 colonnes)
   - Heading_3 "Portefeuille consolidé"
   - Table portefeuille (7 colonnes)
   - Dernier bloc AVANT table répartition (anchor pour append)
4. **Extraire valeurs M-N** : `notion_retrieve_block_children(ref_table_id, json)` → parser les montants EUR
5. **Présenter état actuel** : afficher en terminal les valeurs M-N avec box-drawing

**Output** : État actuel visible, block IDs stockés pour Phase 5.

---

### Phase 2 — INPUT (interactif)

**Objectif** : Collecter nouvelles valeurs du user.

**Actions** :
1. **Demander input** : user fournit (free-form, screenshots, deltas)
2. **Parser positions** : construire liste `{position, devise, montant_brut, risque, commentaire}`
3. **Fetch FX rates** : `WebFetch` sur xe.com ou ECB pour taux live (USD/EUR, SGD/EUR)
4. **Confirmer scope** : user valide "le reste inchangé" ou ajoute positions

**Output** : Liste complète des positions avec taux FX validés.

---

### Phase 3 — COMPUTE (automatique)

**Objectif** : Calculer montants EUR, sous-totaux, variations.

**Règles** :
- **Seuil visibilité** : > 1 000 €
- **Conversion FX** : montant_brut × taux → montant_eur (arrondi entier)
- **Sous-totaux** : somme des lignes visibles par section uniquement
- **Variation M-N** : `(new - ref) / ref × 100`, arrondi 1 décimale, format `+X,Y %`
  - Cas spéciaux : `n/a` (nouveau), `—` (inchangé), `-100,0 %` (liquidé)
- **% du total** : pour table répartition, `catégorie / total × 100`

**Sections** :
1. **— Actifs € — FINANCIER** (comptes, ETF EUR, crypto, illiquide)
2. **— Actifs € — TANGIBLE** (véhicules, métaux, immobilier)
3. **— Actifs FX — FINANCIER** (ETF USD, cash USD, SGD)

**Output** : 2 structures de données (répartition + portefeuille).

---

### Phase 4 — CONFIRM (interactif)

**Objectif** : User valide les données calculées.

**Actions** :
1. **Afficher tables en terminal** avec box-drawing :
   ```
   ╔══════════════════════════════════════════════════════════╗
   ║ RÉPARTITION                                              ║
   ╠══════════════════════════════════════════════════════════╣
   ║ Catégorie         │ Montant (€) │ % total │ Variation   ║
   ╟──────────────────────────────────────────────────────────╢
   ║ Actifs €          │     X XXX   │  XX,X % │    +X,X %   ║
   ...
   ```
2. **Highlighter changements** : `▲` hausse, `▼` baisse, `NEW` nouveau poste
3. **User approuve** ou corrige

**Output** : Validation pour Phase 5.

---

### Phase 5 — WRITE (automatique)

**Objectif** : Mettre à jour la page Notion.

**Actions** :
1. **Delete anciens blocs** :
   - `notion_delete_block(table_répartition_id)`
   - `notion_delete_block(heading_3_id)`
   - `notion_delete_block(table_portefeuille_id)`

2. **Append table répartition** :
   ```json
   {
     "parent": {"page_id": "..."},
     "after": "anchor_block_id",
     "children": [{
       "type": "table",
       "table": {
         "table_width": 4,
         "has_column_header": true,
         "has_row_header": false,
         "children": [
           {
             "type": "table_row",
             "table_row": {
               "cells": [
                 [{"type": "text", "text": {"content": "Catégorie"}}],
                 [{"type": "text", "text": {"content": "Montant (€)"}}],
                 [{"type": "text", "text": {"content": "% du total"}}],
                 [{"type": "text", "text": {"content": "Variation M-N"}}]
               ]
             }
           },
           {
             "type": "table_row",
             "table_row": {
               "cells": [
                 [{"type": "text", "text": {"content": "Actifs €", "annotations": {"bold": true}}}],
                 [{"type": "text", "text": {"content": "XX XXX"}}],
                 [{"type": "text", "text": {"content": "XX,X %"}}],
                 [{"type": "text", "text": {"content": "+X,X %"}}]
               ]
             }
           }
           // ... autres rows
         ]
       }
     }]
   }
   ```

3. **Append heading_3** :
   ```json
   {
     "type": "heading_3",
     "heading_3": {
       "rich_text": [{"type": "text", "text": {"content": "Portefeuille consolidé"}}]
     }
   }
   ```

4. **Append table portefeuille** :
   ```json
   {
     "type": "table",
     "table": {
       "table_width": 7,
       "has_column_header": true,
       "children": [
         {
           "type": "table_row",
           "table_row": {
             "cells": [
               [{"type": "text", "text": {"content": "Position"}}],
               [{"type": "text", "text": {"content": "Devise"}}],
               [{"type": "text", "text": {"content": "Brut (devise)"}}],
               [{"type": "text", "text": {"content": "Euro (€)"}}],
               [{"type": "text", "text": {"content": "Variation M-N"}}],
               [{"type": "text", "text": {"content": "Risque"}}],
               [{"type": "text", "text": {"content": "Commentaire"}}]
             ]
           }
         },
         {
           "type": "table_row",
           "table_row": {
             "cells": [
               [{"type": "text", "text": {"content": "TOTAL GÉNÉRAL", "annotations": {"bold": true}}}],
               [{"type": "text", "text": {"content": ""}}],
               [{"type": "text", "text": {"content": ""}}],
               [{"type": "text", "text": {"content": "XXX XXX", "annotations": {"bold": true}}}],
               [{"type": "text", "text": {"content": "+X,X %"}}],
               [{"type": "text", "text": {"content": ""}}],
               [{"type": "text", "text": {"content": ""}}]
             ]
           }
         }
         // ... sections + rows
       ]
     }
   }
   ```

5. **Verify** : `notion_retrieve_block_children(page_id)` → confirmer block count

**Output** : Page Notion mise à jour.

---

### Phase 6 — WRAP-UP

**Objectif** : Confirmer succès et suggérer suivi.

**Actions** :
1. **Afficher résumé** :
   ```
   ✓ Page Budget-{YYYYMM} mise à jour
   ✓ Total : XXX XXX €
   ✓ Variation : +X,X %

   🔗 https://notion.so/...
   ```

2. **Suggérer /memorize** si nouvelles conventions découvertes

---

## Schémas Notion API

### Table répartition (4 cols × 5 rows)

**Colonnes** : Catégorie | Montant (€) | % du total | Variation M-N

**Rows** :
1. Header (has_column_header: true)
2. Actifs € (bold)
3. Actifs FX (bold)
4. Tangibles (bold)
5. **TOTAL GÉNÉRAL** (bold)

### Table portefeuille (7 cols × ~27 rows)

**Colonnes** : Position | Devise | Brut (devise) | Euro (€) | Variation M-N | Risque | Commentaire

**Structure** :
1. Header
2. **TOTAL GÉNÉRAL** (row 1, bold)
3. **— Actifs € — FINANCIER** (section header, bold)
   - Compte chèque FR
   - Compte épargne FR
   - ETF World EUR
   - Crypto (BTC, ETH)
   - Illiquide (ADP, etc.)
4. **— Actifs € — TANGIBLE** (section header, bold)
   - Véhicules
   - Métaux précieux
   - Immobilier (estimé)
5. **— Actifs FX — FINANCIER** (section header, bold)
   - ETF S&P 500 USD
   - Cash USD
   - Cash SGD

Sections = sous-totaux bold, pas de border visuel (juste typographie).

---

## Conventions

- **Pages Notion** : "Budget-{YYYYMM}" ou "{YYYYMM} Goals"
- **Référence** : M-1 par défaut, fallback M-2, M-3
- **Seuil visibilité** : > 1 000 €
- **Variation format** : `+X,Y %` (1 décimale)
- **FX** : WebFetch automatique (xe.com ou ECB)
- **API** : delete anciens blocs + recreate (table_row non éditable)
- **Block discovery** : dynamique à chaque exécution (pas de hardcode IDs)

</budget-goals-command>
