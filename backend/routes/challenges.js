const express = require('express');
const Challenge = require('../models/Challenge');
const { auth, adminOnly } = require('../middleware/auth');
const router = express.Router();
const normalizeChallengeType = (type) => {
  if (type === 'calories' || type === 'kcal') return 'calories';
  if (type === 'distance' || type === 'km') return 'distance';
  return 'steps';
};

// GET /api/challenges — List challenges (supports ?active=true)
router.get('/', auth, async (req, res) => {
  try {
    const { active } = req.query;
    const query = {};
    if (active === 'true') query.isActive = true;
    if (active === 'false') query.isActive = false;
    const challenges = await Challenge.find(query).sort({ createdAt: -1 });
    res.json({ challenges });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /api/challenges — Create challenge (admin)
router.post('/', auth, adminOnly, async (req, res) => {
  try {
    const {
      title,
      description,
      difficulty,
      reward,
      target,
      type,
      durationDays,
      isActive,
    } = req.body;

    if (!title || !description) {
      return res.status(400).json({ error: 'Title and description are required' });
    }
    if (!['easy', 'moderate', 'hard'].includes(difficulty)) {
      return res.status(400).json({ error: 'Invalid difficulty' });
    }

    const challenge = new Challenge({
      title: String(title).trim(),
      description: String(description).trim(),
      difficulty,
      reward: Number(reward) || 100,
      target: Number(target) || 1,
      type: type || 'steps',
      durationDays: Number(durationDays) || 7,
      isActive: isActive !== false,
    });
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

const UserChallenge = require('../models/UserChallenge');

// ─── User Personal Challenges ───

// POST /api/challenges/join/:id — User joins a global admin challenge
router.post('/join/:id', auth, async (req, res) => {
  try {
    const challengeId = req.params.id;
    const globalChallenge = await Challenge.findById(challengeId);
    if (!globalChallenge) return res.status(404).json({ error: 'Global challenge not found' });
    
    // Check if already joined
    const existing = await UserChallenge.findOne({ userId: req.user._id, challengeId });
    if (existing) return res.status(400).json({ error: 'Already joined this challenge' });

    const { currentProgress } = req.body;
    const userChallenge = new UserChallenge({
      userId: req.user._id,
      challengeId: globalChallenge._id,
      title: globalChallenge.title,
      difficulty: globalChallenge.difficulty,
      type: normalizeChallengeType(globalChallenge.type),
      target: globalChallenge.target,
      reward: globalChallenge.reward,
      progress: Number(currentProgress) || 0,
      completed: false,
    });
    
    await userChallenge.save();
    res.status(201).json({ challenge: userChallenge });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET /api/challenges/user — Fetch user's personalized challenges
router.get('/user', auth, async (req, res) => {
  try {
    const challenges = await UserChallenge.find({ userId: req.user._id, completed: false });
    res.json({ challenges });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// DELETE /api/challenges/user/:id — Skip/Delete user challenge
router.delete('/user/:id', auth, async (req, res) => {
  try {
    const challenge = await UserChallenge.findOneAndDelete({ _id: req.params.id, userId: req.user._id });
    if (!challenge) return res.status(404).json({ error: 'Not found' });
    res.json({ message: 'Challenge skipped' });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// PUT /api/challenges/user/:id/progress — Update personal challenge progress
router.put('/user/:id/progress', auth, async (req, res) => {
  try {
    const { progress } = req.body;
    const challenge = await UserChallenge.findOne({ _id: req.params.id, userId: req.user._id });
    if (!challenge) return res.status(404).json({ error: 'Not found' });

    const normalizedProgress = Math.max(0, Number(progress) || 0);
    challenge.progress = normalizedProgress;
    if (!challenge.completed && normalizedProgress >= challenge.target) {
      challenge.completed = true;
      const user = await require('../models/User').findById(req.user._id);
      user.points += challenge.reward;
      await user.save();
    }
    await challenge.save();
    res.json({ challenge });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

// POST /api/challenges/user/ai — Generate AI challenge based on difficulty
router.post('/user/ai', auth, async (req, res) => {
  try {
    const { difficulty } = req.body;
    if (!['easy', 'moderate', 'hard'].includes(difficulty)) {
      return res.status(400).json({ error: 'Invalid difficulty' });
    }

    const rewardMap = { 'easy': 100, 'moderate': 200, 'hard': 300 };
    const reward = rewardMap[difficulty];

    const prompt = `Generate a very short, specific fitness challenge (e.g. 'Walk 3000 steps', 'Burn 200 calories', '30 min active time') for a user.
Difficulty level: ${difficulty}. The challenge MUST be easily measurable by step count, calorie burn, or minutes. 
Format response exactly as JSON: { "title": "Challenge Name", "target": <numeric_value> }`;

    let aiData;
    try {
      const fetch = (await import('node-fetch')).default;
      const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${process.env.GEMINI_API_KEY}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contents: [{ parts: [{ text: prompt }] }] })
      });
      const result = await response.json();
      const text = result.candidates?.[0]?.content?.parts?.[0]?.text || '';
      const match = text.match(/\{[\s\S]*\}/);
      if (match) aiData = JSON.parse(match[0]);
    } catch (e) {
      console.warn('AI challenge generation failed, using fallback:', e.message);
    }

    // Fallbacks
    if (!aiData) {
      if (difficulty === 'easy') aiData = { title: 'Walk 3000 steps', target: 3000 };
      else if (difficulty === 'moderate') aiData = { title: 'Walk 7000 steps', target: 7000 };
      else aiData = { title: 'Run 10km (13000 steps)', target: 13000 };
    }

    const challenge = new UserChallenge({
      userId: req.user._id,
      title: aiData.title,
      difficulty,
      type: 'steps',
      target: aiData.target,
      reward,
      progress: Number(req.body.currentProgress) || 0,
      completed: false,
    });
    await challenge.save();

    res.status(201).json({ challenge });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

module.exports = router;
