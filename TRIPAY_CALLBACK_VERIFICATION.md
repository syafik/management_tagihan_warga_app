# Tripay Callback Signature Verification

## Overview
Tripay mengirim webhook callback ketika status pembayaran berubah (PAID, EXPIRED, FAILED, REFUND). Untuk keamanan, setiap callback harus diverifikasi menggunakan HMAC SHA256 signature.

## Signature Verification Method

Tripay menggunakan metode berikut untuk generate signature:

```ruby
signature = OpenSSL::HMAC.hexdigest(
  'sha256',
  PRIVATE_KEY,
  json_payload
)
```

**Key Points:**
- Menggunakan **seluruh JSON payload** sebagai input untuk HMAC
- Menggunakan **Private Key** dari credentials Tripay
- Signature dikirim via header `X-Callback-Signature`

## Callback Payload Format

Tripay mengirim callback dengan format JSON berikut:

```json
{
  "reference": "DEV-T42682308965NYPLN",
  "merchant_ref": "PAY176325643799812EA1",
  "payment_method": "QRIS",
  "payment_method_code": "QRIS2",
  "total_amount": 192080,
  "fee_merchant": 2095,
  "fee_customer": 0,
  "total_fee": 2095,
  "amount_received": 189985,
  "is_closed_payment": 1,
  "status": "PAID",
  "paid_at": 1763256923,
  "note": "test"
}
```

**Important Fields:**
- `merchant_ref`: Payment reference dari sistem kita (digunakan untuk find Payment)
- `status`: PAID | EXPIRED | FAILED | REFUND
- `total_amount`: Total pembayaran (bukan `amount`)
- `paid_at`: Unix timestamp

## Implementation

### 1. TripayService (app/services/tripay_service.rb)

```ruby
def verify_callback_signature(signature, json_payload)
  expected = OpenSSL::HMAC.hexdigest(
    'sha256',
    @private_key,
    json_payload
  )

  signature == expected
end
```

### 2. TripayCallbacksController (app/controllers/tripay_callbacks_controller.rb)

```ruby
def callback
  # Get signature from header
  callback_signature = request.headers['X-Callback-Signature']

  # Get raw JSON payload
  json_payload = request.raw_post

  # Verify signature
  tripay_service = TripayService.new
  unless tripay_service.verify_callback_signature(callback_signature, json_payload)
    render json: { success: false, message: 'Invalid signature' }, status: :unauthorized
    return
  end

  # Process callback...
end
```

## Testing

Gunakan script `test_tripay_callback.rb` untuk simulate callback dari Tripay:

```bash
# Test dengan payment reference tertentu
ruby test_tripay_callback.rb PAY176325643799812EA1

# Test dengan last unpaid payment
ruby test_tripay_callback.rb
```

Script ini akan:
1. Generate signature yang benar sesuai metode Tripay
2. Send POST request ke `/tripay/callback`
3. Verify signature di server
4. Process payment jika signature valid

## Reference Management

Ada 2 jenis reference yang perlu dikelola:

1. **Merchant Reference (Ours)**: `PAY1763257160AA1125E9`
   - Generated oleh sistem kita
   - Dikirim ke Tripay sebagai `merchant_ref`
   - Digunakan oleh Tripay dalam callback sebagai `merchant_ref`
   - **Disimpan di kolom `payments.reference`** untuk lookup callback

2. **Tripay Reference (Theirs)**: `DEV-T42682308970POWQD`
   - Generated oleh Tripay
   - Dikembalikan saat create transaction
   - Digunakan untuk get transaction detail
   - **Disimpan di `payments.tripay_response['tripay_reference']`**

### Flow

```ruby
# 1. Create Payment
merchant_ref = generate_reference() # "PAY1763257160AA1125E9"
tripay_data = tripay.create_transaction(merchant_ref: merchant_ref)
# Returns: { reference: "DEV-T42682...", merchant_ref: "PAY176..." }

payment = Payment.create!(
  reference: tripay_data['merchant_ref'], # OUR reference
  tripay_response: {
    tripay_reference: tripay_data['reference'] # THEIR reference
  }
)

# 2. Callback Received
# Tripay sends: merchant_ref = "PAY1763257160AA1125E9"
payment = Payment.find_by(reference: params[:merchant_ref]) # ✅ Found!

# 3. Get Transaction Detail
tripay_ref = payment.tripay_response['tripay_reference']
tripay.get_transaction_detail(tripay_ref) # Use THEIR reference
```

## Common Issues

### Issue 1: Invalid Signature
**Error:** `Invalid Tripay callback signature for reference: XXX`

**Penyebab:**
- Signature calculation tidak sesuai dengan yang dikirim Tripay
- Private key salah
- JSON payload dimodifikasi

**Solusi:**
- Pastikan menggunakan `request.raw_post` sebagai payload
- Verifikasi private key di `config/credentials.yml.enc`
- Jangan parse/modify JSON sebelum verifikasi

### Issue 2: Payment Not Found
**Error:** `Payment not found for reference: XXX`

**Penyebab:**
- Kolom `payments.reference` menyimpan Tripay reference (salah)
- Seharusnya menyimpan merchant_ref (reference kita)

**Solusi:**
- Simpan `tripay_data['merchant_ref']` di `payments.reference`
- Simpan `tripay_data['reference']` di `payments.tripay_response['tripay_reference']`
- Callback akan lookup menggunakan `merchant_ref`

## Security Notes

1. **Always verify signature first** sebelum process callback
2. **Use raw JSON payload** untuk signature verification
3. **Never log Private Key** di production
4. **Check payment status** sebelum update (avoid double processing)
5. **Return 401 Unauthorized** jika signature invalid

## References

- [Tripay API Documentation](https://tripay.co.id/developer?tab=callback)
- Tripay Callback Signature menggunakan HMAC-SHA256 dengan entire JSON payload
