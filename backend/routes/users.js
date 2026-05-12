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

module.exports = router;
