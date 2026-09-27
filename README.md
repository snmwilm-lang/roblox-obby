# 200 Levels Difficulty Obby (Roblox)

Difficulty obby de 200 niveaux en 10 zones de 20, où chaque zone apporte une vraie famille de mécaniques (timing, momentum, verticalité, environnement dynamique, contrôle, gravité, réaction, combinaisons, maîtrise), avec une règle forte : **les niveaux X19 et X20 forment une épreuve continue, sans checkpoint entre les deux.**

**V1 (ce dépôt)** : tous les systèmes + la zone 1 complète (niveaux 1–20, Final Stage inclus) + la transition vers la zone 2 (niveau 21 jouable, checkpoint 22).

## Lancer le jeu

Le plus simple : ouvrir **`Obby200.rbxl`** dans Roblox Studio (**File → Open from File…**). La carte est visible directement en mode édition (dossier `Workspace > Obby`), puis **Play** (F5) pour jouer.

Reconstruire ce fichier après une modification du code ([Rojo](https://rojo.space) 7.4 et [Lune](https://lune-org.github.io), installables avec `rokit install`) :

```bash
rojo build -o build/place.rbxlx
lune run tools/bake.luau build/place.rbxlx Obby200.rbxl   # construit la carte dans le fichier
```

Le serveur réutilise la carte enregistrée dans le fichier (modifiable dans Studio). Si le dossier `Workspace > Obby` est supprimé, il la reconstruit depuis le code au lancement.

Pour tester la sauvegarde et les classements : publier le jeu, puis **Game Settings → Security → Enable Studio Access to API Services** (sans cela le jeu fonctionne, avec un bandeau « progression non sauvegardée »).

## Tests

```bash
lune run tests/run.luau              # ~1650 vérifications, dont la faisabilité de chaque saut
lune run tools/gen_level_plan.luau   # régénère docs/LEVEL_PLAN.md
```

## Documentation

| Document | Contenu |
|---|---|
| [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) | vision, zones, règle des checkpoints, difficulté, DA, audio, UI, multijoueur, monétisation, feuille de route |
| [docs/MECHANICS.md](docs/MECHANICS.md) | chaque mécanique en 9 points (fonctionnement, variables, difficulté, interactions, technique, multijoueur, mobile, feedback visuel et sonore) |
| [docs/LEVEL_PLAN.md](docs/LEVEL_PLAN.md) | tableau des 200 niveaux (généré) |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | code, flux, système d'obstacles modulaire, construction des niveaux, données |
| [docs/TESTING.md](docs/TESTING.md) | tests automatiques + checklist de playtest |

## Personnaliser rapidement

* Musiques / ambiances : ids dans `src/shared/Zones.luau` (vides par défaut).
* Effets sonores : table `SOUNDS` de `src/client/Controllers/AudioController.luau`.
* Un niveau : `src/server/World/Levels/Zone1.luau` puis `lune run tests/run.luau`.
