
import 'package:sqflite/sqflite.dart';

import '../models/study_session.dart';
import '../models/study_task.dart';
import '../models/sticky_note.dart';
import '../models/study_reminder.dart';
import 'app_database.dart';

class StudyRepository {
  Future<Database> get _db async => AppDatabase.instance.database;

  // ---------------- TASKS ----------------

  Future<List<StudyTask>> getTasks() async {
    final rows = await (await _db)
        .query('study_tasks', orderBy: 'createdAt DESC');

    return rows.map(StudyTask.fromMap).toList();
  }

  Future<int> insertTask(StudyTask task) async => (await _db).insert(
        'study_tasks',
        task.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<int> updateTask(StudyTask task) async {
    if (task.id == null) {
      throw ArgumentError('Cannot update a task without an ID.');
    }

    return (await _db).update(
      'study_tasks',
      task.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(int id) async {
    final db = await _db;

    await db.transaction((txn) async {
      await txn.update(
        'study_sessions',
        {'taskId': null},
        where: 'taskId = ?',
        whereArgs: [id],
      );

      await txn.delete(
        'study_tasks',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // ---------------- STUDY SESSIONS ----------------

  Future<List<StudySession>> getSessions() async {
    final rows = await (await _db)
        .query('study_sessions', orderBy: 'startedAt DESC');

    return rows.map(StudySession.fromMap).toList();
  }

  Future<int> insertSession(StudySession session) async => (await _db).insert(
        'study_sessions',
        session.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

  // ---------------- STICKY NOTES ----------------

  Future<List<StickyNote>> getNotes() async {
    final rows = await (await _db).query(
      'sticky_notes',
      orderBy: 'isPinned DESC, updatedAt DESC',
    );

    return rows.map(StickyNote.fromMap).toList();
  }

  Future<int> insertNote(StickyNote note) async {
    return (await _db).insert(
      'sticky_notes',
      note.toMap()..remove('id'),
    );
  }

  Future<int> updateNote(StickyNote note) async {
    if (note.id == null) {
      throw ArgumentError('Cannot update a note without an ID.');
    }

    return (await _db).update(
      'sticky_notes',
      note.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<void> deleteNote(int id) async {
    await (await _db).delete(
      'sticky_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- STUDY REMINDERS ----------------

  Future<List<StudyReminder>> getReminders() async {
    final rows = await (await _db).query(
      'study_reminders',
      orderBy: 'reminderTime ASC',
    );

    return rows.map(StudyReminder.fromMap).toList();
  }

  Future<int> insertReminder(StudyReminder reminder) async {
    return (await _db).insert(
      'study_reminders',
      reminder.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> updateReminder(StudyReminder reminder) async {
    if (reminder.id == null) {
      throw ArgumentError('Cannot update a reminder without an ID.');
    }

    return (await _db).update(
      'study_reminders',
      reminder.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<void> deleteReminder(int id) async {
    await (await _db).delete(
      'study_reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteRemindersForTask(int taskId) async {
    await (await _db).delete(
      'study_reminders',
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
  }
}
