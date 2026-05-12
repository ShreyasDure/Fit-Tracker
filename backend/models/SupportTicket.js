const mongoose = require('mongoose');

const supportTicketSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  message: { type: String, default: '' },
  phone: { type: String, default: '' },
  status: {
    type: String,
    enum: ['pending', 'inspection', 'resolved'],
    default: 'pending',
  },
}, { timestamps: true });

module.exports = mongoose.model('SupportTicket', supportTicketSchema);
