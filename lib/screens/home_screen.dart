import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/company.dart';
import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_header.dart';
import '../widgets/company_selector.dart';
import 'ticket_entry_screen.dart';
import 'reports_screen.dart';
import 'calibration_screen.dart';
import 'company_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  Company? _selectedCompany;

  static const _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long),
      label: Text('New Ticket'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.summarize_outlined),
      selectedIcon: Icon(Icons.summarize),
      label: Text('Reports'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.print_outlined),
      selectedIcon: Icon(Icons.print),
      label: Text('Print Calibration'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.apartment_outlined),
      selectedIcon: Icon(Icons.apartment),
      label: Text('Companies'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final fs = context.read<FirebaseService>();

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: StreamBuilder<List<Company>>(
                    stream: fs.watchCompanies(),
                    builder: (context, snap) {
                      final companies = snap.data ?? [];
                      if (_selectedCompany == null && companies.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          setState(() => _selectedCompany = companies.first);
                        });
                      }
                      if (companies.isEmpty) {
                        return const Text(
                          'No companies yet — add one in the "Companies" tab.',
                          style: TextStyle(color: Colors.grey),
                        );
                      }
                      return CompanySelector(
                        companies: companies,
                        selected: _selectedCompany,
                        onChanged: (c) => setState(() => _selectedCompany = c),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Sign out',
                  onPressed: () => context.read<AuthService>().signOut(),
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 760;
                Widget body;
                if (_tabIndex == 3) {
                  body = const CompanyManagementScreen();
                } else if (_selectedCompany == null) {
                  body = const Center(
                      child: Text('Select or add a company to continue.'));
                } else {
                  body = IndexedStack(
                    index: _tabIndex,
                    children: [
                      TicketEntryScreen(company: _selectedCompany!),
                      ReportsScreen(company: _selectedCompany!),
                      CalibrationScreen(company: _selectedCompany!),
                    ],
                  );
                }

                if (wide) {
                  return Row(
                    children: [
                      NavigationRail(
                        selectedIndex: _tabIndex,
                        onDestinationSelected: (i) =>
                            setState(() => _tabIndex = i),
                        labelType: NavigationRailLabelType.all,
                        destinations: _destinations,
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(child: body),
                    ],
                  );
                }
                return body;
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 760) return const SizedBox.shrink();
          return NavigationBar(
            selectedIndex: _tabIndex,
            onDestinationSelected: (i) => setState(() => _tabIndex = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined), label: 'Ticket'),
              NavigationDestination(
                  icon: Icon(Icons.summarize_outlined), label: 'Reports'),
              NavigationDestination(
                  icon: Icon(Icons.print_outlined), label: 'Calibrate'),
              NavigationDestination(
                  icon: Icon(Icons.apartment_outlined), label: 'Companies'),
            ],
          );
        },
      ),
    );
  }
}
