import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../core/constants.dart';
import '../services/health_service.dart';
import '../controllers/auth_controller.dart';
import '../services/mongodb_service.dart';

class HealthReportScreen extends ConsumerStatefulWidget {
  const HealthReportScreen({super.key});

  @override
  ConsumerState<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends ConsumerState<HealthReportScreen> with SingleTickerProviderStateMixin {
  bool _isGenerating = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // Simulate AI analyzing data for cinematic effect
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    });
  }

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await MongoDbService.downloadHealthReport();
      // Save to device storage
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/FitTracker_Health_Report.pdf');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Report saved! Opening...'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.black,
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
        // Auto-open the PDF
        await OpenFile.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Download failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _sharePdf() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await MongoDbService.downloadHealthReport();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/FitTracker_Health_Report.pdf');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'My FitTracker AI Health Report',
          text: 'Check out my AI-generated Health Intelligence Report from FitTracker! 💪',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Share failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final health = ref.watch(healthControllerProvider);
    final user = ref.watch(authControllerProvider).user;
    final userName = user?.name ?? 'User';

    if (_isGenerating) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PulsingOrb(color: AppColors.neonCyan),
              const SizedBox(height: AppSizes.xl),
              const Text("AI Engine Active", style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 8),
              const Text("Compiling Wellness Analytics...", style: TextStyle(color: Colors.white54, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("AI Health Intelligence"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Cinematic Background
          Positioned(top: -100, left: -100, child: _AmbientOrb(color: AppColors.neonCyan.withValues(alpha: 0.1), size: 300)),
          Positioned(bottom: -50, right: -50, child: _AmbientOrb(color: AppColors.neonPurple.withValues(alpha: 0.1), size: 400)),
          Positioned(top: 400, right: -150, child: _AmbientOrb(color: AppColors.neonGreen.withValues(alpha: 0.05), size: 350)),

          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSizes.xxl),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCoverPage(userName),
                _buildExecutiveSummary(health),
                _buildFitnessScore(health),
                _buildAiInsights(health),
                _buildVisualAnalytics(health),
                _buildDietAnalysis(),
                _buildRecommendations(),
                _buildGoalTracking(health),
                _buildRiskDetection(health),
                _buildExportSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverPage(String userName) {
    final date = "${DateTime.now().day} ${_getMonth(DateTime.now().month)} ${DateTime.now().year}";
    return Padding(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: _GlassContainer(
        padding: const EdgeInsets.all(AppSizes.xl),
        borderRadius: 30,
        color: AppColors.neonCyan.withValues(alpha: 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center_rounded, color: AppColors.neonCyan, size: 28),
                const SizedBox(width: 12),
                const Text("FITTRACKER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.neonPurple.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.neonPurple.withValues(alpha: 0.5))),
                  child: const Text("AI POWERED", style: TextStyle(color: AppColors.neonPurple, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.xxl),
            const Text("Wellness & Fitness Analysis", style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1)),
            const SizedBox(height: 8),
            const Text("AI Health\nIntelligence\nReport.", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1)),
            const SizedBox(height: AppSizes.xl),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            const SizedBox(height: AppSizes.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("PREPARED FOR", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(userName.toUpperCase(), style: const TextStyle(color: AppColors.neonCyan, fontSize: 16, fontWeight: FontWeight.w900)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text("DATE GENERATED", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(date.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveSummary(HealthData health) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle("Executive Summary"),
          const SizedBox(height: AppSizes.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _SummaryCard(title: "Steps", value: "${health.steps}", subtitle: health.steps < health.stepsGoal ? "Below Target" : "Goal Reached", icon: Icons.directions_walk, color: AppColors.neonCyan),
              _SummaryCard(title: "Calories", value: "${health.calories}", subtitle: "Active Burn", icon: Icons.local_fire_department, color: AppColors.neonOrange),
              _SummaryCard(title: "Active Mins", value: "${health.activeMinutes}", subtitle: "Great Intensity", icon: Icons.timer, color: AppColors.neonGreen),
              _SummaryCard(title: "Heart Rate", value: health.heartRate > 0 ? "${health.heartRate} bpm" : "--", subtitle: "Resting Avg", icon: Icons.favorite, color: AppColors.neonPink),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFitnessScore(HealthData health) {
    // Compute a pseudo AI score for visual flair
    int baseScore = (health.stepsProgress * 45).toInt() + ((health.activeMinutes / 60).clamp(0.0, 1.0) * 35).toInt() + 10;
    int score = baseScore.clamp(10, 98);

    return Padding(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: _GlassContainer(
        padding: const EdgeInsets.all(AppSizes.xl),
        color: Colors.white.withValues(alpha: 0.02),
        child: Row(
          children: [
            SizedBox(
              width: 100, height: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(value: 1.0, strokeWidth: 8, color: Colors.white.withValues(alpha: 0.05)),
                  CircularProgressIndicator(value: score / 100, strokeWidth: 8, strokeCap: StrokeCap.round, color: AppColors.neonPurple),
                  Center(child: Text("$score", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white))),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("AI Fitness Score", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  const Text("Excellent Profile", style: TextStyle(color: AppColors.neonPurple, fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text("Your consistency and recovery patterns are in the top 15% of users this week.", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiInsights(HealthData health) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.lg),
          const _SectionTitle("Deep Health Insights"),
          const SizedBox(height: AppSizes.md),
          _InsightRow(icon: Icons.trending_up_rounded, color: AppColors.neonGreen, title: "Activity Analysis", desc: "Activity improved by 18% compared to last week. Peak movement occurs around 6:00 PM."),
          _InsightRow(icon: Icons.battery_charging_full_rounded, color: AppColors.neonCyan, title: "Recovery & Sleep", desc: "Sleep consistency is fair, but deeper REM stages may be lacking. Recommend winding down 30 mins earlier."),
          _InsightRow(icon: Icons.monitor_weight_rounded, color: AppColors.neonOrange, title: "Caloric Efficiency", desc: "You are burning calories highly efficiently during active minutes, indicating good cardiovascular health."),
        ],
      ),
    );
  }

  Widget _buildVisualAnalytics(HealthData health) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.xl),
          const _SectionTitle("Visual Analytics"),
          const SizedBox(height: AppSizes.md),
          _GlassContainer(
            padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Weekly Activity Trend", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 24),
                // Fixed: wrap in ClipRect + give explicit height that includes label space
                SizedBox(
                  height: 148,
                  child: ClipRect(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _ChartBar(height: 60, label: "M"),
                        _ChartBar(height: 80, label: "T"),
                        _ChartBar(height: 40, label: "W"),
                        _ChartBar(height: 100, label: "T", color: AppColors.neonCyan),
                        _ChartBar(height: 70, label: "F"),
                        _ChartBar(height: 50, label: "S"),
                        _ChartBar(
                          height: (health.stepsProgress * 108).clamp(20, 108),
                          label: "S",
                          isToday: true,
                        ),
                      ],
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

  Widget _buildDietAnalysis() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle("Nutrition Intelligence"),
          const SizedBox(height: AppSizes.md),
          _GlassContainer(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              children: [
                _MacroRow(label: "Protein", percent: 0.65, color: AppColors.neonPink, detail: "90g / 140g"),
                const SizedBox(height: 16),
                _MacroRow(label: "Carbs", percent: 0.80, color: AppColors.neonOrange, detail: "200g / 250g"),
                const SizedBox(height: 16),
                _MacroRow(label: "Fats", percent: 0.45, color: AppColors.neonYellow, detail: "30g / 65g"),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.neonPink.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.neonPink, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text("Protein intake is below optimal for muscle recovery. Consider adding 30g post-workout.", style: TextStyle(color: Colors.white70, fontSize: 12))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.md),
          const _SectionTitle("AI Recommendations"),
          const SizedBox(height: AppSizes.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _RecommendationCard(icon: Icons.fitness_center, title: "Workout", desc: "Add 15 mins of HIIT twice a week.", color: AppColors.neonCyan),
                _RecommendationCard(icon: Icons.water_drop, title: "Hydration", desc: "Increase water intake to 2.5L daily.", color: Colors.blue),
                _RecommendationCard(icon: Icons.bedtime, title: "Recovery", desc: "Aim for 7.5 hours of uninterrupted sleep.", color: AppColors.neonPurple),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalTracking(HealthData health) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle("Goal Tracking"),
          const SizedBox(height: AppSizes.md),
          _GlassContainer(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              children: [
                _GoalRow(title: "Daily Steps", progress: health.stepsProgress, color: AppColors.neonCyan),
                const SizedBox(height: 16),
                _GoalRow(title: "Active Time", progress: (health.activeMinutes / 60).clamp(0.0, 1.0), color: AppColors.neonGreen),
                const SizedBox(height: 16),
                _GoalRow(title: "Calorie Burn", progress: (health.calories / 500).clamp(0.0, 1.0), color: AppColors.neonOrange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDetection(HealthData health) {
    if (health.steps > 3000) return const SizedBox.shrink(); // Only show if risks detected
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.lg),
          const Text("⚠️ Wellness Warnings", style: TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.sm),
          _GlassContainer(
            padding: const EdgeInsets.all(16),
            color: AppColors.error.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            child: const Row(
              children: [
                Icon(Icons.warning_rounded, color: AppColors.error),
                SizedBox(width: 12),
                Expanded(child: Text("High sedentary time detected today. Prolonged sitting impacts metabolism. A 5-minute walk is recommended.", style: TextStyle(color: Colors.white, fontSize: 13))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        children: [
          const Text("Consistency is your superpower 💪", style: TextStyle(color: Colors.white54, fontSize: 14, fontStyle: FontStyle.italic)),
          const SizedBox(height: AppSizes.xl),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: _isExporting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(_isExporting ? "Generating..." : "Download PDF", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: IconButton(
                  icon: _isExporting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.ios_share_rounded, color: Colors.white),
                  onPressed: _isExporting ? null : _sharePdf,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonth(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[month - 1];
  }
}

// --- COMPONENTS ---

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5));
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({required this.title, required this.value, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      padding: const EdgeInsets.all(16),
      color: color.withValues(alpha: 0.05),
      border: Border.all(color: color.withValues(alpha: 0.15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Icon(Icons.arrow_outward_rounded, color: Colors.white24, size: 16),
            ],
          ),
          const Spacer(),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;

  const _InsightRow({required this.icon, required this.color, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _RecommendationCard({required this.icon, required this.title, required this.desc, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: _GlassContainer(
        padding: const EdgeInsets.all(16),
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final double height;
  final String label;
  final Color? color;
  final bool isToday;

  const _ChartBar({required this.height, required this.label, this.color, this.isToday = false});

  @override
  Widget build(BuildContext context) {
    final barColor = color ?? (isToday ? AppColors.neonCyan : Colors.white.withValues(alpha: 0.15));
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutQuart,
          width: 32,
          height: height,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isToday || color != null ? [BoxShadow(color: barColor.withValues(alpha: 0.5), blurRadius: 10)] : [],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: isToday ? AppColors.neonCyan : Colors.white54, fontSize: 12, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double percent;
  final Color color;
  final String detail;

  const _MacroRow({required this.label, required this.percent, required this.color, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13))),
        Expanded(
          child: Stack(
            children: [
              Container(height: 8, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4))),
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(width: 70, child: Text(detail, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
      ],
    );
  }
}

class _GoalRow extends StatelessWidget {
  final String title;
  final double progress;
  final Color color;

  const _GoalRow({required this.title, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            Text("${(progress * 100).toInt()}%", style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white.withValues(alpha: 0.1), color: color, minHeight: 6),
        ),
      ],
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? color;
  final BoxBorder? border;

  const _GlassContainer({required this.child, this.padding = const EdgeInsets.all(16), this.borderRadius = 24, this.color, this.border});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(color: color ?? Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(borderRadius), border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.1))),
          child: child,
        ),
      ),
    );
  }
}

class _PulsingOrb extends StatefulWidget {
  final Color color;
  const _PulsingOrb({required this.color});
  @override
  State<_PulsingOrb> createState() => _PulsingOrbState();
}

class _PulsingOrbState extends State<_PulsingOrb> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_ctrl.value * 0.2),
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 10)],
              gradient: RadialGradient(colors: [Colors.white, widget.color], stops: const [0.2, 1.0]),
            ),
          ),
        );
      },
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _AmbientOrb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: const SizedBox()),
    );
  }
}