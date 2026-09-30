import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/company.dart';
import '../services/firebase_service.dart';
import '../services/export_service.dart';

class ReportsScreen extends StatefulWidget {
  final Company company;
  const ReportsScreen({super.key, required this.company});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now();
  bool _generating = false;
  ExportResult? _lastPdf;
  ExportResult? _lastExcel;

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (picked != null) {
      setState(() {
        _start = picked.start;
        _end = picked.end;
      });
    }
  }

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _lastPdf = null;
      _lastExcel = null;
    });
    try {
      final fs = context.read<FirebaseService>();
      final tickets =
          await fs.getTicketsInRange(widget.company.id, _start, _end);

      final pdf = await ExportService.generateDailySummaryPdf(
        company: widget.company,
        tickets: tickets,
        start: _start,
        end: _end,
      );
      final excel = await ExportService.generateDailySummaryExcel(
        company: widget.company,
        tickets: tickets,
        start: _start,
        end: _end,
      );
      if (!mounted) return;
      setState(() {
        _lastPdf = pdf;
        _lastExcel = excel;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tickets.length} tickets — reports saved.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Daily Supply Summary — ${widget.company.name}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text(
                      'Covers this company only. Switch company at the top '
                      'of the app and generate again for another company — '
                      'reports never mix two companies on the same file.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickRange,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date range',
                          prefixIcon: Icon(Icons.date_range_outlined),
                        ),
                        child: Text(
                            '${dateFmt.format(_start)}  -  ${dateFmt.format(_end)}'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _generating ? null : _generate,
                      icon: _generating
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Generate PDF + Excel'),
                    ),
                  ],
                ),
              ),
            ),
            if (_lastPdf != null || _lastExcel != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    if (_lastPdf != null)
                      ListTile(
                        leading: const Icon(Icons.picture_as_pdf,
                            color: Colors.red),
                        title: Text(_lastPdf!.label),
                        subtitle: Text(_lastPdf!.file.path),
                        trailing: IconButton(
                          icon: const Icon(Icons.share_outlined),
                          onPressed: () => Share.shareXFiles(
                              [XFile(_lastPdf!.file.path)]),
                        ),
                      ),
                    if (_lastExcel != null)
                      ListTile(
                        leading: const Icon(Icons.grid_on, color: Colors.green),
                        title: Text(_lastExcel!.label),
                        subtitle: Text(_lastExcel!.file.path),
                        trailing: IconButton(
                          icon: const Icon(Icons.share_outlined),
                          onPressed: () => Share.shareXFiles(
                              [XFile(_lastExcel!.file.path)]),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
