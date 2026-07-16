const mongoose = require('mongoose');

const reminderSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  time: {
    type: String,
    required: true,
  },
  label: {
    type: String,
    default: 'Workout Reminder',
  },
}, {
  timestamps: true,
});

module.exports = mongoose.model('Reminder', reminderSchema);
