# Supabase Database Schema

This document describes the current structure of the Supabase database for the Ridewealth Assistant project.

---

## Table: `users`
| Column                  | Type         | Description                |
|-------------------------|--------------|----------------------------|
| id                      | uuid         | Primary key                |
| email                   | text         | User email                 |
| last_login              | timestamptz  | Last login timestamp       |
| name                    | text         | User's name                |
| phone                   | text         | User's phone number        |
| address                 | text         | User's address             |
| city                    | text         | User's city                |
| state                   | text         | User's state               |
| zip                     | text         | User's zip code            |
| subscription_start_date | timestamptz  | Subscription start date    |
| created_at              | timestamptz  | Row creation timestamp     |
| subscription_status     | text         | Subscription status (active/inactive/cancelled) |
| subscription_type       | text         | Type of subscription (monthly/yearly) |
| subscription_expiry     | timestamptz  | Subscription expiration date |
| subscription_will_renew | boolean      | Whether subscription will auto-renew |
| subscription_platform   | text         | Platform (ios/android) |
| subscription_id         | text         | RevenueCat subscription ID |
| is_subscribed           | boolean      | Whether user has active subscription |
| subscription_end_date   | timestamptz  | Alternative subscription end date |
| last_updated            | timestamptz  | Last update timestamp |

---

## Table: `expenses`
| Column      | Type         | Description                |
|-------------|--------------|----------------------------|
| (see Supabase for details) |

---

## Table: `income`
| Column      | Type         | Description                |
|-------------|--------------|----------------------------|
| (see Supabase for details) |

---

## Table: `mileage`
| Column      | Type         | Description                |
|-------------|--------------|----------------------------|
| (see Supabase for details) |

---

## Table: `feature_flags`
| Column      | Type         | Description                |
|-------------|--------------|----------------------------|
| subscriptions_enabled   | boolean      | Whether subscriptions are enabled |
| subscription_check_enabled | boolean   | Whether subscription checks are enabled |
| subscription_required_screen_enabled | boolean | Whether subscription required screen is shown |
| store_redirect_enabled  | boolean      | Whether store redirect is enabled |

---

> **Note:**
> - This schema is based on the current Supabase dashboard and codebase.
> - Update this file whenever you change the database structure.
> - For full column details on `expenses`, `income`, and `mileage`, refer to the Supabase dashboard or update this file with the exact columns and types. 
>
> blah