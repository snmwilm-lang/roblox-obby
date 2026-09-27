# Architecture technique

## Vue d'ensemble

Projet [Rojo](https://rojo.space) : tout le jeu est du code versionné, y compris les niveaux. Le serveur **construit le monde au démarrage** à partir des définitions de niveaux ; le client **anime tous les obstacles** dans une boucle unique.

```
src/
├── shared/                 → ReplicatedStorage.Shared   (serveur + client)
│   ├── Config.luau           réglages globaux (mouvement, respawn, data, streaming)
│   ├── CheckpointRules.luau  règles pures des checkpoints (testées)
│   ├── Zones.luau            identité des 10 zones (palette, éclairage, musique)
│   ├── Palette.luau          couleurs sémantiques réservées (danger, mobile…)
│   ├── LevelPlan.luau        tableau des 200 niveaux (noms, mécaniques, difficulté)
│   ├── ObstacleTypes.luau    schéma + valeurs par défaut de chaque composant
│   ├── Timing.luau           maths des cycles (ping-pong, on/off, phases)
│   └── Net.luau              déclaration unique des RemoteEvents
├── server/                 → ServerScriptService.Server
│   ├── init.server.luau      bootstrap : init(services) puis start()
│   ├── Services/
│   │   ├── StageService        construit le monde, spawns, routage des déclencheurs
│   │   ├── DataService         DataStore, session lock, autosave, BindToClose
│   │   ├── CheckpointService   progression autoritaire (règles 19→20)
│   │   ├── RespawnService      personnage : placement, collisions, morts, échelles
│   │   ├── SpeedrunService     mode chronométré parallèle
│   │   ├── LeaderboardService  leaderstats + OrderedDataStores + panneaux du hub
│   │   └── OverheadService     nom + meilleur niveau au-dessus des têtes
│   └── World/
│       ├── LevelBuilder        DSL de construction d'un niveau
│       ├── WorldBuilder        enchaîne les niveaux (sortie N = départ N+1)
│       ├── LevelRegistry       fusionne les fichiers de zones
│       ├── Themes              décor par zone
│       └── Levels/Zone1, Zone2 définitions des niveaux
└── client/                 → StarterPlayerScripts.Client
    ├── init.client.luau      bootstrap des contrôleurs
    ├── Controllers/
    │   ├── CharacterState      références du personnage local
    │   ├── ObstacleRuntime     boucle unique des obstacles + capteur de sol + carry
    │   ├── HazardController    détection de mort (hitbox standard, vide)
    │   ├── RespawnController   mort rapide → retour au checkpoint
    │   ├── GravityController   gravité locale
    │   ├── ZoneController      éclairage/atmosphère/musique par zone
    │   ├── UIController        HUD, bannières, toasts, speedrun, victoire
    │   ├── AudioController     SFX (dont sons de gameplay) + musique
    │   ├── SettingsController  musique, masquer les joueurs
    │   └── CheckpointVisuals   couleur locale des disques de checkpoint
    └── Obstacles/            composants (1 module = 1 tag)
        MovingPlatform, Rotator, GhostPlatform, FallingPlatform,
        Laser, Conveyor, JumpPad
```

Séparation stricte : `shared` ne dépend ni du serveur ni du client ; aucun service ne `require` un autre service (ils se trouvent via la table `services` passée à `init`, ce qui évite les require circulaires) ; même principe côté client avec `controllers`.

## Flux principaux

### Démarrage serveur
1. `Net.init()` crée les RemoteEvents.
2. `StageService.init` → `WorldBuilder.build` : pour chaque niveau défini, `LevelBuilder.new` crée le pad de départ (checkpoint ou porte de Final Stage), exécute la définition, calcule `VoidY`, et la sortie du niveau devient l'origine du suivant.
3. Les autres services s'initialisent, puis `start()` dans l'ordre : `DataService` démarre en dernier pour que les écouteurs de `Loaded` soient branchés.

### Arrivée d'un joueur
```
PlayerAdded → DataService.loadAsync (UpdateAsync + session lock)
           → Loaded → CheckpointService : sanitize(checkpoint), attributs Player
CharacterAdded → RespawnService : collisions, échelles R15, attend DataLoaded,
                 RequestStreamAroundAsync, PivotTo(RespawnCFrame)
```

### Progression
```
Touched(StageGate de niveau N) → StageService (anti-rebond 0.5 s)
  → CheckpointService.onGateTouched
      canClaim(cp, N)            → claim : checkpoint, BestLevel, notifications,
                                    split speedrun, victoire si N = 201
      Final Stage et cp = N-1    → CurrentLevel = N, checkpoint inchangé
      N ≤ cp                     → retour en arrière : CurrentLevel = N
      sinon                      → tentative de skip ignorée
```

### Mort (chemin rapide, sans recharger le personnage)
```
Client : HazardController (hitbox ∩ Hazard, ou Y < VoidY)
  → RespawnController.die : son + flash + particules, ReportDeath:FireServer
  → 0.2 s → PivotTo(Player.RespawnCFrame), resetLocal (chutes, gravité)
  → invulnérabilité 0.3 s
Serveur : ReportDeath → Deaths += 1 (anti-rebond)
```
Le bouton Reset de Roblox est redirigé sur ce chemin. Une vraie mort de Humanoid respawn en 0.5 s au checkpoint.

## Système d'obstacles modulaire

Un obstacle = une Part ou un Model avec un **tag** CollectionService + des **attributs** :

| Tag | Attributs (défauts dans `ObstacleTypes`) |
|---|---|
| `Hazard` | — |
| `MovingPlatform` | Travel, Period, Pause, Phase, Easing, LoopType |
| `Rotator` | Axis, Speed, Phase |
| `Laser` | OnTime, OffTime, WarnTime, Phase |
| `GhostPlatform` | VisibleDuration, InvisibleDuration, PhaseOffset, WarnTime |
| `FallingPlatform` | FallDelay, ShakeDuration, RespawnDelay |
| `Conveyor` | Speed, Direction |
| `JumpPad` | Power, Boost |
| `GravityZone` | GravityMultiplier, TransitionTime |

On peut donc aussi construire/ajuster un obstacle **à la main dans Studio** : poser une Part, ajouter le tag, régler les attributs.

`ObstacleRuntime` (client) :
* enregistre chaque instance taggée, y compris celles qui arrivent par streaming ;
* ne met à jour que les obstacles à moins de 260 studs de la caméra (l'état est une fonction pure du temps serveur : rien n'est perdu) ;
* regroupe toutes les écritures de CFrame d'une frame dans un seul `workspace:BulkMoveTo` ;
* fournit un **capteur de sol** unique (Spherecast) utilisé par les chutes, les jump pads et le carry ;
* applique le **carry** : le delta frame-à-frame de la pièce sous les pieds est appliqué au personnage (lacet seulement), et continue pendant un saut.

Ajouter une mécanique = ajouter un module dans `client/Obstacles/` exposant `Tag`, `register(instance, record, runtime)`, `update(state, t, dt, runtime)` et, si besoin, `onGround`, `reset`, `unregister`, `setActive` ; plus son schéma dans `ObstacleTypes` et un helper dans `LevelBuilder`.

## Construire un niveau

Chaque niveau est une fonction qui reçoit le builder `L`, dans son repère local : origine = centre du dessus du pad de départ, +Z = avant.

```lua
-- 11 · The Sweeper
Levels[11] = function(L)
	L:Step(V(0, 0, 11), V(4, 1, 8))                                   -- pos = dessus
	L:Step(V(0, 0, 27), V(22, 1, 22), { shape = "Cylinder" })
	L:Spinner(V(0, 1.6, 27), { length = 10.5, arms = 1, speed = 45, floorY = 0 })
	L:Step(V(0, 0, 43), V(4, 1, 8))
	L:Exit(V(0, 0, 56))                                                -- pad du niveau 12
end
```

Primitives : `Step` (parcours validé), `Pad` (hors parcours), `Kill`, `Wall`, `Mover`, `Spinner`, `Ghost`, `Falling`, `Conveyor`, `JumpPad`, `GravityZone`, `Truss`, `Barrier`, `Sign`, `Arch`, `GoldFrame`, `SectionLabel`, `Decor`, `FinishLine`, `Exit`.

Ajouter une zone : créer `World/Levels/ZoneN.luau`, l'ajouter à `LevelRegistry`, ajouter son thème dans `Themes`, lancer `lune run tests/run.luau`.

## Données sauvegardées

DataStore `Obby200_PlayerData_v1`, clé `player_<UserId>` :

| Champ | Contenu |
|---|---|
| Version | version du schéma (migrations dans `reconcile`) |
| Checkpoint | checkpoint casual (1–201), jamais un Final Stage |
| BestLevel | plus haut checkpoint atteint (affiché plafonné à 200) |
| Deaths | morts totales |
| PlayTime | secondes de jeu cumulées |
| Completions | nombre de victoires au niveau 200 |
| BestFullRun | meilleur speedrun 1→200 (s) |
| BestZoneRuns | meilleurs splits speedrun par zone (s) |
| FirstJoin | horodatage |
| Settings | Music, Sfx, HideOthers |
| Session | verrou `{ JobId, Time }` (retiré en fin de session) |

Garanties : `UpdateAsync` uniquement ; un serveur qui a perdu le verrou n'écrit jamais ; si le chargement échoue, le joueur joue avec un profil temporaire **non sauvegardé** (bandeau d'avertissement) pour ne jamais écraser ses vraies données ; si la sauvegarde pointe vers un niveau qui n'existe pas dans la version publiée (retour en arrière d'une mise à jour), le checkpoint est ramené au plus haut checkpoint existant ; `BestLevel` est conservé.

Classements : OrderedDataStores `HighestLevel`, `Completions`, `BestFullRun` (ms, croissant), `Deaths`, écrits au plus toutes les 150 s par joueur et à la déconnexion, lus toutes les 120 s.

## Réseau

| Remote | Sens | Validation |
|---|---|---|
| ReportDeath | C→S | type, anti-rebond 0.35 s ; n'affecte que ses propres stats |
| SpeedrunRequest | C→S | booléen, cooldown 2 s |
| RestartRequest | C→S | seulement depuis la salle de victoire |
| SaveSetting | C→S | clé en liste blanche, type identique au défaut |
| Notify | S→C | événements UI |

L'état répliqué passe par des attributs de `Player` : `Checkpoint`, `CurrentLevel`, `BestLevel`, `Deaths`, `Completions`, `RespawnCFrame`, `SpeedrunActive`, `SpeedrunStart`, `DataLoaded`, `DataPersistent`, `Setting_*`.

## Sécurité / anti-triche (portée)

Un exploit client peut toujours voler ou se téléporter ; l'objectif réaliste est que la **progression** ne soit pas triviale à falsifier : checkpoints validés un par un côté serveur, spawns calculés côté serveur, aucune remote ne permet de choisir son niveau. Une vérification de vitesse (temps minimum entre deux checkpoints) peut être ajoutée dans `CheckpointService.onGateTouched` si besoin.
