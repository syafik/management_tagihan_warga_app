# Tripay QRIS Payment Integration

## Overview
This document describes the QRIS payment integration using Tripay payment gateway for monthly contribution payments.

## Features Implemented

### 1. Payment Models & Database
- **Payment Model** (`app/models/payment.rb`)
  - Tracks all QRIS payments
  - Fields: reference, user_id, address_id, amount, status, payment_method, checkout_url, qr_url, expired_at, paid_at, tripay_response (JSONB)
  - Statuses: UNPAID, PAID, FAILED, EXPIRED, REFUND
  - Validations and scopes for easy querying

### 2. Tripay Service (`app/services/tripay_service.rb`)
- Handles all Tripay API interactions
- Methods:
  - `create_transaction` - Generate QRIS payment
  - `get_transaction_detail` - Check payment status
  - `calculate_fee` - Calculate MDR fees (0.7% + Rp 750)
  - `verify_callback_signature` - Verify webhook authenticity

### 3. Payments Controller (`app/controllers/payments_controller.rb`)
- **Routes**:
  - `GET /payments/new` - Select months to pay
  - `POST /payments` - Create QRIS payment
  - `GET /payments/:reference` - View QR code and status
  - `GET /payments` - Payment history

- **Logic**:
  - Calculates unpaid months by comparing UserContribution records
  - Supports custom address rates via AddressContribution
  - Falls back to global block rates from Contribution model
  - Creates UserContribution records on successful payment

### 4. Tripay Callbacks Controller (`app/controllers/tripay_callbacks_controller.rb`)
- Webhook endpoint: `POST /tripay/callback`
- Verifies signature for security
- Processes payment status updates (PAID/EXPIRED/FAILED/REFUND)
- Creates UserContribution records
- Sends notifications to users

### 5. Views
- **new.html.erb** - Month selection wizard with:
  - Visual month cards grouped by year
  - Arrears highlighting (red for overdue, orange for current)
  - Real-time total calculation
  - Quick select buttons (all arrears, all unpaid, reset)

- **show.html.erb** - Payment details with:
  - QR code display for pending payments
  - Auto-refresh every 10 seconds
  - Success state with payment confirmation
  - Expired state with option to create new payment

- **index.html.erb** - Payment history with status badges

## Data Flow

### Payment Creation
1. User selects unpaid months on `/payments/new`
2. JavaScript calculates total amount
3. User submits form
4. PaymentsController:
   - Validates selected months
   - Calculates contribution amount for each month (supports custom rates)
   - Calls TripayService to create transaction
   - Saves Payment record with months data in notes as JSON
   - Redirects to QR code page

### Payment Completion (via Webhook)
1. User scans QR code and pays via e-wallet
2. Tripay sends webhook to `/tripay/callback`
3. TripayCallbacksController:
   - Verifies signature
   - Marks payment as PAID
   - Parses months from payment.notes JSON
   - Creates UserContribution record for each month
   - Sends notification to user

### Payment Status Check (via Polling)
1. User views payment on `/payments/:reference`
2. If payment is pending, controller calls Tripay API
3. Updates status if changed
4. Auto-refresh every 10 seconds until paid/expired

## Configuration

### Rails Credentials
```yaml
tripay:
  api_key: DEV-bLTxDPQ2cPkFHzySz6hyuC7yZHeCLJmY6foERLTE
  private_key: UtIrb-rf0AP-EIwzT-SoVT4-LDcBx
  merchant_code: T42682
  base_url: https://tripay.co.id/api-sandbox
```

### Environment Variables
```bash
APP_URL=https://yourdomain.com  # For return_url in Tripay API calls
```

## Testing

### Manual Testing Steps
1. Login as warga user (e.g., dummy merchant +6281012345678, code: 123456)
2. Navigate to `/payments/new`
3. Select one or more unpaid months
4. Click "Bayar dengan QRIS"
5. Scan QR code with test e-wallet (sandbox mode)
6. Verify payment success and UserContribution creation

### Webhook Testing (Local Development)
Use ngrok to expose local server:
```bash
ngrok http 3000
# Update Tripay dashboard with webhook URL:
# https://your-ngrok-url.ngrok.io/tripay/callback
```

## Fee Calculation
- **MDR**: 0.7% + Rp 750
- **Example**: Rp 190,000 payment = Rp 1,330 + Rp 750 = Rp 2,080 fee (paid by merchant)

## Security
- Webhook signature verification using HMAC SHA256
- CSRF token skipped only for callback endpoint
- No authentication required for callback (signature is the auth)

## Future Enhancements
- [ ] Email/WhatsApp confirmation on payment success
- [ ] Bulk payment for multiple addresses
- [ ] Payment reminder scheduling
- [ ] Refund handling
- [ ] Payment analytics dashboard
- [ ] Support for other payment methods (VA, retail outlets)

## Files Created/Modified

### New Files
- `app/models/payment.rb`
- `app/services/tripay_service.rb`
- `app/controllers/payments_controller.rb`
- `app/controllers/tripay_callbacks_controller.rb`
- `app/views/payments/new.html.erb`
- `app/views/payments/show.html.erb`
- `app/views/payments/index.html.erb`
- `db/migrate/20251113063821_create_payments.rb`
- `spec/models/payment_spec.rb`

### Modified Files
- `config/routes.rb` - Added payment routes and webhook
- `app/frontend/controllers/payment_wizard_controller.js` - Already exists, reused for month selection

## Support
For issues or questions, refer to:
- Tripay Documentation: https://tripay.co.id/developer
- TRIPAY_SETUP.md - Detailed Tripay configuration guide
