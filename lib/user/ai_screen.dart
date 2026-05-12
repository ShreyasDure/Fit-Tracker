import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../core/constants.dart';
import '../services/ai_service.dart';
import '../services/health_service.dart';
import '../controllers/auth_controller.dart';

// --- Models & State ---
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  ChatMessage({required this.text, required this.isUser, DateTime? timestamp}) 
    : timestamp = timestamp ?? DateTime.now();
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  ChatState({required this.messages, this.isLoading = false});
}

class ChatController extends StateNotifier<ChatState> {
  ChatController() : super(ChatState(messages: []));

  Future<void> sendMessage(String text, HealthData health, String userName) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(text: text, isUser: true);
    state = ChatState(messages: [...state.messages, userMsg], isLoading: true);

    try {
      final response = await AIService.generateText(
        text,
        userData: {
          "name": userName,
          "steps": health.steps,
          "calories": health.calories,
          "activeMinutes": health.activeMinutes,
          "goal": health.stepsGoal,
        },
      );
      final aiMsg = ChatMessage(text: response, isUser: false);
      state = ChatState(messages: [...state.messages, aiMsg], isLoading: false);
    } catch (e) {
      final errorMsg = ChatMessage(
          text: "⚠️ AI Coach is temporarily offline. Please check your connection.",
          isUser: false);
      state = ChatState(messages: [...state.messages, errorMsg], isLoading: false);
    }
  }

  void clear() {
    state = ChatState(messages: []);
  }
}

final chatProvider =
    StateNotifierProvider.autoDispose<ChatController, ChatState>((ref) => ChatController());

// --- Main AI Screen ---
class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> with TickerProviderStateMixin {
  late TabController _tabCtrl;
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  late AnimationController _orbController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _orbController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(String text, HealthData health, String userName) {
    if (text.trim().isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(text, health, userName);
    _msgCtrl.clear();
    _scrollToBottom();
  }

  void _switchToChatAndSend(String text, HealthData health, String userName) {
    _tabCtrl.animateTo(1);
    _send(text, health, userName);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final health = ref.watch(healthControllerProvider);
    final user = ref.watch(authControllerProvider).user;
    final userName = user?.name ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      body: Stack(
        children: [
          // 1. Background HUD Mesh & Particles
          _buildBackgroundHUD(),
          
          SafeArea(
            child: Column(
              children: [
                // 2. Immersive Hero Header
                _buildImmersiveHeader(health),
                
                // 3. Premium Tab System
                _buildPremiumTabs(),
                
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildCoachTab(health, userName),
                      _buildChatTab(chatState, health, userName),
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

  Widget _buildBackgroundHUD() {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.7, -0.6),
                radius: 1.5,
                colors: [Color(0xFF0A0A25), Color(0xFF050510)],
              ),
            ),
          ),
          // HUD Grid Opacity
          Opacity(
            opacity: 0.05,
            child: CustomPaint(
              painter: _GridPainter(),
              size: Size.infinite,
            ),
          ),
          // Floating Particles
          ...List.generate(10, (i) {
            final random = math.Random(i);
            return Positioned(
              top: random.nextDouble() * 800,
              left: random.nextDouble() * 400,
              child: _buildParticle(random),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildParticle(math.Random r) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.1 + (0.2 * _pulseController.value),
          child: Container(
            width: r.nextDouble() * 4 + 2,
            height: r.nextDouble() * 4 + 2,
            decoration: const BoxDecoration(
              color: AppColors.neonCyan,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildImmersiveHeader(HealthData health) {
    String subtitle = "1,200 steps away from your next milestone 💪";
    if (health.steps > 5000) subtitle = "Recovery score looks strong today 🔥";
    if (health.activeMinutes > 30) subtitle = "Your consistency improved this week 📈";

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FitTracker AI',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.neonGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonGreen.withValues(alpha: _pulseController.value),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'COACH ONLINE',
                      style: TextStyle(
                        color: AppColors.neonGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildAIOrbHUD(),
        ],
      ),
    );
  }

  Widget _buildAIOrbHUD() {
    return AnimatedBuilder(
      animation: _orbController,
      builder: (context, child) {
        return Container(
          width: 75,
          height: 75,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.2), width: 1),
          ),
          padding: const EdgeInsets.all(4),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating Outer HUD Ring
              Transform.rotate(
                angle: _orbController.value * math.pi * 2,
                child: CustomPaint(
                  painter: _HUDRingPainter(AppColors.neonCyan),
                  size: const Size(65, 65),
                ),
              ),
              // Glowing Inner Orb
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.neonCyan.withValues(alpha: 0.8),
                      AppColors.neonPurple.withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonCyan.withValues(alpha: 0.4),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              colors: [
                AppColors.neonCyan.withValues(alpha: 0.25),
                AppColors.neonPurple.withValues(alpha: 0.25),
              ],
            ),
            border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonCyan.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13),
          tabs: const [
            Tab(text: 'COACH'),
            Tab(text: 'CHAT'),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachTab(HealthData health, String name) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        // 1. AI Coach Hero Card
        _buildCoachHeroCard(health),
        
        const SizedBox(height: 30),
        
        // 2. Mini Metric Cards
        _buildMetricGrid(health),
        
        const SizedBox(height: 30),
        
        // 3. Today's Progress Bar Section
        _buildProgressSection(health),
        
        const SizedBox(height: 30),
        
        // 4. AI Insight Engine
        _buildInsightEngine(health, name),
        
        const SizedBox(height: 30),
        
        // 5. Weekly Trend Curved Graph
        _buildWeeklyTrend(),
        
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildCoachHeroCard(HealthData health) {
    final stepsToGo = math.max(0, health.stepsGoal - health.steps);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonCyan.withValues(alpha: 0.04),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "AI MISSION",
                    style: TextStyle(
                      color: AppColors.neonCyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  stepsToGo > 0 ? "$stepsToGo Steps To Go" : "DAILY TARGET CLEARED!",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "Consistency is key. You're currently tracking in the top 15% of users today.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          // Interactive Progress Ring
          Expanded(
            flex: 2,
            child: Center(
              child: SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 12,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.04)),
                    ),
                    ShaderMask(
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          colors: [AppColors.neonCyan, AppColors.neonPurple],
                        ).createShader(rect);
                      },
                      child: CircularProgressIndicator(
                        value: health.stepsProgress.clamp(0.0, 1.0),
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Text(
                      "${health.stepsPercent}%",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(HealthData health) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.45,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildMiniMetricCard("Steps", "${health.steps}", Icons.directions_walk, AppColors.neonCyan),
          _buildMiniMetricCard("Calories", "${health.calories}", Icons.local_fire_department, AppColors.neonOrange),
          _buildMiniMetricCard("Active Min", "${health.activeMinutes}", Icons.timer, AppColors.neonGreen),
          _buildMiniMetricCard("Streak", "12 DAYS", Icons.bolt, AppColors.neonPurple),
        ],
      ),
    );
  }

  Widget _buildMiniMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(HealthData health) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "DAILY GOAL STATUS",
                style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
              Text(
                "${health.steps} / ${health.stepsGoal}",
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: health.stepsProgress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressStat("ACHIEVED", "${health.stepsPercent}%", AppColors.neonCyan),
              _buildProgressStat("EFFORT", "HIGH", AppColors.neonOrange),
              _buildProgressStat("STATUS", "ON TRACK", AppColors.neonGreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildInsightEngine(HealthData health, String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "AI INSIGHT ENGINE",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 2,
              color: Colors.white38,
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 195,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildInsightCard(
                "Performance",
                "A 10-minute walk can improve recovery significantly today.",
                Icons.bolt,
                AppColors.neonCyan,
                "Start Plan",
                () => _switchToChatAndSend("Give me a 10-minute walking plan", health, name),
              ),
              _buildInsightCard(
                "Nutrition",
                "Based on current burn, prioritize high-protein fuel today.",
                Icons.restaurant,
                AppColors.neonGreen,
                "Get Menu",
                () => _switchToChatAndSend("Suggest a high protein recovery meal", health, name),
              ),
              _buildInsightCard(
                "Vitality",
                "Try a 5-minute breathing session to stabilize heart rate.",
                Icons.favorite,
                AppColors.neonPink,
                "Launch Mode",
                () => _switchToChatAndSend("Guide me through breathing", health, name),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(String title, String body, IconData icon, Color color, String action, VoidCallback onTap) {
    return Container(
      width: 290,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.04), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Text(
                title.toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            body,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Text(
                action,
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  "WEEKLY PERFORMANCE",
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "+14% GROWTH",
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: _ChartPainter(),
            ),
          ),
        ],
      ),
    );
  }

  // --- Chat Tab ---
  Widget _buildChatTab(ChatState chatState, HealthData health, String name) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            itemCount: chatState.messages.isEmpty ? 1 : chatState.messages.length + (chatState.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (chatState.messages.isEmpty) return _buildAssistantWelcome();
              if (index == chatState.messages.length) return _buildTypingIndicator();
              return _buildMessageBubble(chatState.messages[index]);
            },
          ),
        ),
        _buildChatInputArea(health, name),
      ],
    );
  }

  Widget _buildAssistantWelcome() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        Container(
          padding: const EdgeInsets.all(45),
          decoration: BoxDecoration(
            color: AppColors.neonCyan.withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.15), width: 2),
          ),
          child: const Icon(Icons.auto_awesome, color: AppColors.neonCyan, size: 65),
        ),
        const SizedBox(height: 35),
        const Text(
          "FitTracker Intelligence",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: Colors.white, letterSpacing: -1),
        ),
        const SizedBox(height: 14),
        Text(
          "All bio-metrics synced.\nI am ready to optimize your performance.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 15, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 22),
        padding: const EdgeInsets.all(22),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.neonCyan : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(26),
            topRight: const Radius.circular(26),
            bottomLeft: Radius.circular(msg.isUser ? 26 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 26),
          ),
          border: Border.all(color: msg.isUser ? Colors.transparent : Colors.white.withValues(alpha: 0.1)),
          boxShadow: msg.isUser ? [BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 6))] : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(color: msg.isUser ? Colors.black : Colors.white, fontWeight: FontWeight.w600, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 10),
            Text(
              "${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
              style: TextStyle(color: msg.isUser ? Colors.black38 : Colors.white24, fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PulseDots(),
            SizedBox(width: 14),
            Text("AI is generating protocol...", style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInputArea(HealthData health, String name) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF050510),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildQuickActionChip("Meal Suggestion", () => _send("Suggest a meal for my calorie goal", health, name)),
                _buildQuickActionChip("Workout Plan", () => _send("Create a 20-min workout", health, name)),
                _buildQuickActionChip("Bio-Audit", () => _send("Analyze my current health stats", health, name)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: "Enter AI Prompt...",
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                  ),
                  onSubmitted: (val) => _send(val, health, name),
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => _send(_msgCtrl.text, health, name),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.neonCyan, AppColors.neonPurple]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.35), blurRadius: 20)],
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 26),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.25)),
          ),
          child: Text(label, style: const TextStyle(color: AppColors.neonCyan, fontSize: 12, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}

// ─── Custom HUD Painters ───

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neonCyan.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HUDRingPainter extends CustomPainter {
  final Color color;
  _HUDRingPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw segmented HUD ring
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        (i * math.pi / 2) + 0.2,
        (math.pi / 2) - 0.4,
        false,
        paint,
      );
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neonCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    final path = Path();
    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.6),
      Offset(size.width * 0.4, size.height * 0.9),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.5),
      Offset(size.width, size.height * 0.1),
    ];
    
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.quadraticBezierTo(
        (points[i - 1].dx + points[i].dx) / 2,
        (points[i - 1].dy + points[i].dy) / 2,
        points[i].dx,
        points[i].dy,
      );
    }
    
    // Draw Glow
    canvas.drawPath(path, paint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawPath(path, paint..maskFilter = null..strokeWidth = 2);
    
    // Fill under path
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.neonCyan.withValues(alpha: 0.15), Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PulseDots extends StatefulWidget {
  const _PulseDots();

  @override
  State<_PulseDots> createState() => _PulseDotsState();
}

class _PulseDotsState extends State<_PulseDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          children: List.generate(3, (index) {
            double value = math.sin((_controller.value * 2 * math.pi) + (index * math.pi / 2));
            return Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withValues(alpha: (value + 1) / 2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.neonCyan.withValues(alpha: (value + 1) / 4), blurRadius: 4),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}