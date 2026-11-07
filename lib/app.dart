
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'models/study_task.dart';
import 'models/study_reminder.dart';
import 'providers/study_provider.dart';
import 'services/reminder_service.dart';
import 'services/notification_helper.dart';

import 'screens/focus_screen.dart';
import 'screens/home_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/tasks_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/sticky_notes_section.dart';

class StudyBuddyApp extends StatelessWidget {
  const StudyBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;
  StudyTask? _selectedTask;
  int _focusInstance = 0;

  final ReminderService _reminderService = ReminderService();
  bool _reminderServiceStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_reminderServiceStarted) {
      _reminderServiceStarted = true;

      final provider = context.read<StudyProvider>();

      _reminderService.start(
        getReminders: () => provider.reminders,
        onReminderDue: _handleReminder,
      );
    }
  }

  Future<void> _handleReminder(StudyReminder reminder) async {
    if (!mounted) return;

    final provider = context.read<StudyProvider>();

    // Mark reminder as sent and cancel its scheduled Android notification.
    if (reminder.id != null) {
      await provider.updateReminder(
        reminder.copyWith(isSent: true),
      );
    }

    if (!mounted) return;

    // Browser notification is only needed on Web.
    if (kIsWeb) {
      await NotificationHelper.playReminderSound();

      await NotificationHelper.show(
        title: 'StudyBuddy Reminder 🌼',
        message: reminder.message,
      );
    }

    if (!mounted) {
      await NotificationHelper.stopReminderSound();
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFAF8EF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Time to Study! 🌿',
            style: TextStyle(
              color: Color(0xFF344438),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            reminder.message,
            style: const TextStyle(
              color: Color(0xFF344438),
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Got it!',
                style: TextStyle(
                  color: Color(0xFF344438),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    await NotificationHelper.stopReminderSound();
  }

  @override
  void dispose() {
    _reminderService.dispose();
    NotificationHelper.stopReminderSound();
    super.dispose();
  }

  void _startFocus(StudyTask? task) {
    setState(() {
      _selectedTask = task;
      _focusInstance++;
      _index = 2;
    });
  }

  void _openStickyNotes() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFAF8EF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF91A88B).withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'My Sticky Notes 🌼',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF344438),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close notes',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: StickyNotesSection(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        onOpenTasks: () => setState(() => _index = 1),
        onStartFocus: _startFocus,
      ),
      TasksScreen(onStartFocus: _startFocus),
      FocusScreen(
        key: ValueKey('focus-$_focusInstance'),
        task: _selectedTask,
      ),
      const ProgressScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: pages,
        ),
      ),
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              heroTag: 'stickyNotesFab',
              onPressed: _openStickyNotes,
              tooltip: 'My Sticky Notes',
              backgroundColor: const Color(0xFF91A88B),
              foregroundColor: const Color(0xFF344438),
              child: const Icon(
                Icons.sticky_note_2_rounded,
                size: 27,
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer_rounded),
            label: 'Focus',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
