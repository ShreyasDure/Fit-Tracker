const express = require('express');
const { auth, adminOnly } = require('../middleware/auth');
const User = require('../models/User');
const DailyActivity = require('../models/DailyActivity');
const Challenge = require('../models/Challenge');
const Reward = require('../models/Reward');
const ActivityLog = require('../models/ActivityLog');
const { logActivity } = require('../services/activityService');
const PDFDocument = require('pdfkit');
const router = express.Router();

// GET /api/admin/analytics - Admin dashboard analytics
router.get('/analytics', auth, adminOnly, async (req, res) => {
  try {
    const totalUsers = await User.countDocuments({ role: 'user' });
    const activeUsersCount = await User.countDocuments({
      role: 'user',
      $or: [
        { isOnline: true },
        { lastActive: { $gte: new Date(Date.now() - 5 * 60 * 1000) } }
      ]
    });
    const totalPoints = await User.aggregate([
      { $match: { role: 'user' } },
      { $group: { _id: null, total: { $sum: "$points" } } }
    ]);
    
    // Aggregate daily active users (unique users with activity logs per day) for charts
    const activeUsersChart = await DailyActivity.aggregate([
      { $group: { _id: "$date", uniqueUsers: { $addToSet: "$userId" } } },
      { $project: { date: "$_id", count: { $size: "$uniqueUsers" }, _id: 0 } },
      { $sort: { date: 1 } },
      { $limit: 7 }
    ]);
    
    // User growth (users registered by date)
    const userGrowth = await User.aggregate([
      { $match: { role: 'user' } },
      { 
        $group: { 
          _id: { $dateToString: { format: "%Y-%m-%d", date: "$createdAt" } },
          count: { $sum: 1 } 
        } 
      },
      { $project: { date: "$_id", count: 1, _id: 0 } },
      { $sort: { date: 1 } },
      { $limit: 7 }
    ]);

    res.json({ 
      totalUsers, 
      activeUsers: activeUsersCount, 
      totalPoints: totalPoints[0]?.total || 0,
      activeUsersChart,
      userGrowth,
      charts: { activeUsersChart, userGrowth }
    });
  } catch (err) {
    console.error('Analytics Error:', err);
    res.status(500).json({ error: 'Failed to fetch analytics' });
  }
});

// GET /api/admin/activity - Live activity feed
router.get('/activity', auth, adminOnly, async (req, res) => {
  try {
    const logs = await ActivityLog.find().sort({ createdAt: -1 }).limit(50);
    res.json({ logs });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch activity logs' });
  }
});

// POST /api/admin/challenges - Create new challenge
router.post('/challenges', auth, adminOnly, async (req, res) => {
  try {
    const { title, description, difficulty, reward, durationDays, target, type, startDate, endDate } = req.body;
    
    const challenge = new Challenge({
      title, description, difficulty, reward, durationDays, target, type,
      startDate: startDate || new Date(),
      endDate: endDate || new Date(Date.now() + (durationDays || 7) * 24 * 60 * 60 * 1000)
    });
    await challenge.save();

    await logActivity({
      type: 'CHALLENGE_CREATED',
      title: 'New Challenge Created',
      description: `Challenge "${title}" was launched by Admin.`,
      category: 'challenge',
      metadata: { challengeId: challenge._id }
    });

    res.status(201).json({ message: 'Challenge created successfully', challenge });
  } catch (err) {
    res.status(500).json({ error: 'Failed to create challenge' });
  }
});

// POST /api/admin/rewards - Reward users
router.post('/rewards', auth, adminOnly, async (req, res) => {
  try {
    const { userIds, achievementName, points, xpBonus, badgeRewarded } = req.body;
    
    const users = await User.find({ _id: { $in: userIds } });
    const rewardLogs = [];

    for (const user of users) {
      user.points += points;
      // Level logic: 1000 XP per level
      user.level = Math.floor(user.points / 1000) + 1;
      await user.save();

      const reward = new Reward({
        userId: user._id,
        userName: user.name,
        achievementName,
        points,
        xpBonus,
        badgeRewarded,
        awardedBy: req.user._id
      });
      await reward.save();
      rewardLogs.push(reward);

      await logActivity({
        type: 'REWARD_SENT',
        title: 'Points Rewarded',
        description: `${points} points awarded to ${user.name} for ${achievementName}.`,
        userId: user._id,
        userName: user.name,
        category: 'reward',
        metadata: { rewardId: reward._id }
      });
    }

    res.json({ message: 'Rewards distributed successfully', count: users.length });
  } catch (err) {
    res.status(500).json({ error: 'Failed to reward users' });
  }
});

module.exports = router;
