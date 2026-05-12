const cron = require('node-cron');
const User = require('./models/User');

function initCronJobs() {
  // Run every 3 hours to remind users to drink water
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
}

module.exports = { initCronJobs };
