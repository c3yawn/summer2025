import 'package:flutter/material.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightGreen[300],
        title: const Text('FocusEd AI'),
        centerTitle: true,
        leading: const Icon(Icons.home),
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
            _DashboardButton(imagePath: 'assets/caila.png', label: 'CAILA'),
            const SizedBox(height: 20),
            _DashboardButton(imagePath: 'assets/materials.png', label: 'Materials Manager'),
            const SizedBox(height: 20),
            _DashboardButton(imagePath: 'assets/content_checker.png', label: 'Content Checker'),
          ],
        ),
      ),
    );
  }
}

class _DashboardButton extends StatelessWidget {
  final String imagePath;
  final String label;

  const _DashboardButton({required this.imagePath, required this.label});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.all(16),
        minimumSize: const Size.fromHeight(80),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage(imagePath),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 18, color: Colors.black),
            ),
          ),
        ],
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
