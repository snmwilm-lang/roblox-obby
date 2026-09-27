# 200 Levels Difficulty Obby (Roblox)

Difficulty obby de 200 niveaux en 10 zones de 20, où chaque zone apporte une vraie famille de mécaniques (timing, momentum, verticalité, environnement dynamique, contrôle, gravité, réaction, combinaisons, maîtrise), avec une règle forte : **les niveaux X19 et X20 forment une épreuve continue, sans checkpoint entre les deux.**

**V1 (ce dépôt)** : tous les systèmes + la zone 1 complète (niveaux 1–20, Final Stage inclus) + la transition vers la zone 2 (niveau 21 jouable, checkpoint 22).

## Lancer le jeu

Outils : [Rojo](https://rojo.space) 7.4 (et [Lune](https://lune-org.github.io) pour les tests), installables avec `rokit install`.

```bash
rojo build -o Obby200.rbxlx     # puis ouvrir Obby200.rbxlx dans Roblox Studio
# ou, pour développer en direct :
rojo serve                      # + plugin Rojo dans Studio → Connect
```

Dans Studio : **Game Settings → Security → Enable Studio Access to API Services** pour tester la sauvegarde et les classements (sans cela le jeu fonctionne, mais affiche que la progression n'est pas sauvegardée). Recommandé : **Game Settings → Avatar → R15, échelles par défaut**.

Le monde est construit par le serveur au démarrage : lancez **Play** pour voir les niveaux (ils n'existent pas en mode édition).

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
