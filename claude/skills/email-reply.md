---
runMode: always
invokedByUser: true
location: user
---

# Email Reply - Draft Generator

Génère un brouillon de réponse email personnalisé en respectant le style d'écriture de Rodolphe.

## Usage

```
/email-reply [messageId]
```

**Paramètres:**
- `messageId` (optionnel): ID du message Gmail à traiter. Si omis, demande à l'utilisateur.

## Actions

1. **Lecture du contexte complet**
   - Récupérer l'email via Gmail MCP (read_email)
   - **CRUCIAL:** Lire tout le thread, pas juste l'email ciblé
   - Extraire: expéditeur, sujet, dates, événements mentionnés, participants

2. **Détection des destinataires**
   - **TO:** L'expéditeur de l'email original
   - **CC:** Identifier tous les participants actifs du thread
   - Vérifier qui est mentionné dans le contexte (ex: "je préviens X en cc")

3. **Analyse temporelle**
   - Calculer le délai de réponse
   - Si >3 jours → mentionner délai/fêtes/excuse légère

4. **Analyse du style et ton appropriés**
   - Consulter ~/.claude/email-style.md pour la structure
   - Catégories:
     - **Pro External** (rodolphe.lecoent): clients, recruteurs, consulting
     - **Pro Internal** (rodolphe.lecoent): collègues, partenariats
     - **Formal** (rodlecoent): notaire, admin, légal
     - **Casual** (rodlecoent): amis, contacts techniques, projets perso

   - **Principes de ton:**
     - **Direct sans brusquerie:** "je vais décliner" > "malheureusement je ne pourrai pas"
     - **Reconnaissance sincère:** "J'ai apprécié nos échanges" (si vrai)
     - **Justification claire:** Une raison précise, pas d'excuses excessives
     - **Positif en clôture:** "Bon courage pour la suite !" pour maintenir la relation

5. **Génération du brouillon**
   - Rédiger une réponse **personnalisée** basée sur le contexte réel
   - Mentionner dates/événements/personnes spécifiques du thread
   - Respecter les règles universelles (pas de phrases vides, questions directes)
   - Signature: *Full Name*\n+33 6 45 45 80 70

6. **Création du draft**
   - Utiliser draft_email avec threadId + to + cc
   - Confirmer la création à l'utilisateur

## Workflow

```
User input → Read email → Analyze context → Select style category → Draft reply → Create Gmail draft
```

## Exemples de détection de catégorie

- Email from client/recruiter → **Pro External**
- Email from colleague (Salut/Hola) → **Pro Internal**
- Email from notary/admin → **Formal**
- Email from friend → **Casual**

## Notes critiques

- **Contexte > template:** Toujours lire le thread complet, pas juste l'email
- **CC essentiels:** Analyser qui doit être en copie (participants actifs, personnes mentionnées)
- **Personnalisation:** Mentionner dates/événements/noms spécifiques du thread
- **Délais de réponse:** Adapter le ton si réponse tardive
- **Recherche large:** Si messageId manquant, chercher avec critères larges (ex: "company OR subject after:YYYY/MM/DD")

Le skill consulte automatiquement ~/.claude/email-style.md pour le style, mais le contexte prime sur le template.
