# Plan des 200 niveaux

> Fichier généré par `lune run tools/gen_level_plan.luau` depuis `src/shared/LevelPlan.luau` (source de vérité). Ne pas éditer à la main.

Colonnes : **Diff.** = note de difficulté 1.00–10.99 (zone + courbe interne) · **Temps** = estimation d'un premier passage réussi (hors morts) · **CP** = checkpoint au début du niveau · **Final** = Final Stage.

Courbe dans chaque zone : X1 introduction · X2–X5 apprentissage · X6–X10 développement · X11–X15 difficulté · X16–X18 maîtrise · X19 pré-finale · X20 Final Stage (pas de checkpoint entre X19 et X20).

## Zone 1 — INTRODUCTION — Verdant Plateau (1–20) · EASY

*Learn the rules* — Jumps, kill bricks, first moving parts

| Lvl | Nom | Diff. | Mécanique principale | Secondaire | Longueur | Temps | Défi principal | CP | Final |
|---:|---|---:|---|---|---|---:|---|:-:|:-:|
| 1 | First Steps | 1.01 | Jump | - | Short | 22s | Grandes plateformes, écarts minuscules : apprendre à sauter. | ✔ |  |
| 2 | Stairway | 1.07 | Vertical jumps | - | Short | 22s | Monter une série de marches de plus en plus hautes. | ✔ |  |
| 3 | Red Means No | 1.13 | Kill bricks | Jump | Short | 22s | Franchir des bandes de lave de plus en plus larges. | ✔ |  |
| 4 | Stepping Stones | 1.19 | Precision jumps | Lateral aim | Short | 22s | Pierres 4x4 en zigzag : viser en diagonale. | ✔ |  |
| 5 | The Walkway | 1.25 | Narrow beams | Kill hurdles | Short | 22s | Poutre de 3 studs avec virage en L et obstacles rouges. | ✔ |  |
| 6 | Moving Along | 1.33 | Moving platforms | - | Medium | 27s | Monter sur deux navettes lentes, attendre, descendre. | ✔ |  |
| 7 | Pillar Hop | 1.38 | Round pillars | Rising jumps | Medium | 27s | Atterrir sur des cylindres tout en montant. | ✔ |  |
| 8 | Lava Floor | 1.43 | Kill floor | Path reading | Medium | 27s | Lire un chemin sinueux de dalles au-dessus d'une salle de lave. | ✔ |  |
| 9 | Elevator | 1.48 | Vertical mover | Crossing movers | Medium | 27s | Ascenseur puis transfert entre deux navettes opposées. | ✔ |  |
| 10 | First Wraparound | 1.53 | Wraparound | Ledges | Medium | 27s | Contourner deux murs en longeant leur bord. | ✔ |  |
| 11 | The Sweeper | 1.59 | Spinner | Jump or wait | Medium | 27s | Traverser un disque balayé par une barre lente : sauter ou attendre. | ✔ |  |
| 12 | Don't Jump | 1.64 | Limbo bars | Hurdles | Medium | 27s | Alterner : passer SOUS une barre, sauter PAR-DESSUS la suivante. | ✔ |  |
| 13 | Ferry Line | 1.69 | Moving platforms | Timing | Medium | 27s | Enchaîner trois navettes qui se rejoignent en bout de course. | ✔ |  |
| 14 | Twin Sweepers | 1.73 | Spinners | Narrow bridge | Medium | 27s | Sauter une barre basse puis attendre une lame haute. | ✔ |  |
| 15 | Tightrope | 1.77 | Thin beams | Turns | Medium | 27s | Poutres de 1.5 stud montantes avec virage à 90°. | ✔ |  |
| 16 | Wraparound Ridge | 1.82 | Wraparounds | Side jumps | Medium | 27s | Sauter autour de trois falaises, côtés alternés. | ✔ |  |
| 17 | Piston Alley | 1.86 | Moving hazards | Timing | Medium | 27s | Couloir de quatre pistons décalés : lire leur rythme. | ✔ |  |
| 18 | Sky Circuit | 1.89 | Mover + spinner | Stones | Medium | 27s | Sauter une barre tournante en étant sur une navette. | ✔ |  |
| 19 | The Threshold | 1.93 | Review | Pre-final | Long | 43s | Révision de la zone ; enchaîne sans checkpoint sur le 20. | ✔ |  |
| 20 | **Verdant Trial** | 1.99 | FINAL STAGE | All Zone 1 | Final (x4) | 108s | Examen en 7 sections : pierres, contournement, navettes, balayeurs, lave, pistons, ascension. | ✘ | ★ |

## Zone 2 — TIMING — Clockwork Foundry (21–40) · MEDIUM

*Watch the cycle, then move* — Disappearing platforms, timed doors, laser cycles

| Lvl | Nom | Diff. | Mécanique principale | Secondaire | Longueur | Temps | Défi principal | CP | Final |
|---:|---|---:|---|---|---|---:|---|:-:|:-:|
| 21 | Now You See It | 2.01 | Ghost platforms | - | Short | 26s | Plateformes fantômes alternées, clignotement d'avertissement. | ✔ |  |
| 22 | Clockwork Doors | 2.07 | Timed doors | - | Short | 26s | Portes sur horloge visible : passer quand elles s'ouvrent. | ✔ |  |
| 23 | Metronome | 2.13 | Laser cycles | - | Short | 26s | Portiques laser avec montée en charge sonore : passer pendant l'arrêt. | ✔ |  |
| 24 | Tick-Tock Path | 2.19 | Sequential platforms | Ghost | Short | 26s | Plateformes qui apparaissent dans l'ordre 1-2-3-4 : suivre la vague. | ✔ |  |
| 25 | Laser Turnstile | 2.25 | Rotating laser | - | Short | 26s | Faire le tour d'un anneau pendant qu'un laser balaie lentement. | ✔ |  |
| 26 | Door & Ferry | 2.33 | Timed doors | Moving platform | Medium | 32s | La navette arrive quand la porte s'ouvre : ne pas partir trop tôt. | ✔ |  |
| 27 | Half Beat | 2.38 | Ghost platforms | Short windows | Medium | 32s | Fenêtres visibles réduites à 1.5 s. | ✔ |  |
| 28 | Gearworks | 2.43 | Rotating gears | Jump | Medium | 32s | Engrenages tournants : sauter quand les dents s'alignent. | ✔ |  |
| 29 | Crossfire | 2.48 | Laser cycles | Opposed phases | Medium | 32s | Deux grilles en opposition de phase : attendre entre les deux. | ✔ |  |
| 30 | Syncopation | 2.53 | Synced platforms | Ghost | Medium | 32s | Deux rangées fantômes à contretemps, zigzag. | ✔ |  |
| 31 | Pendulum Hall | 2.59 | Pendulums | Timing | Medium | 32s | Passer sous des haches pendulaires. | ✔ |  |
| 32 | Sweep Stair | 2.64 | Rotating laser | Rising steps | Medium | 32s | Monter pendant qu'un laser balaie chaque marche. | ✔ |  |
| 33 | Countdown Bridge | 2.69 | Ghost bridge | Commitment | Medium | 32s | Pont visible 3 secondes : partir au bon signal. | ✔ |  |
| 34 | Shutters | 2.73 | Timed doors | Lasers | Medium | 32s | Fenêtres de portes superposées à des fenêtres laser. | ✔ |  |
| 35 | Clock Face | 2.77 | Spinners | Hub hops | Medium | 32s | Plateformes sur un cadran, deux aiguilles à vitesses différentes. | ✔ |  |
| 36 | Staccato | 2.82 | Kill pulses | Precision | Medium | 32s | Dalles électrifiées selon un motif répétitif. | ✔ |  |
| 37 | Assembly Line | 2.86 | Circle movers | Pistons | Medium | 32s | Plateformes en orbite entre des pistons. | ✔ |  |
| 38 | Polyrhythm | 2.89 | Mixed periods | Observation | Medium | 32s | Cycles de 3 s et 4 s : attendre qu'ils s'alignent. | ✔ |  |
| 39 | The Escapement | 2.93 | Review | Pre-final | Long | 51s | Portes, lasers et fantômes en un seul flux. | ✔ |  |
| 40 | **Grand Clockwork** | 2.99 | FINAL STAGE | All timing | Final (x4) | 128s | Parcours multi-cycles finissant dans une tour synchronisée. | ✘ | ★ |

## Zone 3 — MOMENTUM — Velocity Canyon (41–60) · HARD

*Keep your speed* — Conveyors, jump pads, slopes, speed gates

| Lvl | Nom | Diff. | Mécanique principale | Secondaire | Longueur | Temps | Défi principal | CP | Final |
|---:|---|---:|---|---|---|---:|---|:-:|:-:|
| 41 | Conveyor 101 | 3.01 | Conveyors | - | Short | 30s | Marcher avec puis contre des tapis roulants. | ✔ |  |
| 42 | Launch Pad | 3.07 | Jump pads | - | Short | 30s | Rebondir vers des corniches hautes. | ✔ |  |
| 43 | Downhill | 3.13 | Slopes | Speed | Short | 30s | Descendre une pente pour prendre de l'élan avant un long saut. | ✔ |  |
| 44 | Reverse Belt | 3.19 | Opposing conveyors | Jump | Short | 30s | Sauts sur tapis qui vous repoussent. | ✔ |  |
| 45 | Speed Strip | 3.25 | Boost surface | Long jump | Short | 30s | Un écart infranchissable sans la bande d'accélération. | ✔ |  |
| 46 | Bounce House | 3.33 | Jump pad chain | Air control | Medium | 37s | De pad en pad en contrôlant sa trajectoire. | ✔ |  |
| 47 | Crosswind Belts | 3.38 | Side conveyors | Precision | Medium | 37s | Tapis latéraux qui poussent vers le vide. | ✔ |  |
| 48 | Momentum Gate | 3.43 | Momentum gate | Boost | Medium | 37s | Passage exigeant une vitesse d'arrivée, source de vitesse visible. | ✔ |  |
| 49 | Ramp Jump | 3.48 | Ramps | Boost | Medium | 37s | S'envoler depuis des rampes. | ✔ |  |
| 50 | Canyon Crossing | 3.53 | Conveyors | Jump pads | Medium | 37s | Mi-zone : tapis et pads combinés. | ✔ |  |
| 51 | Slingshot | 3.59 | Launcher platforms | Landing | Medium | 37s | Plateformes qui propulsent en fin de course (impulsion scriptée). | ✔ |  |
| 52 | Belt Maze | 3.64 | Conveyor grid | Route choice | Medium | 37s | Grille de tapis : choisir sa route. | ✔ |  |
| 53 | Ricochet | 3.69 | Angled pads | Timing | Medium | 37s | Pads inclinés entre deux murs. | ✔ |  |
| 54 | Rolling Hills | 3.73 | Slopes | Keep speed | Medium | 37s | Conserver sa vitesse sur des bosses. | ✔ |  |
| 55 | Speed Trap | 3.77 | Boost | Laser cycles | Medium | 37s | Traverser une fenêtre laser grâce au boost. | ✔ |  |
| 56 | Catapult Chain | 3.82 | Launchers | Precision landing | Medium | 37s | Lancer, atterrir, relancer. | ✔ |  |
| 57 | Treadmill Tower | 3.86 | Conveyors | Vertical | Medium | 37s | Monter en passant de tapis en tapis. | ✔ |  |
| 58 | Afterburner | 3.89 | Boost lanes | Turns | Medium | 37s | Couloir de vitesse avec virages serrés. | ✔ |  |
| 59 | Terminal Velocity | 3.93 | Review | Pre-final | Long | 59s | Momentum + timing sans temps mort. | ✔ |  |
| 60 | **Canyon Run** | 3.99 | FINAL STAGE | Momentum + Timing | Final (x4) | 148s | Longue course : portes de vitesse, pads, lasers, portes. | ✘ | ★ |

## Zone 4 — VERTICALITY — Skyward Spire (61–80) · DIFFICULT

*Climb* — Truss, head hitters, wraparounds, ascents

| Lvl | Nom | Diff. | Mécanique principale | Secondaire | Longueur | Temps | Défi principal | CP | Final |
|---:|---|---:|---|---|---|---:|---|:-:|:-:|
| 61 | Truss Climb | 4.01 | Truss | - | Short | 34s | Grimper des treillis et en descendre proprement. | ✔ |  |
| 62 | Ladder Line | 4.07 | Ladders | Jumps | Short | 34s | Sauter d'échelle en plateforme. | ✔ |  |
| 63 | Head Hitter | 4.13 | Head hitters | - | Short | 34s | Sauts sous plafond bas : saut court maîtrisé. | ✔ |  |
| 64 | Spiral Stair | 4.19 | Tower ascent | - | Short | 34s | Escalier en spirale autour d'une tour. | ✔ |  |
| 65 | Corner Kick | 4.25 | Wall hop (guided) | - | Short | 34s | Premier wall hop, surface large et tutoriel visuel. | ✔ |  |
| 66 | Truss Flick | 4.33 | Truss jumps | Air control | Medium | 42s | Sauter d'un treillis à l'autre. | ✔ |  |
| 67 | Chimney | 4.38 | Vertical shaft | Alternating ledges | Medium | 42s | Cheminée étroite, corniches alternées. | ✔ |  |
| 68 | Overhang | 4.43 | Advanced wraparound | Head hitter | Medium | 42s | Contournement sous un surplomb. | ✔ |  |
| 69 | Pillar Ascent | 4.48 | Ascent | Shrinking ledges | Medium | 42s | Monter autour d'un pilier, corniches de plus en plus fines. | ✔ |  |
| 70 | Tower Wrap | 4.53 | Wraparounds | Corners | Medium | 42s | Contournements sur les coins d'une tour. | ✔ |  |
| 71 | Ceiling Crawl | 4.59 | Head hitters | Kill ceiling | Medium | 42s | Head hitters sous un plafond mortel. | ✔ |  |
| 72 | Swinging Truss | 4.64 | Moving truss | Timing | Medium | 42s | Treillis mobiles à attraper au bon moment. | ✔ |  |
| 73 | Scaffolding | 4.69 | Vertical maze | Route reading | Medium | 42s | Labyrinthe d'échafaudages à lire de bas en haut. | ✔ |  |
| 74 | Corner Hops | 4.73 | L-corner jumps | Precision | Medium | 42s | Sauts d'angle en L. | ✔ |  |
| 75 | Lift Shaft | 4.77 | Vertical movers | Head hitters | Medium | 42s | Ascenseurs avec plafonds. | ✔ |  |
| 76 | Double Wrap | 4.82 | Double wraparounds | Narrow ledges | Medium | 42s | Deux contournements enchaînés. | ✔ |  |
| 77 | Sky Ladder | 4.86 | Ladders on movers | Timing | Medium | 42s | Échelles suspendues à des plateformes mobiles. | ✔ |  |
| 78 | Wall Hop Tower | 4.89 | Wall hops | Ascent | Medium | 42s | Tour de wall hops, chacun avec zone de réessai proche. | ✔ |  |
| 79 | The Spire | 4.93 | Review | Pre-final | Long | 67s | Ascension de révision. | ✔ |  |
| 80 | **Summit Ascent** | 4.99 | FINAL STAGE | Grand ascent | Final (x4) | 168s | Grande ascension autour d'une aiguille géante. | ✘ | ★ |

## Zone 5 — DYNAMIC — Shifting Ruins (81–100) · CHALLENGING

*The level is the enemy* — Falling blocks, wind, moving walls, chasers

| Lvl | Nom | Diff. | Mécanique principale | Secondaire | Longueur | Temps | Défi principal | CP | Final |
|---:|---|---:|---|---|---|---:|---|:-:|:-:|
| 81 | Crumble | 5.01 | Falling platforms | - | Short | 38s | Plateformes qui craquent puis tombent : ne pas s'arrêter. | ✔ |  |
| 82 | Gust | 5.07 | Wind zones | - | Short | 38s | Vent visible (particules) poussant latéralement. | ✔ |  |
| 83 | Seesaw | 5.13 | Tilting blocks | - | Short | 38s | Blocs qui basculent selon un cycle lisible. | ✔ |  |
| 84 | Closing In | 5.19 | Moving walls | - | Short | 38s | Des murs se rapprochent : avancer. | ✔ |  |
| 85 | Crumble Run | 5.25 | Falling platforms | Speed | Short | 38s | Longue ligne de plateformes friables. | ✔ |  |
| 86 | Headwind | 5.33 | Wind | Jumps | Medium | 47s | Sauter contre le vent. | ✔ |  |
| 87 | Drawbridge | 5.38 | Rotating structures | Timing | Medium | 47s | Ponts-levis qui montent et descendent. | ✔ |  |
| 88 | Collapse | 5.43 | Chaser | Falling | Medium | 47s | Le niveau s'effondre derrière vous. | ✔ |  |
| 89 | Tilt Maze | 5.48 | Tilting platforms | Kill bricks | Medium | 47s | Plateformes basculantes au-dessus de lave. | ✔ |  |
| 90 | Storm Front | 5.53 | Gusts | Telegraphs | Medium | 47s | Rafales périodiques annoncées par un sifflement et des feuilles. | ✔ |  |
| 91 | Rising Lava | 5.59 | Chaser | Vertical | Medium | 47s | La lave monte : grimper sans paniquer. | ✔ |  |
| 92 | Shifting Floor | 5.64 | Moving grid | Observation | Medium | 47s | Une grille de dalles se réorganise. | ✔ |  |
| 93 | Crusher Hall | 5.69 | Moving walls | Pistons | Medium | 47s | Murs et pistons dans le même couloir. | ✔ |  |
| 94 | Falling Stair | 5.73 | Falling platforms | Ascent | Medium | 47s | Escalier friable. | ✔ |  |
| 95 | Wind Tunnel | 5.77 | Wind | Moving platforms | Medium | 47s | Navettes dans un tunnel venteux. | ✔ |  |
| 96 | Toppling Pillars | 5.82 | Rotating structures | Timing | Medium | 47s | Piliers qui basculent et forment un pont. | ✔ |  |
| 97 | Earthquake | 5.86 | Shaking platforms | Falling | Medium | 47s | Secousses annoncées puis effondrements. | ✔ |  |
| 98 | Ruins Chase | 5.89 | Chaser | Falling | Medium | 47s | Poursuite + plateformes friables. | ✔ |  |
| 99 | Eye of the Storm | 5.93 | Review | Pre-final | Long | 75s | Vent, chutes et murs mobiles. | ✔ |  |
| 100 | **Halfway Point** | 5.99 | FINAL STAGE | All dynamic | Final (x4) | 188s | Grande étape 100/200 : les ruines s'écroulent autour de vous. | ✘ | ★ |

## Zone 6 — CONTROL — Frost Circuit (101–120) · INTENSE

*Master your inertia* — Ice, sticky and boost surfaces, inertia

| Lvl | Nom | Diff. | Mécanique principale | Secondaire | Longueur | Temps | Défi principal | CP | Final |
|---:|---|---:|---|---|---|---:|---|:-:|:-:|
| 101 | Thin Ice | 6.01 | Ice | - | Short | 42s | Premier contact avec la glace : large et sans danger. | ✔ |  |
| 102 | Tar Pit | 6.07 | Slow surface | - | Short | 42s | Surface collante qui ralentit. | ✔ |  |
| 103 | Speed Lane | 6.13 | Boost surface | - | Short | 42s | Surface qui accélère. | ✔ |  |
| 104 | Ice Stones | 6.19 | Ice | Precision | Short | 42s | Pierres glacées : anticiper la glissade. | ✔ |  |
| 105 | Skid Turn | 6.25 | Ice | Turns | Short | 42s | Virages sur glace. | ✔ |  |
| 106 | Surface Reading | 6.33 | Mixed surfaces | Recognition | Medium | 52s | Reconnaître glace, goudron et boost au premier coup d'œil. | ✔ |  |
| 107 | Ice Ferry | 6.38 | Ice | Moving platforms | Medium | 52s | Navettes glacées. | ✔ |  |
| 108 | Brake Zone | 6.43 | Slow surface | Gaps | Medium | 52s | Freiner sur le goudron avant un saut. | ✔ |  |
| 109 | Glide Path | 6.48 | Boost surface | Long jump | Medium | 52s | Boost vers un long saut. | ✔ |  |
| 110 | Frozen Sweeper | 6.53 | Ice | Spinner | Medium | 52s | Glace + barre tournante. | ✔ |  |
| 111 | Slalom | 6.59 | Ice | Kill posts | Medium | 52s | Slalom glacé entre poteaux rouges. | ✔ |  |
| 112 | Inertia Stair | 6.64 | Ice | Steps | Medium | 52s | Marches glacées. | ✔ |  |
| 113 | Tar Jumps | 6.69 | Slow surface | Timing | Medium | 52s | Sauts depuis le goudron (élan réduit). | ✔ |  |
| 114 | Ice Belts | 6.73 | Ice | Conveyors | Medium | 52s | Tapis roulants glacés. | ✔ |  |
| 115 | Crossover | 6.77 | Mixed surfaces | Sequencing | Medium | 52s | Glace → boost → goudron en enchaînement. | ✔ |  |
| 116 | Black Ice | 6.82 | Ice | Narrow beams | Medium | 52s | Poutres fines glacées. | ✔ |  |
| 117 | Drift | 6.86 | Ice | Wind | Medium | 52s | Glace + vent. | ✔ |  |
| 118 | Frost Pistons | 6.89 | Ice | Pistons | Medium | 52s | Pistons sur sol glissant. | ✔ |  |
| 119 | Whiteout | 6.93 | Review | Pre-final | Long | 83s | Contrôle total de l'inertie. | ✔ |  |
| 120 | **Frost Circuit** | 6.99 | FINAL STAGE | All control | Final (x4) | 208s | Circuit glacé complet. | ✘ | ★ |

## Zone 7 — GRAVITY — Orbital Station (121–140) · REMORSELESS

*Up is a suggestion* — Gravity zones, gravity pads, rotation rooms

| Lvl | Nom | Diff. | Mécanique principale | Secondaire | Longueur | Temps | Défi principal | CP | Final |
|---:|---|---:|---|---|---|---:|---|:-:|:-:|
| 121 | Moonwalk | 7.01 | Low gravity | - | Short | 46s | Gravité 0.5× : sauts longs et flottants. | ✔ |  |
| 122 | Heavy Feet | 7.07 | High gravity | - | Short | 46s | Gravité 1.5× : petits sauts. | ✔ |  |
| 123 | Gravity Lanes | 7.13 | Gravity zones | Recognition | Short | 46s | Zones alternées clairement colorées. | ✔ |  |
| 124 | Float Gap | 7.19 | Low gravity | Long jumps | Short | 46s | Grands écarts impossibles en 1×. | ✔ |  |
| 125 | Pressure | 7.25 | High gravity 2x | Small steps | Short | 46s | Gravité 2× avec marches basses. | ✔ |  |
| 126 | Rotation Room I | 7.33 | Rotation room | - | Medium | 57s | La salle pivote de 90° : le mur devient le sol. | ✔ |  |
| 127 | Moon Stones | 7.38 | Low gravity | Precision | Medium | 57s | Atterrissages de précision en 0.5×. | ✔ |  |
| 128 | Switchback | 7.43 | Gravity pads | Mid-air change | Medium | 57s | Changer de gravité en plein saut. | ✔ |  |
| 129 | Heavy Timing | 7.48 | High gravity | Laser cycles | Medium | 57s | Gravité forte + lasers. | ✔ |  |
| 130 | Rotation Room II | 7.53 | Rotation room | Two turns | Medium | 57s | Deux rotations successives. | ✔ |  |
| 131 | Orbit | 7.59 | Low gravity | Structure loop | Medium | 57s | Faire le tour d'une structure en gravité faible. | ✔ |  |
| 132 | Ceiling Walk | 7.64 | Rotation room | 180° turn | Medium | 57s | Le plafond devient le sol (deux quarts de tour). | ✔ |  |
| 133 | Gravity Ferries | 7.69 | Gravity zones | Moving platforms | Medium | 57s | Navettes traversant des zones de gravité. | ✔ |  |
| 134 | Drop Zone | 7.73 | High gravity | Head hitters | Medium | 57s | Chutes rapides sous plafonds. | ✔ |  |
| 135 | Spin Cycle | 7.77 | Rotation room | Timing | Medium | 57s | Rotation cadencée + obstacles. | ✔ |  |
| 136 | Weightless Sweepers | 7.82 | Low gravity | Spinners | Medium | 57s | Plus de temps en l'air = plus d'exposition aux barres. | ✔ |  |
| 137 | Axis Shift | 7.86 | Rotation room | Ghost platforms | Medium | 57s | Rotation + fantômes. | ✔ |  |
| 138 | Gravity Well | 7.89 | Gravity gradient | Control | Medium | 57s | Gravité qui varie progressivement le long du parcours. | ✔ |  |
| 139 | Event Horizon | 7.93 | Review | Pre-final | Long | 91s | Toutes les gravités. | ✔ |  |
| 140 | **Orbital Station** | 7.99 | FINAL STAGE | All gravity | Final (x4) | 228s | La station entière pivote section par section. | ✘ | ★ |

## Zone 8 — REACTION — Reactor Core (141–160) · INSANE

*Read. React.* — Proximity traps, pop-up walls, temporary platforms

| Lvl | Nom | Diff. | Mécanique principale | Secondaire | Longueur | Temps | Défi principal | CP | Final |
|---:|---|---:|---|---|---|---:|---|:-:|:-:|
| 141 | Tripwire | 8.01 | Proximity trap | - | Short | 50s | Piège de proximité : lumière + son, 0.8 s pour réagir. | ✔ |  |
| 142 | Pop-Up Walls | 8.07 | Rising walls | - | Short | 50s | Murs qui surgissent après un signal lumineux. | ✔ |  |
| 143 | Blink Platforms | 8.13 | Temporary platforms | - | Short | 50s | Plateformes qui apparaissent à l'approche puis disparaissent. | ✔ |  |
| 144 | Alarm | 8.19 | Light sequences | Rapid sequence | Short | 50s | Séquence de lumières indiquant la voie sûre. | ✔ |  |
| 145 | Snap Floor | 8.25 | Dropping floor | Telegraph | Short | 50s | Le sol tombe après un avertissement. | ✔ |  |
| 146 | Reactive Lasers | 8.33 | Proximity lasers | - | Medium | 62s | Lasers qui s'activent quand on approche. | ✔ |  |
| 147 | Hair Trigger | 8.38 | Proximity traps | Short telegraph | Medium | 62s | Signal réduit à 0.55 s. | ✔ |  |
| 148 | Pattern Lock | 8.43 | Pop-up spikes | Pattern | Medium | 62s | Motif de pics à apprendre. | ✔ |  |
| 149 | Surge | 8.48 | Chaser | Pop-ups | Medium | 62s | Poursuite + pièges surgissants. | ✔ |  |
| 150 | Core Breach | 8.53 | Mixed reaction | Mid-zone | Medium | 62s | Mi-zone : tous les pièges réactifs. | ✔ |  |
| 151 | Flash Step | 8.59 | Temporary platforms | Chain | Medium | 62s | Chaîne de plateformes éphémères. | ✔ |  |
| 152 | Tripwire Maze | 8.64 | Proximity traps | Route | Medium | 62s | Labyrinthe piégé. | ✔ |  |
| 153 | Reflex Bridge | 8.69 | Collapsing bridge | Speed | Medium | 62s | Pont qui s'effondre segment par segment. | ✔ |  |
| 154 | Spike Rhythm | 8.73 | Pop-up spikes | Music beat | Medium | 62s | Pics calés sur le tempo de la musique. | ✔ |  |
| 155 | Warning Lights | 8.77 | Lane lights | Reading | Medium | 62s | Les lumières annoncent quelle voie sera mortelle. | ✔ |  |
| 156 | Proximity Pistons | 8.82 | Reactive pistons | Timing | Medium | 62s | Pistons déclenchés à l'approche. | ✔ |  |
| 157 | Overload | 8.86 | All traps | Pressure | Medium | 62s | Beaucoup de signaux, lecture rapide. | ✔ |  |
| 158 | Meltdown Run | 8.89 | Chaser | Reaction | Medium | 62s | Fuite du réacteur. | ✔ |  |
| 159 | Critical Mass | 8.93 | Review | Pre-final | Long | 99s | Réaction pure. | ✔ |  |
| 160 | **Reactor Core** | 8.99 | FINAL STAGE | All reaction | Final (x4) | 248s | Le cœur du réacteur entre en fusion. | ✘ | ★ |

## Zone 9 — COMBINATIONS — Prism Nexus (161–180) · EXTREME

*Combine what you know* — Everything, two at a time

| Lvl | Nom | Diff. | Mécanique principale | Secondaire | Longueur | Temps | Défi principal | CP | Final |
|---:|---|---:|---|---|---|---:|---|:-:|:-:|
| 161 | Gravity x Timing | 9.01 | Gravity zones | Laser cycles | Short | 54s | Gravité faible pendant des cycles laser. | ✔ |  |
| 162 | Ice x Precision | 9.07 | Ice | Small platforms | Short | 54s | Petites plateformes glacées. | ✔ |  |
| 163 | Momentum x Lasers | 9.13 | Boost | Rotating lasers | Short | 54s | Boost à travers un balayage laser. | ✔ |  |
| 164 | Wind x Movers | 9.19 | Wind | Moving platforms | Short | 54s | Navettes dans le vent. | ✔ |  |
| 165 | Walls x Falling | 9.25 | Moving walls | Falling platforms | Short | 54s | Murs mobiles au-dessus de plateformes friables. | ✔ |  |
| 166 | Rotation x Timing | 9.33 | Rotation room | Timed doors | Medium | 67s | Rotation de salle + portes cadencées. | ✔ |  |
| 167 | Conveyor x Precision | 9.38 | Conveyors | Small platforms | Medium | 67s | Tapis vers des cibles minuscules. | ✔ |  |
| 168 | Ghost x Low Gravity | 9.43 | Ghost platforms | Low gravity | Medium | 67s | Fantômes en gravité faible (le saut dure plus longtemps). | ✔ |  |
| 169 | Ice x Reaction | 9.48 | Ice | Proximity traps | Medium | 67s | Glisser en réagissant. | ✔ |  |
| 170 | Pads x Rotation | 9.53 | Jump pads | Rotation room | Medium | 67s | Pads dans une salle qui pivote. | ✔ |  |
| 171 | Chaser x Doors | 9.59 | Chaser | Timed doors | Medium | 67s | Porte cadencée pendant une poursuite. | ✔ |  |
| 172 | Heavy Ceiling | 9.64 | High gravity | Head hitters | Medium | 67s | Gravité 2× + head hitters. | ✔ |  |
| 173 | Wind x Ghost | 9.69 | Wind | Ghost platforms | Medium | 67s | Fantômes dans le vent. | ✔ |  |
| 174 | Prism Belt | 9.73 | Ice + conveyor | Lasers | Medium | 67s | Triple combinaison. | ✔ |  |
| 175 | Falling Momentum | 9.77 | Falling platforms | Boost | Medium | 67s | Boost sur plateformes friables. | ✔ |  |
| 176 | Reaction Gravity | 9.82 | Proximity traps | Gravity pads | Medium | 67s | Pièges réactifs en gravité variable. | ✔ |  |
| 177 | Truss Sweep | 9.86 | Truss | Spinners | Medium | 67s | Grimper pendant un balayage. | ✔ |  |
| 178 | Triple Threat | 9.89 | Three combos | Endurance | Medium | 67s | Trois combinaisons enchaînées. | ✔ |  |
| 179 | Prism Gate | 9.93 | Review | Pre-final | Long | 107s | Toutes les paires. | ✔ |  |
| 180 | **Nexus** | 9.99 | FINAL STAGE | Everything | Final (x4) | 268s | Énorme examen avant la zone finale. | ✘ | ★ |

## Zone 10 — MASTERY — Summit of Mastery (181–200) · TERRIFYING

*Prove it* — No new rules. Only you.

| Lvl | Nom | Diff. | Mécanique principale | Secondaire | Longueur | Temps | Défi principal | CP | Final |
|---:|---|---:|---|---|---|---:|---|:-:|:-:|
| 181 | Clean Slate | 10.01 | Classic parkour | Precision | Short | 58s | Parkour pur, exigeant et propre. | ✔ |  |
| 182 | Exact | 10.07 | Precision | Small targets | Short | 58s | Cibles de 2 studs. | ✔ |  |
| 183 | Metronome II | 10.13 | Timing | Master tier | Short | 58s | Retour de la zone 2 en version maître. | ✔ |  |
| 184 | Velocity II | 10.19 | Momentum | Master tier | Short | 58s | Retour de la zone 3 en version maître. | ✔ |  |
| 185 | Ascent II | 10.25 | Verticality | Master tier | Short | 58s | Retour de la zone 4 en version maître. | ✔ |  |
| 186 | Upheaval II | 10.33 | Dynamic | Master tier | Medium | 72s | Retour de la zone 5 en version maître. | ✔ |  |
| 187 | Glacier II | 10.38 | Control | Master tier | Medium | 72s | Retour de la zone 6 en version maître. | ✔ |  |
| 188 | Zero-G II | 10.43 | Gravity | Master tier | Medium | 72s | Retour de la zone 7 en version maître. | ✔ |  |
| 189 | Reflex II | 10.48 | Reaction | Master tier | Medium | 72s | Retour de la zone 8 en version maître. | ✔ |  |
| 190 | I Can Finish | 10.53 | Review | Confidence | Medium | 72s | Niveau-respiration : exigeant mais très propre. | ✔ |  |
| 191 | Long Haul | 10.59 | Endurance | Consistency | Medium | 72s | Niveau long sans piège : la régularité. | ✔ |  |
| 192 | Pressure Cooker | 10.64 | Chaser | Whole level | Medium | 72s | Poursuite sur tout le niveau. | ✔ |  |
| 193 | Needle | 10.69 | Precision | Gravity | Medium | 72s | Précision en gravité variable. | ✔ |  |
| 194 | Storm Summit | 10.73 | Wind | Falling | Medium | 72s | Tempête au sommet. | ✔ |  |
| 195 | Clockwork Summit | 10.77 | Timing | Rotation room | Medium | 72s | Horlogerie + rotation. | ✔ |  |
| 196 | No Margin | 10.82 | Precision | Ice | Medium | 72s | Aucune marge d'erreur, mais tout est lisible. | ✔ |  |
| 197 | Everything Everywhere | 10.86 | All mechanics | Chaos (fair) | Medium | 72s | Toutes les mécaniques, jamais aléatoires. | ✔ |  |
| 198 | Last Light | 10.89 | Review | Emotional | Medium | 72s | Le soleil se couche, l'arrivée apparaît. | ✔ |  |
| 199 | The Final Threshold | 10.93 | Review | Pre-final | Long | 115s | Pré-examen ultime ; enchaîne sans checkpoint sur 200. | ✔ |  |
| 200 | **FINAL EXAM** | 10.99 | FINAL STAGE | Everything | Final (x4) | 288s | 10 sections : parkour, timing, momentum, verticalité, dynamique, contrôle, gravité, réaction, combinaisons, final rush. | ✘ | ★ |
