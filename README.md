# FitTracker

> A modern, full-stack fitness and wellness tracking application featuring dedicated User and Admin roles, real-time activity metrics, AI-driven coaching, and community gamification.

Built with a **Flutter** cross-platform mobile frontend and a **Node.js + Express + MongoDB** backend API, integrated with **Google Gemini AI**, the **Wger Exercise Database**, and the **CalorieNinjas Nutrition API**.

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
  - [User Features](#user-features)
  - [Admin Features](#admin-features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Installation & Setup](#installation--setup)
  - [1. Backend Setup](#1-backend-setup)
  - [2. Frontend Setup (Flutter)](#2-frontend-setup-flutter)
- [Environment Variables & Configuration](#environment-variables--configuration)
  - [Backend Configuration (`backend/.env`)](#backend-configuration-backendenv)
  - [Frontend Configuration (`lib/services/api_config.dart`)](#frontend-configuration-libservicesapi_configdart)
- [Running the Application](#running-the-application)
- [Testing & Quality](#testing--quality)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [Helpful Resources](#helpful-resources)

---

## Overview

FitTracker is designed to provide users with a complete fitness companion while offering administrators full control over platform operations, user management, and reward systems.

- **Frontend:** Responsive Flutter application with Riverpod state management, offline caching, local notifications, biometric authentication, and a high-contrast dark/light cyberpunk neon aesthetic.
- **Backend:** Modular Express.js REST API with Mongoose ODM, JWT authentication, automated `node-cron` reminders, Nodemailer transactional email delivery, and PDF report generation.
- **AI Engine:** Google Gemini integration for conversational fitness coaching, automated diet suggestions, and dynamic challenge generation.

---

## Key Features

### User Features

- **Activity & Step Tracking:** Real-time pedometer sensor integration (`pedometer`) tracking daily steps, distance, active minutes, and calories burned with automatic midnight resets.
- **Health Metrics & BMI Tracking:** Interactive BMI calculator with category classifications, historical logs, hydration tracking, and trend charts powered by `fl_chart`.
- **Workout Logging & Exercise Database:** Custom workout session logging (duration, sets, reps, weight) integrated with the open-source **Wger API** to search exercises by category, target muscles, and equipment.
- **Nutrition & Meal Tracking:** Daily macro logging (calories, carbs, protein, fat, water) with real-time food nutritional lookups via the **CalorieNinjas API**.
- **AI Fitness Coach:** Powered by **Google Gemini** to deliver personalized daily insights, AI-crafted diet plans, tailored fitness challenges, and interactive chat assistance.
- **Gamification & Rewards:** Earn points through workout duration and streak bonuses; progress across Bronze, Silver, and Gold tiers; redeem points in the built-in reward store.
- **Community & Social Feed:** Share completed workouts, view community feeds, interact with likes, and compete on the global leaderboard.
- **Authentication & Security:** Email/password login with OTP verification, secure password reset, JWT token sessions, and Biometric Authentication (Fingerprint & Face ID via `local_auth` and `flutter_secure_storage`).
- **Offline Resilience:** Local workout queuing during network dropouts with automatic synchronization upon reconnecting.
- **Health Reports & Reminders:** Scheduled local reminders for workouts and hydration, plus downloadable PDF health reports.

### Admin Features

- **Executive Analytics Dashboard:** Real-time platform metrics, daily workout tallies, active/online user counts, and system activity logs.
- **User Management:** Search and filter registered users, adjust points balances, toggle account statuses (active/suspended), and manage account deletions.
- **Challenge Management:** Create, configure, monitor, and delete global fitness challenges.
- **Points & Tier Configuration:** Configure dynamic points per minute, streak multipliers, daily earning limits, and unlock criteria for membership tiers.
- **AI Broadcast Communication:** Compose and dispatch system announcements and AI-assisted broadcast emails to all active users.
- **Support Ticket Desk:** Manage user-submitted support inquiries, update issue states (`Pending`, `Under Inspection`, `Resolved`), and trigger automated user email updates.

---

## Tech Stack

| Layer | Technologies |
| :--- | :--- |
| **Mobile Frontend** | Flutter (Dart SDK `^3.7.0`), Flutter Riverpod, GoRouter, `fl_chart`, `google_fonts` |
| **Native Device APIs** | `pedometer`, `geolocator`, `local_auth`, `flutter_secure_storage`, `flutter_local_notifications` |
| **Backend API** | Node.js (v18+), Express.js, Mongoose ODM |
| **Database** | MongoDB / MongoDB Atlas |
| **Authentication** | JSON Web Tokens (`jsonwebtoken`), `bcryptjs`, Biometrics |
| **Scheduling & Email** | `node-cron`, Nodemailer |
| **External APIs** | Google Gemini API (`gemini-2.0-flash`), Wger Workout API, CalorieNinjas API |

---

## Prerequisites

Before getting started, make sure you have the following installed on your machine:

- **Flutter SDK:** Version `3.7.0` or higher ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Dart SDK:** Included with Flutter
- **Node.js:** Version `18.0.0` or higher ([Download Node.js](https://nodejs.org/))
- **MongoDB:** A running local MongoDB instance or a free [MongoDB Atlas](https://www.mongodb.com/atlas) cluster
- **Platform Tooling:**
  - Android Studio (with Android SDK & emulator) for Android development
  - Xcode (macOS only) for iOS development
  - Google Chrome for Flutter Web testing

---

## Installation & Setup

### 1. Backend Setup

1. Open your terminal and navigate to the backend directory:
   ```bash
   cd Fit-Tracker/backend
   ```

2. Install Node.js dependencies:
   ```bash
   npm install
   ```

3. Create your environment configuration file:
   ```bash
   cp .env.example .env
   ```
   *(On Windows PowerShell, use: `Copy-Item .env.example .env`)*

4. Open `.env` and fill in your database URI, JWT secret, and API keys (see [Environment Variables](#environment-variables--configuration)).

5. Start the backend server:
   ```bash
   npm run dev
   ```
   *The server runs by default on `http://localhost:3000`. You can verify it by opening `http://localhost:3000/api/health` in your browser.*

---

### 2. Frontend Setup (Flutter)

1. Open a new terminal and navigate to the Flutter project root:
   ```bash
   cd Fit-Tracker
   ```

2. Install the required Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Configure the backend connection endpoint in `lib/services/api_config.dart`:
   - **Chrome / Desktop:** `'http://localhost:3000/api'`
   - **Android Emulator:** `'http://10.0.2.2:3000/api'`
   - **Physical Mobile Device:** `'http://<YOUR_COMPUTER_LOCAL_IP>:3000/api'` *(both device and PC must be on the same Wi-Fi network)*

4. *(Optional)* Add your free CalorieNinjas API key to `ApiConfig.calorieNinjasApiKey` in `lib/services/api_config.dart` for food nutrition queries.

---

## Environment Variables & Configuration

### Backend Configuration (`backend/.env`)

| Variable | Description | Required | Default |
| :--- | :--- | :---: | :--- |
| `PORT` | Port number on which the Express server listens | No | `3000` |
| `MONGODB_URI` | MongoDB connection string (Atlas or local) | **Yes** | — |
| `JWT_SECRET` | Secret key used for signing and verifying JWT tokens | **Yes** | — |
| `GEMINI_API_KEY` | Google Gemini API key for AI coaching, challenges, and insights | Optional | Local fallback used if omitted |
| `EMAIL_SERVICE` | Nodemailer service provider (e.g., `gmail`) | No | `gmail` |
| `EMAIL_USER` | Email address used to send verification and reminder emails | Optional | — |
| `EMAIL_PASS` | App-specific password for the email provider | Optional | — |

### Frontend Configuration (`lib/services/api_config.dart`)

```dart
class ApiConfig {
  // Target backend endpoint:
  // - Android Emulator: 'http://10.0.2.2:3000/api'
  // - Desktop/Web:      'http://localhost:3000/api'
  // - Physical Device:  'http://<YOUR_LOCAL_IP>:3000/api'
  static const String backendUrl = 'http://localhost:3000/api';

  // CalorieNinjas API key from https://api-ninjas.com/
  static const String calorieNinjasApiKey = 'YOUR_API_KEY_HERE';
}
```

---

## Running the Application

### Start the Backend

```bash
cd Fit-Tracker/backend
npm start
```

### Run the Flutter App

Ensure a device, emulator, or browser is available:

```bash
cd Fit-Tracker

# Check available devices
flutter devices

# Run on the default connected device
flutter run

# Or launch specifically for Chrome / Windows
flutter run -d chrome
flutter run -d windows
```

---

## Testing & Quality

FitTracker includes a comprehensive automated test suite covering authentication flows, biometric authentication, sensor fallbacks, reminder scheduling, admin features, charts, and offline synchronization:

### Run All Unit and Widget Tests

```bash
cd Fit-Tracker
flutter test
```

### Run Specific Test Suites

```bash
# Run core test suite (TC_001 through TC_038)
flutter test test/fit_tracker_test.dart

# Run widget smoke test
flutter test test/widget_test.dart
```

### Static Analysis

To run Dart and Flutter static analysis against `analysis_options.yaml`:

```bash
flutter analyze
```

---

## Project Structure

```text
FitTracker/
└── Fit-Tracker/
    ├── android/                  # Android native project and manifest configuration
    ├── ios/                      # iOS native project and permissions
    ├── web/                      # Flutter web support files
    ├── windows/                  # Windows desktop support files
    ├── backend/                  # Node.js + Express backend
    │   ├── middleware/           # JWT and role-based authorization middleware
    │   ├── models/               # Mongoose schemas (User, Workout, Challenge, etc.)
    │   ├── routes/               # API routes (auth, admin, ai, workouts, etc.)
    │   ├── services/             # Background services (activity logging, email)
    │   ├── cron.js               # Scheduled cron jobs for hydration & workouts
    │   ├── package.json          # Node.js dependencies and scripts
    │   └── server.js             # Express application entry point
    ├── lib/                      # Flutter application source code
    │   ├── admin/                # Admin portal screens (dashboard, analytics, users)
    │   ├── controllers/          # Riverpod state controllers (auth, user, ai, etc.)
    │   ├── core/                 # Constants, theme definitions, login screen
    │   ├── models/               # Client-side data models
    │   ├── services/             # Client services (API config, biometric, health, etc.)
    │   ├── user/                 # User portal screens (home, workout, nutrition, AI)
    │   ├── widgets/              # Reusable UI components (neon buttons, cards, grids)
    │   └── main.dart             # Flutter app entry point & routing
    ├── test/                     # Unit, widget, and integration test suite
    │   ├── fit_tracker_test.dart # Comprehensive test suite (TC_001 to TC_038)
    │   └── widget_test.dart      # App smoke test
    ├── pubspec.yaml              # Flutter dependencies and asset configuration
    └── README.md                 # Project documentation
```

---

## Contributing

1. Fork the repository and create a new feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Ensure existing tests pass and adhere to the project's linting rules:
   ```bash
   flutter analyze
   flutter test
   ```
3. Commit your changes with clear, descriptive commit messages:
   ```bash
   git commit -m "feat: add water intake milestone notifications"
   ```
4. Push your branch and open a Pull Request.

---

## Helpful Resources

For developers new to Flutter or looking to expand their knowledge:

- [Flutter Documentation](https://docs.flutter.dev/) — Tutorials, samples, and API references
- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter) — Getting started guide
- [Write Your First Flutter App](https://docs.flutter.dev/get-started/codelab) — Hands-on codelab
- [Flutter Riverpod Documentation](https://riverpod.dev/) — State management guide
- [MongoDB Atlas Documentation](https://www.mongodb.com/docs/atlas/) — Database setup guide
- [Google Gemini API Documentation](https://ai.google.dev/docs) — Generative AI documentation
