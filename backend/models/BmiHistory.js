const mongoose = require('mongoose');

const bmiHistorySchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  weight: { type: Number, required: true },
  height: { type: Number, required: true },
  bmi: { type: Number, required: true },
  recordedAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('BmiHistory', bmiHistorySchema);
