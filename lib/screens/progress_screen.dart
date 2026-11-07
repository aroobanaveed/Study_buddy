
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/study_provider.dart';
import '../services/statistics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyProvider>();
    final tasks = provider.tasks;
    final sessions = provider.sessions;

    final completed = tasks.where((t) => t.isCompleted).length;
    final totalSeconds = StatisticsService.totalSeconds(sessions);
    final todaySeconds = StatisticsService.todaySeconds(sessions);
    final weekSeconds =
        StatisticsService.weeklySeconds(sessions, DateTime.now());

    final bySubject = StatisticsService
        .secondsBySubject(tasks, sessions)
        .entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final now = DateTime.now();

    final weekBars = List.generate(7, (i) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1 - i));

      final seconds = sessions
          .where(
            (s) =>
                s.sessionStatus == 'completed' &&
                s.startedAt.year == day.year &&
                s.startedAt.month == day.month &&
                s.startedAt.day == day.day,
          )
          .fold<int>(0, (sum, s) => sum + s.durationSeconds);

      return _DayBar(day: day, seconds: seconds);
    });

    final activeDays = weekBars.where((d) => d.seconds >= 60).length;

    // Rewards are calculated from saved data, not added on every refresh.
    final completedFocusSeconds = sessions
        .where((s) => s.sessionStatus == 'completed')
        .fold<int>(0, (sum, s) => sum + s.durationSeconds);

    final focusXp = completedFocusSeconds ~/ 60;
    final taskXp = completed * 20;
    final totalXp = focusXp + taskXp;

    final garden = _GardenStage.fromXp(totalXp);

    final achievements = <_Achievement>[
      _Achievement(
        title: 'First Steps',
        description: 'Complete your first study task.',
        icon: Icons.flag_rounded,
        unlocked: completed >= 1,
        progress: math.min(completed, 1),
        target: 1,
      ),
      _Achievement(
        title: 'Getting Started',
        description: 'Finish 5 study tasks.',
        icon: Icons.check_circle_rounded,
        unlocked: completed >= 5,
        progress: math.min(completed, 5),
        target: 5,
      ),
      _Achievement(
        title: 'Focus Explorer',
        description: 'Complete 60 minutes of focus sessions.',
        icon: Icons.timer_rounded,
        unlocked: completedFocusSeconds >= 3600,
        progress: math.min(completedFocusSeconds, 3600),
        target: 3600,
      ),
      _Achievement(
        title: 'Dedicated Learner',
        description: 'Complete 5 hours of focus sessions.',
        icon: Icons.auto_awesome_rounded,
        unlocked: completedFocusSeconds >= 18000,
        progress: math.min(completedFocusSeconds, 18000),
        target: 18000,
      ),
      _Achievement(
        title: 'A Growing Garden',
        description: 'Earn 300 XP.',
        icon: Icons.local_florist_rounded,
        unlocked: totalXp >= 300,
        progress: math.min(totalXp, 300),
        target: 300,
      ),
      _Achievement(
        title: 'Consistency Club',
        description: 'Study on 5 days this week.',
        icon: Icons.calendar_month_rounded,
        unlocked: activeDays >= 5,
        progress: math.min(activeDays, 5),
        target: 5,
      ),
    ];

    final unlockedCount =
        achievements.where((a) => a.unlocked).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My progress'),
        actions: [
          IconButton(
            tooltip: 'Refresh stats',
            onPressed: provider.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                const Text(
                  'Progress, not perfection. Look at you showing up! 🌱',
                  style: TextStyle(
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),

                // STUDY GARDEN
                _StudyGardenCard(
                  xp: totalXp,
                  focusXp: focusXp,
                  taskXp: taskXp,
                  stage: garden,
                ),

                const SizedBox(height: 24),

                // ACHIEVEMENTS
                Row(
                  children: [
                    const Expanded(
                      child: SectionHeading('Little victories'),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.butterYellow.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$unlockedCount/${achievements.length} unlocked',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ...achievements.map(
                  (achievement) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AchievementCard(
                      achievement: achievement,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // EXISTING STATISTICS
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 11,
                  mainAxisSpacing: 11,
                  childAspectRatio: 1.22,
                  children: [
                    StatCard(
                      icon: Icons.timer_rounded,
                      value: _duration(totalSeconds),
                      label: 'Total focus time',
                      color: AppColors.sageLight,
                    ),
                    StatCard(
                      icon: Icons.today_rounded,
                      value: _duration(todaySeconds),
                      label: 'Today',
                      color: AppColors.butterYellow,
                    ),
                    StatCard(
                      icon: Icons.check_circle_rounded,
                      value: '$completed',
                      label: 'Tasks completed',
                      color: AppColors.sageLight,
                    ),
                    StatCard(
                      icon: Icons.calendar_view_week_rounded,
                      value: '$activeDays/7',
                      label: 'Active days this week',
                      color: AppColors.butterYellow,
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const SectionHeading('Your week'),
                const SizedBox(height: 10),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 18, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_duration(weekSeconds)} focused this week',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Every focused minute counts.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 175,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: math.max(
                                1.0,
                                weekBars
                                        .map((d) => d.seconds / 3600)
                                        .fold<double>(
                                          0,
                                          (a, b) => math.max(a, b),
                                        ) *
                                    1.25,
                              ).toDouble(),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (_) =>
                                    const FlLine(
                                  color: AppColors.border,
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                  ),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: false,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    getTitlesWidget: (v, _) => Text(
                                      '${v.toInt()}h',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) {
                                      final i = v.toInt();

                                      if (i < 0 ||
                                          i >= weekBars.length) {
                                        return const SizedBox.shrink();
                                      }

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8),
                                        child: Text(
                                          DateFormat('E')
                                              .format(weekBars[i].day),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              barGroups: List.generate(
                                weekBars.length,
                                (i) => BarChartGroupData(
                                  x: i,
                                  barRods: [
                                    BarChartRodData(
                                      toY: weekBars[i].seconds / 3600,
                                      width: 17,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      color: AppColors.sage,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 22),
                const SectionHeading('Where your time goes'),
                const SizedBox(height: 10),

                if (bySubject.isEmpty)
                  const EmptyState(
                    icon: Icons.insights_rounded,
                    title: 'Your progress will appear here',
                    subtitle:
                        'Finish a focus session to see your study time by subject.',
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          for (final entry in bySubject.take(6))
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 14),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _duration(entry.value),
                                        style: const TextStyle(
                                          color: AppColors.muted,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    child: LinearProgressIndicator(
                                      value: bySubject.first.value > 0
                                          ? entry.value /
                                              bySubject.first.value
                                          : 0,
                                      minHeight: 8,
                                      backgroundColor:
                                          AppColors.sageLight,
                                      color: AppColors.sage,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.sageLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.eco_rounded,
                        color: AppColors.green,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'A streak is nice, but taking a break when you need one is okay too. Keep learning at your own pace.',
                          style: TextStyle(
                            height: 1.45,
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  static String _duration(int seconds) {
    final mins = seconds ~/ 60;

    if (mins < 60) return '${mins}m';

    final hours = mins ~/ 60;
    final rem = mins % 60;

    return rem == 0 ? '${hours}h' : '${hours}h ${rem}m';
  }
}

// GARDEN GROWTH STAGES

class _GardenStage {
  const _GardenStage({
    required this.name,
    required this.message,
    required this.icon,
    required this.nextXp,
    required this.currentStageXp,
    required this.level,
  });

  final String name;
  final String message;
  final IconData icon;
  final int nextXp;
  final int currentStageXp;
  final int level;

  static _GardenStage fromXp(int xp) {
    if (xp < 100) {
      return const _GardenStage(
        name: 'Tiny Seed',
        message: 'Every little study session helps you grow.',
        icon: Icons.spa_rounded,
        nextXp: 100,
        currentStageXp: 0,
        level: 1,
      );
    }

    if (xp < 300) {
      return const _GardenStage(
        name: 'Little Sprout',
        message: 'Your learning journey is taking root!',
        icon: Icons.grass_rounded,
        nextXp: 300,
        currentStageXp: 100,
        level: 2,
      );
    }

    if (xp < 600) {
      return const _GardenStage(
        name: 'Growing Plant',
        message: 'Look at the progress you are making.',
        icon: Icons.local_florist_rounded,
        nextXp: 600,
        currentStageXp: 300,
        level: 3,
      );
    }

    if (xp < 1000) {
      return const _GardenStage(
        name: 'Blooming Garden',
        message: 'Your consistency is helping your garden bloom.',
        icon: Icons.park_rounded,
        nextXp: 1000,
        currentStageXp: 600,
        level: 4,
      );
    }

    return const _GardenStage(
      name: 'Study Forest',
      message: 'A forest of knowledge, grown one session at a time.',
      icon: Icons.nature_rounded,
      nextXp: 1000,
      currentStageXp: 1000,
      level: 5,
    );
  }
}

class _StudyGardenCard extends StatelessWidget {
  const _StudyGardenCard({
    required this.xp,
    required this.focusXp,
    required this.taskXp,
    required this.stage,
  });

  final int xp;
  final int focusXp;
  final int taskXp;
  final _GardenStage stage;

  @override
  Widget build(BuildContext context) {
    final progress = stage.level == 5
        ? 1.0
        : ((xp - stage.currentStageXp) /
                (stage.nextXp - stage.currentStageXp))
            .clamp(0.0, 1.0)
            .toDouble();

    final remainingXp = math.max(0, stage.nextXp - xp);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sageLight,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.sage.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'MY STUDY GARDEN',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 17,
                      color: AppColors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$xp XP',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.ivory,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: AppColors.butterYellow.withOpacity(0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    stage.icon,
                    size: 70,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  stage.name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    stage.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.4,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.butterYellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'GARDEN LEVEL ${stage.level}',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Next growth stage',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                stage.level == 5 ? 'Fully grown!' : '$remainingXp XP to go',
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.card,
              color: AppColors.green,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _XpBreakdown(
                  icon: Icons.timer_rounded,
                  label: 'Focus XP',
                  value: '$focusXp',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _XpBreakdown(
                  icon: Icons.check_circle_rounded,
                  label: 'Task XP',
                  value: '$taskXp',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _XpBreakdown extends StatelessWidget {
  const _XpBreakdown({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 21, color: AppColors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ACHIEVEMENTS

class _Achievement {
  const _Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.unlocked,
    required this.progress,
    required this.target,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
  final int progress;
  final int target;
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
  });

  final _Achievement achievement;

  String get _progressLabel {
    if (achievement.title == 'Focus Explorer' ||
        achievement.title == 'Dedicated Learner') {
      return '${achievement.progress ~/ 60}/${achievement.target ~/ 60} min';
    }

    if (achievement.title == 'Consistency Club') {
      return '${achievement.progress}/${achievement.target} days';
    }

    return '${achievement.progress}/${achievement.target}';
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.card : AppColors.inputBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: unlocked
              ? AppColors.sage.withOpacity(0.7)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppColors.butterYellow.withOpacity(0.65)
                  : AppColors.border,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              unlocked ? achievement.icon : Icons.lock_outline_rounded,
              color: unlocked ? AppColors.green : AppColors.muted,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.muted,
                    height: 1.35,
                  ),
                ),
                if (!unlocked) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: achievement.target > 0
                          ? (achievement.progress / achievement.target)
                              .clamp(0.0, 1.0)
                              .toDouble()
                          : 0,
                      minHeight: 5,
                      backgroundColor: AppColors.border,
                      color: AppColors.sage,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                unlocked
                    ? Icons.check_circle_rounded
                    : Icons.lock_rounded,
                color: unlocked ? AppColors.green : AppColors.muted,
                size: 18,
              ),
              const SizedBox(height: 5),
              Text(
                unlocked ? 'Unlocked' : _progressLabel,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: unlocked ? AppColors.green : AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayBar {
  const _DayBar({
    required this.day,
    required this.seconds,
  });

  final DateTime day;
  final int seconds;
}
