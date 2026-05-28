import { onRequest } from 'firebase-functions/v2/https';
import { exchangeCodeForTokens, saveCalendarTokens } from '../calendar/calendarClient';

export const oauthCallback = onRequest(async (req, res) => {
  try {
    // Google mengirimkan 'code' rahasia dan 'state' (yang kita isi dengan userId) melalui URL
    const { code, state: userId } = req.query;

    if (!code || typeof code !== 'string') {
      res.status(400).send('Gagal: Kode otorisasi tidak ditemukan.');
      return;
    }

    if (!userId || typeof userId !== 'string') {
      res.status(400).send('Gagal: ID Pengguna tidak valid.');
      return;
    }

    // 1. Tukar kode rahasia dengan Token Akses resmi dari Google
    const tokens = await exchangeCodeForTokens(code);

    // 2. Simpan token tersebut ke database Firestore agar tersimpan permanen
    await saveCalendarTokens(userId, tokens);

    // 3. Tampilkan pesan sukses di peramban pengguna
    res.status(200).send(`
      <html>
        <body style="font-family: sans-serif; text-align: center; padding-top: 50px;">
          <h1 style="color: #4CAF50;">✅ Autentikasi Berhasil!</h1>
          <p>Google Calendar Anda telah terhubung ke D.F.S.</p>
          <p style="color: #666;">Anda sudah bisa menutup halaman ini dan kembali ke aplikasi.</p>
        </body>
      </html>
    `);
  } catch (error) {
    console.error("🔥 [oauthCallback] ERROR:", error);
    res.status(500).send('Terjadi kesalahan sistem saat otentikasi OAuth.');
  }
});
