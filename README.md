# GIAA Tournament API

Rails API backend for the Golf Tournament Registration System. Supports multiple tournaments with full registration, check-in, group management, and payment processing.

## Tech Stack

- **Ruby on Rails 8.1** (API mode)
- **PostgreSQL** (database)
- **Clerk** (authentication via JWT)
- **Resend** (email delivery)
- **Stripe** (payment processing)
- **ActionCable** (WebSocket real-time updates)

## Quick Start

```bash
# 1. Install dependencies
bundle install

# 2. Setup database
rails db:create
rails db:migrate
rails db:seed

# 3. Start the server
rails s -p 3000
```

## Environment Variables

Create a `.env` file in the root directory:

```env
# Clerk Authentication (required)
CLERK_JWKS_URL=https://your-clerk-instance.clerk.accounts.dev/.well-known/jwks.json

# Resend Email (required for emails)
RESEND_API_KEY=re_xxxxxxxxxxxxx
MAILER_FROM_EMAIL=noreply@yourdomain.com

# Frontend URL (required for CORS)
FRONTEND_URL=http://localhost:5173

# Stripe (optional - only needed for real payments)
# Configure these in Admin Settings instead
```

## How It Works

### Multi-Tournament System

The app supports multiple tournaments. Each tournament has its own:
- Golfers (registrations)
- Groups (foursomes)
- Activity logs
- Settings (capacity, entry fee, dates, etc.)

Tournaments can be:
- **Draft** - Not yet open for registration
- **Open** - Accepting registrations
- **Closed** - Registration closed but not archived
- **Archived** - Historical, read-only

### Data Flow

1. **Public Registration**: Golfers register via the frontend → Creates golfer record linked to the current open tournament
2. **Admin Management**: Admins log in via Clerk → JWT verified → Access to manage golfers, groups, check-ins
3. **Real-time Updates**: Changes broadcast via ActionCable to all connected admin clients

### Key Models

| Model | Description |
|-------|-------------|
| `Tournament` | Tournament with settings, dates, capacity |
| `Golfer` | Registered player (belongs to tournament) |
| `Group` | Foursome with hole assignment (belongs to tournament) |
| `Admin` | Whitelisted admin user (linked to Clerk) |
| `Setting` | Global settings (Stripe keys, payment mode) |
| `ActivityLog` | Audit trail of admin actions |

## API Endpoints

### Public (No Auth)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/tournaments/current` | Get current open tournament |
| GET | `/api/v1/golfers/registration_status` | Registration capacity & tournament info |
| POST | `/api/v1/golfers` | Register a new golfer |
| POST | `/api/v1/checkout` | Create Stripe checkout session |

### Protected (Clerk JWT Required)

#### Tournaments
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/tournaments` | List all tournaments |
| POST | `/api/v1/tournaments` | Create tournament |
| PATCH | `/api/v1/tournaments/:id` | Update tournament |
| POST | `/api/v1/tournaments/:id/archive` | Archive tournament |
| POST | `/api/v1/tournaments/:id/copy` | Copy for next year |
| POST | `/api/v1/tournaments/:id/open` | Open registration |
| POST | `/api/v1/tournaments/:id/close` | Close registration |

#### Golfers
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/golfers` | List golfers (filtered by tournament) |
| PATCH | `/api/v1/golfers/:id` | Update golfer |
| DELETE | `/api/v1/golfers/:id` | Delete golfer |
| POST | `/api/v1/golfers/:id/check_in` | Toggle check-in |
| POST | `/api/v1/golfers/:id/payment_details` | Record payment |
| POST | `/api/v1/golfers/:id/promote` | Promote from waitlist |

#### Groups
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/groups` | List groups (filtered by tournament) |
| POST | `/api/v1/groups` | Create group |
| POST | `/api/v1/groups/:id/add_golfer` | Add golfer to group |
| POST | `/api/v1/groups/:id/remove_golfer` | Remove golfer |
| POST | `/api/v1/groups/auto_assign` | Auto-assign unassigned golfers |

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

All 140 tests should pass.

## Deployment

Deploy to Render with these environment variables:
- `DATABASE_URL` - PostgreSQL connection string
- `RAILS_MASTER_KEY` - From `config/master.key`
- `CLERK_JWKS_URL` - Clerk JWKS endpoint
- `RESEND_API_KEY` - Resend API key
- `FRONTEND_URL` - Production frontend URL

## WebSocket

Connect to `/cable` for real-time updates:
- `GolfersChannel` - Golfer create/update/delete
- `GroupsChannel` - Group and assignment changes
