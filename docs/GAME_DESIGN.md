# 200 Levels Difficulty Obby — Game Design Document

## 1. Vision

Un obby qui commence comme un obby Roblox classique puis révèle une vraie profondeur mécanique.
Le joueur qui atteint le niveau 200 maîtrise des mécaniques qu'il ne connaissait pas au niveau 1.

Piliers :

1. **Juste** : chaque mort doit se lire comme « j'ai raté quelque chose ». Pas de RNG, pas de piège invisible, pas de glitch requis.
2. **Rapide à recommencer** : mort → effet de 0.2 s → retour au checkpoint, même personnage, pas d'écran noir.
3. **Lisible** : un langage visuel identique dans les 10 zones (rouge = mort, jaune = bouge, etc.).
4. **Progressif** : chaque zone introduit une famille de mécaniques, les zones suivantes les combinent.
5. **Skill only** : rien ne s'achète qui facilite le parcours.

## 2. Structure

200 niveaux = 10 zones × 20 niveaux. Détail complet par niveau : [`LEVEL_PLAN.md`](LEVEL_PLAN.md).

| Zone | Niveaux | Nom | Thème | Difficulté | Mécanique principale |
|---:|---|---|---|---|---|
| 1 | 1–20 | INTRODUCTION | Verdant Plateau (îles flottantes, jour) | EASY | sauts, kill bricks, premières plateformes mobiles, spinners lents, wraparounds faciles |
| 2 | 21–40 | TIMING | Clockwork Foundry (laiton, crépuscule) | MEDIUM | plateformes fantômes, portes temporisées, lasers à cycle, séquences |
| 3 | 41–60 | MOMENTUM | Velocity Canyon (grès, plein soleil) | HARD | tapis, jump pads, pentes, boost, momentum gates |
| 4 | 61–80 | VERTICALITY | Skyward Spire (marbre, au-dessus des nuages) | DIFFICULT | truss, échelles, head hitters, wraparounds avancés, ascensions |
| 5 | 81–100 | DYNAMIC | Shifting Ruins (orage) | CHALLENGING | plateformes qui tombent, vent, blocs basculants, murs mobiles, chasers |
| 6 | 101–120 | CONTROL | Frost Circuit (nuit, aurore) | INTENSE | glace, goudron, surfaces d'accélération, inertie |
| 7 | 121–140 | GRAVITY | Orbital Station (espace) | REMORSELESS | zones de gravité, gravity pads, rotation rooms |
| 8 | 141–160 | REACTION | Reactor Core (industriel, alarmes) | INSANE | pièges de proximité télégraphiés, murs surgissants, plateformes temporaires |
| 9 | 161–180 | COMBINATIONS | Prism Nexus (cristal, aube) | EXTREME | combinaisons de mécaniques par paires puis triplets |
| 10 | 181–200 | MASTERY | Summit of Mastery (sommet, coucher de soleil) | TERRIFYING | aucune règle nouvelle : maîtrise, longueur, pression |

Le parcours monte physiquement : chaque zone est plus haute que la précédente, et le sommet (niveau 200) est visible de loin — « le joueur voit progressivement l'arrivée ».

### Courbe à l'intérieur d'une zone

| Index | Rôle | Intention |
|---|---|---|
| X1 | Introduction | la nouvelle mécanique seule, dans sa forme la plus généreuse, avec un panneau |
| X2–X5 | Apprentissage | une variante par niveau (vitesse, taille, orientation) |
| X6–X10 | Développement | la mécanique + une mécanique d'une zone précédente |
| X11–X15 | Difficulté | fenêtres plus courtes, cibles plus petites, enchaînements |
| X16–X18 | Maîtrise | variantes exigeantes, peu de temps mort |
| X19 | Pré-finale | révision de la zone, ~1.6× plus long, débouche sur X20 **sans checkpoint** |
| X20 | Final Stage | examen de 3 à 5× la longueur d'un niveau normal, sections nommées (I, II, III…) |

La difficulté ne redescend jamais (note monotone dans `LevelPlan`, vérifiée par les tests), mais les premiers niveaux d'une zone sont techniquement plus simples pour laisser apprendre la nouvelle mécanique : la note monte parce que la nouvelle mécanique est inconnue.

### Objectif émotionnel

| Niveau | Ressenti visé | Levier |
|---|---|---|
| 1–20 | « Ça va. » | grands écarts pardonnés, panneaux explicatifs |
| 40 | « Ok, le jeu commence. » | premier Final Stage où il faut observer avant d'agir |
| 80 | « Il faut que je me concentre. » | grande ascension, la chute coûte cher visuellement |
| 100 | « J'ai fait la moitié. » | Final Stage 100 : bannière dédiée, ruines qui s'effondrent autour du joueur |
| 140 | « Ça devient sérieux. » | la station entière pivote |
| 180 | « Je suis vraiment loin. » | Nexus : toutes les paires de mécaniques |
| 190 | « Je peux finir. » | niveau-respiration exigeant mais propre |
| 199 | « Putain. » | pré-finale ultime, arche dorée « NO CHECKPOINT » |
| 200 | « Je dois absolument réussir. » | FINAL EXAM, 10 sections, musique qui évolue, arrivée visible |

## 3. Règle fondamentale des checkpoints

```
1 → CP → 2 → CP → … → 18 → CP → 19 → 20 → CP (zone 2) → 21 …
                               └── épreuve continue ──┘
```

* Chaque niveau a un checkpoint à son départ **sauf** les Final Stages (20, 40, …, 200).
* Mort en 17 → retour en 17. Mort en 19 → retour en 19. Mort en 20 à 90 % → retour en **19**.
* Arrivé au 140 sans le finir → checkpoint sauvegardé = **139**.
* Toucher le checkpoint 21 valide les niveaux 19 et 20 et la zone 1.
* Anti-skip : seul le checkpoint suivant peut être validé (19 → 21, jamais 17 → 19).
* Checkpoint 201 (interne) = salle de victoire après le 200.

Implémentation : `src/shared/CheckpointRules.luau` (fonctions pures, testées), appliquée par `CheckpointService` côté serveur. Le déclencheur couvre tout le pad de départ : impossible de passer à côté sans le valider.

Visuellement : pad de départ normal = disque blanc lumineux (vert une fois validé). Final Stage = cadre doré + arche « FINAL STAGE · NO CHECKPOINT ». Pré-finale = panneau doré « 19 → 20 NO CHECKPOINT IN BETWEEN ».

## 4. Philosophie de difficulté

La difficulté vient de **plusieurs axes**, pas seulement de la taille des plateformes :

| Axe | Exemples |
|---|---|
| Précision | pierres 4×4 → cylindres → poutres 1.5 stud → cibles 2 studs (zone 10) |
| Timing | spinners, pistons, fantômes, lasers, portes |
| Observation | salle de lave (lire le chemin), cycles à regarder avant de partir |
| Anticipation | glace (on glisse après l'atterrissage), gravité faible (sauts longs) |
| Contrôle | poutres fines, virages sur glace, head hitters |
| Momentum | boost, pentes, momentum gates |
| Réaction | pièges de proximité **télégraphiés** (lumière + son + délai fixe) |
| Gravité | 0.5×, 1.5×, 2×, rotation rooms |
| Mémorisation légère | memory path (rare), motifs de pics |
| Enchaînement / pression | Final Stages, chasers, zone 10 |

Règles de justice (appliquées dans le code et les tests) :

* **Enveloppe de saut** : WalkSpeed 16, JumpPower 50 → un saut à plat parcourt ≈ 8.2 studs et monte de ≈ 6.4 studs. Chaque saut de chaque parcours est vérifié automatiquement contre un budget par zone (zone 1 ≤ 62 % du saut max ; les Final Stages +5 %).
* **Rythmes vérifiés** : un simulateur vérifie qu'il existe un timing permettant d'enchaîner tout le parcours (fantômes, navettes).
* **Hitbox standardisée** : boîte 1.6 × 5.6 × 1.6 à partir des pieds, un peu plus petite que l'avatar ; les échelles d'avatar R15 sont normalisées. Les frôlements restent des frôlements.
* **Limbo bars** : toujours ≥ 5.9 studs au-dessus du sol (on passe dessous en marchant) et toujours touchées par un saut.
* **Obstacles déterministes** : tout est fonction de l'horloge serveur, jamais de hasard.
* **Détection côté client** : ce que le joueur voit est ce qui le tue, indépendamment du ping.
* **Pas de grappin**, ni rien d'équivalent.

## 5. Direction artistique

Chaque zone change **architecture, éclairage, ciel/atmosphère, matériaux, formes, particules et ambiance sonore** (`src/shared/Zones.luau`, `src/server/World/Themes.luau`), avec des transitions lissées de 2.5 s au passage de zone.

### Langage visuel réservé (identique dans toutes les zones)

| Élément | Apparence | Jamais utilisé pour |
|---|---|---|
| Danger / mort | rouge vif **Neon** | décor, sol sûr |
| Tout ce qui bouge | ambre/jaune | sol statique |
| Plateforme fantôme | cyan translucide (Glass) + contour visible quand intangible | — |
| Plateforme qui tombe | orange fissuré (Slate) → rouge-orange quand déclenchée | — |
| Jump pad | vert citron Neon | — |
| Glace | bleu pâle Glacier | — |
| Gravité | violet ForceField + indicateur HUD « GRAVITY 0.5× » | — |
| Checkpoint | disque blanc lumineux (vert = validé) | — |
| Final Stage / zone gate | or | — |

Le sol sûr prend la couleur/matériau de la zone ; le décor ne collisionne pas, n'est pas « queryable » et reste hors du parcours et de l'axe caméra.

## 6. Audio

Le son est une information de gameplay (`AudioController`) :

| Événement | Son | Rôle |
|---|---|---|
| Fantôme sur le point de disparaître | tic rapide | anticiper |
| Laser qui charge | ping grave | anticiper |
| Plateforme qui va tomber | craquement | réagir |
| Changement de gravité | whoosh grave | confirmer |
| Jump pad | whoosh | confirmer |
| Checkpoint | ping | récompense |
| Final Stage réussi / victoire | fanfare | récompense |
| Entrée en Final Stage | ping grave | pression |

Les sons positionnels sont coupés au-delà de 55 studs (perf). Musique et ambiance par zone (ids à renseigner dans `Zones.luau`), crossfade de 2 s.

## 7. UI

Minimaliste (`UIController`) :

```
        LEVEL 74 / 200
      ZONE 4 — DIFFICULT
  ▮▮▮▮▮▮▮▮▮▮▮▮▮▯▯▯▯▯▯▯   (segment 20 en or)
          DEATHS 312
```

* Nom du niveau en toast bref à l'entrée de chaque niveau.
* Bannière de zone animée : `ZONE 7 / GRAVITY / LEVELS 121–140 · REMORSELESS`, puis disparition.
* « FINAL STAGE — NO CHECKPOINT » à l'entrée d'un X20, « LEVEL 20 COMPLETE / ZONE 1 CLEARED » à la sortie.
* Victoire : « LEVEL 200 COMPLETE » puis « 200 / 200 », boutons *Play again* / *Stay here*.
* Boutons à gauche (≥ 44 px, hors zones du joystick et du bouton saut) : RESPAWN, SPEEDRUN, MUSIC, PLAYERS (masquer les autres).
* Au-dessus des joueurs : nom + meilleur niveau, coloré selon la zone atteinte ; `★ 200` doré = jeu terminé. Le 200 ne peut s'afficher qu'après avoir fini le 200 (règle `displayLevel`).

## 8. Modes Casual / Speedrun

* **Casual** : progression normale, sauvegardée.
* **Speedrun** : bouton dédié. Retour au niveau 1, compte à rebours 3-2-1 (personnage figé : départ équitable), chronomètre serveur, checkpoints internes au run, splits à chaque fin de zone, record « Best Full Run ». La progression casual est conservée et restaurée si on arrête le run. Aucun changement de level design.

## 9. Multijoueur

* Collisions joueur/joueur désactivées (groupe `Players`) : impossible de pousser quelqu'un.
* Tous les obstacles sont animés **localement** à partir de l'horloge serveur : tout le monde voit le même rythme, sans trafic réseau.
* Plateformes qui tombent : **locales** à chaque joueur (personne ne peut en faire tomber pour un autre), réinitialisées après délai ou au respawn.
* Gravité : locale au joueur.
* Checkpoints et progression : autoritaires côté serveur, anti-skip.
* Option « masquer les autres joueurs » pour la lisibilité dans un serveur plein.

## 10. Monétisation (règles)

Autorisé : trails, auras, death effects, victory effects, emotes, couleurs de nom, animations cosmétiques, serveurs privés.

Interdit, sans exception : skip de niveau, invincibilité, double saut, vitesse ou saut modifiés, checkpoints supplémentaires, réduction de difficulté. Les valeurs `Config.Character` ne sont jamais modifiées par du code de gameplay, et les classements ne contiennent que des statistiques de jeu.

## 11. Mobile / manette

* Aucun obstacle ne demande shift-lock, flick caméra ou précision souris. Wall hops : réservés à 3 niveaux de la zone 4, surfaces larges, zone de réessai proche.
* Jump auto désactivé (`AutoJumpEnabled = false`) pour éviter les sauts involontaires au bord.
* Largeurs minimales : 3 studs en zone 1 (1.5 uniquement au niveau 15), cibles de 2 studs seulement en zone 10.
* HUD mis à l'échelle selon la taille de l'écran (UIScale 0.62–1.15).

## 12. Performance

* 1 seule boucle client anime tous les obstacles, uniquement ceux à moins de 260 studs de la caméra ; écritures groupées via `workspace:BulkMoveTo`.
* Aucun script par obstacle. Aucun obstacle animé côté serveur.
* StreamingEnabled (rayon cible 512) : les appareils mobiles ne chargent que les niveaux proches.
* Décor non collidable, non queryable, non touchable ; kill bricks sans `Touched`.
* V1 : 588 parts pour 22 niveaux (~27 par niveau, 89 pour le Final Stage 20). Budget testé : ≤ 150 parts par niveau normal, ≤ 400 pour un Final Stage.

## 13. Feuille de route

| Phase | Contenu | État |
|---|---|---|
| 1 Design | ce document, [MECHANICS](MECHANICS.md), [LEVEL_PLAN](LEVEL_PLAN.md), [ARCHITECTURE](ARCHITECTURE.md) | ✔ |
| 2 Systems | données, checkpoints, respawn, UI, zones, audio, leaderboards, speedrun | ✔ |
| 3 Prototype | composants : MovingPlatform, Rotator, GhostPlatform, FallingPlatform, Laser, Conveyor, JumpPad, GravityZone | ✔ (Laser/Conveyor/JumpPad/Gravity/Falling prêts, utilisés à partir des zones 2-7) |
| 4 V1 | niveaux 1–20 complets + transition zone 2 (niveau 21 jouable, checkpoint 22) | ✔ |
| 5 Test | tests automatiques (`lune run tests/run.luau`) + checklist de playtest [TESTING](TESTING.md) | automatique ✔ / playtest Studio à faire |
| 6 Expansion | zones 2 → 10, une zone par itération, nouveaux composants au besoin (Door, Chaser, Wind, Surface, RotationRoom, Proximity) | à venir |
| 7 Polish | musiques, VFX, ids audio Creator Store, cosmétiques, badges | à venir |

Composants à créer pour l'expansion (même modèle : tag + attributs, animé par `ObstacleRuntime`) : `WindZone`, `Surface` (glace/goudron/boost), `Chaser`, `RotationRoom`, `ProximityTrap`, `TemporaryPlatform`, `MemoryPath`. Les portes temporisées et pendules sont déjà couverts par `MovingPlatform` et `Rotator` (axe X/Z).
