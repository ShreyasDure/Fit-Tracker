const express = require('express');
const Workout = require('../models/Workout');
const User = require('../models/User');
const { auth } = require('../middleware/auth');

const router = express.Router();

// POST /api/workouts — Save a workout
router.post('/', auth, async (req, res) => {
  try {
    const { type, duration, distance, calories, heartRateAvg, pace } = req.body;

    // Calculate points earned (2 points per minute)
    const minutes = duration / 60;
    const pointsEarned = Math.round(minutes * 2);

    const workout = new Workout({
      userId: req.user._id,
      type,
      duration,
      distance: distance || 0,
      calories: calories || 0,
      heartRateAvg: heartRateAvg || 0,
      pace: pace || 0,
      pointsEarned,
    });
    await workout.save();

    // Update user points and streak
    const user = await User.findById(req.user._id);
    user.points += pointsEarned;
    user.streak += 1;
    await user.save();

    res.status(201).json({ workout, pointsEarned, totalPoints: user.points });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/workouts — Get user's workout history
router.get('/', auth, async (req, res) => {
  try {
    const workouts = await Workout.find({ userId: req.user._id })
      .sort({ createdAt: -1 })
      .limit(50);
    res.json({ workouts });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
