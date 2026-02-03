# RideWealth Assistant

A comprehensive financial management app for rideshare and gig drivers to track income, expenses, mileage, and estimate taxes.

## Overview

RideWealth Assistant helps independent contractors manage their ride-share or delivery business finances. Whether you're driving for Uber, Lyft, DoorDash, or any other gig platform, this app provides the tools you need to stay organized and tax-ready.

## Features

### Income Tracking
- Record income from multiple sources (rideshare, delivery, tips, bonuses)
- Add descriptions and notes for each income entry
- View income history sorted by date
- Edit or delete previous entries

### Expense Tracking
- Categorize expenses using standard business categories (car expenses, supplies, meals, insurance, etc.)
- Track business-related expenditures
- Add descriptions and notes
- Full CRUD operations on expense records

### Mileage Tracking
- Log trip mileage with start and end odometer readings
- Automatically calculates mileage deductions using IRS rates
- Tracks mileage by date
- Remembers last end mileage as next start mileage

### Tax Estimates
- Calculate quarterly and annual tax estimates
- Uses configurable federal and state tax rates
- Applies IRS mileage deduction rates automatically
- Shows profit calculations (income - expenses - mileage deductions)
- Supports custom mileage rates

### Data Export
- Export all financial data to CSV format
- Filter by year
- Export income, expenses, and mileage records separately
- Downloadable files for tax preparation or record-keeping

### User Management
- Secure authentication via Google or Apple Sign-In
- User profiles with customizable display names
- Subscription management
- Account settings and preferences

## Technical Stack

- **Framework**: Flutter (Dart)
- **Backend**: Supabase (PostgreSQL database, authentication)
- **Subscription Management**: RevenueCat
- **In-App Purchases**: Native iOS and Android IAP
- **State Management**: Provider
- **Error Tracking**: Custom error tracking service
- **Authentication**: Supabase Auth with OAuth (Google/Apple)

## Requirements

- Flutter SDK >= 3.4.0
- Dart SDK >= 3.4.0
- iOS 13.0+ / Android (API 21+)
- Supabase project with configured database tables
- RevenueCat account for subscription management

## Setup

### Prerequisites

1. Clone the repository
2. Create a `env.json` file in the root directory with the following structure:
```json
{
  "supabaseUrl": "your-supabase-url",
  "supabaseKey": "your-supabase-anon-key"
}
```

3. Set up Supabase:
   - Create tables for `users`, `income`, `expenses`, and `mileage`
   - Configure authentication providers (Google, Apple)
   - Set up Row Level Security (RLS) policies

4. Configure RevenueCat:
   - Set up products and subscription offerings
   - Configure iOS App Store and Google Play integrations

### Installation

```bash
flutter pub get
```

### Run

```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Web
flutter run -d chrome --web-port=5000
```

## Database Schema

The app requires the following Supabase tables:

- **users**: User profile information
- **income**: Income records with date, amount, source, description, notes
- **expenses**: Expense records with date, amount, category, description, notes
- **mileage**: Mileage records with start_date, start_mileage, end_mileage, notes

## Subscription Model

The app uses a subscription-based model managed through RevenueCat:
- Requires active subscription or trial to access features
- Free trial support
- Cross-platform subscription management (iOS/Android)

## Platform Support

- iOS (13.0+)
- Android (API 21+)
- Web (with limitations)

## Development

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── authmethod.dart          # Authentication methods
├── environment.dart         # Environment variable loader
├── screens/                 # UI screens
│   ├── home_screen.dart
│   ├── income_screen.dart
│   ├── expenses_screen.dart
│   ├── mileage_screen.dart
│   ├── tax_estimates.dart
│   ├── export_screen.dart
│   └── user_screen.dart
├── services/                # Business logic services
├── theme/                   # App theming
└── mileage_rates.dart      # IRS mileage rate data
```

## Build

### iOS
```bash
flutter build ipa
```

### Android
```bash
flutter build appbundle
```

### Codemagic / CI (Android release)

The app bakes Supabase and Sentry config at build time via `--dart-define`. Set these **environment variables** in Codemagic (or your CI), then pass them into the build:

- `SUPABASE_URL` – Supabase project URL
- `SUPABASE_ANON_PUBLIC` – Supabase anon/public key
- `SENTRY_DSN` – Sentry DSN (optional; omit or leave empty to disable Sentry)

**Android build arguments** (single line):

```bash
--release --dart-define=SUPABASE_URL="$SUPABASE_URL" --dart-define=SUPABASE_ANON_PUBLIC="$SUPABASE_ANON_PUBLIC" --dart-define=SENTRY_DSN="$SENTRY_DSN"
```

## License

Private - All rights reserved
