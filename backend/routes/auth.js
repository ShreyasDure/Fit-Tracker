const express = require('express');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const User = require('../models/User');
const { logActivity } = require('../services/activityService');
const { auth } = require('../middleware/auth');
const { sendOtpEmail, sendWelcomeEmail, sendSupportReply } = require('../services/emailService');
const SupportTicket = require('../models/SupportTicket');

const router = express.Router();
const strongPasswordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$/;
const strongPasswordMessage = 'Password must include uppercase, lowercase, number, and special character.';

// In-memory store for signup OTPs (email -> {otp, expiry, name, password, role})
const signupOtpStore = new Map();

// Clean expired OTPs every 10 minutes
setInterval(() => {
  const now = Date.now();
  for (const [email, data] of signupOtpStore) {
    if (now > data.expiry) signupOtpStore.delete(email);
  }
}, 10 * 60 * 1000);

// POST /api/auth/send-signup-otp — Send OTP to verify email before registration
router.post('/send-signup-otp', async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email, and password are required' });
    }
    if (!strongPasswordRegex.test(password)) {
      return res.status(400).json({ error: strongPasswordMessage });
    }

    // Check if email already registered
    const existingUser = await User.findOne({ email: email.toLowerCase() });
    if (existingUser) {
      return res.status(400).json({ error: 'Email already registered' });
    }

    // Generate 6-digit OTP
    const otp = crypto.randomInt(100000, 999999).toString();
    const expiry = Date.now() + 5 * 60 * 1000; // 5 minutes

    // Store OTP + user data temporarily
    signupOtpStore.set(email.toLowerCase(), { otp, expiry, name, password, role: role || 'user' });

    // Send OTP email
    try {
      await sendOtpEmail(email, otp);
      console.log(`📧 Signup OTP sent to ${email}: ${otp}`);
    } catch (emailErr) {
      console.log(`\n⚠️  Email failed. Signup OTP for ${email}: ${otp}\n`);
    }

    res.json({ message: 'Verification OTP sent to your email.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/auth/register — Create account (requires verified OTP)
router.post('/register', async (req, res) => {
  try {
    const { email, otp } = req.body;
    const key = email.toLowerCase();

    // Check OTP
    const stored = signupOtpStore.get(key);
    if (!stored) {
      return res.status(400).json({ error: 'No OTP found. Please request a new one.' });
    }
    if (Date.now() > stored.expiry) {
      signupOtpStore.delete(key);
      return res.status(400).json({ error: 'OTP expired. Please request a new one.' });
    }
    if (stored.otp !== otp) {
      return res.status(400).json({ error: 'Invalid OTP. Please try again.' });
    }

    // Double-check email isn't taken
    const existingUser = await User.findOne({ email: key });
    if (existingUser) {
      signupOtpStore.delete(key);
      return res.status(400).json({ error: 'Email already registered' });
    }

    // Create user with stored data
    const user = new User({
      name: stored.name,
      email: key,
      password: stored.password,
      role: stored.role,
    });
    await user.save();
    
    // Log Activity
    await logActivity({
      type: 'NEW_USER',
      title: 'New Athlete Registered',
      description: `${user.name} joined the FitTracker ecosystem.`,
      userId: user._id,
      userName: user.name,
      category: 'user'
    });

    signupOtpStore.delete(key);

    const token = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.status(201).json({ token, user: user.toJSON() });

    // Send welcome email (non-blocking)
    sendWelcomeEmail(user.email, user.name).catch(err =>
      console.log('⚠️  Welcome email failed:', err.message)
    );
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    if (!user.isActive) {
      return res.status(403).json({ error: 'Account is deactivated' });
    }

    const token = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({ token, user: user.toJSON() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/auth/me
router.get('/me', auth, async (req, res) => {
  res.json({ user: req.user.toJSON() });
});

// ─── OTP-based Password Reset ───

// POST /api/auth/forgot-password — Send 6-digit OTP
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email: email.toLowerCase() });

    // Always return same message (security: don't reveal if email exists)
    const message = 'If an account exists with this email, an OTP has been sent.';

    if (!user) {
      return res.json({ message });
    }

    // Generate 6-digit OTP
    const otp = crypto.randomInt(100000, 999999).toString();
    const expiry = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

    user.resetOtp = otp;
    user.resetOtpExpiry = expiry;
    await user.save({ validateBeforeSave: false });

    // Send OTP via email
    try {
      await sendOtpEmail(email, otp);
      console.log(`📧 OTP sent to ${email}: ${otp}`);
    } catch (emailErr) {
      console.log(`\n⚠️  Email failed. OTP for ${email}: ${otp}\n`);
    }

    res.json({ message });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/auth/verify-otp — Verify the 6-digit OTP
router.post('/verify-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;
    const user = await User.findOne({ email: email.toLowerCase() });

    if (!user || !user.resetOtp || !user.resetOtpExpiry) {
      return res.status(400).json({ error: 'Invalid request. Please request a new OTP.' });
    }

    if (new Date() > user.resetOtpExpiry) {
      user.resetOtp = null;
      user.resetOtpExpiry = null;
      await user.save({ validateBeforeSave: false });
      return res.status(400).json({ error: 'OTP has expired. Please request a new one.' });
    }

    if (user.resetOtp !== otp) {
      return res.status(400).json({ error: 'Invalid OTP. Please try again.' });
    }

    res.json({ message: 'OTP verified successfully', verified: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/auth/reset-password — Set new password after OTP verification
router.post('/reset-password', async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;
    const user = await User.findOne({ email: email.toLowerCase() });

    if (!user || !user.resetOtp || user.resetOtp !== otp) {
      return res.status(400).json({ error: 'Invalid request' });
    }

    if (new Date() > user.resetOtpExpiry) {
      return res.status(400).json({ error: 'OTP expired' });
    }

    if (!strongPasswordRegex.test(newPassword)) {
      return res.status(400).json({ error: strongPasswordMessage });
    }

    user.password = newPassword;
    user.resetOtp = null;
    user.resetOtpExpiry = null;
    await user.save();

    res.json({ message: 'Password updated successfully' });
  } catch (err) {
    res.status(400).json({ error: 'Failed to reset password' });
  }
});

// POST /api/auth/change-password — Change password (logged in)
router.post('/change-password', auth, async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    const isMatch = await req.user.comparePassword(currentPassword);
    if (!isMatch) {
      return res.status(400).json({ error: 'Current password is incorrect' });
    }

    if (!strongPasswordRegex.test(newPassword)) {
      return res.status(400).json({ error: strongPasswordMessage });
    }

    req.user.password = newPassword;
    await req.user.save();

    res.json({ message: 'Password changed successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/auth/profile — Update user profile
router.put('/profile', auth, async (req, res) => {
  try {
    const { name } = req.body;
    if (!name || name.trim().length === 0) {
      return res.status(400).json({ error: 'Name cannot be empty' });
    }

    req.user.name = name.trim();
    await req.user.save({ validateBeforeSave: false });

    res.json({ user: req.user.toJSON() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/auth/notifications — Update notification preferences
router.put('/notifications', auth, async (req, res) => {
  try {
    const { pushNotifications, emailReminders } = req.body;

    if (pushNotifications !== undefined) req.user.pushNotifications = pushNotifications;
    if (emailReminders !== undefined) req.user.emailReminders = emailReminders;
    await req.user.save({ validateBeforeSave: false });

    res.json({
      pushNotifications: req.user.pushNotifications,
      emailReminders: req.user.emailReminders,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/auth/support — Send support ticket
router.post('/support', auth, async (req, res) => {
  try {
    const { message, phone } = req.body;
    if (!phone || !phone.trim()) return res.status(400).json({ error: 'Phone number is required' });

    // Send auto-reply to user
    try {
      await sendSupportReply(req.user.email, req.user.name);
    } catch (emailErr) {
      console.log('⚠️  Support reply email failed:', emailErr.message);
    }

    // Save to DB with phone
    const ticket = new SupportTicket({
      userId: req.user._id,
      message: message?.trim() || '',
      phone: phone.trim(),
    });
    await ticket.save();

    console.log(`📩 Support from ${req.user.email} | phone: ${phone || 'N/A'}: ${message}`);
    res.json({ message: 'Support request received. We will respond within 24 hours.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/auth/support-tickets — Admin: Get all support tickets
const { adminOnly } = require('../middleware/auth');
router.get('/support-tickets', auth, adminOnly, async (req, res) => {
  try {
    const tickets = await SupportTicket.find()
      .populate('userId', 'name email')
      .sort({ createdAt: -1 })
      .limit(100);
    res.json({ tickets });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PUT /api/auth/support-tickets/:id/status — Admin: Update ticket status
router.put('/support-tickets/:id/status', auth, adminOnly, async (req, res) => {
  try {
    const { status } = req.body;
    if (!['pending', 'inspection', 'resolved'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const ticket = await SupportTicket.findById(req.params.id).populate('userId', 'name email');
    if (!ticket) return res.status(404).json({ error: 'Ticket not found' });

    ticket.status = status;
    await ticket.save();

    // Send email to user based on status
    if (ticket.userId?.email) {
      try {
        const { sendInspectionEmail, sendResolvedEmail } = require('../services/emailService');
        if (status === 'inspection') {
          await sendInspectionEmail(ticket.userId.email, ticket.userId.name);
        } else if (status === 'resolved') {
          await sendResolvedEmail(ticket.userId.email, ticket.userId.name);
        }
      } catch (emailErr) {
        console.warn('Ticket status email failed:', emailErr.message);
      }
    }

    res.json({ ticket, message: `Ticket marked as ${status}` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
