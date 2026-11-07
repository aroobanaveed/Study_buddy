
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/study_task.dart';
import '../providers/study_provider.dart';
import '../theme/app_theme.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key, this.task});

  final StudyTask? task;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with WidgetsBindingObserver {
  int _selectedMinutes = 25;
  int _remainingSeconds = 25 * 60;

  Timer? _ticker;
  DateTime? _startedAt;
  DateTime? _targetEnd;

  int _focusedSeconds = 0;
  DateTime? _activeSegmentStartedAt;

  bool _running = false;
  bool _saving = false;
  bool _finished = false;
  bool _showRescue = false;

  String? _rescueChoice;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _selectedMinutes =
        _nearestPreset(widget.task?.estimatedMinutes ?? 25);

    _remainingSeconds = _selectedMinutes * 60;
  }

  int _nearestPreset(int requested) {
    const presets = [15, 25, 45, 60];

    return presets.reduce(
      (a, b) => (a - requested).abs() <= (b - requested).abs()
          ? a
          : b,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  // Synchronize timer when app returns to foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _running) {
      _syncRemaining();
    }
  }

  void _syncRemaining() {
    if (_targetEnd == null || !_running || !mounted) return;

    final next = _targetEnd!.difference(DateTime.now()).inSeconds;

    if (next <= 0) {
      setState(() {
        _remainingSeconds = 0;
        _running = false;
      });

      _ticker?.cancel();
      _finishSession(auto: true);
    } else {
      setState(() => _remainingSeconds = next);
    }
  }

  void _start() {
    if (_finished || _saving || _remainingSeconds <= 0) return;

    final now = DateTime.now();

    _startedAt ??= now;
    _activeSegmentStartedAt = now;
    _targetEnd = now.add(Duration(seconds: _remainingSeconds));

    setState(() => _running = true);

    _ticker?.cancel();

    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted || !_running || _targetEnd == null) return;

        final next =
            _targetEnd!.difference(DateTime.now()).inSeconds;

        if (next <= 0) {
          setState(() {
            _remainingSeconds = 0;
            _running = false;
          });

          _ticker?.cancel();
          _finishSession(auto: true);
        } else {
          setState(() => _remainingSeconds = next);
        }
      },
    );
  }

  void _pause() {
    if (!_running || _targetEnd == null) return;

    final next = _targetEnd!
        .difference(DateTime.now())
        .inSeconds
        .clamp(0, _selectedMinutes * 60)
        .toInt();

    _ticker?.cancel();

    if (_activeSegmentStartedAt != null) {
      _focusedSeconds += DateTime.now()
          .difference(_activeSegmentStartedAt!)
          .inSeconds
          .clamp(0, _selectedMinutes * 60)
          .toInt();

      _activeSegmentStartedAt = null;
    }

    setState(() {
      _remainingSeconds = next;
      _running = false;
      _targetEnd = null;
    });
  }

  Future<void> _endEarly() async {
    if (_startedAt == null || _finished || _saving) {
      setState(() {
        _running = false;
        _ticker?.cancel();
        _remainingSeconds = _selectedMinutes * 60;
        _startedAt = null;
        _targetEnd = null;
        _focusedSeconds = 0;
        _activeSegmentStartedAt = null;
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End this session?'),
        content: const Text(
          'You can save the time you focused so far, '
          'or keep studying.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep studying'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End session'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _finishSession(auto: false);
  }

  Future<void> _finishSession({required bool auto}) async {
    if (_finished || _saving || _startedAt == null) {
      return;
    }

    _ticker?.cancel();

    final started = _startedAt!;
    final ended = DateTime.now();

    final currentSegment = _activeSegmentStartedAt == null
        ? 0
        : ended
            .difference(_activeSegmentStartedAt!)
            .inSeconds
            .clamp(0, _selectedMinutes * 60)
            .toInt();

    final elapsed = (_focusedSeconds + currentSegment)
        .clamp(0, _selectedMinutes * 60)
        .toInt();

    _activeSegmentStartedAt = null;

    if (elapsed < 10) {
      setState(() {
        _running = false;
        _finished = true;
        _remainingSeconds = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Session was too short to record. '
            'Try another focus sprint!',
          ),
        ),
      );

      return;
    }

    setState(() {
      _running = false;
      _saving = true;
    });

    // Prevent accidental dismissal using Android Back button.
    final confidence = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(
            auto
                ? 'Focus session complete! 🎉'
                : 'Nice effort! 🌱',
          ),
          content: const Text(
            'How confident do you feel about this topic now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 1),
              child: const Text('😕 Still confused'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 2),
              child: const Text('😐 Getting there'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, 3),
              child: const Text('😊 I get it'),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (confidence == null) {
      setState(() {
        _saving = false;
        _running = false;
        _finished = true;
        _remainingSeconds = 0;
      });
      return;
    }

    try {
      await context.read<StudyProvider>().recordSession(
            taskId: widget.task?.id,
            startedAt: started,
            endedAt: ended,
            durationSeconds: elapsed,
            status: 'completed',
            confidenceAfter: confidence,
          );

      if (!mounted) return;

      setState(() {
        _saving = false;
        _finished = true;
        _remainingSeconds = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved ${elapsed ~/ 60}m ${elapsed % 60}s '
            'of focus time. Great job!',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _running = false;
          _finished = true;
          _remainingSeconds = 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save session: $e'),
          ),
        );
      }
    }
  }

  void _reset() {
    _ticker?.cancel();

    setState(() {
      _selectedMinutes = 25;
      _remainingSeconds = 25 * 60;

      _startedAt = null;
      _targetEnd = null;

      _focusedSeconds = 0;
      _activeSegmentStartedAt = null;

      _running = false;
      _saving = false;
      _finished = false;

      _showRescue = false;
      _rescueChoice = null;
    });
  }

  String get _timeLabel {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;

    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final total = _selectedMinutes * 60;

    final progress = total == 0
        ? 0.0
        : (1 - _remainingSeconds / total)
            .clamp(0.0, 1.0)
            .toDouble();

    final task = widget.task;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus zone'),
        actions: [
          IconButton(
            tooltip: 'Reset timer',
            onPressed: _running || _saving ? null : _reset,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.sageLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.ivory,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task?.subject ?? 'Free study session',
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        task?.title ?? 'Focus on anything you need',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Center(
            child: Text(
              _finished
                  ? 'You did it! ✨'
                  : _running
                      ? 'You’re in the zone'
                      : 'One thing at a time',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),

          const SizedBox(height: 25),

          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 13,
                      strokeCap: StrokeCap.round,
                      backgroundColor:
                          AppColors.butterYellow.withOpacity(0.65),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.sage,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _timeLabel,
                        style: const TextStyle(
                          fontSize: 49,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _finished
                            ? 'SESSION SAVED'
                            : _running
                                ? 'FOCUS TIME'
                                : 'MINUTES TO YOURSELF',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          const Center(
            child: Text(
              'Choose your focus sprint',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),

          const SizedBox(height: 11),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final minutes in [15, 25, 45, 60])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('$minutes min'),
                    selected: _selectedMinutes == minutes,
                    onSelected:
                        (!_running && !_finished && !_saving)
                            ? (_) {
                                setState(() {
                                  _selectedMinutes = minutes;
                                  _remainingSeconds = minutes * 60;
                                });
                              }
                            : null,
                    selectedColor: AppColors.butterYellow,
                    backgroundColor: AppColors.card,
                    labelStyle: TextStyle(
                      color: AppColors.ink,
                      fontWeight: _selectedMinutes == minutes
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: _selectedMinutes == minutes
                          ? AppColors.butterYellow
                          : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    showCheckmark: false,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 22),

          if (!_finished)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving
                        ? null
                        : (_running ? _pause : _start),
                    icon: Icon(
                      _running
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(
                      _saving
                          ? 'Saving…'
                          : _running
                              ? 'Pause'
                              : _startedAt == null
                                  ? 'Start focus'
                                  : 'Resume focus',
                    ),
                  ),
                ),
                if (_startedAt != null) ...[
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _saving ? null : _endEarly,
                    child: const Text('End'),
                  ),
                ],
              ],
            )
          else
            FilledButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Start another session'),
            ),

          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.favorite_border_rounded,
                        color: AppColors.green,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Need a tiny reset?',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'Getting stuck is part of learning. Pick what is '
                    'making this hard and take one small step.',
                    style: TextStyle(
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _showRescue = !_showRescue);
                      },
                      icon: Icon(
                        _showRescue
                            ? Icons.expand_less
                            : Icons.lightbulb_outline,
                      ),
                      label: Text(
                        _showRescue
                            ? 'Hide suggestions'
                            : 'I’m stuck — help me',
                      ),
                    ),
                  ),

                  if (_showRescue) ...[
                    for (final option in [
                      'I don’t understand the topic',
                      'I keep getting distracted',
                      'This task feels too big',
                    ])
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: AppColors.green,
                        value: option,
                        groupValue: _rescueChoice,
                        onChanged: (value) {
                          setState(() => _rescueChoice = value);
                        },
                        title: Text(
                          option,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),

                    if (_rescueChoice != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.sageLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          _suggestion(_rescueChoice!),
                          style: const TextStyle(
                            height: 1.4,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _suggestion(String choice) {
    if (choice == 'I don’t understand the topic') {
      return 'Try explaining the idea in your own words, then review '
          'one example. You only need to understand the next small piece.';
    }

    if (choice == 'I keep getting distracted') {
      return 'Put your phone on silent, close one distracting app, '
          'and focus for just five minutes. Starting is the win.';
    }

    return 'Shrink the task. Open the material and do one question '
        'or read one page. You can decide the next step after that.';
  }
}
