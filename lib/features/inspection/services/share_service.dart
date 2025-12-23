import 'dart:io';
// ignore: unused_import
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:path_provider/path_provider.dart';
import '../models/inspection_model.dart';
import 'pdf_service.dart';
import 'web_download_helper.dart';

class ShareService {
  final PdfService _pdfService = PdfService();

  // Share inspection report as PDF
  Future<void> shareInspectionReport(
    InspectionModel inspection, {
    required Function(String) onLoading,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      onLoading('Generating report...');

      // Generate PDF
      final pdfFile = await _pdfService.generateInspectionReport(inspection);

      onLoading('Preparing to share...');

      // Share PDF
      await share_plus.Share.shareXFiles(
        [share_plus.XFile(pdfFile.path)],
        subject: 'Vehicle Inspection Report - ${inspection.carTitle}',
        text: 'Here is the inspection report for ${inspection.carTitle}',
      );

      onSuccess('Report shared successfully!');
    } catch (e) {
      onError('Failed to share report: $e');
      print('Error sharing report: $e');
    }
  }

  // Download inspection report as PDF
  Future<void> downloadInspectionReport(
    InspectionModel inspection, {
    required Function(String) onLoading,
    required Function(String, String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      onLoading('Generating report...');
      if (kIsWeb) {
        // Generate PDF bytes and trigger browser download
        final bytes =
            await _pdfService.generateInspectionReportBytes(inspection);
        final fileName =
            'inspection_${inspection.carTitle.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await downloadPdfBytesOnWeb(bytes, fileName);
        onSuccess('Report downloaded successfully!', fileName);
        return;
      }

      // Generate PDF file for mobile/desktop
      final pdfFile = await _pdfService.generateInspectionReport(inspection);

      onLoading('Saving to device...');

      // Move to Downloads folder
      final downloadsDir = await _getDownloadsDirectory();
      final fileName =
          'inspection_${inspection.carTitle.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final downloadedFile =
          await pdfFile.copy('${downloadsDir.path}/$fileName');

      onSuccess('Report downloaded successfully!', downloadedFile.path);
    } catch (e) {
      onError('Failed to download report: $e');
      print('Error downloading report: $e');
    }
  }

  // Get Downloads directory
  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // Prefer the public Download folder on Android
      final downloads = Directory('/storage/emulated/0/Download');
      if (await downloads.exists()) {
        return downloads;
      }

      // Fallback to external app-specific directory and create a Download child
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final downloadChild = Directory('${externalDir.path}/Download');
        if (!await downloadChild.exists()) {
          await downloadChild.create(recursive: true);
        }
        return downloadChild;
      }
    } else if (Platform.isIOS) {
      // For iOS, use app documents directory
      return await getApplicationDocumentsDirectory();
    }

    // Fallback to app documents
    return await getApplicationDocumentsDirectory();
  }

  // Open PDF in default viewer
  Future<void> openPdfFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // Open with default PDF viewer
        // Note: This requires additional setup with platform channels
        // For now, just verify the file exists
        print('PDF ready at: $filePath');
      }
    } catch (e) {
      print('Error opening PDF: $e');
      rethrow;
    }
  }

  // Email inspection report
  Future<void> emailInspectionReport(
    InspectionModel inspection, {
    required String recipientEmail,
    required Function(String) onLoading,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      onLoading('Generating report...');

      // Generate PDF
      final pdfFile = await _pdfService.generateInspectionReport(inspection);

      onLoading('Preparing email...');

      // Create email URI
      final subject = 'Vehicle Inspection Report - ${inspection.carTitle}';
      final body =
          'Please find attached the inspection report for ${inspection.carTitle}.';
      final emailUri = Uri(
        scheme: 'mailto',
        path: recipientEmail,
        queryParameters: {
          'subject': subject,
          'body': body,
        },
      );

      // For actual email with attachment, you'd need to use a platform channel
      // or a service like SendGrid. For now, this opens the email client.
      // final canLaunch = await canLaunchUrl(emailUri);
      // if (canLaunch) {
      //   await launchUrl(emailUri);
      // }

      onSuccess('Email prepared. Please send the attachment manually.');
    } catch (e) {
      onError('Failed to prepare email: $e');
      print('Error emailing report: $e');
    }
  }
}
