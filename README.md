# 200 Levels Difficulty Obby (Roblox)

Difficulty obby de 200 niveaux en 10 zones de 20, où chaque zone apporte une vraie famille de mécaniques (timing, momentum, verticalité, environnement dynamique, contrôle, gravité, réaction, combinaisons, maîtrise), avec une règle forte : **les niveaux X19 et X20 forment une épreuve continue, sans checkpoint entre les deux.**

**Version actuelle** : tous les systèmes + les **100 premiers niveaux** (zones 1 à 5, avec leurs 5 Final Stages) + le checkpoint 101 (entrée de la zone 6, fermée par une barrière).

Contrôles : ZQSD/WASD ou flèches, Espace pour sauter, **Shift = shift lock** (ou bouton SHIFT LOCK à l'écran / L2 à la manette) pour des sauts précis le long des murs.

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

## Boutique Robux

Le bouton **SHOP** propose trois produits (prix affichés : `src/shared/Config.luau`) :

| Produit | Prix | Effet |
|---|---|---|
| Skip level | 17 R$ | passe au checkpoint suivant |
| Kill everyone | 2 500 R$ | tous les autres joueurs du serveur retournent à leur checkpoint |
| Everyone to level 1 | 150 000 R$ | tous les autres joueurs du serveur repartent du niveau 1 (checkpoint sauvegardé remis à 1 ; meilleur niveau et classements conservés) |

Mise en place (obligatoire, Roblox ne permet pas de créer les produits depuis le code) :
1. Publier le jeu, puis sur create.roblox.com : **Creations → le jeu → Monetization → Developer Products → Create**.
2. Créer les 3 produits avec ces prix.
3. Copier chaque **Product ID** dans `Config.Products` (`SkipLevel`, `KillEveryone`, `ResetEveryone`) — dans Studio : `ReplicatedStorage > Shared > Config`.

Tant qu'un id vaut 0, le bouton affiche « not set up yet ».

## Personnaliser rapidement

* Musiques / ambiances : ids dans `src/shared/Zones.luau` (vides par défaut).
* Effets sonores : table `SOUNDS` de `src/client/Controllers/AudioController.luau`.
* Un niveau : `src/server/World/Levels/Zone1.luau` puis `lune run tests/run.luau`.
