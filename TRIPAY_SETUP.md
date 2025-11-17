# Tripay QRIS Setup Guide

Panduan lengkap untuk mengintegrasikan Tripay QRIS payment gateway ke aplikasi.

## Step 1: Daftar Tripay Merchant

⚠️ **Note**: Saat ini Tripay sedang tutup registrasi merchant baru. Jika sudah dibuka:

1. Daftar di https://tripay.co.id/
2. Verifikasi akun merchant
3. Dapatkan credentials:
   - API Key
   - Private Key
   - Merchant Code

## Step 2: Tambahkan Credentials ke Rails

### Edit Rails Credentials:

```bash
EDITOR="code --wait" rails credentials:edit
# atau
EDITOR="vim" rails credentials:edit
```

### Tambahkan credentials Tripay:

```yaml
tripay:
  api_key: your_api_key_here
  private_key: your_private_key_here
  merchant_code: your_merchant_code_here
  mode: sandbox # sandbox atau production
  base_url_sandbox: https://tripay.co.id/api-sandbox
  base_url_production: https://tripay.co.id/api
```

### Contoh lengkap credentials.yml:

```yaml
kirimi:
  user_code: KMTV4B825
  secret_key: xxxxx

tripay:
  api_key: DEV-xxxxxxxxxxxxxxxxxxxxxxx
  private_key: xxxxx-xxxxx-xxxxx-xxxxx
  merchant_code: T1234
  mode: sandbox
  base_url_sandbox: https://tripay.co.id/api-sandbox
  base_url_production: https://tripay.co.id/api

gdrive:
  type: service_account
  # ... existing gdrive config
```

## Step 3: Test Credentials

Setelah credentials ditambahkan, test dengan:

```bash
bundle exec rake tripay:test_connection
```

## Step 4: Channel QRIS yang Tersedia

Tripay menyediakan beberapa QRIS channels:

- **QRIS** - QRIS Standard (0.7% + Rp 750)
- **QRISC** - QRIS Customizable (bisa custom branding)

Untuk iuran Rp 190.000:
- Fee: Rp 1.330 (0.7%) + Rp 750 = **Rp 2.080**
- Diterima: **Rp 187.920**

## Step 5: Webhook/Callback URL

Tripay akan mengirim notifikasi ke callback URL saat payment berhasil/gagal.

**Callback URL**: `https://your-domain.com/tripay/callback`

⚠️ Pastikan server bisa diakses dari internet (gunakan ngrok untuk development)

### Setup Callback di Tripay Dashboard:

1. Login ke Tripay dashboard
2. Settings → Callback URL
3. Masukkan: `https://your-domain.com/tripay/callback`
4. Save

## Step 6: Testing

### Sandbox Mode:
- Gunakan nomor test dari Tripay
- Semua transaksi otomatis success setelah 5 menit
- Tidak ada biaya real

### Production Mode:
- Transaksi real dengan uang real
- Callback real-time
- Fee dipotong dari setiap transaksi

## File Structure

```
app/
├── services/
│   └── tripay_service.rb          # Tripay API integration
├── controllers/
│   ├── payments_controller.rb     # Handle payment creation
│   └── tripay_callbacks_controller.rb  # Webhook handler
├── models/
│   └── payment.rb                 # Payment records
└── views/
    └── payments/
        ├── new.html.erb          # QRIS selection page
        └── show.html.erb         # Display QR Code
```

## API Endpoints yang Digunakan

### 1. Create Transaction (Closed Payment)
```
POST /merchant/payment-channel
```

### 2. Get Transaction Detail
```
GET /merchant/transactions?reference=T123456789
```

### 3. Get Fee Calculator
```
GET /merchant/fee-calculator?code=QRIS&amount=190000
```

## Security Notes

✅ **DO**:
- Simpan credentials di Rails credentials (encrypted)
- Verify signature pada callback
- Use HTTPS untuk callback URL
- Log semua transactions

❌ **DON'T**:
- Commit credentials ke Git
- Expose API keys di frontend
- Skip signature verification
- Ignore failed payments

## Support

- Tripay Docs: https://tripay.co.id/developer
- Tripay Support: support@tripay.co.id
- WhatsApp: Check Tripay dashboard

## Next Steps

Setelah credentials sudah disetup:

```bash
# Generate migration untuk payment table
rails g migration CreatePayments

# Generate service
rails g service TripayService

# Generate controller
rails g controller Payments

# Generate callback controller
rails g controller TripayCallbacks
```

---

**Created**: 2025-11-13
**Last Updated**: 2025-11-13
