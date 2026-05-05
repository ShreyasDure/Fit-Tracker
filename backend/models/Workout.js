const mongoose = require('mongoose');

const workoutSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  type: {
    type: String,
    enum: ['run', 'walk', 'bike', 'gym'],
    required: true,
  },
  duration: {
    type: Number, // seconds
    required: true,
  },
  distance: {
    type: Number, // km
    default: 0,
  },
  calories: {
    type: Number,
    default: 0,
  },
  heartRateAvg: {
    type: Number,
    default: 0,
  },
  pace: {
    type: Number, // min/km
    default: 0,
  },
  pointsEarned: {
    type: Number,
    default: 0,
  },
  // Gym-specific fields
  reps: { type: Number, default: 0 },
  sets: { type: Number, default: 0 },
  weight: { type: Number, default: 0 }, // kg
  // Social
  likes: { type: Number, default: 0 },
  likedBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
}, {
  timestamps: true,
});

module.exports = mongoose.model('Workout', workoutSchema);
