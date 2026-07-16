import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../services/mongodb_service.dart';
import '../services/health_service.dart';
import '../services/ai_service.dart';
import '../controllers/auth_controller.dart';
import 'home_screen.dart';
import 'points_screen.dart';

class TodaysDietScreen extends ConsumerStatefulWidget {
  const TodaysDietScreen({super.key});

  @override
  ConsumerState<TodaysDietScreen> createState() => _TodaysDietScreenState();
}

class _TodaysDietScreenState extends ConsumerState<TodaysDietScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  Map<String, dynamic> _dietPlan = {};
  Map<String, dynamic> _summary = {};

  late AnimationController _pulseController;
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  int _selectedMealTab = 0;
  final List<String> _mealTabs = ['Breakfast', 'Lunch', 'Dinner', 'Snacks'];
  final List<IconData> _mealIcons = [
    Icons.wb_sunny_rounded,
    Icons.wb_cloudy_rounded,
    Icons.nights_stay_rounded,
    Icons.apple_rounded,
  ];
  final List<Color> _mealColors = [
    AppColors.neonCyan,
    AppColors.neonGreen,
    AppColors.neonPurple,
    AppColors.neonOrange,
  ];
  final List<String> _mealKeys = ['breakfast', 'lunch', 'dinner', 'snacks'];
  final List<String> _mealEmojis = ['🍳', '🍛', '🍽️', '🍎'];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _ringAnimation = CurvedAnimation(parent: _ringController, curve: Curves.easeOutCubic);

    _fetchInitialData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final summaryRes = await MongoDbService.getTodayNutritionSummary();
      final plan = await _generateDietPlan(force: false);

      if (mounted) {
        setState(() {
          _summary = summaryRes['summary'] ?? {};
          _dietPlan = plan;
          _isLoading = false;
        });
        _ringController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load diet: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _generateDietPlan({bool force = false}) async {
    final history = await MongoDbService.getBmiHistory();
    double bmi = 22.5;

    if (history.isNotEmpty) {
      bmi = (history.first['bmi'] as num?)?.toDouble() ?? 22.5;
    }

    final health = ref.read(healthControllerProvider);
    String goal = 'maintain';
    if (bmi < 18.5) { goal = 'weight gain'; }
    else if (bmi > 25.0) { goal = 'fat loss'; }

    final dietJsonStr = await AIService.generateDiet(
      name: 'User',
      steps: health.steps,
      activeMinutes: health.activeMinutes,
      calories: health.calories,
      goal: goal,
      bmi: bmi,
    );

    return jsonDecode(dietJsonStr) as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _dietPlan.isEmpty
                          ? _buildEmptyState()
                          : _buildDietUI(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.5),
            radius: 1.4,
            colors: [Color(0xFF0A1A0A), Color(0xFF050510)],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nutrition Protocol',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'AI-generated • Today',
                  style: TextStyle(
                    color: AppColors.neonGreen.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isLoading ? null : _regenerate,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withValues(alpha: 0.08 + 0.04 * _pulseController.value),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.neonGreen.withValues(alpha: 0.2 + 0.1 * _pulseController.value),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonGreen.withValues(alpha: 0.08 * _pulseController.value),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.neonGreen,
                          ),
                        )
                      : const Icon(Icons.auto_fix_high_rounded, color: AppColors.neonGreen, size: 16),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonGreen.withValues(alpha: 0.05 + 0.05 * _pulseController.value),
                  border: Border.all(
                    color: AppColors.neonGreen.withValues(alpha: 0.2 + 0.2 * _pulseController.value),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonGreen.withValues(alpha: 0.1 * _pulseController.value),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.neonGreen, size: 36),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Generating your protocol...',
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'AI is personalizing your nutrition plan',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.12)),
              ),
              child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.neonGreen, size: 56),
            ),
            const SizedBox(height: 28),
            const Text(
              'No Protocol Yet',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              'Let AI build your personalized nutrition plan based on your activity and health data.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _fetchInitialData,
                icon: const Icon(Icons.auto_awesome_rounded, color: Colors.black),
                label: const Text(
                  'Generate Protocol',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietUI() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Macro Ring Card
          _buildMacroRingCard(),

          const SizedBox(height: 20),

          // Calorie Progress Bar Card
          _buildCalorieCard(),

          const SizedBox(height: 24),

          // Meal Tab Selector
          _buildMealTabs(),

          const SizedBox(height: 16),

          // Meal Content
          _buildMealContent(),

          const SizedBox(height: 20),

          // Regenerate CTA
          _buildRegenerateCTA(),
        ],
      ),
    );
  }

  Widget _buildMacroRingCard() {
    final aiTarget = _dietPlan['summary'] ?? {};
    final totalCal = (_summary['totalCalories'] ?? 0) as num;
    final targetCal = (aiTarget['calories'] ?? 2100) as num;
    final protein = (_summary['totalProtein'] ?? 0) as num;
    final targetProtein = (aiTarget['protein'] ?? 140) as num;
    final carbs = (_summary['totalCarbs'] ?? 0) as num;
    final fat = (_summary['totalFat'] ?? 0) as num;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonGreen.withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: AppColors.neonGreen, size: 10),
                    const SizedBox(width: 5),
                    const Text(
                      'AI NUTRITION SUMMARY',
                      style: TextStyle(
                        color: AppColors.neonGreen,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              // Central Calorie Ring
              AnimatedBuilder(
                animation: _ringAnimation,
                builder: (context, child) {
                  final progress = targetCal > 0
                      ? (totalCal / targetCal * _ringAnimation.value).clamp(0.0, 1.0)
                      : 0.0;
                  return SizedBox(
                    width: 110,
                    height: 110,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background ring
                        CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                        // Progress ring
                        ShaderMask(
                          shaderCallback: (rect) => const LinearGradient(
                            colors: [AppColors.neonGreen, AppColors.neonCyan],
                          ).createShader(rect),
                          child: CircularProgressIndicator(
                            value: progress.toDouble(),
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              totalCal.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Text(
                              'kcal',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 24),
              // Macro Bars
              Expanded(
                child: Column(
                  children: [
                    _buildMacroRow(
                      'Protein',
                      protein.toDouble(),
                      targetProtein.toDouble(),
                      'g',
                      AppColors.neonPink,
                    ),
                    const SizedBox(height: 14),
                    _buildMacroRow(
                      'Carbs',
                      carbs.toDouble(),
                      (aiTarget['carbs'] as num? ?? 250).toDouble(),
                      'g',
                      AppColors.neonOrange,
                    ),
                    const SizedBox(height: 14),
                    _buildMacroRow(
                      'Fat',
                      fat.toDouble(),
                      (aiTarget['fat'] as num? ?? 70).toDouble(),
                      'g',
                      AppColors.neonYellow,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Target: ${targetCal.toInt()} kcal/day',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.neonGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Target Protein: ${targetProtein.toInt()}g',
                      style: const TextStyle(
                        color: AppColors.neonGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(String label, double value, double target, String unit, Color color) {
    final progress = target > 0 ? (value / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${value.toInt()}/${ target.toInt()}$unit',
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 5),
        AnimatedBuilder(
          animation: _ringAnimation,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress * _ringAnimation.value,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.04),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCalorieCard() {
    final aiTarget = _dietPlan['summary'] ?? {};
    final totalCal = (_summary['totalCalories'] ?? 0) as num;
    final targetCal = (aiTarget['calories'] ?? 2100) as num;
    final remaining = (targetCal - totalCal).clamp(0, targetCal);
    final isOver = totalCal > targetCal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOver
              ? [AppColors.error.withValues(alpha: 0.08), AppColors.error.withValues(alpha: 0.03)]
              : [AppColors.neonGreen.withValues(alpha: 0.07), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOver
              ? AppColors.error.withValues(alpha: 0.2)
              : AppColors.neonGreen.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isOver ? AppColors.error : AppColors.neonGreen).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOver ? Icons.warning_amber_rounded : Icons.local_fire_department_rounded,
              color: isOver ? AppColors.error : AppColors.neonGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOver ? 'OVER TARGET' : 'REMAINING TODAY',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isOver
                      ? '+${(totalCal - targetCal).toInt()} kcal over'
                      : '${remaining.toInt()} kcal left',
                  style: TextStyle(
                    color: isOver ? AppColors.error : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${totalCal.toInt()}',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
              Text(
                'of ${targetCal.toInt()} kcal',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealTabs() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _mealTabs.length,
        separatorBuilder: (_, _x) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final isSelected = _selectedMealTab == i;
          final color = _mealColors[i];
          return GestureDetector(
            onTap: () => setState(() => _selectedMealTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? color.withValues(alpha: 0.35)
                      : Colors.white.withValues(alpha: 0.07),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: 1)]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _mealIcons[i],
                    size: 14,
                    color: isSelected ? color : Colors.white38,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _mealTabs[i],
                    style: TextStyle(
                      color: isSelected ? color : Colors.white38,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMealContent() {
    final mealKey = _mealKeys[_selectedMealTab];
    final color = _mealColors[_selectedMealTab];
    final emoji = _mealEmojis[_selectedMealTab];
    final title = _mealTabs[_selectedMealTab];
    final options = List<String>.from(_dietPlan[mealKey] ?? []);

    if (options.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Center(
          child: Text(
            'No $title items generated',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(mealKey),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.04),
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${options.length} options available',
                      style: TextStyle(
                        color: color.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              return _buildMealItem(option, color, index);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMealItem(String option, Color color, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.025),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              option,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: color.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildRegenerateCTA() {
    return GestureDetector(
      onTap: _isLoading ? null : _regenerate,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.neonGreen.withValues(alpha: 0.15 + 0.05 * _pulseController.value),
                  AppColors.neonCyan.withValues(alpha: 0.08),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.neonGreen.withValues(alpha: 0.25 + 0.1 * _pulseController.value),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.neonGreen.withValues(alpha: 0.08 * _pulseController.value),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_fix_high_rounded,
                  color: AppColors.neonGreen,
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Regenerate Protocol',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _regenerate() async {
    setState(() => _isLoading = true);
    try {
      final newPlan = await _generateDietPlan(force: true);
      ref.invalidate(userActivitiesProvider);
      ref.invalidate(workoutHistoryProvider);
      await ref.read(authControllerProvider.notifier).refreshProfile();
      if (mounted) {
        setState(() {
          _dietPlan = newPlan;
          _isLoading = false;
        });
        _ringController.forward(from: 0);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✨ Protocol Regenerated!'),
            backgroundColor: AppColors.neonCyan,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Regeneration failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
