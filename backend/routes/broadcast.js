const express = require('express');
const { auth } = require('../middleware/auth');
const User = require('../models/User');
const Broadcast = require('../models/Broadcast');
const UserNotification = require('../models/UserNotification');
const { logActivity } = require('../services/activityService');
const nodemailer = require('nodemailer');

const router = express.Router();

// ─── Helper: Build Premium HTML Email ───
function buildPremiumEmail(userName, subject, body, cta = 'Open FitTracker') {
  const priorityColor = '#00E5FF';
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${subject}</title>
</head>
<body style="margin:0;padding:0;background-color:#0A0A14;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#0A0A14;padding:40px 20px;">
    <tr><td align="center">
      <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;">

        <!-- HEADER -->
        <tr><td style="background:linear-gradient(135deg,#0D1B2A 0%,#1A1A2E 100%);border-radius:16px 16px 0 0;padding:40px 40px 30px;text-align:center;border-bottom:2px solid ${priorityColor}20;">
          <div style="display:inline-block;background:linear-gradient(135deg,${priorityColor},#39FF14);-webkit-background-clip:text;-webkit-text-fill-color:transparent;font-size:28px;font-weight:900;letter-spacing:3px;">⚡ FITTRACKER</div>
          <p style="color:#8892B0;font-size:12px;margin:8px 0 0;letter-spacing:2px;text-transform:uppercase;">AI-Powered Fitness Platform</p>
        </td></tr>

        <!-- AI BADGE -->
        <tr><td style="background:#1A1A2E;padding:16px 40px;text-align:center;">
          <span style="background:${priorityColor}15;color:${priorityColor};font-size:11px;font-weight:700;padding:6px 16px;border-radius:20px;border:1px solid ${priorityColor}30;letter-spacing:1px;">🤖 AI-GENERATED MESSAGE</span>
        </td></tr>

        <!-- MAIN CONTENT -->
        <tr><td style="background:#1A1A2E;padding:40px;">
          <h1 style="color:#FFFFFF;font-size:24px;font-weight:800;margin:0 0 8px;line-height:1.3;">${subject}</h1>
          <p style="color:#8892B0;font-size:13px;margin:0 0 30px;">Dear ${userName},</p>
          <div style="background:#0D1B2A;border-left:3px solid ${priorityColor};border-radius:0 12px 12px 0;padding:24px;margin-bottom:30px;">
            <p style="color:#CCD6F6;font-size:15px;line-height:1.8;margin:0;">${body.replace(/\n/g, '<br>')}</p>
          </div>

          <!-- CTA BUTTON -->
          <table width="100%" cellpadding="0" cellspacing="0"><tr><td align="center" style="padding:10px 0 30px;">
            <a href="#" style="display:inline-block;background:linear-gradient(135deg,${priorityColor},#39FF14);color:#000000;font-weight:800;font-size:15px;text-decoration:none;padding:14px 40px;border-radius:50px;letter-spacing:0.5px;">${cta} →</a>
          </td></tr></table>
        </td></tr>

        <!-- DIVIDER -->
        <tr><td style="background:#1A1A2E;padding:0 40px;"><hr style="border:none;border-top:1px solid #ffffff10;margin:0;"></td></tr>

        <!-- FOOTER -->
        <tr><td style="background:#121220;border-radius:0 0 16px 16px;padding:30px 40px;text-align:center;">
          <p style="color:${priorityColor};font-size:13px;font-weight:700;margin:0 0 8px;">💪 Stay Consistent. Stay Fit.</p>
          <p style="color:#8892B0;font-size:12px;margin:0 0 16px;line-height:1.6;">
            You received this because you are a registered FitTracker member.<br>
            For support: <a href="mailto:${process.env.EMAIL_USER}" style="color:${priorityColor};text-decoration:none;">${process.env.EMAIL_USER || 'support@fittracker.app'}</a>
          </p>
          <p style="color:#4A5568;font-size:11px;margin:0;">© 2026 FitTracker. All rights reserved.</p>
        </td></tr>

      </table>
    </td></tr>
  </table>
</body>
</html>`;
}

// ─── Helper: Generate fallback content locally ───
function generateFallbackContent(topic, type, tone) {
  const toneMap = {
    Professional: { opener: 'We wanted to inform you', cta: 'Learn More' },
    Friendly: { opener: "Hey there! We've got news", cta: 'Check It Out 🎉' },
    Urgent: { opener: '⚠️ Urgent: Action required regarding', cta: 'Act Now →' },
    Motivational: { opener: '🔥 Exciting news! Get ready for', cta: 'Let\'s Go! 💪' },
  };
  const t = toneMap[tone] || toneMap.Professional;

  if (type === 'email') {
    return {
      subject: `FitTracker Update: ${topic}`,
      body: `${t.opener} ${topic.toLowerCase()}.\n\nWe are committed to providing you with the best fitness experience. Please stay tuned for more details.\n\nThank you for being a valued member of the FitTracker community.`,
      cta: t.cta,
    };
  }
  return {
    title: topic.length > 40 ? topic.substring(0, 37) + '...' : topic,
    body: `${t.opener} ${topic.toLowerCase()}. Open FitTracker for details.`,
    cta: t.cta,
  };
}

// ─── POST /generate-content — AI Email/Notification Content ───
router.post('/generate-content', auth, async (req, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ error: 'Access denied' });

  try {
    const { topic, type, tone, priority } = req.body;
    const apiKey = process.env.GEMINI_API_KEY;

    if (!apiKey || apiKey === 'YOUR_GEMINI_API_KEY_HERE') {
      return res.json(generateFallbackContent(topic, type, tone));
    }

    const prompt = type === 'email'
      ? `You are a professional copywriter for FitTracker, a premium AI fitness app.
Topic: "${topic}"
Tone: ${tone}
Priority: ${priority}

Write a broadcast email. Return ONLY valid JSON, no markdown:
{
  "subject": "Compelling subject line under 60 chars",
  "body": "Professional 2-3 paragraph email body. Use line breaks (\\n) between paragraphs.",
  "cta": "Short CTA button text under 20 chars"
}`
      : `You are a copywriter for FitTracker fitness app.
Topic: "${topic}"
Tone: ${tone}

Write a push notification. Return ONLY valid JSON, no markdown:
{
  "title": "Engaging title under 40 chars",
  "body": "Compelling notification body under 100 chars",
  "cta": "Short CTA under 20 chars"
}`;

    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 12000);

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.8, maxOutputTokens: 500, topP: 0.9 },
      }),
      signal: controller.signal,
    });
    clearTimeout(timeoutId);

    if (!response.ok) throw new Error(`Gemini error: ${response.status}`);

    const data = await response.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text || '';
    const cleaned = text.replace(/```json|```/gi, '').trim();
    const start = cleaned.indexOf('{');
    const end = cleaned.lastIndexOf('}');
    if (start === -1 || end === -1) throw new Error('No JSON in response');

    const parsed = JSON.parse(cleaned.substring(start, end + 1));
    res.json(parsed);
  } catch (err) {
    console.warn('Broadcast AI generation failed, using fallback:', err.message);
    const { topic, type, tone } = req.body;
    res.json(generateFallbackContent(topic, type, tone));
  }
});

// ─── POST /send-email — Mass email with premium HTML template ───
router.post('/send-email', auth, async (req, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ error: 'Access denied' });

  try {
    const { subject, body, cta, priority, tone } = req.body;
    const users = await User.find({ email: { $exists: true, $ne: '' } });

    let sentCount = 0;
    let failedCount = 0;

    const transporter = nodemailer.createTransport({
      service: process.env.EMAIL_SERVICE || 'gmail',
      auth: { user: process.env.EMAIL_USER, pass: process.env.EMAIL_PASS },
    });

    // PRIVACY: Individual sending — no BCC/CC exposure
    for (const user of users) {
      try {
        const htmlBody = buildPremiumEmail(user.name || 'Valued Member', subject, body, cta || 'Open FitTracker');
        await transporter.sendMail({
          from: `"FitTracker" <${process.env.EMAIL_USER}>`,
          to: user.email,
          subject,
          text: body,
          html: htmlBody,
        });
        sentCount++;
      } catch (err) {
        console.error(`Mail failed for ${user.email}:`, err.message);
        failedCount++;
      }
    }

    const broadcast = new Broadcast({
      adminId: req.user._id, adminName: req.user.name || 'Admin',
      type: 'email', title: subject, content: body, priority, tone,
      sentCount, failedCount,
      status: failedCount === users.length ? 'failed' : 'sent',
    });
    await broadcast.save();

    await logActivity({
      type: 'BROADCAST_SENT',
      title: 'Email Broadcast Sent',
      description: `Subject: "${subject}" sent to ${sentCount} users.`,
      category: 'broadcast',
      metadata: { broadcastId: broadcast._id, sentCount }
    });

    res.json({ sentCount, failedCount, total: users.length });
  } catch (err) {
    console.error('Email Broadcast Error:', err.message);
    res.status(500).json({ error: 'Broadcast failed' });
  }
});

// ─── POST /send-notification — Mass in-app + stores per user ───
router.post('/send-notification', auth, async (req, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ error: 'Access denied' });

  try {
    const { title, body, priority, tone } = req.body;
    const users = await User.find({});

    const broadcast = new Broadcast({
      adminId: req.user._id, adminName: req.user.name || 'Admin',
      type: 'notification', title, content: body,
      priority: priority || 'Normal', tone: tone || 'Friendly',
      sentCount: users.length, failedCount: 0, status: 'sent',
    });
    await broadcast.save();

    // Store individual notification per user (privacy safe)
    const notifications = users.map(user => ({
      userId: user._id,
      title,
      body,
      priority: priority || 'Normal',
      broadcastId: broadcast._id,
    }));
    await UserNotification.insertMany(notifications);

    await logActivity({
      type: 'BROADCAST_SENT',
      title: 'Notification Broadcast Sent',
      description: `Title: "${title}" pushed to ${users.length} users.`,
      category: 'broadcast',
      metadata: { broadcastId: broadcast._id, sentCount: users.length }
    });

    res.json({ sentCount: users.length, failedCount: 0, total: users.length });
  } catch (err) {
    console.error('Notification Broadcast Error:', err.message);
    res.status(500).json({ error: 'Broadcast failed' });
  }
});

// ─── GET /my-notifications — Fetch logged-in user's notifications ───
router.get('/my-notifications', auth, async (req, res) => {
  try {
    const notifications = await UserNotification
      .find({ userId: req.user._id })
      .sort({ createdAt: -1 })
      .limit(30);
    const unreadCount = await UserNotification.countDocuments({ userId: req.user._id, isRead: false });
    res.json({ notifications, unreadCount });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
});

// ─── PATCH /my-notifications/:id/read — Mark one notification read ───
router.patch('/my-notifications/:id/read', auth, async (req, res) => {
  try {
    await UserNotification.findOneAndUpdate(
      { _id: req.params.id, userId: req.user._id },
      { isRead: true }
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Failed to mark read' });
  }
});

// ─── PATCH /my-notifications/read-all — Mark all notifications read ───
router.patch('/my-notifications/read-all', auth, async (req, res) => {
  try {
    await UserNotification.updateMany({ userId: req.user._id, isRead: false }, { isRead: true });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: 'Failed to mark all read' });
  }
});

// ─── GET /history — Broadcast history (admin only) ───
router.get('/history', auth, async (req, res) => {
  if (req.user.role !== 'admin') return res.status(403).json({ error: 'Access denied' });
  try {
    const history = await Broadcast.find().sort({ createdAt: -1 }).limit(20);
    res.json({ history });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch history' });
  }
});

module.exports = router;
