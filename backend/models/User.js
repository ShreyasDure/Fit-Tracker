const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true,
  },
  password: {
    type: String,
    required: true,
    minlength: 8,
  },
  role: {
    type: String,
    enum: ['user', 'admin'],
    default: 'user',
  },
  points: {
    type: Number,
    default: 0,
  },
  level: {
    type: Number,
    default: 1,
  },
  streak: {
    type: Number,
    default: 0,
  },
  isActive: {
    type: Boolean,
    default: true,
  },
  healthData: {
    steps: { type: Number, default: 0 },
    calories: { type: Number, default: 0 },
    activeMinutes: { type: Number, default: 0 },
    heartRate: { type: Number, default: 0 },
    lastSynced: { type: Date, default: Date.now },
  },
  badges: [{
    badgeName: String,
    achieved: { type: Boolean, default: true },
    achievedAt: { type: Date, default: Date.now }
  }],
  // OTP for password reset
  resetOtp: { type: String, default: null },
  resetOtpExpiry: { type: Date, default: null },
  // Notification preferences
  pushNotifications: { type: Boolean, default: true },
  emailReminders: { type: Boolean, default: true },
  // Deactivation info
  deactivationReason: { type: String, default: null },
  deactivatedAt: { type: Date, default: null },
}, {
  timestamps: true,
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Return user without sensitive fields
userSchema.methods.toJSON = function() {
  const obj = this.toObject();
  delete obj.password;
  delete obj.resetOtp;
  delete obj.resetOtpExpiry;
  obj.id = obj._id;
  return obj;
};

module.exports = mongoose.model('User', userSchema);
