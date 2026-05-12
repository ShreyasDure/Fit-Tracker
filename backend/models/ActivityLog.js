const mongoose = require('mongoose');

const activityLogSchema = new mongoose.Schema({
  type: { type: String, required: true }, // e.g., 'NEW_USER', 'CHALLENGE_CREATED', 'REWARD_SENT'
  title: { type: String, required: true },
  description: { type: String, required: true },
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  userName: { type: String },
  category: { type: String, enum: ['user', 'challenge', 'reward', 'system', 'broadcast'], default: 'system' },
  metadata: { type: mongoose.Schema.Types.Mixed },
}, { timestamps: true });

module.exports = mongoose.model('ActivityLog', activityLogSchema);
