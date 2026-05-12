const mongoose = require('mongoose');

const userNotificationSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  body: { type: String, required: true },
  priority: { type: String, enum: ['Normal', 'Important', 'Critical'], default: 'Normal' },
  isRead: { type: Boolean, default: false },
  broadcastId: { type: mongoose.Schema.Types.ObjectId, ref: 'Broadcast' },
  createdAt: { type: Date, default: Date.now }
});

// Index for fast per-user queries
userNotificationSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('UserNotification', userNotificationSchema);
