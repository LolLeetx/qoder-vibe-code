# TaskMon

A gamified iOS to-do list app where completing tasks earns XP to collect and evolve creatures, then battle other players in real-time PvP.

## Features

- **Task Management** - Create tasks across 5 categories (Work, Health, Learning, Creative, Personal) with Easy/Medium/Hard difficulty
- **Creature Collection** - Earn XP by completing tasks. At 100 XP in a category, a creature spawns. Creatures evolve at 500 XP (Stage 2) and 1000 XP (Stage 3)
- **Type System** - Work > Learning > Creative > Health > Work effectiveness chain (1.5x damage multiplier)
- **Online PvP** - Real-time matchmaking and turn-based battles against other players via Firebase
- **Local Battles** - Practice against AI opponents matched to your team strength
- **Leaderboard** - Global rankings by wins with player stats
- **Google Sign-In** - Authentication with profile management

## Tech Stack

- **SwiftUI** - iOS 17+ with MVVM architecture
- **Firebase Auth** - Google Sign-In + Anonymous authentication
- **Firebase Realtime Database** - Battle state sync and matchmaking queue
- **Firebase Firestore** - Player profiles and leaderboard
- **Swift Package Manager** - Dependency management

## Project Structure

```
TaskMon/
  Models/          - Battle, Creature, CreatureMove, Player, TaskItem, LeaderboardEntry
  ViewModels/      - AuthViewModel, BattleViewModel, CreatureViewModel, TaskViewModel
  Views/
    Auth/          - LoginView
    Tasks/         - TasksView, AddTaskView, TaskRowView
    Creatures/     - CreaturesView, CreatureCardView, CreatureDetailView, EvolutionAnimationView
    Battle/        - BattleView, BattleArenaView, BattleSetupView, MatchmakingView
    Leaderboard/   - LeaderboardView
    Settings/      - SettingsView
    Components/    - PixelText, PixelButton, HPBar, CreatureSpriteView
  Services/        - FirebaseService (protocols), FirebaseImplementation, BattleEngine, CreatureGenerator, XPManager
  Utils/           - Constants, TypeEffectiveness
```

## Setup

### Prerequisites

- Xcode 15.2+
- iOS 17.0+ deployment target
- Firebase project

### Firebase Configuration

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an iOS app with bundle ID `com.taskmon.app`
3. Download `GoogleService-Info.plist` and add it to the `TaskMon/TaskMon/` directory
4. Enable these services in Firebase Console:
   - **Authentication** > Sign-in method > Google (required) and Anonymous (optional)
   - **Firestore Database** - Create database
   - **Realtime Database** - Create database (note the region)

### Google Sign-In

1. Enable Google as a sign-in provider in Firebase Console
2. Download a fresh `GoogleService-Info.plist` (must contain `CLIENT_ID` and `REVERSED_CLIENT_ID`)
3. In Xcode: Target > Info > URL Types > add the `REVERSED_CLIENT_ID` value as a URL Scheme

### Firestore Security Rules

Deploy the included `firestore.rules` file:

```bash
firebase login
firebase deploy --only firestore:rules --project YOUR_PROJECT_ID
```

Or paste the rules manually in Firebase Console > Firestore > Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /leaderboard/{entry} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Realtime Database URL

If your Realtime Database is not in the default US region, update the URL in `FirebaseImplementation.swift`:

```swift
private let rtdb = Database.database(url: "https://YOUR-PROJECT-default-rtdb.REGION.firebasedatabase.app").reference()
```

### Build & Run

1. Open `TaskMon.xcodeproj` in Xcode
2. Wait for Swift Package Manager to resolve dependencies (Firebase SDK, GoogleSignIn SDK)
3. Select a simulator or device (iOS 17+)
4. Build and run

## Gameplay

1. **Add Tasks** - Create tasks in any category and difficulty
2. **Complete Tasks** - Earn XP (Easy: 10, Medium: 25, Hard: 50)
3. **Collect Creatures** - First creature spawns at 100 category XP
4. **Evolve** - Creatures evolve at 500 XP (Stage 2) and 1000 XP (Stage 3), gaining new moves and stronger stats
5. **Battle** - Select up to 3 creatures, choose Local (AI) or Online (PvP)
6. **Climb Ranks** - Win battles to appear on the leaderboard

## Architecture

- **Local-first** - All data persists locally via UserDefaults. Firebase syncs in the background.
- **Protocol-based services** - `AuthServiceProtocol`, `DatabaseServiceProtocol`, `RealtimeBattleServiceProtocol` allow swapping between stub (offline) and Firebase implementations.
- **Host-based PvP** - The player with the alphabetically lower ID hosts. Host resolves turns when both actions are submitted, pushes updated state to Firebase. Both players observe the shared battle node.
