import 'package:flutter/material.dart';
import 'package:care_connnect_prototype_v1/widgets/patient_card.dart';
import 'package:care_connnect_prototype_v1/widgets/app_drawer.dart';
import 'package:care_connnect_prototype_v1/models/patient.dart';

import '../models/patient.dart';
import '../widgets/app_drawer.dart';
import '../widgets/patient_card.dart';

class CaregiverDashboard extends StatefulWidget {
  const CaregiverDashboard({Key? key}) : super(key: key);

  @override
  State<CaregiverDashboard> createState() => _CaregiverDashboardState();
}

class _CaregiverDashboardState extends State<CaregiverDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Mock data for demonstration
  final List<Patient> _patients = [
    Patient(
      id: '1',
      name: 'John Doe',
      age: 75,
      conditions: ['Diabetes', 'Hypertension'],
      lastCheckIn: DateTime.now().subtract(const Duration(hours: 2)),
      nextAppointment: DateTime.now().add(const Duration(days: 3)),
      adherenceRate: 0.85,
      profileImage: null,
    ),
    Patient(
      id: '2',
      name: 'Jane Smith',
      age: 82,
      conditions: ['Arthritis'],
      lastCheckIn: DateTime.now().subtract(const Duration(days: 1)),
      nextAppointment: DateTime.now().add(const Duration(days: 1)),
      adherenceRate: 0.92,
      profileImage: null,
    ),
  ];

  bool _showNotifications = true;

  void _addNewPatient() {
    // Navigate to add patient screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Patient feature coming soon')),
    );
  }

  void _showPatientActions(Patient patient, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action patient: ${patient.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('My Patients'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  setState(() {
                    _showNotifications = !_showNotifications;
                  });
                },
              ),
              if (_showNotifications)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
      drawer: const AppDrawer(userRole: 'caregiver'),
      body: RefreshIndicator(
        onRefresh: () async {
          // Simulate refresh
          await Future.delayed(const Duration(seconds: 2));
        },
        child: CustomScrollView(
          slivers: [
            // Summary Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Message
                    Text(
                      'Welcome back, Caregiver!',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have ${_patients.length} patients under your care',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Tasks Today',
                            '12',
                            Icons.task_alt,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Alerts',
                            '3',
                            Icons.warning_amber,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Check-ins',
                            '5',
                            Icons.check_circle_outline,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Patients',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () {
                            // Show all patients
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Patient List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final patient = _patients[index];
                    return PatientCard(
                      patient: patient,
                      onTap: () => _showPatientActions(patient, 'View'),
                      onEdit: () => _showPatientActions(patient, 'Edit'),
                      onArchive: () => _showPatientActions(patient, 'Archive'),
                    );
                  },
                  childCount: _patients.length,
                ),
              ),
            ),

            // Add padding at bottom
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewPatient,
        icon: const Icon(Icons.add),
        label: const Text('Add Patient'),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}