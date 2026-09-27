# Tests

## 1. Tests automatiques (sans Roblox)

```bash
lune run tests/run.luau
```

[Lune](https://lune-org.github.io) exécute les **vrais modules du jeu** hors de Roblox (`tests/loader.luau` émule `script`, `game` et `require`). Environ 1650 vérifications :

| Suite | Vérifie |
|---|---|
| CheckpointRules | pas de checkpoint sur les X20 ; mort en 17 → 17, en 19 → 19, en 20 → 19, 140 non fini → 139 ; 19 → 21 ; anti-skip ; nettoyage des sauvegardes ; parcours complet 1 → 201 |
| LevelPlan | 200 niveaux, noms uniques, difficulté jamais décroissante, Final Stage tous les 20 |
| Timing | ping-pong, pauses, cycles on/off, phase = retard |
| World build | construit **le vrai monde** avec le vrai `LevelBuilder`, puis : chaque saut de chaque parcours est dans l'enveloppe de saut et le budget de la zone ; chaque paire mobile/fantôme a une fenêtre utilisable ; **un simulateur vérifie qu'il existe un timing qui enchaîne tout le parcours** (auto-testé sur un cas volontairement impossible) ; les limbo bars passent en marchant et jamais en sautant ; chaque Final Stage fait 3 à 5× un niveau normal de sa zone ; déclencheurs de checkpoint conformes aux règles ; budget de parts par niveau |

Le script sort avec le code 1 en cas d'échec (utilisable en CI).

Vérifications de build complémentaires :

```bash
rojo build -o Obby200.rbxlx                      # le projet se construit
for f in $(find src -name '*.luau'); do luau-compile --binary "$f" > /dev/null || echo "$f"; done
```

## 2. Playtest Studio (phase 5), à faire à chaque itération

Lancer avec **Test → Start** (1 joueur), puis **Test → Clients and Servers** avec 3 joueurs, puis **Device emulator** (téléphone + tablette).

### Checkpoints / respawn
- [ ] Nouveau joueur : spawn sur le pad du niveau 1, face au parcours, HUD `LEVEL 1 / 200`, bannière `ZONE 1`.
- [ ] Toucher le pad 2 : disque 1 vert, disque 2 blanc lumineux, son de checkpoint, toast du nom du niveau.
- [ ] Mourir (lave, spinner, vide) : flash + particules, retour au checkpoint en ~0.2 s, compteur de morts +1.
- [ ] Bouton RESPAWN et bouton Reset du menu Roblox : même chemin rapide.
- [ ] Au pad 19 : panneau doré « 19 → 20 NO CHECKPOINT ». Au pad 20 : arche « FINAL STAGE », toast, `LEVEL 20 / 200` en or.
- [ ] Mourir dans le 20 (section VI par ex.) : retour au **19**.
- [ ] Atteindre le 21 : `LEVEL 20 COMPLETE / ZONE 1 CLEARED`, transition d'éclairage + bannière `ZONE 2 TIMING`.
- [ ] Quitter au niveau 13, revenir : spawn au 13 (place publiée avec API Services activées).
- [ ] Quitter pendant le 20, revenir : spawn au 19.

### Obstacles
- [ ] Navettes (6, 9, 13, 18, 20) : on reste dessus sans glisser ; un saut sur place retombe sur la navette.
- [ ] Ascenseur (9, 20) : pas de tremblement en montée ni en descente.
- [ ] Spinners : la barre tue exactement quand elle touche visuellement ; frôler sans toucher ne tue pas.
- [ ] Limbo (12, 20) : marcher dessous ne tue jamais ; sauter dessous tue toujours.
- [ ] Pistons (17, 20) : un rythme lisible, passage possible sans deviner.
- [ ] Fantômes (21) : clignotement + tic avant disparition ; contour visible quand intangible ; la vague 1-2-3 se suit.

### Multijoueur (3 clients)
- [ ] Les joueurs se traversent (impossible de pousser quelqu'un).
- [ ] Les obstacles sont au même endroit sur les 3 écrans.
- [ ] Un joueur qui meurt / respawn n'affecte pas les autres.
- [ ] Tags au-dessus des têtes : nom + niveau coloré ; PLAYERS OFF les masque localement.

### Mobile / manette
- [ ] Émulateur téléphone : HUD lisible, boutons à gauche non masqués par le joystick, rien sous le bouton saut.
- [ ] Niveaux 10, 15, 16 (wraparounds, poutres fines) terminables au joystick sans shift-lock.
- [ ] Manette : tout est jouable sans souris.

### Speedrun
- [ ] SPEEDRUN : retour au niveau 1, compte à rebours 3-2-1 personnage figé, chrono qui démarre sur GO.
- [ ] Atteindre le 21 : split « ZONE 1 SPLIT », « NEW PERSONAL BEST » la première fois.
- [ ] STOP RUN : retour au checkpoint casual.

### Performance
- [ ] MicroProfiler : la boucle `PreSimulation` d'ObstacleRuntime reste sous 0.3 ms.
- [ ] Nombre de parts (Stats) : ~600 pour la V1.
- [ ] Mémoire client en émulation téléphone stable pendant 10 minutes de jeu.
