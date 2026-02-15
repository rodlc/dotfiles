# Audit Homebrew — Commandes manuelles finales

## État actuel

L'audit automatisé a été exécuté avec succès partiel :

```
✓ Brewfile nettoyé et réécrit
✓ Script brew-audit.sh créé
✓ Taps inutiles supprimés (heroku/brew, teamookla/speedtest)
✓ Formulae orphelines désinstallées (go, ghostscript, openssl@3.5, python@3.12, etc.)
✓ Packages upgradés (sqlite, deno, node, mpv, ffmpeg, weasyprint, etc.)
✓ Cache nettoyé (~390MB libérés)

✗ 9 casks orphelins toujours présents (erreurs sudo)
✗ ykman upgrade échoué (problème permissions)
⚠ raycast/zed non adoptés par brew (auto-update, OK)
```

────────────────────────────────────────────────────────────────

## Casks orphelins à supprimer manuellement

Ces casks nécessitent sudo interactif et doivent être supprimés à la main :

```bash
# Supprimer les casks orphelins un par un
brew uninstall --zap balenaetcher
brew uninstall --zap battery
brew uninstall --zap bruno
brew uninstall --zap gdisk
brew uninstall --zap iterm2
brew uninstall --zap keepassxc
brew uninstall --zap veracrypt
brew uninstall --zap macfuse
brew uninstall --zap visual-studio-code
```

**Note :** `--zap` supprime aussi les fichiers de configuration/support.
Si tu veux garder les configs, enlève le flag `--zap`.

────────────────────────────────────────────────────────────────

## Fixer ykman

Le package ykman a eu un problème de permissions lors de l'upgrade :

```bash
# Option 1 : Forcer réinstallation
brew reinstall ykman

# Option 2 : Si ça échoue encore
brew uninstall ykman
brew install ykman
```

────────────────────────────────────────────────────────────────

## Raycast et Zed (auto-update)

Ces apps sont installées hors brew (auto-update). Brew veut les "adopter" mais échoue
sans sudo interactif. **C'est OK de les laisser comme ça** — elles se mettent à jour
toutes seules.

Si tu veux vraiment les gérer via brew :

```bash
# Option A : Retirer du Brewfile (recommandé)
# Éditer ~/Code/rodlc/dotfiles/Brewfile et commenter :
# cask "raycast"
# cask "zed"

# Option B : Les adopter manuellement (nécessite sudo)
sudo chown -R $(whoami):admin /Applications/Raycast.app
sudo chown -R $(whoami):admin /Applications/Zed.app
brew bundle install --file=~/Code/rodlc/dotfiles/Brewfile
```

────────────────────────────────────────────────────────────────

## Vérification finale

Après avoir exécuté les commandes manuelles :

```bash
# 1. Vérifier que tous les orphelins sont partis
brew list --cask | grep -E "(visual-studio-code|iterm2|battery|bruno|keepassxc|balenaetcher|gdisk|macfuse|veracrypt)"
# → Devrait être vide

# 2. Vérifier conformité Brewfile
brew bundle check --file=~/Code/rodlc/dotfiles/Brewfile --verbose
# → Devrait dire "satisfied" (sauf raycast/zed si auto-update)

# 3. Lister les casks restants
brew list --cask

# 4. Lister les formulae "leaves" (sans dépendants)
brew leaves

# 5. Cleanup final
brew autoremove
brew cleanup -s
```

────────────────────────────────────────────────────────────────

## Commit final

Une fois tout propre :

```bash
cd ~/Code/rodlc/dotfiles
git add Brewfile scripts/system/brew-audit.sh BREW_CLEANUP_MANUAL.md
git commit -m "Audit Homebrew: nettoyer Brewfile + ajouter brew-audit.sh

- Retrait casks orphelins (vscode, iterm2, battery, etc.)
- Retrait formulae obsolètes (go, ghostscript, python@3.12, etc.)
- Ajout yt-dlp, pinentry-mac, ykman, finicky, google-chrome
- Script brew-audit.sh pour drift detection
- ~390MB cache libéré"
```

────────────────────────────────────────────────────────────────

## Résumé des changements

### Casks ajoutés
- google-chrome
- finicky

### Casks retirés
- balenaetcher
- battery
- bruno
- gdisk
- gcloud-cli
- iterm2
- keepassxc
- macfuse
- veracrypt
- visual-studio-code

### Formulae ajoutées
- yt-dlp
- pinentry-mac
- ykman

### Formulae retirées
- go
- ghostscript
- jbig2dec
- libidn
- openssl@3.5
- python@3.12
- sqlcipher
- speedtest (teamookla)

### Taps retirés
- heroku/brew
- teamookla/speedtest
