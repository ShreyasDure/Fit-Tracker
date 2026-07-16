const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

transporter.verify()
  .then(() => console.log('📧 Email service ready'))
  .catch((err) => console.log('⚠️  Email not configured:', err.message));

// ─── OTP Email ───
async function sendOtpEmail(to, otp) {
  const html = `
    <div style="font-family: 'Inter', Arial, sans-serif; max-width: 480px; margin: 0 auto; background: #121220; border-radius: 16px; overflow: hidden;">
      <div style="background: linear-gradient(135deg, #00E5FF, #39FF14); padding: 32px; text-align: center;">
        <h1 style="color: #000; margin: 0; font-size: 24px;">🏋️ FitTracker</h1>
        <p style="color: #000; margin: 8px 0 0; opacity: 0.7;">Password Reset</p>
      </div>
      <div style="padding: 32px; color: #fff;">
        <h2 style="color: #00E5FF; margin: 0 0 16px;">Your OTP Code</h2>
        <p style="color: #B0B0C0; line-height: 1.6;">Use the code below to reset your password:</p>
        <div style="background: #1E1E2C; border: 2px solid #00E5FF; border-radius: 16px; padding: 24px; margin: 24px 0; text-align: center;">
          <p style="color: #00E5FF; font-size: 36px; letter-spacing: 12px; font-weight: 900; margin: 0;">${otp}</p>
        </div>
        <p style="color: #6E6E80; font-size: 12px;">⏰ This code expires in <strong style="color: #FF9100;">5 minutes</strong>.<br>If you didn't request this, ignore this email.</p>
      </div>
      <div style="background: #1E1E2C; padding: 16px; text-align: center;">
        <p style="color: #6E6E80; margin: 0; font-size: 11px;">© 2026 FitTracker. Stay fit! 💪</p>
      </div>
    </div>`;

  await transporter.sendMail({
    from: `"FitTracker" <${process.env.EMAIL_USER}>`,
    to,
    subject: '🔐 FitTracker - Your OTP Code',
    html,
  });
}

// ─── Welcome Email ───
async function sendWelcomeEmail(to, name) {
  const html = `
    <div style="font-family: 'Inter', Arial, sans-serif; max-width: 480px; margin: 0 auto; background: #121220; border-radius: 16px; overflow: hidden;">
      <div style="background: linear-gradient(135deg, #00E5FF, #39FF14); padding: 32px; text-align: center;">
        <h1 style="color: #000; margin: 0; font-size: 24px;">🏋️ FitTracker</h1>
      </div>
      <div style="padding: 32px; color: #fff;">
        <h2 style="color: #00E5FF; margin: 0 0 16px;">Hey ${name}! 🎉</h2>
        <p style="color: #B0B0C0; line-height: 1.6;">Welcome to FitTracker!</p>
        <div style="background: #1E1E2C; border-radius: 12px; padding: 20px; margin: 24px 0;">
          <p style="color: #39FF14; margin: 4px 0;">✅ Track workouts</p>
          <p style="color: #00E5FF; margin: 4px 0;">✅ Earn points</p>
          <p style="color: #BB86FC; margin: 4px 0;">✅ Join challenges</p>
          <p style="color: #FF9100; margin: 4px 0;">✅ Connect with friends</p>
        </div>
      </div>
      <div style="background: #1E1E2C; padding: 16px; text-align: center;">
        <p style="color: #6E6E80; margin: 0; font-size: 11px;">© 2026 FitTracker</p>
      </div>
    </div>`;

  await transporter.sendMail({
    from: `"FitTracker" <${process.env.EMAIL_USER}>`,
    to,
    subject: '🏋️ Welcome to FitTracker!',
    html,
  });
}

// ─── Support Auto-Reply ───
async function sendSupportReply(to, name) {
  const html = `
    <div style="font-family: 'Inter', Arial, sans-serif; max-width: 480px; margin: 0 auto; background: #121220; border-radius: 16px; overflow: hidden;">
      <div style="background: linear-gradient(135deg, #BB86FC, #FF006E); padding: 32px; text-align: center;">
        <h1 style="color: #fff; margin: 0; font-size: 24px;">FitTracker Support</h1>
      </div>
      <div style="padding: 32px; color: #fff;">
        <h2 style="color: #BB86FC; margin: 0 0 16px;">Hi ${name},</h2>
        <p style="color: #B0B0C0; line-height: 1.8;">
          We are concerned about your issue. Our team will review it and respond within <strong style="color: #00E5FF;">24 hours</strong>.
        </p>
        <p style="color: #B0B0C0; line-height: 1.8;">Thank you for your understanding.</p>
        <div style="background: #1E1E2C; border-radius: 12px; padding: 16px; margin: 24px 0;">
          <p style="color: #6E6E80; margin: 0; font-size: 12px;">📧 support.fittracker@gmail.com</p>
        </div>
      </div>
      <div style="background: #1E1E2C; padding: 16px; text-align: center;">
        <p style="color: #6E6E80; margin: 0; font-size: 11px;">© 2026 FitTracker Support Team</p>
      </div>
    </div>`;

  await transporter.sendMail({
    from: `"FitTracker Support" <${process.env.EMAIL_USER}>`,
    to,
    subject: 'FitTracker Support - We received your request',
    html,
  });
}

// ─── Account Deactivation Email ───
async function sendDeactivationEmail(to, name, reason) {
  const html = `
    <div style="font-family: 'Inter', Arial, sans-serif; max-width: 480px; margin: 0 auto; background: #121220; border-radius: 16px; overflow: hidden;">
      <div style="background: linear-gradient(135deg, #F44336, #B71C1C); padding: 32px; text-align: center;">
        <h1 style="color: #fff; margin: 0; font-size: 24px;">⚠️ Account Notice</h1>
        <p style="color: #ffcdd2; margin: 8px 0 0;">FitTracker</p>
      </div>
      <div style="padding: 32px; color: #fff;">
        <h2 style="color: #EF9A9A; margin: 0 0 16px;">Hi ${name},</h2>
        <p style="color: #B0B0C0; line-height: 1.8;">
          We're writing to inform you that your <strong style="color: #fff;">FitTracker account has been deactivated</strong>.
        </p>
        <div style="background: #1E1E2C; border: 1px solid #F44336; border-radius: 12px; padding: 20px; margin: 24px 0;">
          <p style="color: #90A4AE; margin: 0 0 8px; font-size: 12px; text-transform: uppercase; letter-spacing: 1px;">Reason</p>
          <p style="color: #EF9A9A; margin: 0; font-size: 15px; line-height: 1.6;">${reason}</p>
        </div>
        <p style="color: #B0B0C0; line-height: 1.8;">
          If you believe this was a mistake or need further assistance, please contact our support team.
        </p>
        <div style="background: #1E1E2C; border-radius: 12px; padding: 16px; margin: 24px 0;">
          <p style="color: #00E5FF; margin: 0; font-size: 12px;">📧 support.fittracker@gmail.com</p>
        </div>
      </div>
      <div style="background: #1E1E2C; padding: 16px; text-align: center;">
        <p style="color: #6E6E80; margin: 0; font-size: 11px;">© 2026 FitTracker Support Team</p>
      </div>
    </div>`;

  await transporter.sendMail({
    from: `"FitTracker" <${process.env.EMAIL_USER}>`,
    to,
    subject: '⚠️ FitTracker - Account Deactivated',
    html,
  });
}

// ─── Workout Reminder Email ───
async function sendWorkoutReminderEmail(to, name, time) {
  const quotes = [
    "The only bad workout is the one that didn't happen.",
    "Push yourself, because no one else is going to do it for you.",
    "Your body can stand almost anything. It's your mind you have to convince.",
    "Sweat is just fat crying. Keep going!",
    "Success starts with self-discipline.",
  ];
  const quote = quotes[Math.floor(Math.random() * quotes.length)];

  const html = `
    <div style="font-family: 'Inter', Arial, sans-serif; max-width: 520px; margin: 0 auto; background: #0D0D1A; border-radius: 20px; overflow: hidden; box-shadow: 0 0 40px rgba(0,229,255,0.15);">
      <!-- Header -->
      <div style="background: linear-gradient(135deg, #00E5FF 0%, #00B4D8 40%, #39FF14 100%); padding: 36px 32px; text-align: center; position: relative;">
        <div style="font-size: 48px; margin-bottom: 8px;">🏋️</div>
        <h1 style="color: #000; margin: 0; font-size: 26px; font-weight: 900; letter-spacing: -0.5px;">Time to Work Out!</h1>
        <p style="color: rgba(0,0,0,0.65); margin: 8px 0 0; font-size: 14px; font-weight: 600;">Your scheduled session is right now</p>
      </div>

      <!-- Body -->
      <div style="padding: 36px 32px; color: #fff;">
        <h2 style="color: #00E5FF; margin: 0 0 12px; font-size: 20px;">Hey ${name || 'Champ'}! 💪</h2>
        <p style="color: #B0B0C0; line-height: 1.7; margin: 0 0 24px;"
          >You set a workout reminder for <strong style="color: #fff;">${time}</strong> — and that time is <strong style="color: #39FF14;">NOW</strong>. Lace up and let's go!</p>

        <!-- Time Badge -->
        <div style="background: #1A1A2E; border: 2px solid #00E5FF; border-radius: 16px; padding: 20px 24px; margin-bottom: 28px; display: flex; align-items: center; justify-content: space-between;">
          <div>
            <p style="color: #6E6E80; font-size: 11px; text-transform: uppercase; letter-spacing: 1.5px; margin: 0 0 4px;">Reminder Time</p>
            <p style="color: #00E5FF; font-size: 32px; font-weight: 900; margin: 0; letter-spacing: 2px;">${time}</p>
          </div>
          <div style="font-size: 36px;">⏰</div>
        </div>

        <!-- Quick Tips -->
        <div style="background: #141428; border-radius: 14px; padding: 20px 24px; margin-bottom: 28px;">
          <p style="color: #39FF14; font-size: 12px; text-transform: uppercase; letter-spacing: 1.5px; margin: 0 0 12px; font-weight: 700;">Quick Warm-Up Checklist</p>
          <p style="color: #B0B0C0; margin: 6px 0; font-size: 14px;">🔥 5 min dynamic stretching</p>
          <p style="color: #B0B0C0; margin: 6px 0; font-size: 14px;">💧 Hydrate before you begin</p>
          <p style="color: #B0B0C0; margin: 6px 0; font-size: 14px;">🎧 Queue your workout playlist</p>
          <p style="color: #B0B0C0; margin: 6px 0; font-size: 14px;">📱 Open FitTracker to log your session</p>
        </div>

        <!-- Motivational Quote -->
        <div style="border-left: 4px solid #00E5FF; padding: 14px 20px; background: #1A1A2E; border-radius: 0 12px 12px 0;">
          <p style="color: #00E5FF; font-size: 13px; font-style: italic; margin: 0; line-height: 1.6;">"${quote}"</p>
        </div>
      </div>

      <!-- Footer -->
      <div style="background: #1A1A2E; padding: 20px 32px; text-align: center;">
        <p style="color: #39FF14; font-size: 13px; margin: 0 0 6px; font-weight: 600;">Keep crushing it! 🚀</p>
        <p style="color: #6E6E80; margin: 0; font-size: 11px;">© 2026 FitTracker · You are receiving this because you enabled workout reminders.</p>
      </div>
    </div>`;

  await transporter.sendMail({
    from: `"FitTracker" <${process.env.EMAIL_USER}>`,
    to,
    subject: `🏋️ Workout Reminder — It's ${time}, time to train!`,
    html,
  });
}

module.exports = { sendOtpEmail, sendWelcomeEmail, sendSupportReply, sendDeactivationEmail, sendInspectionEmail, sendResolvedEmail, sendReactivationEmail, sendWorkoutReminderEmail };

// ─── Issue Under Inspection Email ───
async function sendInspectionEmail(to, name) {
  const html = `
    <div style="font-family: 'Inter', Arial, sans-serif; max-width: 480px; margin: 0 auto; background: #121220; border-radius: 16px; overflow: hidden;">
      <div style="background: linear-gradient(135deg, #FF9100, #FFEA00); padding: 32px; text-align: center;">
        <h1 style="color: #000; margin: 0; font-size: 24px;">🔍 Issue Update</h1>
        <p style="color: #000; margin: 8px 0 0; opacity: 0.7;">FitTracker Support</p>
      </div>
      <div style="padding: 32px; color: #fff;">
        <h2 style="color: #FF9100; margin: 0 0 16px;">Hi ${name},</h2>
        <p style="color: #B0B0C0; line-height: 1.8;">Your support request is now <strong style="color: #FFEA00;">under inspection</strong> by our team.</p>
        <div style="background: #1E1E2C; border: 1px solid #FF9100; border-radius: 12px; padding: 16px; margin: 24px 0;">
          <p style="color: #FF9100; margin: 0;">📋 Status: Under Inspection</p>
          <p style="color: #B0B0C0; margin: 8px 0 0; font-size: 12px;">We are actively reviewing your case and will respond soon.</p>
        </div>
      </div>
      <div style="background: #1E1E2C; padding: 16px; text-align: center;">
        <p style="color: #6E6E80; margin: 0; font-size: 11px;">© 2026 FitTracker Support Team</p>
      </div>
    </div>`;
  await transporter.sendMail({ from: `"FitTracker Support" <${process.env.EMAIL_USER}>`, to, subject: '🔍 FitTracker - Issue Under Inspection', html });
}

// ─── Issue Resolved Email ───
async function sendResolvedEmail(to, name) {
  const html = `
    <div style="font-family: 'Inter', Arial, sans-serif; max-width: 480px; margin: 0 auto; background: #121220; border-radius: 16px; overflow: hidden;">
      <div style="background: linear-gradient(135deg, #39FF14, #00E5FF); padding: 32px; text-align: center;">
        <h1 style="color: #000; margin: 0; font-size: 24px;">✅ Issue Resolved</h1>
        <p style="color: #000; margin: 8px 0 0; opacity: 0.7;">FitTracker Support</p>
      </div>
      <div style="padding: 32px; color: #fff;">
        <h2 style="color: #39FF14; margin: 0 0 16px;">Hi ${name},</h2>
        <p style="color: #B0B0C0; line-height: 1.8;">Great news! Your support request has been <strong style="color: #39FF14;">resolved</strong>.</p>
        <div style="background: #1E1E2C; border: 1px solid #39FF14; border-radius: 12px; padding: 16px; margin: 24px 0;">
          <p style="color: #39FF14; margin: 0;">✅ Status: Resolved</p>
          <p style="color: #B0B0C0; margin: 8px 0 0; font-size: 12px;">If you have further questions, feel free to contact us again.</p>
        </div>
        <p style="color: #6E6E80; font-size: 12px;">📧 support.fittracker@gmail.com</p>
      </div>
      <div style="background: #1E1E2C; padding: 16px; text-align: center;">
        <p style="color: #6E6E80; margin: 0; font-size: 11px;">© 2026 FitTracker Support Team</p>
      </div>
    </div>`;
  await transporter.sendMail({ from: `"FitTracker Support" <${process.env.EMAIL_USER}>`, to, subject: '✅ FitTracker - Issue Resolved', html });
}

// ─── Account Reactivated Email ───
async function sendReactivationEmail(to, name) {
  const html = `
    <div style="font-family: 'Inter', Arial, sans-serif; max-width: 480px; margin: 0 auto; background: #121220; border-radius: 16px; overflow: hidden;">
      <div style="background: linear-gradient(135deg, #00E5FF, #39FF14); padding: 32px; text-align: center;">
        <h1 style="color: #000; margin: 0; font-size: 24px;">🎉 Account Reactivated</h1>
        <p style="color: #000; margin: 8px 0 0; opacity: 0.7;">FitTracker</p>
      </div>
      <div style="padding: 32px; color: #fff;">
        <h2 style="color: #00E5FF; margin: 0 0 16px;">Welcome back, ${name}! 👋</h2>
        <p style="color: #B0B0C0; line-height: 1.8;">Your FitTracker account has been <strong style="color: #39FF14;">successfully reactivated</strong>. You can now log in and continue your fitness journey!</p>
        <div style="background: #1E1E2C; border: 1px solid #39FF14; border-radius: 12px; padding: 16px; margin: 24px 0;">
          <p style="color: #39FF14; margin: 4px 0;">✅ Account status: Active</p>
          <p style="color: #00E5FF; margin: 4px 0;">💪 Keep up the great work!</p>
        </div>
      </div>
      <div style="background: #1E1E2C; padding: 16px; text-align: center;">
        <p style="color: #6E6E80; margin: 0; font-size: 11px;">© 2026 FitTracker</p>
      </div>
    </div>`;
  await transporter.sendMail({ from: `"FitTracker" <${process.env.EMAIL_USER}>`, to, subject: '🎉 FitTracker - Account Reactivated', html });
}
