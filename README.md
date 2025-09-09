# Management Tagihan Warga

A modern Ruby on Rails 7.0 application for managing residential billing and contributions in housing complexes. This system helps administrators track monthly contributions, manage debts, process installments, and maintain financial records for different blocks within a residential community.

## Features

- **Resident Management**: User registration and profile management with block assignments
- **Monthly Contributions**: Track and manage monthly payments from residents
- **Financial Tracking**: Comprehensive cash flow management with debit/credit transactions
- **Block-based Organization**: Manage different residential blocks (A, B, C, D, F) with dedicated PICs
- **Google Sheets Integration**: Import/export data from Google Spreadsheets
- **Debt Management**: Track resident debts and installment payments
- **Notification System**: Send notifications to residents
- **PDF Reports**: Generate financial reports and billing statements
- **REST API**: Mobile-friendly API endpoints with token authentication
- **Modern UI**: Clean, responsive interface built with Tailwind CSS
- **Fast Development**: Vite for lightning-fast asset compilation and HMR

## Tech Stack

- **Backend**: Ruby on Rails 7.0
- **Database**: PostgreSQL
- **Frontend**: Tailwind CSS + Stimulus JS
- **Build Tool**: Vite for modern asset pipeline
- **PDF Generation**: PDFKit with wkhtmltopdf
- **Background Jobs**: Delayed Job
- **Authentication**: Devise + DeviseTokenAuth
- **External APIs**: Google Drive, SendInBlue

## Requirements

- **Ruby**: 3.2.1
- **Node.js**: 16+ (for Vite and Tailwind CSS)
- **PostgreSQL**: 12+
- **wkhtmltopdf**: For PDF generation
- **Google Drive API credentials**: For spreadsheet integration

## Installation

### 1. Clone the repository
```bash
git clone <repository-url>
cd management_tagihan_warga_app
```

### 2. Install Ruby dependencies
```bash
bundle install
```

### 3. Install Node.js dependencies
```bash
npm install
```

### 4. Setup environment variables
```bash
cp .env.example .env.local
# Edit .env.local with your configuration
```

### 5. Setup the database
```bash
rails db:create
rails db:migrate
rails db:seed
```

### 6. Configure Google Drive API
- Create a service account in Google Cloud Console
- Download the credentials JSON file
- Set the `GDRIVE_CONFIG` environment variable in `.env.local`

## Running the Application

### 🚀 Quick Start (Recommended)
Use the built-in development script that runs both Rails and Vite servers concurrently:

```bash
bin/dev
```

This will start:
- **Rails server** at `http://localhost:3100`
- **Vite dev server** at `http://localhost:3036/vite-dev/` (for assets)

### Manual Setup
If you prefer to run servers separately:

#### Terminal 1 - Rails Server
```bash
bundle exec rails server
```

#### Terminal 2 - Vite Dev Server
```bash
npm run dev
# or
bin/vite dev
```

#### Terminal 3 - Background Jobs (Optional)
```bash
bundle exec rake jobs:work
```

### 🔧 Production Build
```bash
# Build assets for production
npm run build

# Start production server
bundle exec rails server -e production
```

## Development Commands

### Testing
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run system tests
bundle exec rspec spec/system/
```

### Code Quality
```bash
# Run RuboCop linter
bundle exec rubocop

# Auto-fix RuboCop issues
bundle exec rubocop -a

# Security audit
bundle exec brakeman
```

### Asset Management
```bash
# Build assets for production
npm run build

# Start Vite dev server only
npm run dev

# Check package vulnerabilities
npm audit
```

## Project Structure

```
management_tagihan_warga_app/
├── app/
│   ├── frontend/                 # Vite + Stimulus frontend assets
│   │   ├── controllers/          # Stimulus controllers
│   │   └── entrypoints/          # Vite entry points (JS/CSS)
│   ├── views/                    # ERB templates with Tailwind CSS
│   ├── controllers/              # Rails controllers
│   ├── models/                   # ActiveRecord models
│   └── jobs/                     # Background jobs
├── config/
│   ├── vite.json                 # Vite Rails configuration
│   ├── database.yml              # Database settings
│   └── routes.rb                 # Application routes
├── bin/dev                       # Development server script
├── Procfile.dev                  # Foreman process definitions
├── vite.config.ts               # Vite configuration
├── tailwind.config.js           # Tailwind CSS configuration
└── package.json                 # Node.js dependencies
```

## API Documentation

The application provides RESTful API endpoints under `/api/v1/` with token-based authentication. Visit `/api` for Swagger documentation.

## Configuration

### Key Configuration Files
- `config/database.yml` - Database settings
- `config/routes.rb` - Application routes
- `.env.local` - Environment variables
- `config/initializers/` - Rails initializers
- `vite.config.ts` - Vite build configuration
- `tailwind.config.js` - Tailwind CSS configuration
- `package.json` - Node.js dependencies and scripts

### Environment Variables
Create `.env.local` with:
```bash
# Database
DATABASE_URL=postgresql://user:password@localhost/management_tagihan_warga_development

# Google Drive API
GDRIVE_CONFIG={"type":"service_account","project_id":"..."}

# Other configurations
RAILS_ENV=development
SECRET_KEY_BASE=your_secret_key
```

## Deployment

### Production Build
```bash
# Install dependencies
bundle install --without development test
npm ci --only=production

# Build assets
npm run build

# Precompile additional assets (if any)
RAILS_ENV=production bundle exec rails assets:precompile

# Run migrations
RAILS_ENV=production bundle exec rails db:migrate
```

### Using Capistrano
```bash
cap production deploy
```

## Architecture

### Backend (Rails)
- **Models**: User, Address, UserContribution, CashTransaction, Debt, Installment, Notification
- **Controllers**: Web controllers for admin interface, API controllers for mobile access
- **Background Jobs**: Delayed Job for asynchronous processing
- **External APIs**: Google Drive for spreadsheet management, SendInBlue for emails

### Frontend (Vite + Tailwind + Stimulus)
- **Vite**: Modern build tool with HMR for fast development
- **Tailwind CSS**: Utility-first CSS framework for rapid UI development
- **Stimulus**: Modest JavaScript framework for progressive enhancement
- **Responsive Design**: Mobile-first approach with modern UI components

## Troubleshooting

### Common Issues

1. **Assets not loading**
   ```bash
   # Make sure both servers are running
   bin/dev
   
   # Or manually start Vite
   npm run dev
   ```

2. **Database connection issues**
   ```bash
   # Check PostgreSQL is running
   brew services start postgresql
   
   # Verify database exists
   rails db:create
   ```

3. **Node.js/npm issues**
   ```bash
   # Clear npm cache
   npm cache clean --force
   
   # Reinstall dependencies
   rm -rf node_modules package-lock.json
   npm install
   ```

4. **Ruby/Rails issues**
   ```bash
   # Clear bundler cache
   bundle clean --force
   
   # Reinstall gems
   bundle install
   ```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Run the test suite (`bundle exec rspec`)
6. Run code quality checks (`bundle exec rubocop`)
7. Commit your changes (`git commit -m 'Add amazing feature'`)
8. Push to the branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

## License

This project is proprietary software for residential management purposes.

---

## Quick Reference

| Command | Purpose |
|---------|---------|
| `bin/dev` | Start development servers |
| `npm run build` | Build for production |
| `bundle exec rspec` | Run tests |
| `bundle exec rubocop` | Lint code |
| `rails console` | Rails console |
| `rails db:migrate` | Run migrations |

**🏠 Happy managing your residential community!**
