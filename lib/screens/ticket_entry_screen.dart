import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/company.dart';
import '../models/ticket.dart';
import '../models/printer_profile.dart';
import '../services/firebase_service.dart';
import '../services/print_service.dart';

class TicketEntryScreen extends StatefulWidget {
  final Company company;
  const TicketEntryScreen({super.key, required this.company});

  @override
  State<TicketEntryScreen> createState() => _TicketEntryScreenState();
}

class _TicketEntryScreenState extends State<TicketEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _serialCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay? _timeLoaded;
  final _typeOfMixCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _customerCtrl = TextEditingController();
  final _projectJoCtrl = TextEditingController();
  final _othersCtrl = TextEditingController();
  final _truckNumberCtrl = TextEditingController();
  final _truckDriverCtrl = TextEditingController();
  final _siteTempCtrl = TextEditingController();
  final _supvrCtrl = TextEditingController();
  TimeOfDay? _arrJob;
  final _receivedByCtrl = TextEditingController();
  TimeOfDay? _depJob;
  final _jobSiteCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _serialCtrl,
      _typeOfMixCtrl,
      _quantityCtrl,
      _tempCtrl,
      _customerCtrl,
      _projectJoCtrl,
      _othersCtrl,
      _truckNumberCtrl,
      _truckDriverCtrl,
      _siteTempCtrl,
      _supvrCtrl,
      _receivedByCtrl,
      _jobSiteCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmtTime(TimeOfDay? t) {
    if (t == null) return '';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  Future<void> _pickTime(ValueChanged<TimeOfDay> onPicked,
      {TimeOfDay? initial}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? TimeOfDay.now(),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Ticket _buildTicket() {
    return Ticket(
      id: '',
      companyId: widget.company.id,
      serialNumber: _serialCtrl.text.trim(),
      date: _date,
      timeLoaded: _fmtTime(_timeLoaded),
      typeOfMix: _typeOfMixCtrl.text.trim(),
      quantityTon: double.tryParse(_quantityCtrl.text.trim()) ?? 0,
      temp: _tempCtrl.text.trim(),
      customerName: _customerCtrl.text.trim(),
      projectJoNo: _projectJoCtrl.text.trim(),
      others: _othersCtrl.text.trim(),
      truckNumber: _truckNumberCtrl.text.trim(),
      truckDriver: _truckDriverCtrl.text.trim(),
      siteTemp: _siteTempCtrl.text.trim(),
      projectSupvr: _supvrCtrl.text.trim(),
      arrJob: _fmtTime(_arrJob),
      receivedBy: _receivedByCtrl.text.trim(),
      depJob: _fmtTime(_depJob),
      jobSiteNameNumber: _jobSiteCtrl.text.trim(),
    );
  }

  void _clearForm() {
    _serialCtrl.clear();
    _typeOfMixCtrl.clear();
    _quantityCtrl.clear();
    _tempCtrl.clear();
    _customerCtrl.clear();
    _projectJoCtrl.clear();
    _othersCtrl.clear();
    _truckNumberCtrl.clear();
    _truckDriverCtrl.clear();
    _siteTempCtrl.clear();
    _supvrCtrl.clear();
    _receivedByCtrl.clear();
    _jobSiteCtrl.clear();
    setState(() {
      _timeLoaded = null;
      _arrJob = null;
      _depJob = null;
      _date = DateTime.now();
    });
  }

  Future<void> _save({required bool andPrint}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final fs = context.read<FirebaseService>();
    final ticket = _buildTicket();
    try {
      await fs.addTicket(ticket);
      if (andPrint) {
        final profile = await fs.getPrinterProfile(widget.company.id);
        await PrintService.printTicket(ticket, profile);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved${andPrint ? ' & sent to printer' : ''}.')),
      );
      _clearForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reprint(Ticket ticket) async {
    final fs = context.read<FirebaseService>();
    final profile = await fs.getPrinterProfile(widget.company.id);
    await PrintService.printTicket(ticket, profile);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('New Asphalt Mix Ticket — ${widget.company.name}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text(
                        'Serial No. below is for your records only — it is '
                        'never printed, since the paper ticket already has one.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      _row([
                        _text(_serialCtrl, 'Serial No. (internal)',
                            icon: Icons.tag, required: true),
                        _dateField(),
                      ]),
                      _row([
                        _timeField('Time Loaded', _timeLoaded,
                            (t) => setState(() => _timeLoaded = t)),
                        _text(_typeOfMixCtrl, 'Type of Mix', required: true),
                      ]),
                      _row([
                        _text(_quantityCtrl, 'Quantity (Ton)',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            required: true),
                        _text(_tempCtrl, 'Temp'),
                      ]),
                      _row([
                        _text(_customerCtrl, 'Customer Name', required: true),
                        _text(_projectJoCtrl, 'Project / J.O. No.'),
                      ]),
                      _text(_othersCtrl, 'Others', maxLines: 2),
                      const Divider(height: 28),
                      _row([
                        _text(_truckNumberCtrl, 'Truck Number'),
                        _text(_truckDriverCtrl, 'Truck Driver'),
                      ]),
                      _row([
                        _text(_siteTempCtrl, 'Site Temp'),
                        _text(_supvrCtrl, 'Project Supvr.'),
                      ]),
                      _row([
                        _timeField('Arr. Job', _arrJob,
                            (t) => setState(() => _arrJob = t)),
                        _text(_receivedByCtrl, 'Received By'),
                      ]),
                      _row([
                        _timeField('Dep. Job', _depJob,
                            (t) => setState(() => _depJob = t)),
                        _text(_jobSiteCtrl, '(At Job Site Name & Number)'),
                      ]),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _saving ? null : () => _save(andPrint: false),
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Save only'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : () => _save(andPrint: true),
                              icon: _saving
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.print_outlined),
                              label: const Text('Save & Print'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text("Today's entries — ${widget.company.name}",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _TodayList(company: widget.company, onReprint: _reprint),
          ],
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }

  Widget _text(
    TextEditingController ctrl,
    String label, {
    IconData? icon,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _dateField() {
    return InkWell(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(DateFormat('dd/MM/yyyy').format(_date)),
      ),
    );
  }

  Widget _timeField(
      String label, TimeOfDay? value, ValueChanged<TimeOfDay> onPicked) {
    return InkWell(
      onTap: () => _pickTime(onPicked, initial: value),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time),
        ),
        child: Text(value == null ? 'Tap to set' : _fmtTime(value)),
      ),
    );
  }
}

class _TodayList extends StatelessWidget {
  final Company company;
  final ValueChanged<Ticket> onReprint;
  const _TodayList({required this.company, required this.onReprint});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirebaseService>();
    return StreamBuilder<List<Ticket>>(
      stream: fs.watchTicketsForDay(company.id, DateTime.now()),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final tickets = snap.data!;
        if (tickets.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No entries yet today.',
                style: TextStyle(color: Colors.grey)),
          );
        }
        final totalTon =
            tickets.fold<double>(0, (s, t) => s + t.quantityTon);
        return Card(
          child: Column(
            children: [
              for (final t in tickets)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: Text(
                      '${t.serialNumber.isEmpty ? '—' : t.serialNumber}   '
                      '${t.typeOfMix}   ${t.quantityTon} Ton'),
                  subtitle: Text(
                      '${t.customerName}   •   Truck ${t.truckNumber}   •   ${t.timeLoaded}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.print_outlined),
                    tooltip: 'Reprint',
                    onPressed: () => onReprint(t),
                  ),
                ),
              const Divider(height: 1),
              ListTile(
                dense: true,
                title: Text('Total today: ${totalTon.toStringAsFixed(2)} Ton'
                    '  (${tickets.length} tickets)'),
              ),
            ],
          ),
        );
      },
    );
  }
}
