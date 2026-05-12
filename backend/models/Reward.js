const mongoose = require('mongoose');

const rewardSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  userName: String,
  achievementName: { type: String, required: true },
  points: { type: Number, required: true },
  xpBonus: { type: Number, default: 0 },
  badgeRewarded: { type: String },
  awardedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' }, // Admin ID
}, { timestamps: true });

module.exports = mongoose.model('Reward', rewardSchema);
