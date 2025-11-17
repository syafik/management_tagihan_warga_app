# Contoh Perhitungan Fee QRIS

## Formula Fee Tripay QRIS
**Fee = (Amount × 0.7%) + Rp 750**

Fee ini **ditanggung oleh pembayar (warga)**, bukan merchant.

---

## Contoh 1: Bayar 1 Bulan

### Iuran Bulanan
- Januari 2025: **Rp 190.000**

### Perhitungan Fee
- Fee Persentase: Rp 190.000 × 0.007 = **Rp 1.330**
- Fee Tetap: **Rp 750**
- **Total Fee: Rp 2.080**

### Total Yang Harus Dibayar
```
Iuran Bulanan:  Rp 190.000
Biaya Admin:    Rp   2.080
─────────────────────────────
TOTAL:          Rp 192.080
```

---

## Contoh 2: Bayar 3 Bulan Sekaligus

### Iuran Bulanan
- Januari 2025: Rp 190.000
- Februari 2025: Rp 190.000
- Maret 2025: Rp 190.000
- **Subtotal: Rp 570.000**

### Perhitungan Fee
- Fee Persentase: Rp 570.000 × 0.007 = **Rp 3.990**
- Fee Tetap: **Rp 750**
- **Total Fee: Rp 4.740**

### Total Yang Harus Dibayar
```
Iuran Bulanan:  Rp 570.000
Biaya Admin:    Rp   4.740
─────────────────────────────
TOTAL:          Rp 574.740
```

---

## Contoh 3: Bayar 6 Bulan Sekaligus

### Iuran Bulanan
- Januari - Juni 2025 (6 bulan)
- **Subtotal: Rp 1.140.000**

### Perhitungan Fee
- Fee Persentase: Rp 1.140.000 × 0.007 = **Rp 7.980**
- Fee Tetap: **Rp 750**
- **Total Fee: Rp 8.730**

### Total Yang Harus Dibayar
```
Iuran Bulanan:  Rp 1.140.000
Biaya Admin:    Rp     8.730
─────────────────────────────
TOTAL:          Rp 1.148.730
```

---

## Perbandingan: Bayar Per Bulan vs Sekaligus

### Skenario: Bayar 6 Bulan

#### Opsi A: Bayar Per Bulan (6x Transaksi)
```
Bulan 1: Rp 190.000 + Rp 2.080 = Rp 192.080
Bulan 2: Rp 190.000 + Rp 2.080 = Rp 192.080
Bulan 3: Rp 190.000 + Rp 2.080 = Rp 192.080
Bulan 4: Rp 190.000 + Rp 2.080 = Rp 192.080
Bulan 5: Rp 190.000 + Rp 2.080 = Rp 192.080
Bulan 6: Rp 190.000 + Rp 2.080 = Rp 192.080
─────────────────────────────────────────────
TOTAL:                          Rp 1.152.480
Total Fee Dibayar:              Rp    12.480
```

#### Opsi B: Bayar Sekaligus (1x Transaksi)
```
6 Bulan: Rp 1.140.000 + Rp 8.730 = Rp 1.148.730
─────────────────────────────────────────────
TOTAL:                          Rp 1.148.730
Total Fee Dibayar:              Rp     8.730
```

### 💰 **HEMAT: Rp 3.750** (bayar sekaligus lebih murah!)

---

## Kesimpulan

✅ **Semakin banyak bulan dibayar sekaligus, semakin hemat biaya admin**

Karena fee tetap (Rp 750) hanya dikenakan **1x per transaksi**, bukan per bulan.

### Rekomendasi:
- Untuk menghemat biaya admin, lebih baik bayar **beberapa bulan sekaligus**
- Terutama jika ada tunggakan, bayar semua tunggakan dalam 1x transaksi

---

## Implementasi di Sistem

### Di Halaman Pilih Bulan (`/payments/new`)
- Warga pilih bulan mana saja yang mau dibayar (checkbox)
- Total otomatis dihitung **sudah termasuk fee**
- Tampilan: "Total Pembayaran: Rp XXX (sudah termasuk biaya admin)"

### Di Halaman QR Code (`/payments/:reference`)
```
Iuran Bulanan:  Rp 570.000
Biaya Admin:    Rp   4.740
─────────────────────────────
Total Pembayaran: Rp 574.740
```

### Di Halaman Success
```
✓ Pembayaran Berhasil!

Iuran Bulanan:  Rp 570.000
Biaya Admin:    Rp   4.740
─────────────────────────────
Total Dibayar:  Rp 574.740
```

---

## Technical Notes

- Fee calculation ada di `TripayService#calculate_total_with_fee`
- Payment amount yang disimpan adalah **total sudah include fee**
- Breakdown disimpan di `payment.tripay_response` untuk tracking:
  - `contribution_amount`: Amount iuran saja
  - `fee_amount`: Amount fee saja
  - `total_amount`: Total yang dibayar
