const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const Achievement = require('../models/Achievement');
const DailyActivity = require('../models/DailyActivity');
const User = require('../models/User');

// GET /api/achievements - Fetch user achievements
router.get('/', auth, async (req, res) => {
  try {
    const achievements = await Achievement.find({ userId: req.user._id }).sort({ isUnlocked: -1, updatedAt: -1 });
    res.json({ achievements });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch achievements' });
  }
});

// POST /api/achievements/sync - Sync progress and unlock achievements
router.post('/sync', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    // Get health data totals
    const health = user.healthData;
    const streak = user.streak;

    const achievementConfigs = [
      {
        id: 'steps_5k',
        title: '5K Steps',
        description: 'Completed 5,000 steps in a day',
        icon: '🏃',
        target: 5000,
        type: 'steps',
        rarity: 'Common',
        xp: 100
      },
      {
        id: 'steps_10k',
        title: '10K Steps',
        description: 'Reached 10,000 steps milestone',
        icon: '👟',
        target: 10000,
        type: 'steps',
        rarity: 'Rare',
        xp: 250
      },
      {
        id: 'streak_7d',
        title: '7 Day Streak',
        description: 'Maintained activity for 7 consecutive days',
        icon: '🔥',
        target: 7,
        type: 'streak',
        rarity: 'Rare',
        xp: 500
      },
      {
        id: 'active_100m',
        title: '100 Active Min',
        description: 'Log 100 active minutes in one day',
        icon: '⏱',
        target: 100,
        type: 'activeMinutes',
        rarity: 'Rare',
        xp: 300
      },
      {
        id: 'diet_master',
        title: 'Diet Master',
        description: 'Followed AI diet plans consistently',
        icon: '🥗',
        target: 5, // 5 logs
        type: 'diet',
        rarity: 'Epic',
        xp: 400
      }
    ];

    const results = [];

    for (const config of achievementConfigs) {
      let achievement = await Achievement.findOne({ userId: user._id, achievementId: config.id });
      
      if (!achievement) {
        achievement = new Achievement({
          userId: user._id,
          achievementId: config.id,
          title: config.title,
          description: config.description,
          icon: config.icon,
          target: config.target,
          rarity: config.rarity,
          xpReward: config.xp
        });
      }

      // Update progress based on type
      let currentProgress = 0;
      if (config.type === 'steps') currentProgress = health.steps;
      else if (config.type === 'streak') currentProgress = streak;
      else if (config.type === 'activeMinutes') currentProgress = health.activeMinutes;
      // For diet, we could count logs in DailyNutrition (simplified here)
      else if (config.type === 'diet') {
          const DailyNutrition = require('../models/DailyNutrition');
          currentProgress = await DailyNutrition.countDocuments({ userId: user._id });
      }

      achievement.progress = Math.min(currentProgress, config.target);

      // Check for unlock
      if (!achievement.isUnlocked && achievement.progress >= config.target) {
        achievement.isUnlocked = true;
        achievement.unlockedAt = new Date();
        
        // Reward User with XP/Points
        user.points += achievement.xpReward;
        // Simple level logic: 1000 XP per level
        user.level = Math.floor(user.points / 1000) + 1;
      }

      await achievement.save();
      results.push(achievement);
    }

    await user.save();
    res.json({ achievements: results });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to sync achievements' });
  }
});

module.exports = router;
