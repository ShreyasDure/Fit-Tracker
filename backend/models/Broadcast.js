const mongoose = require('mongoose');

const broadcastSchema = new mongoose.Schema({
  adminId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  adminName: { type: String, required: true },
  type: { type: String, enum: ['email', 'notification'], required: true },
  title: { type: String, required: true },
  content: { type: String, required: true },
  priority: { type: String, enum: ['Normal', 'Important', 'Critical'], default: 'Normal' },
  tone: { type: String, enum: ['Professional', 'Friendly', 'Urgent', 'Motivational'], default: 'Professional' },
  sentCount: { type: Number, default: 0 },
  failedCount: { type: Number, default: 0 },
  status: { type: String, enum: ['sent', 'failed'], default: 'sent' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Broadcast', broadcastSchema);
