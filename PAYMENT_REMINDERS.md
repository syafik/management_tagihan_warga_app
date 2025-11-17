# Payment Reminders - Dokumentasi

## Overview
Sistem reminder otomatis untuk mengingatkan warga yang belum membayar iuran bulanan. Reminder akan dikirim via WhatsApp setiap tanggal 20 di bulan berjalan.

## Fitur

### 1. Automatic Monthly Reminder (Tanggal 20)
- **Schedule**: Setiap tanggal 20 jam 09:00 pagi
- **Target**: Warga yang belum bayar di bulan berjalan
- **Filter**:
  - Hanya rumah yang **tidak FREE**
  - Hanya rumah yang **punya warga terdaftar**
  - Hanya rumah yang **belum bayar di bulan ini**
- **Recipient**: Kepala Keluarga (head of family/KK)
- **Method**: WhatsApp notification

### 2. Staggered Delivery
Untuk menghindari spam dan rate limiting:
- Notifikasi dikirim dengan jeda 5 detik antar pesan
- Menggunakan background job queue
- Retry otomatis jika gagal

## Format Pesan WhatsApp

```
🔔 *Pengingat Pembayaran Iuran*

Yth. Bapak/Ibu *Ahmad Syafik*

Kami ingin mengingatkan bahwa pembayaran iuran bulan *Oktober 2025* belum kami terima.

📍 *Alamat:* A12
💰 *Nominal:* Rp 150.000/bulan
📅 *Bulan:* Oktober 2025
⚠️ *Total Tunggakan:* 3 bulan

*Cara Pembayaran:*
💵 Transfer ke rekening resmi (lihat aplikasi)
💵 Bayar tunai ke petugas keamanan

Untuk informasi lebih lanjut atau konfirmasi pembayaran, silakan hubungi pengurus atau akses aplikasi di https://app.puriayana.com

Terima kasih atas perhatian dan kerjasamanya dalam menjaga lingkungan Puri Ayana tetap nyaman.

Salam,
Pengurus Puri Ayana 🏡
```

## Rake Tasks untuk Testing

### 1. Preview Reminder (Dry Run)
Melihat siapa saja yang akan menerima reminder tanpa mengirim notifikasi:

```bash
bundle exec rake payment_reminders:preview
```

Output:
```
Payment Reminder Preview
Current date: 27 Oktober 2025
================================================================================

📋 Residents who will receive reminders (15 total):
--------------------------------------------------------------------------------
Address         Name                           Phone                Total Arrears
--------------------------------------------------------------------------------
A12             Ahmad Syafik                   081234567890         3 bulan
B05             Budi Santoso                   081234567891         2 bulan
C08             Citra Dewi                     081234567892         5 bulan
...

Total: 15 reminders will be sent
================================================================================
```

### 2. Send Reminders Manually
Mengirim reminder secara manual (untuk testing atau jika schedule gagal):

```bash
bundle exec rake payment_reminders:send
```

### 3. Test Specific Address
Mengirim test reminder ke satu alamat tertentu:

```bash
bundle exec rake payment_reminders:test[A12]
```

## Configuration

### Scheduled Task (Production)
File: `config/recurring.yml`

```yaml
production:
  monthly_payment_reminder:
    class: SendMonthlyPaymentReminderJob
    queue: default
    schedule: at 9am on day 20 of month
```

### Mengubah Schedule
Edit `config/recurring.yml` dan restart Solid Queue worker:

```bash
# Ubah jam
schedule: at 10am on day 20 of month

# Ubah tanggal
schedule: at 9am on day 25 of month

# Setiap minggu (jika perlu)
schedule: at 9am every monday
```

Restart worker:
```bash
# Production
sudo systemctl restart solid_queue
```

## Background Jobs

### Jobs yang Terlibat

1. **SendMonthlyPaymentReminderJob**
   - File: `app/jobs/send_monthly_payment_reminder_job.rb`
   - Fungsi: Mengidentifikasi semua warga yang belum bayar
   - Schedule: Setiap tanggal 20 jam 09:00

2. **SendPaymentReminderNotificationJob**
   - File: `app/jobs/send_payment_reminder_notification_job.rb`
   - Fungsi: Mengirim notifikasi WhatsApp individual
   - Triggered by: SendMonthlyPaymentReminderJob dengan stagger 5 detik

### Monitoring Jobs

Via Solid Queue Dashboard:
```
https://app.puriayana.com/solid-queue
```

Via Rails Console:
```ruby
# Check scheduled jobs
SolidQueue::ScheduledExecution.all

# Check pending jobs
SolidQueue::Job.where(finished_at: nil)

# Check failed jobs
SolidQueue::FailedExecution.all
```

## Logging

Semua aktivitas dicatat di Rails log:

```bash
# Production
tail -f log/production.log | grep "payment reminder"

# Example log output:
# Starting monthly payment reminder for Oktober 2025
# Found 15 addresses to remind
# Queued 15 payment reminder notifications
# Sending payment reminder to 081234567890 for A12
# Payment reminder sent successfully to 081234567890
```

## Troubleshooting

### Reminder tidak terkirim
1. Check Solid Queue worker running:
   ```bash
   sudo systemctl status solid_queue
   ```

2. Check recurring job config:
   ```ruby
   rails console
   SolidQueue::RecurringTask.all
   ```

3. Check logs untuk error:
   ```bash
   tail -100 log/production.log | grep -i error
   ```

### Manual trigger jika schedule gagal
```bash
bundle exec rake payment_reminders:send
```

### Test ke satu alamat
```bash
bundle exec rake payment_reminders:test[A12]
```

## Environment Variables

Pastikan WhatsApp service sudah dikonfigurasi dengan benar di `.env`:

```bash
# WhatsApp API credentials
WHATSAPP_API_URL=...
WHATSAPP_API_KEY=...
```

## Notes

- Reminder hanya dikirim di **production environment**
- Notifikasi dikirim ke **kepala keluarga** (head of family)
- Rumah dengan flag **FREE = true** tidak akan menerima reminder
- Rumah **tanpa warga** tidak akan menerima reminder
- Total tunggakan dihitung dari **Januari 2025** + arrears lama
- Jika sudah bayar di bulan berjalan, tidak akan menerima reminder

## Manual Override

Jika perlu menonaktifkan sementara:

1. Edit `config/recurring.yml` dan comment job:
```yaml
# monthly_payment_reminder:
#   class: SendMonthlyPaymentReminderJob
#   queue: default
#   schedule: at 9am on day 20 of month
```

2. Restart Solid Queue worker

Untuk mengaktifkan kembali, uncomment dan restart worker.
