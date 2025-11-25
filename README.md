# GIAA Tournament API

Rails API backend for the 2026 Airport Week – Edward A.P. Muna II Memorial Golf Tournament Registration System.

## Tech Stack

- **Ruby on Rails 8.1** (API mode)
- **PostgreSQL** (database)
- **Clerk** (authentication via JWT)
- **Resend** (email delivery)
- **ActionCable** (WebSocket real-time updates)

## Setup

```bash
# Install dependencies
bundle install

# Create and migrate database
rails db:create
rails db:migrate

# Seed development data
rails db:seed

# Start the server
rails s -p 3001
```

## Environment Variables

Create a `.env` file with:

```
# Clerk Authentication
CLERK_JWKS_URL=https://your-clerk-instance.clerk.accounts.dev/.well-known/jwks.json

# Resend Email
RESEND_API_KEY=re_xxxxxxxxxxxxx
MAILER_FROM_EMAIL=noreply@airportgolf.com

# Frontend URL (for CORS)
FRONTEND_URL=http://localhost:5173
```

## API Endpoints

### Public Endpoints (No Auth Required)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/api/v1/golfers/registration_status` | Get registration capacity status |
| POST | `/api/v1/golfers` | Register a new golfer |
| POST | `/api/v1/checkout` | Create Stripe checkout session |
| POST | `/api/v1/checkout/confirm` | Confirm payment |

### Protected Endpoints (Clerk JWT Required)

#### Golfers

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/golfers` | List all golfers (with filters) |
| GET | `/api/v1/golfers/:id` | Get single golfer |
| PATCH | `/api/v1/golfers/:id` | Update golfer |
| DELETE | `/api/v1/golfers/:id` | Delete golfer |
| POST | `/api/v1/golfers/:id/check_in` | Mark golfer as checked in |
| POST | `/api/v1/golfers/:id/payment_details` | Add payment details (pay-on-day) |
| POST | `/api/v1/golfers/:id/promote` | Promote from waitlist to confirmed |
| GET | `/api/v1/golfers/stats` | Get registration statistics |

**Golfer Filters (query params):**
- `payment_status` - paid/unpaid
- `payment_type` - stripe/pay_on_day
- `registration_status` - confirmed/waitlist
- `checked_in` - true/false
- `assigned` - true/false
- `hole_number` - 1-18
- `group_number` - group number
- `search` - search by name, email, phone
- `sort_by` - name, email, created_at, etc.
- `sort_order` - asc/desc
- `page` - page number
- `per_page` - items per page

#### Groups

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/groups` | List all groups with golfers |
| GET | `/api/v1/groups/:id` | Get single group |
| POST | `/api/v1/groups` | Create a new group |
| PATCH | `/api/v1/groups/:id` | Update group |
| DELETE | `/api/v1/groups/:id` | Delete group |
| POST | `/api/v1/groups/:id/set_hole` | Assign hole number |
| POST | `/api/v1/groups/:id/add_golfer` | Add golfer to group |
| POST | `/api/v1/groups/:id/remove_golfer` | Remove golfer from group |
| POST | `/api/v1/groups/update_positions` | Drag-and-drop reordering |
| POST | `/api/v1/groups/batch_create` | Create multiple groups |
| POST | `/api/v1/groups/auto_assign` | Auto-assign unassigned golfers |

#### Admins

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/admins/me` | Get current admin |
| GET | `/api/v1/admins` | List all admins (super_admin only) |
| POST | `/api/v1/admins` | Create new admin (super_admin only) |
| PATCH | `/api/v1/admins/:id` | Update admin (super_admin only) |
| DELETE | `/api/v1/admins/:id` | Delete admin (super_admin only) |

#### Settings

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/settings` | Get settings |
| PATCH | `/api/v1/settings` | Update settings (super_admin only) |

## WebSocket Channels

Connect to `/cable` for real-time updates:

- **GolfersChannel** - Broadcasts golfer updates
- **GroupsChannel** - Broadcasts group/assignment updates

## Models

### Golfer
- name, company, address, phone, mobile, email
- payment_type (stripe/pay_on_day)
- payment_status (paid/unpaid)
- registration_status (confirmed/waitlist)
- waiver_accepted_at, checked_in_at
- group_id, hole_number, position
- payment_method, receipt_number, payment_notes
- notes

### Group
- group_number (unique)
- hole_number (1-18)
- Has many golfers (max 4)

### Admin
- clerk_id (unique)
- name, email
- role (super_admin/admin)

### Setting
- max_capacity (default: 160)
- stripe_public_key, stripe_secret_key
- admin_email

## Deployment

Deploy to Render with these environment variables:
- `DATABASE_URL`
- `RAILS_MASTER_KEY`
- `CLERK_JWKS_URL`
- `RESEND_API_KEY`
- `FRONTEND_URL`
