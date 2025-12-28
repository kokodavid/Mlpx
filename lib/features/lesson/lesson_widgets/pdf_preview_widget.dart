import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PdfPreviewWidget extends StatefulWidget {
  final String pdfUrl;
  final String fileName;
  const PdfPreviewWidget({Key? key, required this.pdfUrl, required this.fileName}) : super(key: key);

  @override
  State<PdfPreviewWidget> createState() => _PdfPreviewWidgetState();
}

class _PdfPreviewWidgetState extends State<PdfPreviewWidget> {
  String? localPath;

  @override
  void initState() {
    super.initState();
    _downloadAndSavePdf();
  }

  Future<void> _downloadAndSavePdf() async {
    final response = await http.get(Uri.parse(widget.pdfUrl));
    if (response.statusCode == 200) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.fileName}.pdf');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      setState(() {
        localPath = file.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pdfUri = Uri.parse(widget.pdfUrl);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () async {
              if (await canLaunchUrl(pdfUri)) {
                await launchUrl(pdfUri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: localPath == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.fileName,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Open this PDF in an external viewer.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        if (await canLaunchUrl(pdfUri)) {
                          await launchUrl(pdfUri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: const Text('Open PDF'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localPath!,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 
