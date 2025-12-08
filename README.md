# Final Project PSD - Reso Sense: Detektor Getaran Mesin Berbasis Algoritma Goertzel

## Latar Belakang (Background)

Dalam industri modern, kesehatan mesin adalah prioritas utama. Kerusakan fatal pada mesin industri sering kali tidak terjadi secara tiba-tiba, melainkan diawali dengan munculnya getaran resonansi pada frekuensi tertentu yang sering kali terabaikan oleh sensor amplitudo biasa karena tertutup oleh kebisingan (*noise*) operasional pabrik.

Proyek kami, **Reso Sense**, bertujuan untuk menciptakan *Hardware Accelerator* menggunakan VHDL yang berfungsi sebagai sistem pemantauan kondisi (*Condition Monitoring System*). Berbeda dengan FFT (*Fast Fourier Transform*) yang memakan banyak sumber daya komputasi untuk seluruh spektrum, kami mengimplementasikan **Algoritma Goertzel**. Algoritma ini sangat efisien untuk mendeteksi satu target frekuensi spesifik (seperti frekuensi kerusakan *bearing* atau *shaft*) dengan penggunaan *resource* FPGA yang minimal.

Desain ini didasarkan pada implementasi *Register Transfer Level* (RTL) yang terstruktur dan teroptimasi.

## Cara Kerja (How it works)

Sistem bekerja dengan menerima sinyal input digital dari sensor getaran. Sinyal tersebut diproses melalui dua mode utama yang dikendalikan oleh *Finite State Machine* (FSM):

1.  **Mode Konfigurasi (Config Mode):** Pengguna memasukkan parameter target (Koefisien Frekuensi) dan Batas Ambang Bahaya (*Threshold*). Ini membuat alat bersifat *programmable*.
2.  **Mode Pemantauan (Monitor Mode):** Sinyal input masuk ke jalur data (*Datapath*).
    * Sinyal melewati filter digital Goertzel untuk mengisolasi frekuensi target.
    * Sistem menghitung total energi ($Magnitude^2$) dari frekuensi tersebut.
    * Hasil energi dibandingkan dengan *Threshold*. Jika Energi > Threshold, maka **ALARM** akan menyala.

Desain kami memiliki 3 *state* utama: **IDLE**, **CONFIG_MODE**, dan **MONITOR_MODE**.

## Komponen Utama

### 1. Control Unit 
Komponen ini berfungsi sebagai pengendali logika sistem. Ia menerima input konfigurasi dan menyimpannya ke dalam register internal agar parameter deteksi bisa diubah secara *real-time* tanpa sintesis ulang.

```vhdl
case current_state is
    when IDLE =>
        if write_en = '1' then
            current_state <= CONFIG_MODE;
        else
            current_state <= MONITOR_MODE;
        end if;
-- ... logika transisi lainnya
```
Input: addr_in (alamat register), data_in (nilai konfigurasi).
Output: coeff_out (ke datapath), thresh_out (ke komparator top-level).

### 2. Goertzel Datapath 
Modul ini adalah jantung pemrosesan sinyal. Ia melakukan perhitungan matematika iteratif menggunakan rumus filter IIR orde dua Goertzel. 
Salah satu keunggulan desain kami adalah Optimasi Aritmatika. Kami menggantikan operasi pembagian (yang memboroskan area FPGA) dengan teknik Bit Shifting dan Resizing untuk menghitung energi akhir, sehingga sistem lebih ringan dan cepat.

### 3. Machine Detector Top (Top Level)
Modul teratas yang mengintegrasikan Control Unit dan Datapath. Modul ini juga menangani logika keputusan alarm. Output alarm menggunakan registered output untuk memastikan 
sinyal stabil dan bebas dari glitch (kedipan palsu) saat transisi sinyal.
```vhdl
if w_energy > w_threshold then
    alarm_status <= '1'; -- trigger alarm
else
    alarm_status <= '0'; -- ga ketrigger
end if;
```

### Cara Menggunakan (How to use)
1. Compile all : Lakukan compile pada seluruh file source code:
- control_unit.vhd
- goertzel_datapath.vhd
- machine_detector_top.vhd
- tb_machine_detector.vhd

2. Simulate : Jalankan simulasi pada file testbench tb_machine_detector.

3. run all

### Pengujian (Testing)
Kami memvalidasi keandalan desain menggunakan skenario Testbench komprehensif yang mencakup 5 fase:
1. Fase Konfigurasi: Menguji kemampuan sistem menerima parameter koefisien (250) dan threshold (2000).
2. Fase Aman (Safe Test): Memberikan sinyal gangguan (noise) frekuensi rendah.
Ekspektasi: Alarm tetap Mati (0).
3. Fase Acak (Random Noise): Menggunakan fungsi UNIFORM untuk membangkitkan sinyal acak guna menguji kekebalan (robustness) sistem.
Ekspektasi: Alarm Mati (0) karena energi tersebar dan tidak terpusat.
4. Fase Bahaya (Danger Test): Memberikan sinyal sinus murni pada frekuensi target dengan amplitudo tinggi.
Ekspektasi: Alarm Menyala (1).
5. Fase High Threshold: Menguji fitur programmable dengan menaikkan threshold ke nilai ekstrem (10.000) saat sinyal bahaya aktif.
Ekspektasi: Alarm Mati (0), membuktikan parameter berhasil diubah secara dinamis.

### Result 
![WhatsApp Image 2025-12-07 at 10 37 09_f2f47469](https://github.com/user-attachments/assets/1c580631-a471-4b32-8f7a-6f59eaffee42)

### Hasil Sintesis
<img width="1181" height="644" alt="Screenshot 2025-12-07 185228" src="https://github.com/user-attachments/assets/f96bbb58-3f45-4d87-b35f-63e4ffc0d459" />

