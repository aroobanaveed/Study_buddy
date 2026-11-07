
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final String dbPath;

    if (kIsWeb) {
      dbPath = 'studybuddy_web.db';
    } else {
      final basePath = await getDatabasesPath();
      dbPath = p.join(basePath, 'studybuddy.db');
    }

    _database = await openDatabase(
      dbPath,
      version: 3,

      // ---------------- CREATE DATABASE ----------------

      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE study_tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            subject TEXT NOT NULL,
            taskType TEXT NOT NULL,
            dueDate TEXT,
            estimatedMinutes INTEGER NOT NULL,
            difficulty INTEGER NOT NULL,
            confidence INTEGER,
            status TEXT NOT NULL DEFAULT 'pending',
            createdAt TEXT NOT NULL,
            completedAt TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE study_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            taskId INTEGER,
            startedAt TEXT NOT NULL,
            endedAt TEXT,
            durationSeconds INTEGER NOT NULL,
            sessionStatus TEXT NOT NULL,
            confidenceAfter INTEGER,
            FOREIGN KEY(taskId) REFERENCES study_tasks(id)
              ON DELETE SET NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE sticky_notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            color INTEGER NOT NULL DEFAULT 0,
            isPinned INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');

        await _createReminderTable(db);

        await db.execute(
          'CREATE INDEX idx_tasks_status ON study_tasks(status)',
        );

        await db.execute(
          'CREATE INDEX idx_sessions_started ON study_sessions(startedAt)',
        );
      },

      // ---------------- DATABASE MIGRATION ----------------

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE sticky_notes (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              content TEXT NOT NULL,
              color INTEGER NOT NULL DEFAULT 0,
              isPinned INTEGER NOT NULL DEFAULT 0,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL
            )
          ''');
        }

        if (oldVersion < 3) {
          await _createReminderTable(db);
        }
      },

      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );

    return _database!;
  }

  // ---------------- REMINDER TABLE ----------------

  static Future<void> _createReminderTable(Database db) async {
    await db.execute('''
      CREATE TABLE study_reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        taskId INTEGER NOT NULL,
        reminderTime TEXT NOT NULL,
        message TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        isSent INTEGER NOT NULL DEFAULT 0,

        FOREIGN KEY(taskId) REFERENCES study_tasks(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_reminders_time ON study_reminders(reminderTime)',
    );

    await db.execute(
      'CREATE INDEX idx_reminders_status ON study_reminders(isActive, isSent)',
    );
  }
}
