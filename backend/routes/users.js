const express = require('express');
const User = require('../models/User');
const { auth, adminOnly } = require('../middleware/auth');

const router = express.Router();

// GET /api/users — List all users (admin only)
router.get('/', auth, adminOnly, async (req, res) => {
  try {
    const users = await User.find({ role: 'user' }).sort({ createdAt: -1 });
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

// PUT /api/users/:id/toggle — Toggle active status
router.put('/:id/toggle', auth, adminOnly, async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });

    user.isActive = !user.isActive;
    await user.save();
    res.json({ user: user.toJSON() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
