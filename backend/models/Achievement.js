const mongoose = require('mongoose');

const achievementSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  achievementId: {
    type: String, // e.g., 'steps_5k', 'streak_7d'
    required: true
  },
  title: {
    type: String,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  icon: {
    type: String,
    required: true
  },
  isUnlocked: {
    type: Boolean,
    default: false
  },
  unlockedAt: {
    type: Date
  },
  progress: {
    type: Number,
    default: 0
  },
  target: {
    type: Number,
    required: true
  },
  xpReward: {
    type: Number,
    default: 100
  },
  rarity: {
    type: String,
    enum: ['Common', 'Rare', 'Epic', 'Legendary'],
    default: 'Common'
  }
}, { timestamps: true });

// Ensure a user can only have one of each achievement type
achievementSchema.index({ userId: 1, achievementId: 1 }, { unique: true });

module.exports = mongoose.model('Achievement', achievementSchema);
