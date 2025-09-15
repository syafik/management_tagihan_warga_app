# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
This is a Ruby on Rails 7.0 application for managing resident billing/contributions in a housing complex. The system tracks monthly contributions, debts, installments, and financial transactions for different blocks (A, B, C, D, F) in a residential area.

## Tech Stack
- **Framework**: Ruby on Rails 7.0
- **Ruby Version**: 3.2.1
- **Database**: PostgreSQL
- **Authentication**: Devise + DeviseTokenAuth (for API endpoints)
- **PDF Generation**: PDFKit with wkhtmltopdf-binary
- **File Upload**: Paperclip
- **Background Jobs**: Delayed Job
- **Pagination**: Pagy
- **Search**: Ransack
- **External Integration**: Google Drive API for spreadsheet management
- **Email**: SendInBlue API
- **Frontend**: ERB views with Bootstrap, jQuery, CKEditor

## Key Architecture Components

### Core Models
- **User**: Residents and administrators with role-based access
- **Address**: Housing units organized by blocks (A-F)
- **UserContribution**: Monthly payment records with Google Sheets integration
- **CashTransaction**: Financial transactions (DEBIT/KREDIT) with categorization
- **CashFlow**: Monthly financial summaries
- **Debt/Installment**: Debt management system
- **Notification**: System notifications with user targeting

### Block Management System
The application manages 5 blocks (A, B, C, D, F) with dedicated PIC (Person in Charge) users. Block assignments are stored in `Address::BLOK_NAME` constant.

### Google Drive Integration
Heavy integration with Google Sheets for:
- Importing contribution data from spreadsheets
- Generating monthly billing reports
- Managing transfer payments
- Updating contribution status

### API Structure
RESTful API endpoints under `/api/v1/` with token-based authentication for mobile/external access.

## Common Development Commands

### Server Management
```bash
# Start development server
rails server
# or
bundle exec rails server

# Start background jobs
bundle exec rake jobs:work
```

### Database Operations
```bash
# Run migrations
rails db:migrate

# Seed database
rails db:seed

# Reset database (development only)
rails db:reset
```

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

# Auto-fix RuboCop offenses
bundle exec rubocop -a

# Security audit
bundle exec brakeman
```

### Deployment (Capistrano)
```bash
# Deploy to production
cap production deploy

# Check deployment status
cap production deploy:check
```

## Important Configuration Files
- **Environment Variables**: Use `.env.local` for local development settings
- **Google Drive Config**: `GDRIVE_CONFIG` constant contains service account credentials
- **Database Config**: `config/database.yml`
- **Routes**: Complex routing with both web and API endpoints in `config/routes.rb`
- **ActiveAdmin**: Admin interface mounted at `/admin` with authentication

## Development Notes
- The system heavily relies on Google Sheets integration for data import/export
- Block-based permissions are managed through `pic_blok` field in User model
- Financial transactions are categorized using TYPE and GROUP constants
- Month names are localized in Indonesian (`UserContribution::MONTHNAMES`)
- PDF reports are generated using wkhtmltopdf for financial statements
- ActiveAdmin provides administrative interface with CanCanCan authorization
- New models: Contribution, AddressContribution for flexible contribution management
- Application uses Delayed Job for background processing (start with `bundle exec rake jobs:work`)

## Console and Debugging Commands
```bash
# Rails console
rails console
# or
bundle exec rails console

# Debug with Pry (available in development/test)
# Add binding.pry in code, then continue with:
# continue, next, step commands

# Check background jobs
rails console
> Delayed::Job.all

# Check Google Sheets connection
rails console  
> GoogleDrive::Session.from_service_account_key(StringIO.new(GDRIVE_CONFIG.to_json))
```

## Key Constants and Configuration
- `Address::BLOK_NAME`: Maps block letters (A,B,C,D,F) to numeric indices
- `UserContribution::MONTHNAMES`: Indonesian month names mapped to numbers
- `GDRIVE_CONFIG`: Google Drive API service account configuration
- Application name in config: "SwitchupAdministrator"