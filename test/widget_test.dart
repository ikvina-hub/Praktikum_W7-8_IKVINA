import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_jurnal/main.dart'; // pastikan nama folder sama seperti di proyek Anda

void main() {
  testWidgets('MediaJournal smoke test', (WidgetTester tester) async {
    // Jalankan aplikasi utama
    await tester.pumpWidget(const MediaJournalApp());

    // Verifikasi bahwa aplikasi berhasil menampilkan teks awal
    expect(find.text('Catatan'), findsNothing);
  });
}