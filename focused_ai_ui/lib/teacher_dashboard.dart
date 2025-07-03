import 'package:flutter/material.dart';
import 'materials_manager.dart';
import 'content_checker.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightGreen[300],
        title: const Text('FocusEd AI'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TeacherDashboard()),
            );
          },
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Icon(Icons.account_circle),
          )
        ],
      ),
      backgroundColor: Colors.lightGreen[100],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text(
              'Teacher Homepage',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Text('Welcome, [user]!', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 40),
            _DashboardButton(label: 'CAILA', onTap: () {
              // TODO: Add navigation for CAILA if needed
            }),
            const SizedBox(height: 20),
            _DashboardButton(
              label: 'Materials Manager',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MaterialsManagerScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            _DashboardButton(
              label: 'Content Checker',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContentCheckerScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DashboardButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
        minimumSize: const Size.fromHeight(80),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, color: Colors.black),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TeacherDashboard(),
  ));
}
