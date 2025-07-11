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

> **Note:**
> - This schema is based on the current Supabase dashboard and codebase.
> - Update this file whenever you change the database structure.
> - For full column details on `expenses`, `income`, and `mileage`, refer to the Supabase dashboard or update this file with the exact columns and types. 