const express = require('express');
const User = require('../models/User');
const { auth, adminOnly } = require('../middleware/auth');

const router = express.Router();

// GET /api/users — List all users (admin only) with optional date filtering
router.get('/', auth, adminOnly, async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const query = { role: 'user' };
    
    if (startDate || endDate) {
      query.createdAt = {};
      if (startDate) {
        query.createdAt.$gte = new Date(startDate);
      }
      if (endDate) {
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);
        query.createdAt.$lte = end;
      }
    }

    const users = await User.find(query).sort({ createdAt: -1 });
    res.json({ users: users.map(u => u.toJSON()) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/users/:id/points — Add or remove points
router.put('/:id/points', auth, adminOnly, async (req, res) => {
  try {
    const { amount } = req.body; // positive = add, negative = remove
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    user.points = Math.max(0, user.points + amount);

    // Auto-calculate level
    if (user.points >= 5000) user.level = Math.max(user.level, 7);
    else if (user.points >= 2000) user.level = Math.max(user.level, 4);
    else user.level = Math.max(user.level, 1);

    await user.save();
    res.json({ user: user.toJSON() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/users/:id/toggle — Toggle active status with optional reason
router.put('/:id/toggle', auth, adminOnly, async (req, res) => {
  try {
    const { reason } = req.body || {};
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    const wasActive = user.isActive;
    user.isActive = !user.isActive;

    // If deactivating, store reason
    if (wasActive && !user.isActive && reason) {
      user.deactivationReason = reason;
      user.deactivatedAt = new Date();
    } else if (!wasActive && user.isActive) {
      // Clear reason on reactivation
      user.deactivationReason = undefined;
      user.deactivatedAt = undefined;
    }

    await user.save();

    // Send email notification based on action
    if (wasActive && !user.isActive) {
      try {
        const { sendDeactivationEmail } = require('../services/emailService');
        await sendDeactivationEmail(user.email, user.name, reason || 'No specific reason provided');
        console.log(`📧 Deactivation email sent to ${user.email}`);
      } catch (emailErr) {
        console.warn('Deactivation email failed:', emailErr.message);
      }
    } else if (!wasActive && user.isActive) {
      try {
        const { sendReactivationEmail } = require('../services/emailService');
        await sendReactivationEmail(user.email, user.name);
        console.log(`📧 Reactivation email sent to ${user.email}`);
      } catch (emailErr) {
        console.warn('Reactivation email failed:', emailErr.message);
      }
    }

    res.json({ user: user.toJSON(), message: user.isActive ? 'Account activated' : 'Account deactivated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/users/me/activities — Fetch consolidated user activity logs (workouts, achievements, points, AI, challenges)
router.get('/me/activities', auth, async (req, res) => {
  try {
    const userId = req.user._id;

    // Fetch in parallel
    const [workouts, achievements, rewards, dailyNutrition, userChallenges, activityLogs] = await Promise.all([
      require('../models/Workout').find({ userId }).sort({ createdAt: -1 }).limit(15),
      require('../models/Achievement').find({ userId, isUnlocked: true }).sort({ updatedAt: -1 }).limit(15),
      require('../models/Reward').find({ userId }).sort({ createdAt: -1 }).limit(15),
      require('../models/DailyNutrition').find({ userId, aiDietPlan: { $ne: null } }).sort({ updatedAt: -1 }).limit(15),
      require('../models/UserChallenge').find({ userId }).sort({ updatedAt: -1 }).limit(15),
      require('../models/ActivityLog').find({ userId }).sort({ createdAt: -1 }).limit(15),
    ]);

    const activities = [];

    // 1. Workouts
    for (const w of workouts) {
      activities.push({
        id: w._id.toString(),
        type: 'workout_completed',
        title: `Completed ${w.type.toUpperCase()}`,
        description: `${Math.round(w.duration / 60)} min workout • ${w.calories} kcal burned${w.distance ? ` • ${w.distance} km` : ''}`,
        timestamp: w.createdAt,
        points: w.pointsEarned || 0,
      });
    }

    // 2. Achievements
    for (const a of achievements) {
      activities.push({
        id: a._id.toString(),
        type: 'achievement_unlocked',
        title: `Unlocked: ${a.title}`,
        description: a.description,
        timestamp: a.unlockedAt || a.updatedAt || a.createdAt,
        points: a.xpReward || 0,
      });
    }

    // 3. Rewards / Points History
    for (const r of rewards) {
      activities.push({
        id: r._id.toString(),
        type: 'points_earned',
        title: `Points Earned: ${r.achievementName}`,
        description: `Awarded ${r.points} points with a ${r.xpBonus} XP bonus!`,
        timestamp: r.createdAt,
        points: r.points,
      });
    }

    // 4. DailyNutrition (AI Diet Plans)
    for (const n of dailyNutrition) {
      activities.push({
        id: n._id.toString(),
        type: 'diet_plan_created',
        title: `Generated AI Diet Plan`,
        description: `Diet plan designed for ${n.date} with a target of ${n.totalCalories} kcal.`,
        timestamp: n.updatedAt || n.createdAt,
        points: 0,
      });
    }

    // 5. UserChallenges
    for (const uc of userChallenges) {
      activities.push({
        id: uc._id.toString(),
        type: 'challenge_status',
        title: uc.completed ? `Completed Challenge: ${uc.title}` : `Joined Challenge: ${uc.title}`,
        description: `Target: ${uc.target} • Difficulty: ${uc.difficulty}`,
        timestamp: uc.updatedAt || uc.createdAt,
        points: uc.completed ? uc.reward : 0,
      });
    }

    // 6. AI recommendations/insights and chats (from ActivityLog)
    for (const log of activityLogs) {
      if (log.type === 'AI_INSIGHT') {
        activities.push({
          id: log._id.toString(),
          type: 'ai_recommendation',
          title: 'Generated AI Insight',
          description: log.description || 'Analyzed health metrics.',
          timestamp: log.createdAt,
          points: 0,
        });
      } else if (log.type === 'AI_CHAT') {
        activities.push({
          id: log._id.toString(),
          type: 'ai_chat',
          title: 'Consulted AI Coach',
          description: log.description || 'Asked for advice.',
          timestamp: log.createdAt,
          points: 0,
        });
      }
    }

    // Sort by timestamp in descending order
    activities.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    // Limit to latest 30 events
    res.json({ activities: activities.slice(0, 30) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const Reminder = require('../models/Reminder');

// DELETE /api/users/:id — Delete user (admin only)
router.delete('/:id', auth, adminOnly, async (req, res) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({ message: 'User deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/users/me/reminders — List user's scheduled reminders
router.get('/me/reminders', auth, async (req, res) => {
  try {
    const reminders = await Reminder.find({ userId: req.user._id });
    res.json({ reminders: reminders.map(r => ({ id: r._id.toString(), time: r.time, label: r.label })) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/users/me/reminders — Schedule a new reminder
router.post('/me/reminders', auth, async (req, res) => {
  try {
    const { time, label } = req.body;
    const reminder = new Reminder({
      userId: req.user._id,
      time,
      label: label || 'Workout Reminder'
    });
    await reminder.save();
    res.status(201).json({ reminder: { id: reminder._id.toString(), time: reminder.time, label: reminder.label } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/users/me/reminders/:id — Delete a scheduled reminder
router.delete('/me/reminders/:id', auth, async (req, res) => {
  try {
    const reminder = await Reminder.findOneAndDelete({ _id: req.params.id, userId: req.user._id });
    if (!reminder) return res.status(404).json({ error: 'Reminder not found' });
    res.json({ message: 'Reminder deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
