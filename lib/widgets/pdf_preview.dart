import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/budget_provider.dart';

class PDFPreviewPage extends StatelessWidget {
  final String category;
  final List<Transaction> transactions;
  final Map<String, double> balances;

  const PDFPreviewPage({
    super.key,
    required this.category,
    required this.transactions,
    required this.balances,
  });

  Future<String> _generatePDF() async {
    final pdf = pw.Document();
    
    // Türkçe karakter desteği için font yükleme
    final font = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(font);

    final boldFont = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final ttfBold = pw.Font.ttf(boldFont);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttfBold,
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerLeft,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Knuclew-BudgetControl',
            style: pw.TextStyle(
              font: ttf,
              color: PdfColors.grey600,
              fontSize: 10,
            ),
          ),
        ),
        build: (context) => [
          // Başlık ve tarih
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Bütçe Raporu - $category',
                  style: pw.TextStyle(
                    fontSize: 24,
                    font: ttfBold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Oluşturulma Tarihi: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          
          // Özet tablosu
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue200),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Table(
              border: pw.TableBorder.symmetric(
                inside: pw.BorderSide(color: PdfColors.blue200),
              ),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue100,
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(12),
                      child: pw.Text(
                        'Toplam Gelir',
                        style: pw.TextStyle(font: ttfBold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(12),
                      child: pw.Text(
                        'Toplam Gider',
                        style: pw.TextStyle(font: ttfBold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(12),
                      child: pw.Text(
                        'Net Bakiye',
                        style: pw.TextStyle(font: ttfBold),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(12),
                      child: pw.Text(
                        '${balances['Gelir'] ?? 0} ₺',
                        style: const pw.TextStyle(color: PdfColors.green700),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(12),
                      child: pw.Text(
                        '${balances['Gider'] ?? 0} ₺',
                        style: const pw.TextStyle(color: PdfColors.red700),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(12),
                      child: () {
                        final netAmount = ((balances['Gelir'] ?? 0) + (balances['Tasarruf'] ?? 0)) - (balances['Gider'] ?? 0);
                        return pw.Text(
                          '${netAmount < 0 ? '-' : ''}${netAmount.abs()} ₺',
                          style: pw.TextStyle(
                            font: ttfBold,
                            color: netAmount < 0 ? PdfColors.red700 : PdfColors.blue700,
                          ),
                        );
                      }(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // İşlem geçmişi başlığı
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'İşlem Geçmişi',
              style: pw.TextStyle(
                fontSize: 18,
                font: ttfBold,
                color: PdfColors.blue800,
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          
          ...transactions.map((transaction) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          transaction.subCategory,
                          style: pw.TextStyle(
                            font: ttfBold,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(transaction.date),
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                        if (transaction.note != null) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            transaction.note!,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.Text(
                    '${transaction.type == 'Gelir' ? '+' : '-'}${transaction.amount} ₺',
                    style: pw.TextStyle(
                      font: ttfBold,
                      color: transaction.type == 'Gelir' 
                          ? PdfColors.green700 
                          : PdfColors.red700,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/rapor.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rapor Önizleme',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 22,
          ),
        ),
      ),
      body: FutureBuilder<String>(
        future: _generatePDF(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Hata: ${snapshot.error}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.red,
                ),
              ),
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  size: isSmallScreen ? 72 : 96,
                  color: Colors.red,
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),
                Text(
                  'PDF Raporu Hazır!',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 32 : 48),
                SizedBox(
                  width: isSmallScreen ? 200 : 300,
                  height: isSmallScreen ? 48 : 56,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      Icons.share,
                      size: isSmallScreen ? 24 : 28,
                    ),
                    label: Text(
                      'Raporu Paylaş',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 20,
                      ),
                    ),
                    onPressed: () async {
                      if (snapshot.hasData) {
                        await Share.shareXFiles(
                          [XFile(snapshot.data!)],
                          subject: 'Bütçe Raporu - $category',
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 