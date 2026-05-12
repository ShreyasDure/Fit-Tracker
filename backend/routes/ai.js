const express = require('express');
const { auth } = require('../middleware/auth');

const router = express.Router();

// In-memory cache: userId -> { insight, timestamp }
const insightCache = new Map();
const CACHE_TTL = 30 * 1000; // 30 seconds cooldown

// POST /api/ai/insight — Get personalized AI fitness insight
router.post('/insight', auth, async (req, res) => {
  try {
    const userId = req.user._id.toString();
    const { name, steps, calories, activeMinutes, goal } = req.body;

    // Check cache (cooldown)
    const cached = insightCache.get(userId);
    if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
      return res.json({ insight: cached.insight, cached: true });
    }

    const goalPercent = goal > 0 ? Math.round((steps / goal) * 100) : 0;

    // Build the prompt
    const prompt = buildPrompt(name, steps, calories, activeMinutes, goal, goalPercent);

    // Call AI API
    let insight;
    const apiKey = process.env.GEMINI_API_KEY;

    if (apiKey && apiKey !== 'YOUR_GEMINI_API_KEY_HERE') {
      insight = await callGemini(apiKey, prompt);
    } else {
      // Smart fallback when no API key
      insight = generateLocalInsight(name, steps, calories, activeMinutes, goal, goalPercent);
    }

    // Cache the result
    insightCache.set(userId, { insight, timestamp: Date.now() });

    res.json({ insight, cached: false });
  } catch (err) {
    console.error('❌ AI Insight error:', err.message);
    // Fallback on error
    const { name, steps, calories, activeMinutes, goal } = req.body;
    const goalPercent = goal > 0 ? Math.round((steps / goal) * 100) : 0;
    const insight = generateLocalInsight(name || 'Champ', steps || 0, calories || 0, activeMinutes || 0, goal || 10000, goalPercent);
    res.json({ insight, cached: false });
  }
});

function buildPrompt(name, steps, calories, activeMinutes, goal, goalPercent) {
  return `You are a friendly, motivational fitness coach inside a mobile app called FitTracker. 
Generate a SHORT personalized insight (2-3 lines maximum) for the user.

User data:
- Name: ${name}
- Steps today: ${steps}
- Goal: ${goal} steps
- Goal completion: ${goalPercent}%
- Calories burned: ${calories}
- Active minutes: ${activeMinutes}

Rules:
- If below 50% of goal → motivate them to get moving
- If 50-89% → encourage them, they're almost there
- If 90-100% → congratulate and suggest next steps
- If over 100% → celebrate the achievement
- Use their first name
- Include 1-2 relevant emojis
- Keep it conversational and warm
- Maximum 2-3 short sentences
- Do NOT use markdown formatting
- Do NOT include any prefixes like "Here's your insight:"`;
}

async function callGemini(apiKey, prompt, maxTokens = 200) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 15000); // 15s timeout

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.7,
          maxOutputTokens: maxTokens,
          topP: 0.9,
        },
      }),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      const errBody = await response.text();
      throw new Error(`Gemini API error (${response.status}): ${errBody}`);
    }

    const data = await response.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) throw new Error('Empty Gemini response');
    return text.trim();
  } catch (err) {
    clearTimeout(timeoutId);
    throw err;
  }
}

// Smart local fallback — no AI API needed
function generateLocalInsight(name, steps, calories, activeMinutes, goal, goalPercent) {
  const firstName = name.split(' ')[0];

  if (goalPercent >= 100) {
    const messages = [
      `🏆 Amazing ${firstName}! You crushed your ${goal.toLocaleString()} step goal today! ${calories} calories burned and ${activeMinutes} active minutes — you're on fire! Time to hydrate and recover 💧`,
      `🎉 ${firstName}, you did it! ${steps.toLocaleString()} steps today — that's ${goalPercent}% of your goal! Your consistency is inspiring. Rest well tonight 🌙`,
      `💪 Incredible work ${firstName}! Goal smashed with ${steps.toLocaleString()} steps! With ${activeMinutes} active minutes logged, you're building real momentum. Keep it up! 🔥`,
    ];
    return messages[Math.floor(Math.random() * messages.length)];
  }

  if (goalPercent >= 75) {
    const remaining = goal - steps;
    const messages = [
      `🔥 So close ${firstName}! You're at ${goalPercent}% — just ${remaining.toLocaleString()} steps to go. A quick 10-minute walk will get you there! Let's finish strong 💪`,
      `✨ Almost there ${firstName}! ${steps.toLocaleString()} steps and counting. ${remaining.toLocaleString()} more and you'll hit your goal. You've got this!`,
      `👏 Great progress ${firstName}! ${goalPercent}% done with ${calories} calories burned. A short evening walk is all you need to cross the finish line 🏁`,
    ];
    return messages[Math.floor(Math.random() * messages.length)];
  }

  if (goalPercent >= 50) {
    const remaining = goal - steps;
    const messages = [
      `👋 Hey ${firstName}! You're halfway there at ${goalPercent}%. ${remaining.toLocaleString()} steps to go — try taking the stairs or a walk break. You'll thank yourself later! 🚶`,
      `💫 Nice pace ${firstName}! ${steps.toLocaleString()} steps so far today. Keep moving and you can hit your goal by evening. Every step counts!`,
      `🎯 Solid effort ${firstName}! You've burned ${calories} cals in ${activeMinutes} minutes. Stay active this afternoon to reach your ${goal.toLocaleString()} step target 💪`,
    ];
    return messages[Math.floor(Math.random() * messages.length)];
  }

  if (goalPercent >= 10) {
    const messages = [
      `👋 Hey ${firstName}! You're at ${goalPercent}% of your goal. It's still early — a brisk 20-minute walk can add 2,000+ steps. Let's get moving! 🚀`,
      `☀️ Good start ${firstName}! ${steps.toLocaleString()} steps logged. Remember, every step counts toward your ${goal.toLocaleString()} goal. How about a walk break? 🌿`,
      `🌟 ${firstName}, your fitness journey continues! ${activeMinutes} active minutes so far. Try squeezing in a quick walk — small steps lead to big results!`,
    ];
    return messages[Math.floor(Math.random() * messages.length)];
  }

  // Under 10%
  const messages = [
    `👋 Hey ${firstName}! Today is a fresh start. Your ${goal.toLocaleString()} step goal is waiting — even a 5-minute walk makes a difference. Let's go! 💪`,
    `🌅 Rise and shine ${firstName}! Your body is ready to move. Start with a short walk and watch those steps add up throughout the day ✨`,
    `🎯 ${firstName}, every champion starts at zero! Lace up those shoes and take the first step toward your ${goal.toLocaleString()} goal today 🔥`,
  ];
  return messages[Math.floor(Math.random() * messages.length)];
}

// ─── AI Challenges Endpoint ───
const Challenge = require('../models/Challenge');

router.post('/ai-challenges', auth, async (req, res) => {
  try {
    const { steps, calories, activeMinutes, streak } = req.body;
    const apiKey = process.env.GEMINI_API_KEY;

    let challengesData = [];

    if (apiKey && apiKey !== 'YOUR_GEMINI_API_KEY_HERE') {
      const prompt = `Based on the user's data: steps=${steps}, calories=${calories}, activeMinutes=${activeMinutes}, streak=${streak}. 
Generate 3 personalized daily fitness challenges. 
Return ONLY a valid JSON array of objects (no markdown, no backticks). 
Format: [{"title": "Challenge Name", "description": "Short description", "target": numeric_target, "type": "steps|calories|activeMinutes", "reward": numeric_points}]`;

      const aiResponse = await callGemini(apiKey, prompt);
      try {
        challengesData = JSON.parse(aiResponse);
      } catch (e) {
        console.error('Failed to parse AI JSON:', aiResponse);
        throw new Error('Invalid JSON from AI');
      }
    } else {
      // Local fallback
      challengesData = [
        { title: `Walk ${steps + 2000} steps`, description: 'Push yourself a little further today!', target: steps + 2000, type: 'steps', reward: 50 },
        { title: `Burn ${calories + 100} kcal`, description: 'Stay active to burn more calories.', target: calories + 100, type: 'calories', reward: 40 },
        { title: `Active for ${activeMinutes + 10} min`, description: 'Keep your heart rate up.', target: activeMinutes + 10, type: 'activeMinutes', reward: 30 }
      ];
    }

    const createdChallenges = [];
    for (const c of challengesData) {
      const challenge = new Challenge({
        title: c.title,
        description: c.description,
        target: c.target,
        type: c.type,
        reward: c.reward,
        difficulty: 'moderate',
        durationDays: 1,
        participants: [{
          userId: req.user._id,
          userName: req.user.name || 'User',
          status: 'in_progress',
          progress: 0
        }]
      });
      await challenge.save();
      createdChallenges.push(challenge);
    }

    res.json({ challenges: createdChallenges });
  } catch (err) {
    console.error('❌ AI Challenges error:', err.message);
    res.status(500).json({ error: 'Failed to generate challenges' });
  }
});

// ─── AI Diet Recommendation Endpoint ───
router.post('/diet', auth, async (req, res) => {
  try {
    const { bmi, category, activity, steps, calories } = req.body;
    const apiKey = process.env.GEMINI_API_KEY;

    const bmiVal = parseFloat(bmi) || 22;
    const cat = category || 'Normal';
    const activeMin = parseInt(activity) || 0;

    let dietPlan;
    let summary = { calories: 2000, protein: 120 }; // Default

    // Calculate basic targets locally as backup/supplement
    if (cat === 'Weight Gain') {
      summary.calories = 2800;
      summary.protein = 160;
    } else if (cat === 'Fat Loss') {
      summary.calories = 1600;
      summary.protein = 130;
    } else if (cat === 'Obese') {
      summary.calories = 1400;
      summary.protein = 110;
    }

    if (apiKey && apiKey !== 'YOUR_GEMINI_API_KEY_HERE') {
      const prompt = `You are a certified nutritionist. Create a healthy 1-day meal plan for:
- BMI: ${bmiVal.toFixed(1)} (${cat})
- Active minutes today: ${activeMin}
- Steps today: ${steps || 0}
- Calories burned: ${calories || 0}

Return ONLY plain text (no markdown), exactly in this format:
Breakfast: [meal]
Lunch: [meal]
Dinner: [meal]
Snack: [meal]
Summary: [Calories] kcal, [Protein] g protein

Keep it realistic and healthy. No extra commentary.`;
      try {
        const rawResponse = await callGemini(apiKey, prompt, 300);
        dietPlan = rawResponse;
        
        // Try to parse summary from AI response if present
        const match = rawResponse.match(/Summary: (\d+) kcal, (\d+) g/);
        if (match) {
          summary.calories = parseInt(match[1]);
          summary.protein = parseInt(match[2]);
        }
      } catch (aiErr) {
        console.warn('Gemini failed for diet, using fallback:', aiErr.message);
        dietPlan = getFallbackDiet(cat);
      }
    } else {
      dietPlan = getFallbackDiet(cat);
    }
    res.json({ dietPlan, summary });
  } catch (err) {
    console.error('Diet endpoint error:', err.message);
    res.json({ dietPlan: 'Breakfast: Oatmeal with berries and nuts.\nLunch: Grilled chicken with mixed greens and quinoa.\nDinner: Baked salmon with steamed broccoli and brown rice.\nSnack: Greek yogurt with honey.' });
  }
});

function getFallbackDiet(category) {
  const plans = {
    'Underweight': [
      'Breakfast: Whole milk oatmeal with banana, peanut butter, and honey.\nLunch: Rice with grilled chicken, avocado, and beans.\nDinner: Pasta with meat sauce, olive oil, and parmesan.\nSnack: Mixed nuts and cheese.',
      'Breakfast: Scrambled eggs with cheese and avocado on toast.\nLunch: Beef burrito with extra rice and guacamole.\nDinner: Salmon with butter sauce and baked potato.\nSnack: Greek yogurt with honey and granola.'
    ],
    'Normal': [
      'Breakfast: Greek yogurt with granola, berries, and chia seeds.\nLunch: Grilled chicken salad with chickpeas, cucumber, and olive oil.\nDinner: Salmon with roasted sweet potato and steamed greens.\nSnack: Apple with almond butter.',
      'Breakfast: Scrambled eggs with spinach and feta on whole grain toast.\nLunch: Turkey and avocado wrap with a side of mixed nuts.\nDinner: Grilled lean steak with roasted broccoli and quinoa.\nSnack: Protein shake with a banana.',
      'Breakfast: Overnight oats with almond milk, blueberries, and walnuts.\nLunch: Quinoa bowl with roasted vegetables, tofu, and tahini dressing.\nDinner: Baked cod with asparagus and a small side of brown rice.\nSnack: Pear with a few cubes of low-fat cheese.',
      'Breakfast: Smoothie with spinach, protein powder, mango, and coconut water.\nLunch: Black bean soup with a side of whole grain bread.\nDinner: Stir-fried chicken with bell peppers, snap peas, and ginger.\nSnack: Handful of grapes and 5-6 almonds.'
    ],
    'Overweight': [
      'Breakfast: Egg white omelette with spinach and tomatoes.\nLunch: Large salad with tuna, lemon dressing, and no croutons.\nDinner: Grilled lean protein with steamed vegetables.\nSnack: Carrot sticks and hummus.',
      'Breakfast: Chia pudding with almond milk and a few berries.\nLunch: Grilled chicken breast with steamed asparagus and a small side of lentils.\nDinner: Baked white fish with lemon and sautéed zucchini.\nSnack: Sliced cucumber with a light dip.',
      'Breakfast: 1 slice of whole grain toast with 2 poached eggs.\nLunch: Roasted cauliflower and chickpea salad with lemon-herb dressing.\nDinner: Turkey meatballs with zucchini noodles and tomato sauce.\nSnack: A small orange.',
      'Breakfast: Low-fat Greek yogurt with a sprinkle of cinnamon and 3 walnuts.\nLunch: Lentil salad with diced peppers, onions, and parsley.\nDinner: Broiled chicken strips with a double portion of steamed spinach.\nSnack: Half a grapefruit.'
    ],
    'Obese': [
      'Breakfast: Vegetable omelette with 2 eggs and a small fruit.\nLunch: Large mixed salad with grilled chicken breast and vinaigrette.\nDinner: Steamed fish with cauliflower rice and green vegetables.\nSnack: Celery with low-fat cottage cheese.',
      'Breakfast: 1 boiled egg with half an avocado.\nLunch: Zucchini noodles with ground turkey and tomato sauce.\nDinner: Grilled shrimp with a large bowl of steamed spinach.\nSnack: A handful of raw almonds.',
      'Breakfast: Spinach and mushroom egg-white scramble.\nLunch: Steamed cabbage and chicken breast with ginger-soy dressing.\nDinner: Lean beef stir-fry with broccoli and green beans (no rice).\nSnack: 10 cherry tomatoes.'
    ],
  };
  const list = plans[category] || plans['Normal'];
  return list[Math.floor(Math.random() * list.length)];
}

// ─── Chat Endpoint ───

// POST /api/ai/chat — Conversational AI coach
router.post('/chat', auth, async (req, res) => {
  try {
    const { message, userData } = req.body;
    const { name, steps, calories, activeMinutes, goal } = userData || {};
    const goalPercent = goal > 0 ? Math.round((steps / goal) * 100) : 0;
    const firstName = (name || 'Champ').split(' ')[0];

    const apiKey = process.env.GEMINI_API_KEY;
    let reply;

    if (apiKey && apiKey !== 'YOUR_GEMINI_API_KEY_HERE') {
      const chatPrompt = buildChatPrompt(firstName, message, steps, calories, activeMinutes, goal, goalPercent);
      reply = await callGemini(apiKey, chatPrompt);
    } else {
      reply = generateLocalChatReply(firstName, message, steps, calories, activeMinutes, goal, goalPercent);
    }

    res.json({ reply });
  } catch (err) {
    console.error('❌ Chat error:', err.message);
    const { message, userData } = req.body;
    const firstName = ((userData?.name) || 'Champ').split(' ')[0];
    const goalPercent = (userData?.goal > 0) ? Math.round((userData?.steps / userData?.goal) * 100) : 0;
    const reply = generateLocalChatReply(firstName, message, userData?.steps || 0, userData?.calories || 0, userData?.activeMinutes || 0, userData?.goal || 10000, goalPercent);
    res.json({ reply });
  }
});

function buildChatPrompt(name, userMessage, steps, calories, activeMinutes, goal, goalPercent) {
  return `You are FitCoach, a friendly AI fitness assistant inside FitTracker app.
You are chatting with ${name}.

Their current fitness data:
- Steps: ${steps} / ${goal} (${goalPercent}%)
- Calories burned: ${calories}
- Active minutes: ${activeMinutes}

User says: "${userMessage}"

Rules:
- Reply in 2-3 short sentences MAX
- Be friendly, warm, and motivational
- Use 1-2 emojis naturally
- Reference their data when relevant
- If they ask about progress, use their actual numbers
- If they feel lazy/tired, be encouraging not pushy
- If they ask for workout tips, give specific short advice
- Do NOT use markdown
- Do NOT start with "Sure!" or "Of course!"
- Sound natural like a friendly coach texting them`;
}

// Smart local chat fallback
function generateLocalChatReply(name, message, steps, calories, activeMinutes, goal, goalPercent) {
  const msg = message.toLowerCase();
  const firstName = name.split(' ')[0];
  const remainingSteps = Math.max(0, goal - steps);

  // 1. Progress & Analysis
  if (msg.includes('how am i') || msg.includes('my progress') || msg.includes('status') || msg.includes('doing')) {
    if (goalPercent >= 100) {
      return `🏆 Outstanding work, ${firstName}! You've smashed your goal with ${steps.toLocaleString()} steps today. That's ${goalPercent}% completion! With ${calories} calories burned, you've earned some quality recovery time. I suggest some light stretching and extra hydration tonight 💧.`;
    }
    if (goalPercent >= 75) {
      return `🔥 You're in the home stretch, ${firstName}! You've hit ${goalPercent}% of your target. Only ${remainingSteps.toLocaleString()} steps to go. A quick 10-minute brisk walk after your next meal will seal the deal. Let's finish this day strong! 💪`;
    }
    if (goalPercent >= 40) {
      return `📈 Solid momentum, ${firstName}. You're at ${goalPercent}% (${steps.toLocaleString()} steps). To hit your goal of ${goal.toLocaleString()}, you need to pick up the pace this afternoon. Try taking the stairs or a longer route for your next move. You've got this! ⚡`;
    }
    return `👋 Hey ${firstName}, we've got some work to do! You're currently at ${goalPercent}% of your goal. Your body is built for movement—try to squeeze in a 20-minute walk now to get those numbers moving. Even small bursts of activity count! 🚀`;
  }

  // 2. Motivation & Mindset
  if (msg.includes('motivat') || msg.includes('inspire') || msg.includes('push') || msg.includes('lazy')) {
    const motivations = [
      `${firstName}, motivation is what gets you started, but habit is what keeps you going. Even if you don't feel like it, just commit to 5 minutes of movement. Once the blood starts flowing, you'll feel like a different person! ⚡`,
      `Remember why you started this journey, ${firstName}. Every step is a vote for the person you want to become. Don't let a temporary feeling of laziness stop your long-term progress. Stand up, take a deep breath, and let's go! 🦁`,
      `The only bad workout is the one that didn't happen. ${firstName}, you have ${activeMinutes} active minutes so far—let's double that! Your future self will thank you for the effort you put in right now. 💪`,
    ];
    return motivations[Math.floor(Math.random() * motivations.length)];
  }

  // 3. Specific Workout Advice
  if (msg.includes('workout') || msg.includes('exercise') || msg.includes('what should i do')) {
    if (activeMinutes < 10) {
      return `Since you're just starting your activity today, ${firstName}, let's go with a 'Power Circuit': 20 Jumping Jacks, 15 Bodyweight Squats, and 10 Push-ups. Repeat this 3 times for a quick metabolic boost! 🔥`;
    }
    return `Great energy, ${firstName}! Since you've already logged ${activeMinutes} minutes, let's focus on 'Functional Strength': Try 3 sets of Lunges (12 per leg), a 45-second Plank, and 15 Glute Bridges. This will build core stability and leg power. 🏋️‍♂️`;
  }

  // 4. Nutrition & Diet
  if (msg.includes('diet') || msg.includes('eat') || msg.includes('food') || msg.includes('nutrition') || msg.includes('plan')) {
    const advice = [
      `With ${calories} calories burned today, focus on 'High-Octane' fuel, ${firstName}. Prioritize lean protein (like chicken, lentils, or eggs) and complex carbs (brown rice or sweet potato). And don't forget your greens! 🥗`,
      `${firstName}, consistency in the kitchen is 70% of the battle. Aim for a balanced plate: 1/2 vegetables, 1/4 protein, and 1/4 healthy grains. Also, make sure you're drinking at least 2-3 liters of water today 💧.`,
    ];
    return advice[Math.floor(Math.random() * advice.length)];
  }

  // 5. Greetings & Defaults
  if (msg.includes('hello') || msg.includes('hi') || msg.includes('hey')) {
    return `Hello ${firstName}! 👋 Your AI Coach is online. You've logged ${steps.toLocaleString()} steps today (${goalPercent}% of your goal). What can I help you with—a workout plan, some motivation, or a diet check?`;
  }

  return `I hear you, ${firstName}. Based on your current stats (${steps.toLocaleString()} steps and ${activeMinutes} active minutes), my best advice is to keep the momentum high. If you have a specific question about your training or nutrition, just ask! 🤖💪`;
}

module.exports = router;
