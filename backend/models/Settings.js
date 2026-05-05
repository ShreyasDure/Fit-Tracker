const mongoose = require('mongoose');

const settingsSchema = new mongoose.Schema({
  key: {
    type: String,
    required: true,
    unique: true,
  },
  // Points configuration
  pointsPerMinute: { type: Number, default: 2.0 },
  streakBonus: { type: Number, default: 50.0 },
  bonusMultiplier: { type: Number, default: 1.5 },
  dailyEarningLimit: { type: Number, default: 500 },
  // Levels configuration
  silverMinPoints: { type: Number, default: 2000 },
  goldMinPoints: { type: Number, default: 5000 },
  bronzeBenefits: { type: String, default: 'Basic tracking, Community access' },
  silverBenefits: { type: String, default: 'AI insights, Priority support' },
  goldBenefits: { type: String, default: 'All features, Custom plans, 2x points' },
  // Premium plans
  premiumPlans: [{
    name: String,
    days: Number,
    pointsRequired: Number,
    isEnabled: { type: Boolean, default: true },
  }],
}, {
  timestamps: true,
});

module.exports = mongoose.model('Settings', settingsSchema);
