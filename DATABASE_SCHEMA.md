# Supabase Database Schema

This document describes the current structure of the Supabase database for the Ridewealth Assistant project.

---

## Table: `auth.users` (Supabase Auth)
| Column                  | Type         | Description                |
|-------------------------|--------------|----------------------------|
| id                      | uuid         | Primary key (auth users)  |
| instance_id             | uuid         | Instance identifier        |
| aud                     | varchar      | Audience                   |
| role                    | varchar      | User role                  |
| email                   | varchar      | User email                 |
| encrypted_password      | varchar      | Encrypted password         |
| email_confirmed_at      | timestamptz  | Email confirmation time    |
| invited_at              | timestamptz  | Invitation timestamp       |
| confirmation_token      | varchar      | Email confirmation token  |
| confirmation_sent_at    | timestamptz  | Confirmation sent time     |
| recovery_token          | varchar      | Password recovery token   |
| recovery_sent_at        | timestamptz  | Recovery sent time         |
| email_change_token_new  | varchar      | New email change token     |
| email_change            | varchar      | New email address          |
| email_change_sent_at    | timestamptz  | Email change sent time    |
| last_sign_in_at         | timestamptz  | Last sign in timestamp    |
| raw_app_meta_data       | jsonb        | App metadata               |
| raw_user_meta_data      | jsonb        | User metadata              |
| is_super_admin          | boolean      | Super admin flag           |
| created_at              | timestamptz  | Row creation timestamp     |
| updated_at              | timestamptz  | Last update timestamp      |
| phone                   | text         | User's phone number        |
| phone_confirmed_at      | timestamptz  | Phone confirmation time    |
| phone_change            | text         | New phone number           |
| phone_change_token      | varchar      | Phone change token         |
| phone_change_sent_at    | timestamptz  | Phone change sent time    |
| confirmed_at            | timestamptz  | Account confirmation time |
| email_change_token_current | varchar   | Current email change token |
| email_change_confirm_status | smallint | Email change status       |
| banned_until            | timestamptz  | Ban expiration time        |
| reauthentication_token  | varchar      | Reauthentication token     |
| reauthentication_sent_at | timestamptz | Reauthentication sent time |
| is_sso_user             | boolean      | SSO user flag              |
| deleted_at              | timestamptz  | Deletion timestamp         |
| is_anonymous             | boolean      | Anonymous user flag        |

## Table: `users` (Custom User Data)
| Column                  | Type         | Description                |
|-------------------------|--------------|----------------------------|
| id                      | text         | Primary key (references auth.users.id) |
| first_name              | text         | User's first name          |
| last_name               | text         | User's last name           |
| membership_number       | integer      | Membership number          |
| council_number          | integer      | Council number             |
| assembly_number         | integer      | Assembly number            |
| jurisdiction            | text         | User's jurisdiction       |
| council_roles           | array        | Council roles array        |
| assembly_roles          | array        | Assembly roles array       |
| email                   | varchar      | User email                 |
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

## Table: `error_tracking`
| Column                  | Type         | Description                |
|-------------------------|--------------|----------------------------|
| id                      | uuid         | Primary key                |
| error_type              | text         | Error type (authentication/database/ui/general) |
| error_message           | text         | Error message              |
| stack_trace             | text         | Stack trace (optional)     |
| user_id                 | uuid         | User ID (references auth.users.id) |
| platform                | text         | Platform (android/ios/web/etc) |
| app_version             | text         | App version (auto-extracted) |
| device_info             | jsonb        | Device/platform information |
| context                 | jsonb        | Additional context data   |
| tags                    | jsonb        | Error tags for categorization |
| created_at              | timestamptz  | Error occurrence timestamp |
| resolved_at             | timestamptz  | Resolution timestamp (optional) |
| resolved_by             | uuid         | Who resolved it (optional) |
| resolution_notes        | text         | Resolution notes (optional) |

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