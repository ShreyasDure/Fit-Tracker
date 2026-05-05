const express = require('express');
const Settings = require('../models/Settings');
const { auth, adminOnly } = require('../middleware/auth');

const router = express.Router();

// GET /api/settings — Get settings (creates defaults if not exist)
router.get('/', auth, adminOnly, async (req, res) => {
  try {
    let settings = await Settings.findOne({ key: 'global' });
    if (!settings) {
      // Create default settings
      settings = new Settings({
        key: 'global',
        premiumPlans: [
          { name: 'Weekly', days: 7, pointsRequired: 500, isEnabled: true },
          { name: 'Monthly', days: 30, pointsRequired: 1500, isEnabled: true },
          { name: 'Quarterly', days: 90, pointsRequired: 3500, isEnabled: true },
        ],
      });
      await settings.save();
    }
    res.json({ settings });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/settings — Update settings
router.put('/', auth, adminOnly, async (req, res) => {
  try {
    const updates = req.body;
    let settings = await Settings.findOne({ key: 'global' });
    if (!settings) {
      settings = new Settings({ key: 'global', ...updates });
    } else {
      Object.assign(settings, updates);
    }
    await settings.save();
    res.json({ settings });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
