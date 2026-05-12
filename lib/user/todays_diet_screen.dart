import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../services/mongodb_service.dart';
import '../services/health_service.dart';
import '../services/ai_service.dart';

class TodaysDietScreen extends ConsumerStatefulWidget {
  const TodaysDietScreen({super.key});

  @override
  ConsumerState<TodaysDietScreen> createState() => _TodaysDietScreenState();
}

class _TodaysDietScreenState extends ConsumerState<TodaysDietScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _dietPlan = {};
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
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
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load diet: $e'), backgroundColor: AppColors.error),
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
    if (bmi < 18.5) goal = 'weight gain';
    else if (bmi > 25.0) goal = 'fat loss';

    // Use AIService for direct Gemini generation with variety seeds
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
      appBar: AppBar(
        title: const Text("Today's AI Diet"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _fetchInitialData,
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.neonCyan))
          : _dietPlan.isEmpty 
            ? _buildEmptyState()
            : _buildDietUI(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.neonGreen.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.1)),
            ),
            child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.neonGreen, size: 64),
          ),
          const SizedBox(height: 24),
          const Text('No protocol generated.', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Let AI create your personalized nutrition plan.', style: TextStyle(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _fetchInitialData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('GENERATE DIET PLAN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildDietUI() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Illustration
          Center(
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.neonGreen.withValues(alpha: 0.2), blurRadius: 40)],
              ),
              child: const Icon(Icons.lunch_dining_rounded, color: AppColors.neonGreen, size: 80),
            ),
          ),
          const SizedBox(height: 30),
          
          _buildSummaryCard(),
          const SizedBox(height: 30),
          
          const Text('AI NUTRITION PROTOCOL', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 16),
          
          _buildMealSection('Breakfast 🍳', List<String>.from(_dietPlan['breakfast'] ?? []), AppColors.neonCyan),
          _buildMealSection('Lunch 🍛', List<String>.from(_dietPlan['lunch'] ?? []), AppColors.neonGreen),
          _buildMealSection('Dinner 🍽️', List<String>.from(_dietPlan['dinner'] ?? []), AppColors.neonPurple),
          _buildMealSection('Snacks 🍎', List<String>.from(_dietPlan['snacks'] ?? []), AppColors.neonOrange),
          
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                try {
                  final newPlan = await _generateDietPlan(force: true);
                  if (mounted) {
                    setState(() {
                      _dietPlan = newPlan;
                      _isLoading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✨ AI Plan Regenerated!'), backgroundColor: AppColors.neonCyan),
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
              },
              icon: const Icon(Icons.auto_fix_high_rounded, color: Colors.black),
              label: const Text('REGENERATE PROTOCOL', style: TextStyle(fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final aiTarget = _dietPlan['summary'] ?? {};
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: AppColors.neonGreen.withValues(alpha: 0.02), blurRadius: 30)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.neonGreen, size: 22),
              const SizedBox(width: 12),
              const Text('NUTRITION SUMMARY', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            ],
          ),
          const SizedBox(height: 24),
          _row('Total Calories', '${(_summary['totalCalories'] ?? 0).toString()} kcal', AppColors.neonGreen),
          _row('Protein Intake', '${(_summary['totalProtein'] ?? 0).toString()} g', AppColors.neonPink),
          _row('Carbs Intake', '${(_summary['totalCarbs'] ?? 0).toString()} g', AppColors.neonOrange),
          _row('Fat Intake', '${(_summary['totalFat'] ?? 0).toString()} g', AppColors.neonYellow),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10),
          ),
          const Text('AI TARGET RECOMMENDATION', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _miniStat('Target Cal', '${(aiTarget['calories'] ?? 2100)}', 'kcal')),
              Expanded(child: _miniStat('Target Protein', '${(aiTarget['protein'] ?? 140)}', 'g')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(width: 4),
            Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  Widget _buildMealSection(String title, List<String> options, Color color) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          ...options.map((option) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 18, color: color.withValues(alpha: 0.5)),
                const SizedBox(width: 14),
                Expanded(child: Text(option, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color.withValues(alpha: 0.5), shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
        ],
      ),
    );
  }
}
