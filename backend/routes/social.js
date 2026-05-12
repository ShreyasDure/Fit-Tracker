const express = require('express');
const Workout = require('../models/Workout');
const User = require('../models/User');
const { auth } = require('../middleware/auth');
const router = express.Router();

// GET /api/social/feed — Activity feed (real workouts from all users)
router.get('/feed', auth, async (req, res) => {
  try {
    const workouts = await Workout.find()
      .sort({ createdAt: -1 })
      .limit(30)
      .populate('userId', 'name email level points');

    const feed = workouts.map(w => ({
      id: w._id,
      userId: w.userId?._id,
      name: w.userId?.name || 'User',
      level: w.userId?.level || 1,
      activityType: w.type,
      duration: w.duration,
      distance: w.distance,
      calories: w.calories,
      points: w.pointsEarned || 0,
      likes: w.likes || 0,
      likedBy: w.likedBy || [],
      createdAt: w.createdAt,
    }));

    res.json({ feed });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /api/social/like/:workoutId — Toggle like on a workout
router.post('/like/:workoutId', auth, async (req, res) => {
  try {
    const workout = await Workout.findById(req.params.workoutId);
    if (!workout) return res.status(404).json({ error: 'Workout not found' });

    const userId = req.user._id.toString();
    const likedBy = (workout.likedBy || []).map(id => id.toString());
    const alreadyLiked = likedBy.includes(userId);

    if (alreadyLiked) {
      workout.likedBy = workout.likedBy.filter(id => id.toString() !== userId);
      workout.likes = Math.max(0, (workout.likes || 1) - 1);
    } else {
      workout.likedBy = [...(workout.likedBy || []), req.user._id];
      workout.likes = (workout.likes || 0) + 1;
    }
    await workout.save();

    res.json({ likes: workout.likes, liked: !alreadyLiked });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /api/social/leaderboard
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
