# Documentation des mécaniques

Chaque mécanique est décrite selon 9 aspects : **fonctionnement · variables · difficulté possible · interactions · problèmes techniques · multijoueur · mobile · feedback visuel · feedback sonore**.

Statut : ✔ implémenté (V1) · ◐ couvert par un composant existant · ○ composant à créer pendant l'expansion.

## 0. Référence de mouvement

Réglages imposés (`Config.Character`, `default.project.json`) : WalkSpeed 16, JumpPower 50, gravité 196.2, AutoJump désactivé.

| Donnée | Valeur | Utilisation |
|---|---|---|
| Temps de vol (sol plat) | 0.51 s | fenêtres de timing, simulateur de tests |
| Distance d'un saut à plat | ≈ 8.2 studs (+≈1 de marge pieds) | écart max théorique ≈ 9.1 |
| Hauteur max | ≈ 6.37 studs | marches ≤ 5.9 dans les tests |
| Hitbox mortelle | 1.6 × 5.6 × 1.6, depuis 0.2 sous les pieds | limbo ≥ 5.9 au-dessus du sol |

Budget d'écart (fraction du saut maximum à la même hauteur, vérifié par `tests/run.luau`) : zone 1 ≤ 0.62, zone 2 ≤ 0.70, puis ≤ 0.80 ; +0.05 sur les Final Stages. Les zones 9-10 pourront monter à 0.85-0.9, jamais au-delà (au-delà, le saut devient dépendant du framerate et du ping).

---

## 1. Plateformes et sauts ✔ (`LevelBuilder:Step`)
1. **Fonctionnement** : blocs, cylindres ou poutres statiques sur le parcours validé.
2. **Variables** : taille, forme (Block/Cylinder), écart, dénivelé, orientation du saut (droit, diagonal, latéral).
3. **Difficulté** : écart (ratio du saut max), taille de la cible, cylindres (bords ronds), poutres étroites, sauts diagonaux, enchaînements sans pause.
4. **Interactions** : base de tout ; avec glace (atterrissage glissant), gravité (portée modifiée), fantômes/chutes (fenêtre temporelle).
5. **Problèmes techniques** : aucun ; éviter les écarts > 0.9 du max (dépendance au framerate).
6. **Multijoueur** : pas de collision entre joueurs → pas de blocage sur les petites cibles.
7. **Mobile** : cibles ≥ 3 studs en zone 1, ≥ 2 studs en zone 10 ; jamais d'orientation caméra imposée.
8. **Visuel** : matériau/couleur sûrs de la zone, jamais rouge ni jaune.
9. **Sonore** : sons natifs de pas/atterrissage.

## 2. Kill bricks ✔ (tag `Hazard`)
1. **Fonctionnement** : toute partie taggée `Hazard` tue au contact de la hitbox standardisée.
2. **Variables** : forme, position (au sol = bande de lave, surélevée = haie, en hauteur = limbo bar), mouvement (combinable avec `MovingPlatform`/`Rotator`).
3. **Difficulté** : largeur des bandes, haies sur poutres, limbo (ne PAS sauter), studs sur petites plateformes.
4. **Interactions** : sur navettes, sur spinners, en pistons, en lasers.
5. **Technique** : détection client par géométrie exacte (`GetPartsInPart`), liste d'inclusion mise à jour par tags (compatible streaming). `CanTouch = false` : aucun coût physique.
6. **Multijoueur** : purement local, sans effet sur les autres.
7. **Mobile** : hitbox légèrement plus petite que l'avatar = tolérance aux imprécisions tactiles.
8. **Visuel** : rouge Neon réservé.
9. **Sonore** : son de mort court + flash rouge 0.35 s.

## 3. Plateforme mobile ✔ (`MovingPlatform`)
1. **Fonctionnement** : aller-retour entre la base et `base + Travel`, ou orbite (`LoopType = "Circle"`), en fonction de l'horloge serveur. Le joueur est transporté (carry) et le reste pendant un saut (air-carry ≤ 1.2 s) : sauter sur une navette fait retomber sur la navette.
2. **Variables** : `Travel`, `Period`, `Pause` (arrêt à chaque extrémité), `Phase` (retard 0-1), `Easing` (Sine/Linear), `LoopType`.
3. **Difficulté** : vitesse, pause courte, transfert entre navettes, navettes opposées, ascenseurs, obstacles à franchir en étant dessus.
4. **Interactions** : portes temporisées (= MovingPlatform verticale), pistons (`kill = true`), glace sur navette (zone 6), gravité (zone 7).
5. **Technique** : animée uniquement côté client (écriture groupée `BulkMoveTo`) ; le carry applique le delta de la plateforme au HumanoidRootPart avant la simulation physique (pas de pénétration, pas de glissement). Pas de dépendance à la physique Roblox.
6. **Multijoueur** : déterministe → même position pour tous sans réseau.
7. **Mobile** : pauses aux extrémités ≥ 0.6 s en zone 1-2 pour laisser le temps de sauter.
8. **Visuel** : ambre/jaune réservé ; version mortelle en rouge.
9. **Sonore** : (expansion) léger bourdonnement positionnel près des pistons.

## 4. Spinner / structures tournantes ✔ (`Rotator`)
1. **Fonctionnement** : un Model (moyeu + bras) tourne autour de son pivot à vitesse constante.
2. **Variables** : `Axis` (X/Y/Z : spinners, pendules, roues), `Speed` (°/s, signe = sens), `Phase` (°), longueur et nombre de bras, hauteur de lame (`bladeHeight`).
3. **Difficulté** : barre basse (sauter OU attendre) → lame haute (attendre obligatoirement) → deux spinners opposés → spinner sur navette → laser sweep.
4. **Interactions** : lasers (sweep), plateformes rotatives (engrenages zone 2, porteuses grâce au carry avec transfert de lacet), low gravity (plus de temps en l'air = plus d'exposition).
5. **Technique** : l'angle est calculé modulo 360 avant conversion (précision malgré un temps serveur ~1.7e9 s). Model `Atomic` pour le streaming.
6. **Multijoueur** : déterministe.
7. **Mobile** : vitesses ≤ 70 °/s en zone 1 ; la barre traverse toujours une zone large et visible.
8. **Visuel** : bras rouges, moyeu métal.
9. **Sonore** : (expansion) whoosh à chaque passage près du joueur.

## 5. Wraparound ✔ (géométrie)
1. **Fonctionnement** : un mur bloque le chemin, on le contourne par une corniche en longeant son bord.
2. **Variables** : largeur de corniche, écart corniche/chemin, largeur du mur, côté.
3. **Difficulté** : marche simple (niv. 10) → petits sauts latéraux (16) → contournements multiples, sous surplomb, sur tour (zone 4).
4. **Interactions** : head hitters, ascensions, glace (zone 6, très exigeant).
5. **Technique** : murs de 14-16 de haut (impossibles à sauter) ; normalisation des échelles d'avatar pour que tout le monde ait la même largeur.
6. **Multijoueur** : pas de collision entre joueurs → pas de bouchon sur la corniche.
7. **Mobile** : corniche ≥ 2.5 studs ; aucun wraparound ne demande de tourner la caméra.
8. **Visuel** : mur en roche/structure, corniche en sol sûr.
9. **Sonore** : —

## 6. Limbo bars ✔ (Hazard)
1. **Fonctionnement** : barre mortelle au-dessus du chemin : on passe dessous en marchant, tout saut la touche.
2. **Variables** : hauteur (entre 5.9 et ~10.5 au-dessus du sol), espacement avec les haies (≥ 7 studs).
3. **Difficulté** : alternance « sauter / ne pas sauter », limbo juste après un atterrissage.
4. **Interactions** : haies, tapis (zone 3 : ne pas sauter alors qu'on accélère), gravité forte.
5. **Technique** : hauteur vérifiée automatiquement contre la hitbox.
6. **Multijoueur** : —
7. **Mobile** : lisible sans précision.
8. **Visuel** : barre rouge sur deux poteaux (lecture « portique »).
9. **Sonore** : —

## 7. Plateformes fantômes ✔ (`GhostPlatform`)
1. **Fonctionnement** : solide pendant `VisibleDuration`, intangible pendant `InvisibleDuration`.
2. **Variables** : `VisibleDuration`, `InvisibleDuration`, `PhaseOffset` (retard), `WarnTime`.
3. **Difficulté** : alternance 2 temps → vague séquentielle (phases 0, ⅓, ⅔) → fenêtres courtes → combinaison avec gravité faible/vent.
4. **Interactions** : séquences, lasers, low gravity, vent.
5. **Technique** : bascule locale `CanCollide/CanQuery` ; un fantôme sur le point de disparaître n'est pas compté comme atterrissage sûr par le simulateur de tests.
6. **Multijoueur** : même rythme pour tous (horloge serveur).
7. **Mobile** : fenêtres ≥ 1.5 s en zone 2.
8. **Visuel** : cyan translucide ; clignote pendant `WarnTime` ; contour faible visible quand intangible (on sait toujours où elle reviendra).
9. **Sonore** : tic d'avertissement au début du clignotement.

## 8. Plateformes séquentielles ◐ (GhostPlatform + phases)
Plateformes qui apparaissent dans un ordre : fantômes avec `PhaseOffset` croissants (0, ⅓, ⅔). Même fiche que 7 ; la vague va toujours dans le sens de progression (vérifié par le simulateur).

## 9. Portes temporisées ✔ (`LevelBuilder:Door` → MovingPlatform)
1. Porte qui s'ouvre/ferme sur un cycle. 2. `Travel` (ouverture), `Period`, `Pause` (= durée ouverte/fermée), `Phase`. 3. Fenêtres courtes, portes successives déphasées, porte + navette. 4. Chaser (zone 9). 5. Porte non mortelle (bloquante) par défaut ; une porte qui peut écraser doit être rouge. 6. Déterministe. 7. Fenêtre ≥ 1 s. 8. (expansion) voyant vert/rouge au-dessus de la porte, horloge visible. 9. signal sonore 0.5 s avant fermeture.

## 10. Lasers à cycle et laser sweep ✔ (`Laser`, + `Rotator`)
1. **Fonctionnement** : mortel pendant `OnTime`, inoffensif pendant `OffTime`, avec une charge visible pendant `WarnTime`. Sweep = laser dans un Model `Rotator`.
2. **Variables** : `OnTime`, `OffTime`, `WarnTime`, `Phase`.
3. **Difficulté** : grilles en opposition de phase, polyrythmes (3 s / 4 s), sweep pendant une montée.
4. **Interactions** : boost (zone 3), gravité, rotation rooms.
5. **Technique** : `HazardController.setLethal` désactive localement la létalité pendant l'arrêt.
6. **Multijoueur** : déterministe.
7. **Mobile** : `WarnTime` ≥ 0.6 s.
8. **Visuel** : faisceau rouge plein → presque invisible → clignotement fin pendant la charge.
9. **Sonore** : ping grave de charge.

## 11. Plateformes qui tombent ✔ (`FallingPlatform`)
1. **Fonctionnement** : au contact du joueur local : changement de couleur + craquement, tremblement, chute, retour après délai.
2. **Variables** : `FallDelay`, `ShakeDuration`, `RespawnDelay`.
3. **Difficulté** : délai réduit, lignes longues, escaliers, combinaison vent/murs mobiles.
4. **Interactions** : chasers, momentum, murs mobiles.
5. **Technique** : état local, réinitialisé au respawn (`ObstacleRuntime.resetLocal`).
6. **Multijoueur** : **locale** : un joueur ne fait jamais tomber la plateforme d'un autre.
7. **Mobile** : `FallDelay` ≥ 0.45 s.
8. **Visuel** : orange fissuré → rouge-orange au contact, tremblement.
9. **Sonore** : craquement grave au contact.

## 12. Tapis roulants ✔ (`Conveyor`)
1. Vitesse de surface moteur (`AssemblyLinearVelocity` sur pièce ancrée). 2. `Speed`, `Direction`. 3. Contre le joueur, latéraux vers le vide, grilles. 4. Glace, limbo, sauts. 5. Fiable, sans physique instable ; on ne garde pas l'élan en l'air (règle Roblox, cohérente). 6. Identique pour tous. 7. Vitesse ≤ 14 en zone 3. 8. Chevrons défilants dans le sens du tapis. 9. (expansion) ronronnement positionnel.

## 13. Jump pads ✔ (`JumpPad`)
1. Vitesse verticale fixée à l'atterrissage (+ `Boost` optionnel). 2. `Power`, `Boost`. 3. Chaînes, pads inclinés, visée en l'air. 4. Gravité (hauteur ×1/g), rotation rooms. 5. Hauteur identique à chaque fois (vitesse imposée, pas d'impulsion additive). 6. Local. 7. Pas de contrôle aérien fin requis en zone 3. 8. Vert Neon + écrasement. 9. Whoosh.

## 14. Boost et momentum gates ✔ (`Boost`)
1. **Momentum gate** : écart infranchissable à vitesse normale mais franchissable après une surface d'accélération visible juste avant. 2. Longueur du boost, WalkSpeed temporaire, durée. 3. Boost + virage, boost + laser. 4. Glace. 5. Le boost modifie la WalkSpeed locale temporairement de façon scriptée (pas via la physique) ; réinitialisé au respawn. 6. Local. 7. Pas de précision de trajectoire extrême. 8. Surface orange à flèches. 9. Son montant pendant le boost.

## 15. Truss, échelles, head hitters, wraparounds de coin ✔ (géométrie, shift lock)
* **Truss/échelles** (`LevelBuilder:Truss`) : montée native Roblox, fiable sur tous les supports.
* **Head hitters** : plafond bas au-dessus d'un saut → saut raccourci ; hauteur de plafond calculée pour un seul timing.
* **Wall hops** : limités à 3 niveaux de la zone 4, surfaces larges, zone de réessai proche ; jamais obligatoires en zones 9-10 sur mobile sans alternative.

## 16. Vent ✔ (`WindZone`)
1. Volume qui applique une force latérale constante au joueur local. 2. Direction, force, rafales périodiques (`OnTime/OffTime`). 3. Contre-vent, latéral, rafales. 4. Navettes, fantômes. 5. `VectorForce` local sur le HumanoidRootPart (pas de modification de la physique globale). 6. Local. 7. Force limitée pour rester contrôlable au joystick. 8. Particules/feuilles dans le sens du vent, intensité visible avant la rafale. 9. Sifflement qui monte avant une rafale.

## 17. Bascules, ponts-levis, pendules, presses ✔ (`Swing`, `MovingPlatform`)
Basculants = `Rotator` à axe X/Z avec `Speed` alterné ou `MovingPlatform` (expansion : composant `Tilt` ping-pong d'angle). Murs mobiles = `MovingPlatform` lents non mortels qui réduisent l'espace (écrasement = rouge seulement). Déterministes, carry-compatibles.

## 18. Chaser ✔ (`Chaser`, option `StartRadius`)
1. Mur/lave/vide qui avance derrière le joueur. 2. Vitesse (≤ 70 % de la vitesse de marche), délai de départ, trajectoire. 3. Pression, jamais la vitesse brute. 4. Chutes, portes. 5. **Local** : démarre quand le joueur local entre dans la section, réinitialisé au respawn. 6. Chacun a son chaser. 7. Vitesse tolérante. 8. Lave rouge (règle danger), lumière pulsante. 9. Grondement qui se rapproche.

## 19. Surfaces de contrôle ○ (`Surface` : glace, goudron, boost)
1. Friction/vitesse modifiées localement selon la surface sous les pieds (détectée par le capteur de sol central). 2. Friction, vitesse max, accélération. 3. Glissade à l'atterrissage, freinage avant un saut, virages. 4. Tapis, vent, pistons. 5. Implémentation par `CustomPhysicalProperties` + ajustement de la WalkSpeed locale ; aucun élan hérité de bug physique. 6. Local. 7. Pas de micro-corrections impossibles au joystick. 8. Glace = Glacier bleu pâle, goudron = noir mat à bulles, boost = orange à flèches. 9. Crissement / succion / whoosh.

## 20. Zones et pads de gravité ✔ (`GravityZone`)
1. Volume qui modifie la gravité **du joueur local** (0.5×, 1×, 1.5×, 2×). 2. `GravityMultiplier`, `TransitionTime`. 3. Sauts longs, sauts courts, changements en plein saut. 4. Fantômes (temps en l'air), spinners, head hitters. 5. `workspace.Gravity` modifié côté client (local), réinitialisé au respawn. 6. Local. 7. Transitions douces (0.25 s). 8. Volume violet ForceField + HUD « GRAVITY 0.5× ». 9. Whoosh grave au changement.

## 21. Rotation Room ○ (`RotationRoom`)
1. **Fonctionnement** : une salle entière pivote de 90° autour de son axe : le mur devient le sol. Le joueur n'est jamais téléporté : la salle tourne autour de lui pendant qu'il est tenu par le carry (la rotation est appliquée à la salle ET au joueur qui s'y trouve), puis la gravité locale reste verticale.
2. **Variables** : axe, angle (90/180), durée de rotation (≥ 1.2 s), déclencheur (plaque au sol ou cycle), délai.
3. **Difficulté** : une rotation → deux → rotation cadencée avec obstacles → station entière (Final 140).
4. **Interactions** : fantômes, pads, portes.
5. **Technique** : rotation du Model via `ObstacleRuntime.move` + carry avec transfert complet (pas seulement le lacet) pendant la rotation ; caméra laissée libre.
6. **Multijoueur** : locale (chaque joueur tourne sa salle), sinon un joueur ferait tourner la salle d'un autre.
7. **Mobile** : pas d'input pendant la rotation, lisible sans caméra.
8. **Visuel** : bandes de danger clignotantes, flèche de rotation au sol, flash avant le mouvement.
9. **Sonore** : alarme mécanique + grondement pendant la rotation.

## 22. Obstacles réactifs / pièges de proximité ○ (`ProximityTrap`)
1. Déclenchés quand le joueur local approche (murs surgissants, pics, lasers, sols qui cèdent). 2. Rayon, délai de télégraphe (0.8 s → 0.55 s), durée. 3. Réduction du télégraphe, motifs, enchaînements rapides. 4. Chaser, gravité. 5. Local, délai fixe (jamais aléatoire). 6. Local. 7. Télégraphe ≥ 0.55 s (réaction humaine + latence tactile). 8. Lumière orange puis rouge + animation préparatoire. 9. Bip d'armement puis claquement.

## 23. Plateformes temporaires ○
Apparaissent à l'approche, disparaissent après N secondes. Même rendu que les fantômes (cyan) + compte à rebours visuel (remplissage) pour rester lisible.

## 24. Memory path ○ (rare)
Le chemin sûr s'illumine brièvement puis certaines informations disparaissent. Deux niveaux maximum dans tout le jeu, chemin court (≤ 6 cases), l'indice revient à chaque respawn.
