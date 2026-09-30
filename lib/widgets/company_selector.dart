import 'package:flutter/material.dart';
import '../models/company.dart';

class CompanySelector extends StatelessWidget {
  final List<Company> companies;
  final Company? selected;
  final ValueChanged<Company?> onChanged;

  const CompanySelector({
    super.key,
    required this.companies,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Company>(
      value: selected,
      decoration: const InputDecoration(
        labelText: 'Company',
        prefixIcon: Icon(Icons.apartment_outlined),
      ),
      items: companies
          .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
          .toList(),
      onChanged: onChanged,
      isExpanded: true,
    );
  }
}
