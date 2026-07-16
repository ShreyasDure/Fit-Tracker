const cron = require('node-cron');
const User = require('./models/User');
const Reminder = require('./models/Reminder');
const { sendWorkoutReminderEmail } = require('./services/emailService');

function initCronJobs() {
  // ─── Water Intake Reminder – every 3 hours ───
  cron.schedule('0 */3 * * *', async () => {
    console.log('⏰ Running Water Intake Reminder cron job...');
    try {
      const users = await User.find({ 'preferences.pushNotifications': true });
      // In a real app, you would send an FCM push notification here
      // For now we just log it as the mock notification service
      console.log(`💧 Sent water intake push notification to ${users.length} users.`);
    } catch (err) {
      console.error('Cron job error:', err);
    }
  });

  // ─── Workout Reminder – runs every minute, matches HH:MM ───
  cron.schedule('* * * * *', async () => {
    const now = new Date();
    const hh = String(now.getHours()).padStart(2, '0');
    const mm = String(now.getMinutes()).padStart(2, '0');
    const currentTime = `${hh}:${mm}`;

    try {
      // Find all reminders whose saved time matches the current HH:MM
      const reminders = await Reminder.find({ time: currentTime }).populate('userId');

      for (const reminder of reminders) {
        const user = reminder.userId;
        if (!user) continue;

        // Log app notification (FCM not yet integrated)
        console.log(`🏋️ Workout Reminder firing for ${user.email} at ${currentTime}`);

        // Send email only when the user has opted in
        if (user.emailReminders) {
          try {
            await sendWorkoutReminderEmail(user.email, user.name, currentTime);
            console.log(`📧 Workout reminder email sent to ${user.email}`);
          } catch (e) {
            console.error('Email reminder error:', e.message);
          }
        }
      }
    } catch (err) {
      console.error('Workout reminder cron error:', err);
    }
  });
}

module.exports = { initCronJobs };
