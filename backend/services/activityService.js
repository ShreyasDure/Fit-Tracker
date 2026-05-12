const ActivityLog = require('../models/ActivityLog');

/**
 * Log an administrative or system activity
 * @param {string} type - Action type (e.g., 'NEW_USER', 'CHALLENGE_CREATED')
 * @param {string} title - Brief title of the action
 * @param {string} description - Detailed description
 * @param {string} userId - User associated with action (optional)
 * @param {string} userName - User name associated (optional)
 * @param {string} category - Category: 'user', 'challenge', 'reward', 'system', 'broadcast'
 * @param {object} metadata - Any additional data
 */
const logActivity = async ({ type, title, description, userId, userName, category, metadata }) => {
  try {
    const log = new ActivityLog({
      type,
      title,
      description,
      userId,
      userName,
      category: category || 'system',
      metadata
    });
    await log.save();
    console.log(`[ACTIVITY LOG] ${type}: ${title}`);
  } catch (err) {
    console.error('FAILED TO LOG ACTIVITY:', err.message);
  }
};

module.exports = { logActivity };
