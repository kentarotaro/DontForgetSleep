/**
 * REPOSITORI EMBEDDING — STUB MVP (Dibiarkan Kosong)
 * 
 * Modul ini sengaja dikosongkan untuk versi MVP.
 * 
 * KAPAN HARUS DIAKTIFKAN:
 * Aktifkan repositori ini ketika skema mulai memperkenalkan isian teks bebas (free-text)
 * yang memiliki nilai semantik, secara spesifik:
 *   - SleepLog.dreamJournal: string (Jurnal mimpi)
 *   - DailyCheckin.emotionNotes: string (Catatan emosi)
 * 
 * RENCANA IMPLEMENTASI:
 * - Embedder: Model Gemini text-embedding-004
 * - Vector Store: Firestore dengan perhitungan cosine similarity manual (untuk MVP) atau
 *                 Vertex AI Vector Search (untuk skala sesudah hackathon)
 * - Retriever: Pencarian Top-K similarity yang hanya dibatasi pada dokumen milik pengguna itu sendiri
 */

export {};
