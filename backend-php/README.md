# Gulflands Admin Portal API

This is a PHP API built with Slim Framework for managing land plot listings.

## Setup

1. Install dependencies:
   ```
   composer install
   ```

2. Create a MySQL database named `gulflands`.

3. Run migrations:
   ```
   mysql -u root -p gulflands < migrations/001_create_listings_table.sql
   mysql -u root -p gulflands < migrations/002_create_audit_logs_table.sql
   mysql -u root -p gulflands < migrations/003_create_admins_table.sql
   ```

4. Run seeders:
   ```
   mysql -u root -p gulflands < seeders/001_admin_seeder.sql
   ```

5. Start the server:
   ```
   php -S localhost:8000 -t public
   ```

## API Endpoints

### Authentication
- `POST /login` - Login with username/password, returns JWT token

### Listings (Protected, requires Bearer token)
- `GET /api/listings` - Get all listings
- `GET /api/listings/{id}` - Get listing by ID
- `POST /api/listings` - Create new listing
- `PUT /api/listings/{id}` - Update listing
- `DELETE /api/listings/{id}` - Delete listing
- `PATCH /api/listings/{id}/publish` - Publish/unpublish listing

## Default Admin Credentials
- Username: admin
- Password: password

## Features
- JWT Authentication
- Role-based access (admin role)
- Rate limiting (100 requests/minute per IP)
- Data validation
- Audit logging for all CRUD operations
- Publish/unpublish functionality