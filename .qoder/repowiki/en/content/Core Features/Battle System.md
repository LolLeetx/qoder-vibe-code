# Battle System

<cite>
**Referenced Files in This Document**
- [Battle.swift](file://TaskMon/TaskMon/Models/Battle.swift)
- [BattleEngine.swift](file://TaskMon/TaskMon/Services/BattleEngine.swift)
- [TypeEffectiveness.swift](file://TaskMon/TaskMon/Utils/TypeEffectiveness.swift)
- [BattleViewModel.swift](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift)
- [BattleView.swift](file://TaskMon/TaskMon/Views/Battle/BattleView.swift)
- [BattleArenaView.swift](file://TaskMon/TaskMon/Views/Battle/BattleArenaView.swift)
- [BattleSetupView.swift](file://TaskMon/TaskMon/Views/Battle/BattleSetupView.swift)
- [MatchmakingView.swift](file://TaskMon/TaskMon/Views/Battle/MatchmakingView.swift)
- [Creature.swift](file://TaskMon/TaskMon/Models/Creature.swift)
- [CreatureMove.swift](file://TaskMon/TaskMon/Models/CreatureMove.swift)
- [CreatureGenerator.swift](file://TaskMon/TaskMon/Services/CreatureGenerator.swift)
- [FirebaseService.swift](file://TaskMon/TaskMon/Services/FirebaseService.swift)
- [CreatureViewModel.swift](file://TaskMon/TaskMon/ViewModels/CreatureViewModel.swift)
- [CreatureSpriteView.swift](file://TaskMon/TaskMon/Views/Components/CreatureSpriteView.swift)
- [HPBar.swift](file://TaskMon/TaskMon/Views/Components/HPBar.swift)
- [Constants.swift](file://TaskMon/TaskMon/Utils/Constants.swift)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Project Structure](#project-structure)
3. [Core Components](#core-components)
4. [Architecture Overview](#architecture-overview)
5. [Detailed Component Analysis](#detailed-component-analysis)
6. [Dependency Analysis](#dependency-analysis)
7. [Performance Considerations](#performance-considerations)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Conclusion](#conclusion)
10. [Appendices](#appendices)

## Introduction
This document provides comprehensive documentation for the Battle System, covering battle setup and team management, turn-based combat mechanics, AI logic, state management, multiplayer matchmaking and synchronization, and the ViewModels and UI components that drive the experience. It also includes implementation details for the battle engine calculations, type effectiveness matrix, and AI decision trees, along with code example paths for common workflows such as initializing a battle, resolving turns, and coordinating multiplayer battles.

## Project Structure
The Battle System spans Models, Services, ViewModels, Views, and Utilities. The central data model defines the battle state, while the Battle Engine performs turn resolution and damage calculation. ViewModels orchestrate UI state, user actions, and multiplayer coordination. Views render the battle arena, team selection, and matchmaking screens. Utilities define constants and type effectiveness.

```mermaid
graph TB
subgraph "Models"
BattleModel["Battle.swift"]
CreatureModel["Creature.swift"]
MoveModel["CreatureMove.swift"]
end
subgraph "Services"
BattleEngine["BattleEngine.swift"]
CreatureGen["CreatureGenerator.swift"]
FirebaseSvc["FirebaseService.swift"]
end
subgraph "ViewModels"
BattleVM["BattleViewModel.swift"]
CreatureVM["CreatureViewModel.swift"]
end
subgraph "Views"
BattleView["BattleView.swift"]
ArenaView["BattleArenaView.swift"]
SetupView["BattleSetupView.swift"]
MatchmakingView["MatchmakingView.swift"]
SpriteView["CreatureSpriteView.swift"]
HPBarView["HPBar.swift"]
end
subgraph "Utils"
TypeEff["TypeEffectiveness.swift"]
Consts["Constants.swift"]
end
BattleVM --> BattleModel
BattleVM --> BattleEngine
BattleVM --> CreatureGen
BattleVM --> FirebaseSvc
BattleEngine --> TypeEff
BattleEngine --> CreatureModel
BattleEngine --> MoveModel
ArenaView --> BattleVM
SetupView --> BattleVM
MatchmakingView --> BattleVM
SetupView --> CreatureVM
ArenaView --> SpriteView
ArenaView --> HPBarView
CreatureVM --> CreatureModel
```

**Diagram sources**
- [Battle.swift](file://TaskMon/TaskMon/Models/Battle.swift#L32-L68)
- [BattleEngine.swift](file://TaskMon/TaskMon/Services/BattleEngine.swift#L3-L169)
- [TypeEffectiveness.swift](file://TaskMon/TaskMon/Utils/TypeEffectiveness.swift#L3-L33)
- [BattleViewModel.swift](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L10-L462)
- [BattleView.swift](file://TaskMon/TaskMon/Views/Battle/BattleView.swift#L3-L52)
- [BattleArenaView.swift](file://TaskMon/TaskMon/Views/Battle/BattleArenaView.swift#L3-L287)
- [BattleSetupView.swift](file://TaskMon/TaskMon/Views/Battle/BattleSetupView.swift#L3-L164)
- [MatchmakingView.swift](file://TaskMon/TaskMon/Views/Battle/MatchmakingView.swift#L3-L95)
- [Creature.swift](file://TaskMon/TaskMon/Models/Creature.swift#L33-L98)
- [CreatureMove.swift](file://TaskMon/TaskMon/Models/CreatureMove.swift#L3-L68)
- [CreatureGenerator.swift](file://TaskMon/TaskMon/Services/CreatureGenerator.swift#L3-L44)
- [FirebaseService.swift](file://TaskMon/TaskMon/Services/FirebaseService.swift#L30-L41)
- [CreatureViewModel.swift](file://TaskMon/TaskMon/ViewModels/CreatureViewModel.swift#L5-L90)
- [CreatureSpriteView.swift](file://TaskMon/TaskMon/Views/Components/CreatureSpriteView.swift#L3-L52)
- [HPBar.swift](file://TaskMon/TaskMon/Views/Components/HPBar.swift#L3-L110)
- [Constants.swift](file://TaskMon/TaskMon/Utils/Constants.swift#L4-L40)

**Section sources**
- [Battle.swift](file://TaskMon/TaskMon/Models/Battle.swift#L1-L69)
- [BattleEngine.swift](file://TaskMon/TaskMon/Services/BattleEngine.swift#L1-L170)
- [TypeEffectiveness.swift](file://TaskMon/TaskMon/Utils/TypeEffectiveness.swift#L1-L34)
- [BattleViewModel.swift](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L1-L462)
- [BattleView.swift](file://TaskMon/TaskMon/Views/Battle/BattleView.swift#L1-L53)
- [BattleArenaView.swift](file://TaskMon/TaskMon/Views/Battle/BattleArenaView.swift#L1-L287)
- [BattleSetupView.swift](file://TaskMon/TaskMon/Views/Battle/BattleSetupView.swift#L1-L164)
- [MatchmakingView.swift](file://TaskMon/TaskMon/Views/Battle/MatchmakingView.swift#L1-L95)
- [Creature.swift](file://TaskMon/TaskMon/Models/Creature.swift#L1-L98)
- [CreatureMove.swift](file://TaskMon/TaskMon/Models/CreatureMove.swift#L1-L68)
- [CreatureGenerator.swift](file://TaskMon/TaskMon/Services/CreatureGenerator.swift#L1-L44)
- [FirebaseService.swift](file://TaskMon/TaskMon/Services/FirebaseService.swift#L1-L157)
- [CreatureViewModel.swift](file://TaskMon/TaskMon/ViewModels/CreatureViewModel.swift#L1-L90)
- [CreatureSpriteView.swift](file://TaskMon/TaskMon/Views/Components/CreatureSpriteView.swift#L1-L52)
- [HPBar.swift](file://TaskMon/TaskMon/Views/Components/HPBar.swift#L1-L110)
- [Constants.swift](file://TaskMon/TaskMon/Utils/Constants.swift#L1-L40)

## Core Components
- Battle Model: Defines battle state, teams, active creatures, turn tracking, logs, and status.
- Battle Engine: Implements turn resolution, move execution, damage calculation, type effectiveness, fainting checks, and win conditions.
- Type Effectiveness: Provides multiplier logic and textual feedback for type matchups.
- Battle ViewModel: Manages UI state, team selection, local and online battle flows, matchmaking, action submission, and battle observation.
- Creature and Moves: Define stats, evolution, movesets, and damage mechanics.
- Creature Generator: Generates AI teams and matched AI teams based on player team characteristics.
- Firebase Service Protocols: Define authentication, database, and realtime battle service interfaces (with stub implementations).
- UI Components: Battle arena, team setup, matchmaking, creature sprites, and HP bars.

**Section sources**
- [Battle.swift](file://TaskMon/TaskMon/Models/Battle.swift#L32-L68)
- [BattleEngine.swift](file://TaskMon/TaskMon/Services/BattleEngine.swift#L3-L169)
- [TypeEffectiveness.swift](file://TaskMon/TaskMon/Utils/TypeEffectiveness.swift#L3-L33)
- [BattleViewModel.swift](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L10-L462)
- [Creature.swift](file://TaskMon/TaskMon/Models/Creature.swift#L33-L98)
- [CreatureMove.swift](file://TaskMon/TaskMon/Models/CreatureMove.swift#L3-L68)
- [CreatureGenerator.swift](file://TaskMon/TaskMon/Services/CreatureGenerator.swift#L3-L44)
- [FirebaseService.swift](file://TaskMon/TaskMon/Services/FirebaseService.swift#L30-L41)
- [CreatureSpriteView.swift](file://TaskMon/TaskMon/Views/Components/CreatureSpriteView.swift#L3-L52)
- [HPBar.swift](file://TaskMon/TaskMon/Views/Components/HPBar.swift#L3-L110)

## Architecture Overview
The Battle System follows a MVVM architecture with clear separation of concerns:
- Models encapsulate game state and data.
- Services implement core logic (battle engine, AI, persistence).
- ViewModels coordinate UI state, user actions, and external services.
- Views render the UI and bind to ViewModel state.
- Utilities provide constants and type effectiveness.

```mermaid
classDiagram
class Battle {
+string id
+string player1Id
+string player2Id
+[Creature] player1Team
+[Creature] player2Team
+int player1ActiveIndex
+int player2ActiveIndex
+int currentTurn
+[string] battleLog
+BattleStatus status
+string? winnerId
+BattleAction? player1Action
+BattleAction? player2Action
+bool isOver
+addLog(message)
}
class BattleEngine {
+resolveTurn(battle, player1Action, player2Action)
+selectAIAction(battle) BattleAction
}
class TypeEffectiveness {
+multiplier(attacking, defending) Double
+effectivenessText(attacking, defending) String?
}
class BattleViewModel {
+Battle? currentBattle
+[Creature] selectedTeam
+BattleMode battleMode
+BattlePhase battlePhase
+Bool isPlayerTurn
+Bool showBattleResult
+Bool playerWon
+Bool isMatchmaking
+Int matchmakingSeconds
+Bool shakePlayer1
+Bool shakePlayer2
+Bool isOnlineBattle
+Bool waitingForOpponent
+startLocalBattle()
+startMatchmaking()
+cancelMatchmaking()
+playerSelectMove(index)
+playerSwitchCreature(index)
+forfeit()
}
class Creature {
+UUID id
+string name
+TaskCategory category
+int stage
+int level
+int currentXP
+CreatureStats stats
+[CreatureMove] moves
+bool isFainted
+evolve(to)
+takeDamage(amount)
+heal()
}
class CreatureMove {
+UUID id
+string name
+int power
+TaskCategory type
+string description
}
class CreatureGenerator {
+generate(category, stage, level) Creature
+generateAITeam(count, stageRange) [Creature]
+generateMatchedAITeam(playerTeam) [Creature]
}
class FirebaseServiceProtocol {
<<interface>>
}
BattleEngine --> Battle : "mutates"
BattleEngine --> TypeEffectiveness : "uses"
BattleEngine --> Creature : "reads"
BattleEngine --> CreatureMove : "reads"
BattleViewModel --> Battle : "manages"
BattleViewModel --> CreatureGenerator : "generates AI team"
BattleViewModel --> FirebaseServiceProtocol : "coordinates online"
CreatureGenerator --> Creature : "creates"
Creature --> CreatureMove : "has"
```

**Diagram sources**
- [Battle.swift](file://TaskMon/TaskMon/Models/Battle.swift#L32-L68)
- [BattleEngine.swift](file://TaskMon/TaskMon/Services/BattleEngine.swift#L3-L169)
- [TypeEffectiveness.swift](file://TaskMon/TaskMon/Utils/TypeEffectiveness.swift#L3-L33)
- [BattleViewModel.swift](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L10-L462)
- [Creature.swift](file://TaskMon/TaskMon/Models/Creature.swift#L33-L98)
- [CreatureMove.swift](file://TaskMon/TaskMon/Models/CreatureMove.swift#L3-L68)
- [CreatureGenerator.swift](file://TaskMon/TaskMon/Services/CreatureGenerator.swift#L3-L44)
- [FirebaseService.swift](file://TaskMon/TaskMon/Services/FirebaseService.swift#L30-L41)

## Detailed Component Analysis

### Battle Setup and Team Management
- Team Composition: Players select 1–GameConstants.maxTeamSize creatures for battle. The selection toggles via the ViewModel and is validated against the limit.
- Preparation Workflow:
  - Local Battle: Selected team is healed, an AI team is generated, and a Battle instance is created with initial logs.
  - Online Battle: Team is submitted to matchmaking; the host creates the shared battle and observers receive updates.
- UI: BattleSetupView renders available creatures, selected team preview, mode selection, and start button.

```mermaid
sequenceDiagram
participant User as "User"
participant Setup as "BattleSetupView"
participant VM as "BattleViewModel"
participant Gen as "CreatureGenerator"
participant Engine as "BattleEngine"
User->>Setup : "Select creatures and choose mode"
Setup->>VM : "toggleCreatureSelection(creature)"
Setup->>VM : "startLocalBattle() or startMatchmaking()"
VM->>VM : "validate selectedTeam size"
VM->>VM : "heal() selectedTeam"
VM->>Gen : "generateMatchedAITeam(playerTeam)"
Gen-->>VM : "[Creature] AI team"
VM->>VM : "create Battle(player1Team, player2Team)"
VM->>Engine : "resolveTurn(..., playerAction : .useMove(0))"
Engine-->>VM : "updated Battle state"
VM-->>Setup : "@Published currentBattle, battlePhase"
```

**Diagram sources**
- [BattleSetupView.swift](file://TaskMon/TaskMon/Views/Battle/BattleSetupView.swift#L3-L164)
- [BattleViewModel.swift](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L52-L82)
- [CreatureGenerator.swift](file://TaskMon/TaskMon/Services/CreatureGenerator.swift#L24-L42)
- [BattleEngine.swift](file://TaskMon/TaskMon/Services/BattleEngine.swift#L5-L66)

**Section sources**
- [BattleViewModel.swift](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L52-L82)
- [BattleSetupView.swift](file://TaskMon/TaskMon/Views/Battle/BattleSetupView.swift#L3-L164)
- [Constants.swift](file://TaskMon/TaskMon/Utils/Constants.swift#L15-L17)
- [CreatureGenerator.swift](file://TaskMon/TaskMon/Services/CreatureGenerator.swift#L24-L42)

### Turn-Based Combat Mechanics
- Turn Resolution:
  - Actions: Player and AI submit actions (useMove, switchCreature, forfeit).
  - Order: Speed determines who attacks first; ties resolved randomly.
  - Execution: Moves apply damage considering type effectiveness and variance.
  - Fainting: Active creature faints if HP <= 0; auto-switch to next available creature.
  - Win Condition: All of one side’s creatures faint → declare winner/draw.
- Damage Calculation:
  - Base damage derived from attacker stats and move power, scaled by defense and type effectiveness.
  - Random variance applied to introduce stochasticity.
- Type Effectiveness:
  - Matrix defines super-effective, not very effective, and neutral against Work/Learning/Creative/Health with Personal being neutral to all.
  - Textual feedback is logged when effectiveness differs from neutral.

```mermaid
flowchart TD
Start(["Turn Start"]) --> CheckForfeit{"Any forfeit?"}
CheckForfeit --> |Yes| DeclareWinner["Set winner and finish"]
CheckForfeit --> |No| Switches["Apply switch actions if requested"]
Switches --> SpeedOrder["Determine who attacks first by speed"]
SpeedOrder --> Attacker1{"Attacker 1 move?"}
Attacker1 --> |Yes| Execute1["executeMove(attacker1, moveIndex)"]
Attacker1 --> |No| DefenderCheck1["Check defender still active"]
Execute1 --> DefenderCheck1
DefenderCheck1 --> |Alive| Attacker2{"Attacker 2 move?"}
DefenderCheck1 --> |Fainted| CheckFaint1["handleFainting(isPlayer1=true)"]
Attacker2 --> |Yes| Execute2["executeMove(attacker2, moveIndex)"]
Attacker2 --> |No| CheckFaint1
Execute2 --> CheckFaint2["handleFainting(isPlayer1=false)"]
CheckFaint1 --> CheckFaint2
CheckFaint2 --> WinCheck["checkWinCondition()"]
WinCheck --> End(["Turn End"])
```

**Diagram sources**
- [BattleEngine.swift](file://TaskMon/TaskMon/Services/BattleEngine.swift#L5-L143)
- [TypeEffectiveness.swift](file://TaskMon/TaskMon/Utils/TypeEffectiveness.swift#L11-L32)

**Section sources**
- [BattleEngine.swift](file://TaskMon/TaskMon/Services/BattleEngine.swift#L5-L143)
- [TypeEffectiveness.swift](file://TaskMon/TaskMon/Utils/TypeEffectiveness.swift#L3-L33)

### AI Opponent Logic
- Decision-Making:
  - AI selects the move with the highest score, computed as move.power multiplied by the type effectiveness multiplier against the player’s active creature.
  - If no moves are available, defaults to using the first move.
- Difficulty and Behavior:
  - Current implementation is a simple optimal-choice heuristic; no explicit difficulty tiers are present in code.
  - Strategy pattern allows future extension to include randomness, risk assessment, or status-based decisions.

```mermaid
flowchart TD
StartAI(["AI Turn"]) --> GetTeam["Get AI active creature and player active creature"]
GetTeam --> Enumerate["Enumerate available moves"]
Enumerate --> Score["score = power × effectivenessMultiplier"]
Score --> Best{"Best score so far?"}
Best --> |Yes| Update["Update bestIndex and bestScore"]
Best --> |No| Next["Next move"]
Update --> Next
Next --> DoneAI(["Return .useMove(bestIndex)"])
```

**Diagram sources**
- [BattleEngine.swift](file://TaskMon/TaskMon/Services/BattleEngine.swift#L147-L168)

**Section sources**
- [BattleEngine.swift](file://TaskMon/TaskMon/Services/BattleEngine.swift#L147-L168)

### Battle State Management
- State Tracking:
  - Turn counter increments per resolved turn.
  - BattleAction stores type and index for moves or switches.
  - Logs capture all events; animations play out messages sequentially.
- Health Management:
  - Creatures track HP and can be healed or damaged.
  - Fainting triggers automatic replacement with the next healthy creature.
- Result Processing:
  - Win conditions checked after each turn; logs declare outcomes and status transitions to finished.

```mermaid
stateDiagram-v2
[*] --> Setup
Setup --> Fighting : "startLocalBattle() or startObservingOnlineBattle()"
Fighting --> Finished : "checkWinCondition() sets status"
Finished --> Setup : "resetBattle()"
```

**Diagram sources**
- [Battle.swift](file://TaskMon/TaskMon/Models/Battle.swift#L32-L68)
- [BattleEngine.swift](file://TaskMon/TaskMon/Services/BattleEngine.swift#L127-L143)
- [BattleViewModel.swift](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L388-L414)

**Section sources**
- [Battle.swift](file://TaskMon/TaskMon/Models/Battle.swift#L32-L68)
- [BattleEngine.swift](file://TaskMon/TaskMon/Services/BattleEngine.swift#L105-L143)
- [BattleViewModel.swift](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L388-L414)

### Multiplayer Features
- Matchmaking Coordination:
  - Queue joining and observation to detect matches.
  - Host determines battle ID and creates the shared battle document.
  - Non-host leaves queue and observes the created battle.
- Real-Time Synchronization:
  - Observers receive updates and apply new logs with animations.
  - Host resolves turns when both actions are present.
- Opponent Management:
  - Perspective swapping ensures the local player always sees themselves as player1.
  - Friendly log text replaces IDs with “You” and “Opponent”.

```mermaid
sequenceDiagram
participant P1 as "Player 1"
participant P2 as "Player 2"
participant Queue as "Queue Observer"
participant Host as "Host Device"
participant Remote as "Remote Device"
participant RTB as "RealtimeBattleService"
P1->>RTB : "joinQueue(playerId, team)"
P2->>RTB : "joinQueue(playerId, team)"
RTB-->>Queue : "onMatchFound(p1Id, p2Id)"
Queue-->>Host : "handleMatchFound(p1Id, p2Id)"
alt Host
Host->>RTB : "fetchQueueEntry(opponentId)"
Host->>RTB : "createBattle(sharedBattle)"
else Remote
Remote->>RTB : "leaveQueue(playerId)"
end
P1->>RTB : "observeBattle(battleId)"
P2->>RTB : "observeBattle(battleId)"
Note over P1,P2 : "Both observe and apply updates"
```

**Diagram sources**
- [BattleViewModel.swift](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L167-L281)
- [FirebaseService.swift](file://TaskMon/TaskMon/Services/FirebaseService.swift#L30-L41)

**Section sources**
- [BattleViewModel.swift](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L167-L281)
- [FirebaseService.swift](file://TaskMon/TaskMon/Services/FirebaseService.swift#L30-L41)

### ViewModels Responsibilities
- BattleViewModel:
  - Team selection and validation.
  - Local and online battle lifecycle.
  - Action submission and turn resolution.
  - Matchmaking timers and UI state.
  - Shake animations and log message sequencing.
- CreatureViewModel:
  - Loads and persists creatures.
  - Exposes battle-ready creatures and heals them.
  - Subscribes to XP events to evolve creatures.

**Section sources**
- [BattleViewModel.swift](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L10-L462)
- [CreatureViewModel.swift](file://TaskMon/TaskMon/ViewModels/CreatureViewModel.swift#L5-L90)

### UI Components
- BattleArenaView:
  - Renders opponent and player sides with sprites, HP bars, and team indicators.
  - Displays battle log with color-coded messages and animations.
  - Presents move buttons, switch menu, and forfeit controls.
- BattleSetupView:
  - Grid of selectable creatures, selected team preview, and mode buttons.
  - Start button triggers either local fight or matchmaking.
- MatchmakingView:
  - Animated radar/wifi visuals, elapsed time, and team preview.
  - Cancel button to exit matchmaking.
- Components:
  - CreatureSpriteView: Renders creature sprites with fallback icons.
  - HPBar: Visual HP indicator with color thresholds.

**Section sources**
- [BattleArenaView.swift](file://TaskMon/TaskMon/Views/Battle/BattleArenaView.swift#L3-L287)
- [BattleSetupView.swift](file://TaskMon/TaskMon/Views/Battle/BattleSetupView.swift#L3-L164)
- [MatchmakingView.swift](file://TaskMon/TaskMon/Views/Battle/MatchmakingView.swift#L3-L95)
- [CreatureSpriteView.swift](file://TaskMon/TaskMon/Views/Components/CreatureSpriteView.swift#L3-L52)
- [HPBar.swift](file://TaskMon/TaskMon/Views/Components/HPBar.swift#L3-L110)

## Dependency Analysis
- BattleEngine depends on:
  - TypeEffectiveness for damage multipliers.
  - Creature and CreatureMove for stats and moves.
- BattleViewModel depends on:
  - BattleEngine for turn resolution.
  - CreatureGenerator for AI teams.
  - FirebaseServiceProtocol for matchmaking and battle observation.
- UI binds to ViewModels via @EnvironmentObject and reacts to @Published state changes.

```mermaid
graph LR
BattleEngine --> TypeEffectiveness
BattleEngine --> Creature
BattleEngine --> CreatureMove
BattleViewModel --> BattleEngine
BattleViewModel --> CreatureGenerator
BattleViewModel --> FirebaseServiceProtocol
BattleView --> BattleViewModel
BattleArenaView --> BattleViewModel
BattleSetupView --> BattleViewModel
MatchmakingView --> BattleViewModel
```

**Diagram sources**
- [BattleEngine.swift](file://TaskMon/TaskMon/Services/BattleEngine.swift#L3-L169)
- [TypeEffectiveness.swift](file://TaskMon/TaskMon/Utils/TypeEffectiveness.swift#L3-L33)
- [BattleViewModel.swift](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L10-L462)
- [FirebaseService.swift](file://TaskMon/TaskMon/Services/FirebaseService.swift#L30-L41)
- [BattleView.swift](file://TaskMon/TaskMon/Views/Battle/BattleView.swift#L3-L52)
- [BattleArenaView.swift](file://TaskMon/TaskMon/Views/Battle/BattleArenaView.swift#L3-L287)
- [BattleSetupView.swift](file://TaskMon/TaskMon/Views/Battle/BattleSetupView.swift#L3-L164)
- [MatchmakingView.swift](file://TaskMon/TaskMon/Views/Battle/MatchmakingView.swift#L3-L95)

**Section sources**
- [BattleEngine.swift](file://TaskMon/TaskMon/Services/BattleEngine.swift#L3-L169)
- [BattleViewModel.swift](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L10-L462)
- [FirebaseService.swift](file://TaskMon/TaskMon/Services/FirebaseService.swift#L30-L41)

## Performance Considerations
- Animation and Rendering:
  - Pixel art scaling and minimal re-renders improve frame stability.
  - Scroll-to-bottom animations for logs are throttled by delays.
- Network and State Updates:
  - Debounce log application and turn resolution to prevent redundant updates.
  - Use observer handles to clean up listeners and avoid memory leaks.
- Calculation Complexity:
  - Turn resolution is O(1) per action; type effectiveness lookup is constant.
  - Consider caching type effectiveness multipliers if extended to dynamic charts.

## Troubleshooting Guide
- No Creatures Available:
  - Ensure creatures are unlocked and not fainted; use CreatureViewModel.healAll() to restore HP.
- Matchmaking Stalls:
  - Verify queue observers are registered and timer runs; cancel and retry matchmaking.
- Online Battle Not Syncing:
  - Confirm battleId correctness and that both devices observe the same ID.
  - Check perspective swapping and friendly log replacements.
- Turn Not Resolving:
  - Ensure both actions are submitted (or default fallback used) and isResolvingTurn flag is cleared.

**Section sources**
- [CreatureViewModel.swift](file://TaskMon/TaskMon/ViewModels/CreatureViewModel.swift#L69-L74)
- [BattleViewModel.swift](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L167-L281)
- [BattleViewModel.swift](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L285-L357)

## Conclusion
The Battle System integrates a robust turn-based engine with intuitive UI, flexible team management, and scalable multiplayer support. The modular design enables straightforward enhancements such as AI difficulty tiers, advanced type charts, and richer multiplayer features while maintaining clear separation between models, services, ViewModels, and views.

## Appendices

### Implementation Details and Example Paths
- Battle Initialization:
  - Local: [BattleViewModel.startLocalBattle](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L66-L82)
  - Online Host: [BattleViewModel.handleMatchFound](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L225-L281)
- Turn Resolution Pattern:
  - [BattleEngine.resolveTurn](file://TaskMon/TaskMon/Services/BattleEngine.swift#L5-L66)
  - [BattleEngine.executeMove](file://TaskMon/TaskMon/Services/BattleEngine.swift#L68-L103)
- Multiplayer Coordination:
  - [BattleViewModel.startMatchmaking](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L167-L203)
  - [BattleViewModel.startObservingOnlineBattle](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L285-L294)
  - [BattleViewModel.handleBattleUpdate](file://TaskMon/TaskMon/ViewModels/BattleViewModel.swift#L296-L357)
- Type Effectiveness Matrix:
  - [TypeEffectiveness.multiplier](file://TaskMon/TaskMon/Utils/TypeEffectiveness.swift#L11-L22)
  - [TypeEffectiveness.effectivenessText](file://TaskMon/TaskMon/Utils/TypeEffectiveness.swift#L24-L32)
- AI Decision Tree:
  - [BattleEngine.selectAIAction](file://TaskMon/TaskMon/Services/BattleEngine.swift#L147-L168)