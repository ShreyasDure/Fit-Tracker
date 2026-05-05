const express = require('express');
const Workout = require('../models/Workout');
const User = require('../models/User');
const { auth } = require('../middleware/auth');
const router = express.Router();

// GET /api/social/feed — Activity feed (recent workouts from all users)
router.get('/feed', auth, async (req, res) => {
  try {
    const workouts = await Workout.find()
      .sort({ createdAt: -1 })
      .limit(30)
      .populate('userId', 'name email level points');

    const feed = workouts.map(w => ({
      id: w._id,
      user: w.userId ? { id: w.userId._id, name: w.userId.name, level: w.userId.level } : null,
      type: w.type,
      duration: w.duration,
      distance: w.distance,
      calories: w.calories,
      pointsEarned: w.pointsEarned,
      likes: w.likes || 0,
      createdAt: w.createdAt,
    }));

    res.json({ feed });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /api/social/leaderboard — Points leaderboard
router.get('/leaderboard', auth, async (req, res) => {
  try {
    const users = await User.find({ role: 'user' })
      .sort({ points: -1 })
      .limit(50)
      .select('name email points level streak');
    res.json({ leaderboard: users });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;
