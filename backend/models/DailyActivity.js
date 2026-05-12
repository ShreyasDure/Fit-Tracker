const mongoose = require('mongoose');

const dailyActivitySchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  date: {
    type: String, // format: "YYYY-MM-DD"
    required: true,
  },
  steps: { type: Number, default: 0 },
  calories: { type: Number, default: 0 },
  activeMinutes: { type: Number, default: 0 },
  waterIntake: { type: Number, default: 0 },
}, { timestamps: true });

// Ensure one document per user per day
dailyActivitySchema.index({ userId: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('DailyActivity', dailyActivitySchema);
