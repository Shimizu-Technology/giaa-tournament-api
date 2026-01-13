# GIAA Tournament API

Rails API backend for the Golf Tournament Registration System. Supports multiple tournaments with full registration, check-in, group management, payment processing, employee discounts, and refunds.

## Prerequisites

- **Ruby 3.3.4** (use [rbenv](https://github.com/rbenv/rbenv) or [asdf](https://asdf-vm.com/))
- **PostgreSQL 14+** (install via Homebrew: `brew install postgresql@16`)
- **Bundler** (`gem install bundler`)

## Tech Stack

- **Ruby on Rails 8.1** (API mode)
- **PostgreSQL** (database)
- **Clerk** (authentication via JWT)
- **Resend** (email delivery)
- **Stripe** (payment processing with embedded checkout)
- **ActionCable** (WebSocket real-time updates)

## Quick Start

```bash
# 1. Clone and enter the directory
cd giaa-tournament-api

# 2. Install Ruby dependencies
bundle install

# 3. Create .env file
cp .env.example .env
# Edit .env with your Clerk JWKS URL and other keys

# 4. Setup database
rails db:create
rails db:migrate
rails db:seed

# 5. Start the server
rails s
```

The API will be available at `http://localhost:3000`

## Environment Variables

Create a `.env` file in the root directory:

```env
# Clerk Authentication (required)
CLERK_JWKS_URL=https://your-clerk-instance.clerk.accounts.dev/.well-known/jwks.json

# Resend Email (required for emails)
RESEND_API_KEY=re_xxxxxxxxxxxxx
MAILER_FROM_EMAIL=noreply@yourdomain.com

# Frontend URL (required for CORS and Stripe redirects)
FRONTEND_URL=http://localhost:5173

# Stripe (optional - configure in Admin Settings)
# STRIPE_SECRET_KEY and STRIPE_PUBLIC_KEY can be set in Admin Settings UI
```

## How It Works

### Multi-Tournament System

Each tournament has its own:
- Golfers (registrations)
- Groups (foursomes)
- Activity logs
- Employee numbers (for discounts)
- Settings (capacity, entry fee, reserved slots, dates)

Tournament statuses:
- **Draft** - Not yet open for registration
- **Open** - Accepting registrations
- **Closed** - Registration closed but not archived
- **Archived** - Historical, read-only

### Key Features

| Feature | Description |
|---------|-------------|
| **Registration** | Public multi-step form with automatic waitlist |
| **Stripe Payments** | Embedded checkout modal with card capture |
| **Payment Links** | Admin sends payment link email, golfer pays via unique URL |
| **Employee Discounts** | Admin-managed employee numbers for reduced rate |
| **Reserved Slots** | Block capacity for sponsors/VIPs |
| **Cancel/Refund** | Full refund processing with Stripe integration |
| **Race Condition Protection** | Database row-locking prevents duplicate payments |
| **Auto Group Removal** | Cancelled/waitlisted golfers auto-removed from groups |
| **Real-time Updates** | ActionCable broadcasts changes to admin dashboards |

### Key Models

| Model | Description |
|-------|-------------|
| `Tournament` | Tournament with settings, dates, capacity, reserved slots |
| `Golfer` | Registered player with payment/check-in status |
| `Group` | Foursome with hole assignment |
| `Admin` | Whitelisted admin user (linked to Clerk) |
| `Setting` | Global settings (Stripe keys, payment mode) |
| `EmployeeNumber` | Valid employee numbers for discounts |
| `ActivityLog` | Audit trail of all admin actions |

## API Endpoints

### Public (No Auth)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/tournaments/current` | Get current open tournament |
| GET | `/api/v1/golfers/registration_status` | Registration capacity & tournament info |
| POST | `/api/v1/golfers` | Register a new golfer |
| POST | `/api/v1/checkout/embedded` | Create Stripe embedded checkout session |
| POST | `/api/v1/checkout/confirm` | Confirm payment and create golfer |
| POST | `/api/v1/employee_numbers/validate` | Validate employee number |
| GET | `/api/v1/payment_links/:token` | Get golfer info for payment link |
| POST | `/api/v1/payment_links/:token/checkout` | Create checkout session for payment link |

### Protected (Clerk JWT Required)

#### Tournaments
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/tournaments` | List all tournaments |
| POST | `/api/v1/tournaments` | Create tournament |
| PATCH | `/api/v1/tournaments/:id` | Update tournament |
| POST | `/api/v1/tournaments/:id/archive` | Archive tournament |
| POST | `/api/v1/tournaments/:id/copy` | Copy for next year |
| POST | `/api/v1/tournaments/:id/open_registration` | Open registration |
| POST | `/api/v1/tournaments/:id/close_registration` | Close registration |

#### Golfers
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/golfers` | List golfers (with filters) |
| GET | `/api/v1/golfers/stats` | Get dashboard statistics |
| PATCH | `/api/v1/golfers/:id` | Update golfer |
| POST | `/api/v1/golfers/:id/check_in` | Toggle check-in |
| POST | `/api/v1/golfers/:id/payment_details` | Record payment |
| POST | `/api/v1/golfers/:id/promote` | Promote from waitlist |
| POST | `/api/v1/golfers/:id/demote` | Demote to waitlist |
| POST | `/api/v1/golfers/:id/cancel` | Cancel registration |
| POST | `/api/v1/golfers/:id/refund` | Process Stripe refund |
| POST | `/api/v1/golfers/:id/mark_refunded` | Mark as manually refunded |
| POST | `/api/v1/golfers/:id/send_payment_link` | Send payment link email to golfer |

#### Groups
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/groups` | List groups |
| POST | `/api/v1/groups` | Create group |
| POST | `/api/v1/groups/:id/add_golfer` | Add golfer to group |
| POST | `/api/v1/groups/:id/remove_golfer` | Remove golfer |
| POST | `/api/v1/groups/auto_assign` | Auto-assign unassigned golfers |

#### Employee Numbers
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/employee_numbers` | List employee numbers |
| POST | `/api/v1/employee_numbers` | Add employee number |
| POST | `/api/v1/employee_numbers/bulk_create` | Bulk add employee numbers |
| DELETE | `/api/v1/employee_numbers/:id` | Delete employee number |
| POST | `/api/v1/employee_numbers/:id/release` | Release used number |

#### Settings & Admins
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/settings` | Get global settings |
| PATCH | `/api/v1/settings` | Update settings |
| GET | `/api/v1/admins` | List admins |
| POST | `/api/v1/admins` | Add admin by email |
| DELETE | `/api/v1/admins/:id` | Remove admin |

## Testing

```bash
# Run all tests
rails test

# Run specific test file
rails test test/models/golfer_test.rb

# Run with verbose output
rails test -v
```

## Deployment

Deploy to Render with these environment variables:
- `DATABASE_URL` - PostgreSQL connection string
- `RAILS_MASTER_KEY` - From `config/master.key`
- `CLERK_JWKS_URL` - Clerk JWKS endpoint
- `RESEND_API_KEY` - Resend API key
- `FRONTEND_URL` - Production frontend URL (e.g., https://giaa-tournament.com)

## WebSocket

Connect to `/cable` for real-time updates:
- `GolfersChannel` - Golfer create/update/delete
- `GroupsChannel` - Group and assignment changes
