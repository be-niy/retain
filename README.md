# Retain

Retain is a personal expense and monthly budget manager built for my React summative project.

Live application: https://retain-production-e29a.up.railway.app
GitHub repository: https://github.com/be-niy/retain

## Features

- Sign up, sign in, and sign out.
- React Context authentication with user roles and protected routes.
- Create, view, edit, and delete personal expenses.
- Search expenses by title or notes.
- Filter by category, payment method, date range, and amount.
- Sort by date or amount, with paginated results.
- Redux management of search, filter, sort, and pagination state.
- Set and update monthly budgets.
- View monthly spending, remaining budget, highest expense, spending by category, and recent expenses.
- Admin category creation, editing, and deletion.
- Admin platform totals, category rankings, recent expenses, and recent users.
- Responsive layouts for desktop and mobile.

Deleting a category preserves its expenses as Uncategorized.

## Technology stack

- Frontend: React, TypeScript, Vite, React Router, Redux, React Redux
- Backend: Node.js, Express
- Database: MySQL
- Authentication: JWT, bcryptjs, React Context
- Deployment: Docker and Railway

## Project structure

- frontend/src/components: reusable forms, filters, and route protection
- frontend/src/context: authentication Context and provider
- frontend/src/pages: authentication, expenses, user dashboard, and admin dashboard
- frontend/src/store: Redux filter state and selectors
- backend/src/controllers: API request handlers
- backend/src/routes: API routes
- backend/src/middleware: authentication and admin authorization
- backend/src/config: database connection
- backend/sql/schema.sql: database tables and constraints

## Requirements

- Node.js 24 and npm
- MySQL 8 or later
- Git
- Docker, if using the container deployment

## Local setup

### 1. Clone the repository

    git clone https://github.com/be-niy/retain.git
    cd retain

If NVM is installed:

    nvm install
    nvm use

### 2. Create the database

Open MySQL with an administrator account:

    sudo mysql

Run the following SQL, replacing the password with your own private value:

    CREATE DATABASE retain CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    CREATE USER 'retain_user'@'localhost' IDENTIFIED BY 'REPLACE_WITH_PRIVATE_PASSWORD';
    GRANT SELECT, INSERT, UPDATE, DELETE ON retain.* TO 'retain_user'@'localhost';
    EXIT;

Import the schema from the repository root:

    sudo mysql retain < backend/sql/schema.sql

The schema creates users, categories, expenses, and budgets.

### 3. Configure and run the backend

    cd backend
    npm ci
    cp .env.example .env

Edit backend/.env with your database credentials:

    PORT=3000
    CLIENT_URL=http://localhost:5173
    DB_HOST=localhost
    DB_PORT=3306
    DB_USER=retain_user
    DB_PASSWORD=your_private_database_password
    DB_NAME=retain
    JWT_SECRET=your_private_random_secret

Generate a JWT secret with:

    openssl rand -hex 48

Copy the generated value into JWT_SECRET. Keep .env private.

Start the API:

    npm run dev

Health endpoint: http://localhost:3000/api/health

### 4. Run the frontend

In a separate terminal, from the repository root:

    cd frontend
    npm ci
    npm run dev

Open http://localhost:5173.

The development API URL defaults to http://localhost:3000/api.
It can be overridden using VITE_API_URL in frontend/.env.

## Admin setup

Public registration always creates a normal user.

To create an administrator, first register the intended account through the application.
Then use a database administrator connection to promote that specific account:

    UPDATE users SET role = 'admin' WHERE email = 'YOUR_REGISTERED_ADMIN_EMAIL';

Sign out and sign in again after changing the role.

For Railway, run this against the deployed database, not your local database.
Local users and data are separate from deployed users and data.

## State management and authorization

React Context manages authentication, the current user, roles, and frontend route protection.

Redux stores expense search, filters, sorting, and pagination. A selector builds the API query.
The backend applies those criteria before pagination.

Protected API requests use:

    Authorization: Bearer YOUR_TOKEN

JWTs expire after one hour. Passwords are stored as bcrypt hashes.
The backend reads the authenticated user's ID when accessing expenses and budgets.
Admin category mutations and platform insights require an admin role.

## API overview

All endpoints below use the /api prefix.

| Method | Endpoint | Purpose | Access |
| --- | --- | --- | --- |
| GET | /health | API health response | Public |
| POST | /auth/register | Register an account | Public |
| POST | /auth/login | Sign in and receive a token | Public |
| GET | /auth/me | Get the signed-in user | Signed-in user |
| GET | /categories | List categories | Signed-in user |
| POST | /categories | Create a category | Admin |
| PUT | /categories/:id | Rename a category | Admin |
| DELETE | /categories/:id | Delete a category | Admin |
| GET | /expenses | List and filter personal expenses | Owner |
| GET | /expenses/:id | View a personal expense | Owner |
| POST | /expenses | Create an expense | Signed-in user |
| PUT | /expenses/:id | Update a personal expense | Owner |
| DELETE | /expenses/:id | Delete a personal expense | Owner |
| GET | /budgets/:month | Monthly budget and spending summary | Owner |
| PUT | /budgets/:month | Set or update a monthly budget | Owner |
| GET | /admin/insights | Platform statistics | Admin |

### Expense fields

- title: required, up to 150 characters
- amount: positive, with at most two decimal places
- category_id: category ID or null
- expense_date: YYYY-MM-DD
- payment_method: cash, card, bank_transfer, mobile_money, or other
- notes: optional, up to 5000 characters

### Expense query parameters

- search
- category_id: a category ID or uncategorized
- payment_method
- date_from and date_to: YYYY-MM-DD
- min_amount and max_amount
- sort: date_desc, date_asc, amount_desc, or amount_asc
- page
- page_size: between 1 and 100

Example:

    /api/expenses?payment_method=cash&min_amount=10&sort=amount_desc&page=1&page_size=10

### Monthly budgets

The month parameter uses YYYY-MM, for example /api/budgets/2026-10.
The request body for setting a budget contains an amount.

Budget status is:
- Within: spending below 80% of budget
- Approaching: spending from 80% through 100% of budget
- Over: spending above 100% of budget
- Not set: no budget exists for the selected month

## Validation

From the frontend directory:

    npm run build
    npm run lint

Manual checks performed during development covered authentication, protected routes,
expense CRUD, ownership protection, filters, sorting, pagination, budget calculations,
admin category management, category deletion preserving expenses, and mobile layouts.

No automated test suite is included.

## Production deployment

Retain is deployed on Railway using two services:
- The application, built from the root Dockerfile
- A MySQL database with persistent storage

The Docker build compiles the frontend and installs backend production dependencies.
Express serves the frontend and /api endpoints from the same public domain.
The production frontend uses /api as its API base URL.

Application runtime variables:

- NODE_ENV=production, set by the Dockerfile
- PORT, supplied by Railway
- JWT_SECRET, a private random secret
- DB_HOST
- DB_PORT
- DB_USER
- DB_PASSWORD
- DB_NAME

When the database service is named MySQL, Railway variable references can be used:

    DB_HOST=${{MySQL.MYSQLHOST}}
    DB_PORT=${{MySQL.MYSQLPORT}}
    DB_USER=${{MySQL.MYSQLUSER}}
    DB_PASSWORD=${{MySQL.MYSQLPASSWORD}}
    DB_NAME=${{MySQL.MYSQLDATABASE}}

For a new deployment, import backend/sql/schema.sql into the hosted database
before registering users. Configure the application service's public domain
to target its PORT value.

The database schema contains no predefined accounts. Create accounts through
the live application and promote an intended admin through the database.

## Author

Beni Niyogisubizo
