# StudyBuddy — Flutter + SQLite

A pastel, offline-first student study companion with four main screens: Home, My Tasks, Focus, and My Progress.

## Features

- Add, edit, delete, complete, filter, and sort tasks.
- Store tasks and focus sessions in SQLite; data persists after app restart.
- Rule-based Smart Priority ranking using urgency, difficulty, estimated effort, and confidence.
- Focus timer with 15/25/45/60-minute sprints, pause/resume, early ending, and post-session confidence feedback.
- “I'm stuck” support with practical suggestions.
- Weekly study-time chart, total focus time, completed-task count, active days, and subject breakdown.
- Friendly pastel lavender, mint, blue, peach, and cream theme.

## Requirements

- Flutter SDK compatible with Dart `>=3.3.0 <4.0.0`
- Android Studio / VS Code with Flutter extension
- Android emulator or physical Android device (or another Flutter-supported target)

## Run the app

1. Extract this project folder.
2. Open a terminal in the project root (the folder containing `pubspec.yaml`).
3. Run:

   ```bash
   flutter create . --platforms=android,ios
   flutter pub get
   flutter run
   ```

   If you already have the platform folders from your own Flutter project, you can skip `flutter create .`.

4. To build an Android APK:

   ```bash
   flutter build apk --release
   ```

## Main dependencies

- `provider`: shared application state
- `sqflite` + `path`: local SQLite storage
- `intl`: date formatting
- `fl_chart`: weekly study chart

## Project structure

```text
lib/
├── main.dart
├── app.dart
├── data/                 # SQLite database and repository
├── models/               # StudyTask and StudySession
├── providers/             # Shared state
├── screens/               # Home, Tasks, Focus, Progress
├── services/              # Priority and statistics calculations
├── theme/                 # App theme and palette
└── widgets/               # Reusable cards and task form
```

## SQLite data

The app creates `studybuddy.db` on first launch with `study_tasks` and `study_sessions` tables. No account or network connection is required for core features.

## Notes before submission

- Run `flutter analyze` and test on the actual device/emulator used for demonstration.
- Test task creation, edit, completion, deletion, timer pause/resume, session recording, and app restart persistence.
- The priority score is a transparent heuristic for a student project, not a machine-learning model.
- The Focus timer records active focus time (paused time is excluded). The timer state itself is not persisted if the app process is killed; task and completed-session data are persisted.
