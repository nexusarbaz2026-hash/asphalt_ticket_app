import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/company.dart';
import '../models/printer_profile.dart';
import '../services/firebase_service.dart';
import '../services/print_service.dart';

const Map<String, String> _fieldLabels = {
  'date': 'Date',
  'timeLoaded': 'Time Loaded',
  'typeOfMix': 'Type of Mix',
  'quantityTon': 'Quantity (Ton)',
  'temp': 'Temp',
  'customerName': 'Customer Name',
  'projectJoNo': 'Project / J.O. No.',
  'others': 'Others',
  'truckNumber': 'Truck Number',
  'truckDriver': 'Truck Driver',
  'siteTemp': 'Site Temp',
  'projectSupvr': 'Project Supvr.',
  'arrJob': 'Arr. Job',
  'receivedBy': 'Received By',
  'depJob': 'Dep. Job',
  'jobSiteNameNumber': '(At Job Site Name & Number)',
};

/// Lets you nudge every field until it lands exactly on the pre-printed
/// blank line, then Save. This profile is stored per company in
/// Firestore, so it syncs to every device/platform automatically.
///
/// Workflow:
///  1. Load one blank ticket into the LQ-690II.
///  2. Tap "Test print" — it prints each field's label at its current
///     position on a page sized to Page width/height below.
///  3. Compare the printed sheet to the blank ticket. Select a field
///     below, nudge it with the arrows until it lines up, repeat.
///  4. Tap Save.
class CalibrationScreen extends StatefulWidget {
  final Company company;
  const CalibrationScreen({super.key, required this.company});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  PrinterProfile? _profile;
  String? _selectedField;
  double _step = 1.0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CalibrationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.company.id != widget.company.id) _load();
  }

  Future<void> _load() async {
    final fs = context.read<FirebaseService>();
    final profile = await fs.getPrinterProfile(widget.company.id);
    if (mounted) setState(() => _profile = profile);
  }

  Future<void> _save() async {
    if (_profile == null) return;
    setState(() => _saving = true);
    final fs = context.read<FirebaseService>();
    await fs.savePrinterProfile(widget.company.id, _profile!);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Calibration saved.')));
  }

  void _nudge(double dx, double dy) {
    if (_profile == null || _selectedField == null) return;
    setState(() {
      _profile = _profile!.nudge(_selectedField!, dx, dy);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Print Calibration — ${widget.company.name}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Positions here are millimetres from the top-left of the '
              'physical ticket. Tap a field name, then use the arrows to '
              'nudge it — the preview below updates live.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _preview(profile)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _controls(profile)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(PrinterProfile profile) {
    const maxPreviewWidth = 560.0;
    final scale = maxPreviewWidth / profile.pageWidthMm;
    final previewHeight = profile.pageHeightMm * scale;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Preview (not to exact scale on screen — use the '
                'test print to verify against paper)',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              width: maxPreviewWidth,
              height: previewHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                color: Colors.grey.shade50,
              ),
              child: Stack(
                children: [
                  for (final key in kPrintableFields)
                    Positioned(
                      left: profile.positions[key]!.xMm * scale,
                      top: profile.positions[key]!.yMm * scale,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedField = key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: _selectedField == key
                                ? Colors.amber.shade200
                                : Colors.teal.shade50,
                            border: Border.all(
                              color: _selectedField == key
                                  ? Colors.amber.shade800
                                  : Colors.teal.shade200,
                            ),
                          ),
                          child: Text(
                            _fieldLabels[key] ?? key,
                            style: const TextStyle(fontSize: 9),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls(PrinterProfile profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: profile.pageWidthMm.toString(),
                    decoration: const InputDecoration(labelText: 'Page width (mm)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final val = double.tryParse(v);
                      if (val != null) {
                        setState(() => _profile = profile.copyWith(pageWidthMm: val));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: profile.pageHeightMm.toString(),
                    decoration: const InputDecoration(labelText: 'Page height (mm)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final val = double.tryParse(v);
                      if (val != null) {
                        setState(() => _profile = profile.copyWith(pageHeightMm: val));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedField,
              decoration: const InputDecoration(labelText: 'Field to adjust'),
              items: kPrintableFields
                  .map((k) => DropdownMenuItem(
                      value: k, child: Text(_fieldLabels[k] ?? k)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedField = v),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Step:'),
                const SizedBox(width: 8),
                DropdownButton<double>(
                  value: _step,
                  items: const [0.5, 1.0, 2.0, 5.0]
                      .map((s) => DropdownMenuItem(value: s, child: Text('${s}mm')))
                      .toList(),
                  onChanged: (v) => setState(() => _step = v ?? 1.0),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _arrowPad(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => PrintService.printCalibrationTest(profile),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Test print'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _arrowPad() {
    final enabled = _selectedField != null;
    return Column(
      children: [
        IconButton(
          onPressed: enabled ? () => _nudge(0, -_step) : null,
          icon: const Icon(Icons.arrow_upward),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: enabled ? () => _nudge(-_step, 0) : null,
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 40),
            IconButton(
              onPressed: enabled ? () => _nudge(_step, 0) : null,
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
        IconButton(
          onPressed: enabled ? () => _nudge(0, _step) : null,
          icon: const Icon(Icons.arrow_downward),
        ),
      ],
    );
  }
}
