import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/company.dart';
import '../services/firebase_service.dart';

class CompanyManagementScreen extends StatelessWidget {
  const CompanyManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirebaseService>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Companies',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showEditDialog(context, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Add company'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Each company here is a fully separate data silo — its own '
              'tickets, reports and print calibration. Nothing is ever '
              'shared or mixed between companies.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Company>>(
                stream: fs.watchCompanies(),
                builder: (context, snap) {
                  final companies = snap.data ?? [];
                  if (companies.isEmpty) {
                    return const Center(
                        child: Text('No companies yet.',
                            style: TextStyle(color: Colors.grey)));
                  }
                  return ListView.separated(
                    itemCount: companies.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final c = companies[i];
                      return ListTile(
                        leading: const Icon(Icons.apartment_outlined),
                        title: Text(c.name),
                        subtitle: Text(
                          [
                            if (c.address != null) c.address,
                            if (c.crNumber != null) 'C.R. ${c.crNumber}',
                          ].whereType<String>().join('   •   '),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showEditDialog(context, c),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Company? existing) {
    showDialog(
      context: context,
      builder: (_) => _CompanyEditDialog(existing: existing),
    );
  }
}

class _CompanyEditDialog extends StatefulWidget {
  final Company? existing;
  const _CompanyEditDialog({this.existing});

  @override
  State<_CompanyEditDialog> createState() => _CompanyEditDialogState();
}

class _CompanyEditDialogState extends State<_CompanyEditDialog> {
  late final _nameCtrl =
      TextEditingController(text: widget.existing?.name ?? '');
  late final _nameArCtrl =
      TextEditingController(text: widget.existing?.nameArabic ?? '');
  late final _addressCtrl =
      TextEditingController(text: widget.existing?.address ?? '');
  late final _crCtrl =
      TextEditingController(text: widget.existing?.crNumber ?? '');
  late final _vatCtrl =
      TextEditingController(text: widget.existing?.vatNumber ?? '');
  late final _phoneCtrl =
      TextEditingController(text: widget.existing?.phone ?? '');
  bool _saving = false;

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final fs = context.read<FirebaseService>();
    final company = Company(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text.trim(),
      nameArabic: _nameArCtrl.text.trim().isEmpty ? null : _nameArCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      crNumber: _crCtrl.text.trim().isEmpty ? null : _crCtrl.text.trim(),
      vatNumber: _vatCtrl.text.trim().isEmpty ? null : _vatCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );
    await fs.saveCompany(company);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add company' : 'Edit company'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Company name *'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nameArCtrl,
                decoration:
                    const InputDecoration(labelText: 'Company name (Arabic)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _crCtrl,
                decoration: const InputDecoration(labelText: 'C.R. No.'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _vatCtrl,
                decoration: const InputDecoration(labelText: 'VAT No.'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
