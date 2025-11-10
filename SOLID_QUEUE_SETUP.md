# Solid Queue Setup untuk Production

Aplikasi ini menggunakan **Solid Queue** untuk menjalankan background jobs (pengiriman notifikasi, proses Google Sheets, dll).

## Setup di Production Server (First Time)

### 1. Install Systemd Service

Setelah deploy pertama kali, jalankan command ini **sekali saja** di production server:

```bash
# SSH ke production server
ssh your_user@your_server

# Copy service file ke systemd
cd /var/www/puriayana-app
sudo cp config/systemd/solid_queue.service /etc/systemd/system/

# Edit service file untuk menambahkan credentials (PENTING!)
sudo nano /etc/systemd/system/solid_queue.service
```

**Tambahkan baris ini** setelah `Environment=RAILS_LOG_TO_STDOUT=true`:

```ini
Environment=RAILS_MASTER_KEY=your_production_key_here
```

**Note**: Dapatkan production key dari file `config/credentials/production.key` di local repository.

Simpan file (Ctrl+O, Enter, Ctrl+X), lalu:

```bash
# Enable dan start service
sudo systemctl daemon-reload
sudo systemctl enable solid_queue
sudo systemctl start solid_queue
```

**⚠️ PENTING**: File service di server mengandung credentials. Jangan pernah commit credentials ke git repository!

### 2. Verifikasi Service Berjalan

```bash
# Cek status service
sudo systemctl status solid_queue

# Atau via Capistrano dari local
bundle exec cap production solid_queue:status
```

Output yang benar:
```
● solid_queue.service - Solid Queue Worker for Management Tagihan Warga
   Loaded: loaded (/etc/systemd/system/solid_queue.service; enabled)
   Active: active (running) since ...
```

### 3. Migrasi Database (First Time)

Pastikan tabel Solid Queue sudah ada:

```bash
# SSH ke server
cd /var/www/management_tagihan_warga_app/current
RAILS_ENV=production bundle exec rails solid_queue:install
RAILS_ENV=production bundle exec rails db:migrate
```

## Operasional Sehari-hari

### Auto-restart Setelah Deploy

Service akan **otomatis restart** setelah setiap `cap production deploy`. Tidak perlu action manual.

Kode di `lib/capistrano/tasks/solid_queue.rake`:
```ruby
after 'deploy:publishing', 'solid_queue:restart'
```

### Manual Commands (jika diperlukan)

```bash
# Start worker
bundle exec cap production solid_queue:start

# Stop worker
bundle exec cap production solid_queue:stop

# Restart worker
bundle exec cap production solid_queue:restart

# Check status
bundle exec cap production solid_queue:status
```

### Monitoring via Web Dashboard

Dashboard tersedia di: **https://your-domain.com/solid-queue**

- **Login**: Hanya user dengan role Admin yang bisa akses
- **Features**:
  - Lihat jumlah jobs pending/running/failed
  - Monitor worker processes
  - Lihat job history
  - Retry failed jobs

## Troubleshooting

### Jobs tidak berjalan

1. **Cek service status**
   ```bash
   sudo systemctl status solid_queue
   ```

2. **Cek logs**
   ```bash
   # Application log
   tail -f /var/www/management_tagihan_warga_app/shared/log/production.log

   # Solid Queue log
   tail -f /var/www/management_tagihan_warga_app/shared/log/solid_queue.log

   # Error log
   tail -f /var/www/management_tagihan_warga_app/shared/log/solid_queue_error.log
   ```

3. **Restart service**
   ```bash
   sudo systemctl restart solid_queue
   ```

4. **Cek di Rails console**
   ```bash
   cd /var/www/management_tagihan_warga_app/current
   RAILS_ENV=production bundle exec rails console
   ```

   Di console:
   ```ruby
   # Lihat pending jobs
   SolidQueue::Job.pending.count

   # Lihat failed jobs
   SolidQueue::Job.failed.count

   # Lihat running processes
   SolidQueue::Process.all

   # Test enqueue job manual
   TestJob.perform_later
   ```

### Service tidak start setelah server reboot

```bash
# Enable auto-start
sudo systemctl enable solid_queue

# Start service
sudo systemctl start solid_queue
```

### Permission issues

Pastikan user `deploy` memiliki akses ke direktori aplikasi:

```bash
sudo chown -R deploy:deploy /var/www/management_tagihan_warga_app
```

## Configuration Files

- **Systemd Service**: `config/systemd/solid_queue.service`
- **Capistrano Tasks**: `lib/capistrano/tasks/solid_queue.rake`
- **Production Config**: `config/environments/production.rb` (line 62-63)
- **Database Config**: `config/database.yml` (line 94-98)

## Background Jobs yang Menggunakan Solid Queue

Contoh jobs di aplikasi ini:
- Pengiriman email notifikasi pembayaran
- Update Google Sheets
- Generate laporan PDF
- Proses import data bulk

Untuk membuat job baru:
```ruby
rails generate job NotificationSender
```

Kemudian di code:
```ruby
NotificationSenderJob.perform_later(user_id, message)
```
