import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../services/health_service.dart';
import '../services/mongodb_service.dart';
import '../services/ai_service.dart';

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});
  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _heightFeetCtrl = TextEditingController();
  final _heightInchesCtrl = TextEditingController();

  String _weightUnit = 'kg';
  String _heightUnit = 'cm';

  double? _bmi;
  double? _lastWeight;
  double? _lastHeight;
  String? _category;
  String? _insight;
  Color _categoryColor = AppColors.neonPurple;

  String? _dietPlan;
  bool _isLoadingDiet = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _heightFeetCtrl.dispose();
    _heightInchesCtrl.dispose();
    super.dispose();
  }

  double? _parseWeightKg() {
    final w = double.tryParse(_weightCtrl.text.trim());
    if (w == null) return null;
    if (_weightUnit == 'kg') return w;
    if (_weightUnit == 'grams') return w / 1000;
    if (_weightUnit == 'pounds') return w * 0.453592;
    return null;
  }

  double? _parseHeightMeters() {
    if (_heightUnit == 'feet + inches') {
      final f = double.tryParse(_heightFeetCtrl.text.trim()) ?? 0;
      final i = double.tryParse(_heightInchesCtrl.text.trim()) ?? 0;
      if (f <= 0 && i <= 0) return null;
      return (f * 12 + i) * 0.0254;
    }
    final h = double.tryParse(_heightCtrl.text.trim());
    if (h == null || h <= 0) return null;
    if (_heightUnit == 'cm') return h / 100;
    if (_heightUnit == 'meters') return h;
    return null;
  }

  void _calculate() {
    final weightKg = _parseWeightKg();
    final heightMeters = _parseHeightMeters();
    if (weightKg == null || heightMeters == null || heightMeters <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid weight and height'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final bmi = weightKg / (heightMeters * heightMeters);
    setState(() {
      _bmi = bmi;
      _lastWeight = weightKg;
      _lastHeight = heightMeters;
      _dietPlan = null;
      if (bmi < 18.5) {
        _category = 'Underweight';
        _categoryColor = AppColors.neonPurple;
        _insight =
            'You are underweight. Consider increasing calorie intake with balanced nutrition and protein-rich foods.';
      } else if (bmi < 25.0) {
        _category = 'Normal';
        _categoryColor = AppColors.neonGreen;
        _insight =
            'Great job! You have a healthy body weight. Keep maintaining your balanced diet and regular exercise.';
      } else if (bmi < 30.0) {
        _category = 'Overweight';
        _categoryColor = AppColors.neonOrange;
        _insight =
            'You are slightly overweight. A balanced diet with reduced sugar and regular cardio can help you reach a healthier weight.';
      } else {
        _category = 'Obese';
        _categoryColor = AppColors.error;
        _insight =
            'Your BMI indicates obesity. Consider consulting a healthcare provider for a personalized plan to improve your health.';
      }
    });

    // Save to backend history
    MongoDbService.saveBmi(
      weightKg,
      heightMeters,
      bmi,
    ).catchError((_) => <String, dynamic>{});
  }

  Future<void> _getDietPlan() async {
    if (_bmi == null || _category == null) return;
    setState(() => _isLoadingDiet = true);
    try {
      final health = ref.read(healthControllerProvider);
      String goal = 'maintain';
      if (_bmi! < 18.5) goal = 'weight gain';
      else if (_bmi! > 25.0) goal = 'fat loss';

      final dietJsonStr = await AIService.generateDiet(
        name: 'User',
        steps: health.steps,
        activeMinutes: health.activeMinutes,
        calories: health.calories,
        goal: goal,
        bmi: _bmi!,
      );

      final dietMap = jsonDecode(dietJsonStr) as Map<String, dynamic>;

      // Format the Map into a readable string for this screen
      String planText = '';
      dietMap.forEach((key, value) {
        if (value is List) {
          planText += '${key.toUpperCase()}:\n- ${value.join('\n- ')}\n\n';
        }
      });

      setState(() {
        _dietPlan = planText.trim();
        _isLoadingDiet = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDiet = false;
        _dietPlan = 'Failed to generate personalized diet plan. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health & BMI')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BMI Calculator',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Calculate your Body Mass Index',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSizes.xl),

              // ─── Input Card ───
              Container(
                padding: EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weight row
                    Text(
                      'Weight',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall!.color!,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _weightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  _weightUnit == 'grams'
                                      ? 'e.g. 70000'
                                      : _weightUnit == 'pounds'
                                      ? 'e.g. 154'
                                      : 'e.g. 70',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            style: TextStyle(fontSize: 15, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Flexible(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _weightUnit,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                            ),
                            dropdownColor:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                            style: TextStyle(fontSize: 12, color: Colors.white),
                            items:
                                ['kg', 'grams', 'pounds']
                                    .map(
                                      (u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(
                                          u,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setState(() => _weightUnit = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Height row
                    Text(
                      'Height',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall!.color!,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (_heightUnit == 'feet + inches') ...[
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _heightFeetCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                hintText: 'Feet',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.xs),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _heightInchesCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                hintText: 'Inches',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ] else
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _heightCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                hintText:
                                    _heightUnit == 'meters'
                                        ? 'e.g. 1.75'
                                        : 'e.g. 175',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        const SizedBox(width: AppSizes.sm),
                        Flexible(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _heightUnit,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 12,
                              ),
                            ),
                            dropdownColor:
                                Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                            style: TextStyle(fontSize: 12, color: Colors.white),
                            items:
                                ['cm', 'meters', 'feet + inches']
                                    .map(
                                      (u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(
                                          u,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setState(() => _heightUnit = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.lg),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _calculate,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.neonCyan,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppSizes.buttonRadius,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Calculate BMI',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ─── BMI Result ───
              if (_bmi != null) ...[
                const SizedBox(height: AppSizes.lg),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: _categoryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                    border: Border.all(
                      color: _categoryColor.withValues(alpha: 0.25),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _categoryColor.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                  ],
                ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'BMI: ${_bmi!.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: _categoryColor,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _categoryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _category!,
                              style: TextStyle(
                                color: _categoryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      // BMI Scale visual
                      _BmiScale(bmi: _bmi!),
                      const SizedBox(height: AppSizes.md),
                      Text(
                        _insight ?? '',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      if (_dietPlan != null) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(AppSizes.md),
                          decoration: BoxDecoration(
                            color: AppColors.neonGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.neonGreen.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.restaurant_menu_rounded,
                                        color: AppColors.neonGreen,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'AI Diet Plan',
                                        style: TextStyle(
                                          color: AppColors.neonGreen,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: AppColors.neonGreen,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.sm),
                              Text(
                                _dietPlan!,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        TextButton.icon(
                          onPressed: _isLoadingDiet ? null : _getDietPlan,
                          icon: _isLoadingDiet
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.neonCyan,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 16),
                          label: Text(_isLoadingDiet ? 'Regenerating...' : 'Get New Plan'),
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).textTheme.bodySmall!.color!,
                          ),
                        ),
                      ] else
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoadingDiet ? null : _getDietPlan,
                            icon:
                                _isLoadingDiet
                                    ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.neonCyan,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 16,
                                    ),
                            label: Text(
                              _isLoadingDiet
                                  ? 'Generating...'
                                  : 'Get AI Diet Plan',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.neonCyan,
                              side: BorderSide(
                                color: AppColors.neonCyan.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSizes.buttonRadius,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              // ─── BMI Reference Chart ───
              const SizedBox(height: AppSizes.xl),
              Text(
                'BMI Reference',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSizes.sm),
              _buildReferenceRow(
                context,
                'Underweight',
                '< 18.5',
                AppColors.neonPurple,
              ),
              _buildReferenceRow(
                context,
                'Normal',
                '18.5 – 24.9',
                AppColors.neonGreen,
              ),
              _buildReferenceRow(
                context,
                'Overweight',
                '25.0 – 29.9',
                AppColors.neonOrange,
              ),
              _buildReferenceRow(context, 'Obese', '≥ 30.0', AppColors.error),
              const SizedBox(height: AppSizes.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceRow(
    BuildContext context,
    String label,
    String range,
    Color color,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.xs),
      padding: EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Text(
            range,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _BmiScale extends StatelessWidget {
  final double bmi;
  const _BmiScale({required this.bmi});

  @override
  Widget build(BuildContext context) {
    // clamp position: 10 to 45 BMI range
    final clamped = bmi.clamp(10.0, 45.0);
    final position = (clamped - 10) / 35; // 0.0 to 1.0

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Color gradient bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF9C27B0), // underweight - purple
                          Color(0xFF00E676), // normal - green
                          Color(0xFFFF9800), // overweight - orange
                          Color(0xFFF44336), // obese - red
                        ],
                        stops: [0.0, 0.24, 0.43, 1.0],
                      ),
                    ),
                  ),
                ),
                // Indicator
                Positioned(
                  left: (constraints.maxWidth * position).clamp(
                    0,
                    constraints.maxWidth - 12,
                  ),
                  top: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '10',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall!.color!,
                fontSize: 10,
              ),
            ),
            Text(
              '18.5',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall!.color!,
                fontSize: 10,
              ),
            ),
            Text(
              '25',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall!.color!,
                fontSize: 10,
              ),
            ),
            Text(
              '30',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall!.color!,
                fontSize: 10,
              ),
            ),
            Text(
              '45+',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall!.color!,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
