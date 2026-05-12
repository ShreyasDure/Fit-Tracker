const mongoose = require('mongoose');

const userChallengeSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  challengeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Challenge' },
  title: { type: String, required: true },
  difficulty: { type: String, enum: ['easy', 'moderate', 'hard'] },
  type: { type: String, enum: ['steps', 'calories', 'distance'], default: 'steps' },
  target: { type: Number, required: true },
  reward: { type: Number, required: true },
  progress: { type: Number, default: 0 },
  completed: { type: Boolean, default: false },
}, { timestamps: true });

module.exports = mongoose.model('UserChallenge', userChallengeSchema);
