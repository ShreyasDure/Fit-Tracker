const mongoose = require('mongoose');

const intakeItemSchema = new mongoose.Schema({
  food: { type: String, required: true },
  quantity: { type: Number, required: true }, // grams
  calories: { type: Number, default: 0 },
  protein: { type: Number, default: 0 },
  carbs: { type: Number, default: 0 },
  fat: { type: Number, default: 0 },
  loggedAt: { type: Date, default: Date.now },
}, { _id: false });

const dailyNutritionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  date: {
    type: String, // YYYY-MM-DD
    required: true,
  },
  totalCalories: { type: Number, default: 0 },
  totalProtein: { type: Number, default: 0 },
  totalCarbs: { type: Number, default: 0 },
  totalFat: { type: Number, default: 0 },
  items: { type: [intakeItemSchema], default: [] },
  aiDietPlan: { type: Object, default: null },
}, { timestamps: true });

dailyNutritionSchema.index({ userId: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('DailyNutrition', dailyNutritionSchema);
