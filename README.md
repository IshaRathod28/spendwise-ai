# SpendWise AI 💰🤖

AI-powered expense tracking app with Ruby on Rails API backend and Flutter mobile frontend.

## ✨ Features

- 🤖 **AI Categorization** - Automatic expense categorization using OpenAI GPT-4o-mini
- 📸 **Screenshot Analysis** - Extract transaction details from payment screenshots
- 📊 **Smart Analytics** - Stock market-style charts and category breakdowns
- 🎯 **Smart Filters** - Today, This Week, This Month, or custom date ranges
- 🎉 **Motivational UI** - Celebrate zero-spending days

## 🏗️ Structure

```
spendwise-ai/
├── backend/    # Rails 7.1.6 API (Ruby 3.3.3)
└── mobile/     # Flutter 3.24.5 App (Dart 3.5.0)
```

## 🚀 Quick Start

### Backend Setup

```bash
cd backend
bundle install
cp .env.example .env  # Add your OpenAI API key
rails db:create db:migrate db:seed
rails server -b 0.0.0.0 -p 3000
```

### Mobile Setup

```bash
cd mobile
flutter pub get
# Update API URL in lib/services/transaction_provider.dart
flutter run -d DEVICE_ID
```

## 🔧 Prerequisites

**Backend:** Ruby 3.3.3, Rails 7.1.6, SQLite3, OpenAI API Key  
**Mobile:** Flutter 3.24.5+, Dart 3.5.0+, Android SDK 34, Java 17

## 📚 API Endpoints

```
GET    /api/v1/transactions       # List all transactions (with pagination)
GET    /api/v1/transactions/:id   # Get single transaction
POST   /api/v1/transactions       # Create transaction (supports file upload)
PATCH  /api/v1/transactions/:id   # Update transaction
DELETE /api/v1/transactions/:id   # Delete transaction
```

## 🎨 Categories

🍔 Food & Dining • 🚗 Transportation • 🛍️ Shopping • 🥦 Groceries  
⚡ Utilities • 🎬 Entertainment • 🏥 Healthcare • 📚 Education  
🏠 Rent • 👤 Personal • 📦 Other

## 🛠️ Tech Stack

**Backend:** Rails 7.1.6 (API-only) • SQLite3 • OpenAI GPT-4o-mini • Active Storage • Puma  
**Mobile:** Flutter 3.24.5 • Provider • FL Chart • http • image_picker

## 📦 Build Release

```bash
# Backend (Docker)
docker build -t spendwise-backend .
docker run -p 3000:3000 spendwise-backend

# Mobile (APK)
cd mobile && flutter build apk --release
```

## 👨‍💻 Author

**Isha Rathod** - [@IshaRathod28](https://github.com/IshaRathod28)

## �� License

MIT License - Open source and free to use

---

Made with ❤️ using Ruby on Rails & Flutter
