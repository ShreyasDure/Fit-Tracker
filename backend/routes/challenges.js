const express = require('express');
const Challenge = require('../models/Challenge');
const { auth, adminOnly } = require('../middleware/auth');
const router = express.Router();

// GET /api/challenges — List all challenges
router.get('/', auth, async (req, res) => {
  try {
    const challenges = await Challenge.find().sort({ createdAt: -1 });
    res.json({ challenges });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /api/challenges — Create challenge (admin)
router.post('/', auth, adminOnly, async (req, res) => {
  try {
    const challenge = new Challenge(req.body);
    await challenge.save();
    res.status(201).json({ challenge });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// PUT /api/challenges/:id — Update challenge (admin)
router.put('/:id', auth, adminOnly, async (req, res) => {
  try {
    const challenge = await Challenge.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!challenge) return res.status(404).json({ error: 'Not found' });
    res.json({ challenge });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// DELETE /api/challenges/:id — Delete challenge (admin)
router.delete('/:id', auth, adminOnly, async (req, res) => {
  try {
    await Challenge.findByIdAndDelete(req.params.id);
    res.json({ message: 'Challenge deleted' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /api/challenges/:id/join — User joins challenge
router.post('/:id/join', auth, async (req, res) => {
  try {
    const challenge = await Challenge.findById(req.params.id);
    if (!challenge) return res.status(404).json({ error: 'Not found' });

    const already = challenge.participants.find(p => p.userId.toString() === req.user._id.toString());
    if (already) return res.status(400).json({ error: 'Already joined' });

    challenge.participants.push({
      userId: req.user._id,
      userName: req.user.name,
      status: 'in_progress',
    });
    await challenge.save();
    res.json({ challenge });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// PUT /api/challenges/:id/progress — Update user progress
router.put('/:id/progress', auth, async (req, res) => {
  try {
    const { progress } = req.body;
    const challenge = await Challenge.findById(req.params.id);
    if (!challenge) return res.status(404).json({ error: 'Not found' });

    const participant = challenge.participants.find(p => p.userId.toString() === req.user._id.toString());
    if (!participant) return res.status(400).json({ error: 'Not joined' });

    participant.progress = progress;
    if (progress >= challenge.targetValue) {
      participant.status = 'completed';
      participant.completedAt = new Date();
    }
    await challenge.save();
    res.json({ challenge });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;
