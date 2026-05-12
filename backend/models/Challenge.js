const mongoose = require('mongoose');

const challengeSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, required: true },
  difficulty: { type: String, enum: ['easy', 'moderate', 'hard'], required: true },
  reward: { type: Number, required: true },
  durationDays: { type: Number, default: 7 },
  target: { type: Number, default: 1 }, 
  type: { type: String, default: 'steps' },
  isActive: { type: Boolean, default: true },
  participants: [{
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    userName: String,
    status: { type: String, enum: ['joined', 'in_progress', 'completed', 'failed'], default: 'joined' },
    progress: { type: Number, default: 0 },
    joinedAt: { type: Date, default: Date.now },
    completedAt: Date,
  }],
}, { timestamps: true });

module.exports = mongoose.model('Challenge', challengeSchema);
