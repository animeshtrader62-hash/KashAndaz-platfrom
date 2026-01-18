# KashAndaz - Cashback & Affiliate Platform

**Status:** ✅ Frontend MVP Complete

## Project Description
This project is a frontend MVP of the KashAndaz platform built in Flutter.
It demonstrates the complete UI flow, screen architecture, and user experience using mock data.
Backend APIs, authentication, and real transaction logic are intentionally not implemented yet and will be integrated in the next phase.

## Quick Start
```bash
flutter pub get
flutter run -d chrome    # Web testing
flutter run -d android   # Android device
flutter build apk        # Production APK
```

## Features
✅ Auth (Login/Signup with validation)  
✅ Dashboard (Wallet summary + Top stores)  
✅ Transactions (History with filters + Detail view)  
✅ Wallet (Balance + Withdrawal with min ₹50)  
✅ Profile (Settings + Logout)  
✅ Shimmer loaders + Page transitions  

## Tech Stack
- Flutter 3.38.5 | Riverpod 2.6.1 | Dio 5.9.0
- Secure storage | Mock data fallback
- Feature-based architecture

## Structure
```
lib/
├── core/        # Theme, API, Storage, Utils
├── features/    # Auth, Home, Stores, Transactions, Wallet, Profile
└── main.dart
```

## API Setup
Update `lib/core/utils/constants.dart` with your backend URL. Currently uses mock data.

## Build Production
```bash
flutter build apk --release                    # APK
flutter build appbundle --release              # App Bundle (Play Store)
```
Output: `build/app/outputs/`

## Code Quality
- ✅ 0 errors (flutter analyze)
- ✅ Clean architecture
- ✅ Phase-gated development (Day 1-45 complete)
