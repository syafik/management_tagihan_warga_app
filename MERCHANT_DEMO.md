# Dummy Merchant Account

Account dummy ini dibuat khusus untuk keperluan demo/testing merchant payment gateway.

## Credentials

```
Phone Number: 081012345678
Email: merchant@demo.com
Password: password123
Login Code: 123456 (6 digits - fixed, selalu diterima)
Address: D2
```

## Cara Login

### Via Phone Login (WhatsApp):
1. Buka halaman login
2. Pilih "Login dengan WhatsApp"
3. Masukkan nomor: `081012345678`
4. Masukkan kode: `123456`
5. Login berhasil → redirect ke halaman D2

### Via Email Login:
1. Buka halaman login
2. Email: `merchant@demo.com`
3. Password: `password123`

## Fitur Khusus

- **Fixed Login Code**: Kode login selalu `123456` (6 digits) dan tidak pernah expired
- **No WhatsApp Send**: Tidak akan send WhatsApp untuk login code
- **Linked to D2**: Selalu terhubung ke alamat D2 sebagai Kepala Keluarga

## Cara Membuat Ulang (Jika Dihapus)

```bash
bundle exec rake merchant:create_dummy
```

## Technical Details

**User ID**: 177 (dapat berubah jika database di-reset)
**Role**: Warga (role = 1)
**Address ID**: 72 (D2)
**KK Status**: Head of Family (kk = true)

## Security Notes

⚠️ **PERINGATAN**: Account ini HANYA untuk development/demo purposes!

- Jangan gunakan di production
- Kode hardcoded di `app/models/user.rb`:
  - Method `login_code_valid?` - line ~305
  - Method `send_login_code!` - line ~326

## Use Case

Account ini dibuat untuk:
1. **Testing Payment Gateway**: Simulasi transaksi merchant tanpa perlu nomor HP asli
2. **Demo untuk Client**: Showcase fitur payment dengan data yang konsisten
3. **Development**: Testing flow payment tanpa setup WhatsApp

## Data Address D2

```ruby
Address.find_by(block_address: 'D2')
# => #<Address id: 72, block_address: "D2", ...>
```

Untuk melihat data user contributions untuk D2:
```ruby
user = User.find_by(phone_number: '081012345678')
user.addresses.first.user_contributions
```

## Cleanup

Jika ingin menghapus account dummy:

```ruby
user = User.find_by(phone_number: '081012345678')
user.destroy if user
```

---

**Created**: 2025-11-13
**Last Updated**: 2025-11-13
