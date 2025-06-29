import 'package:flutter/material.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 95, 190, 253),
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
      backgroundColor: Color.fromARGB(255, 148, 207, 247),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Text(
              'Student Homepage',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Text('Welcome, [user]!', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 40),
            _DashboardButton(imagePath: 'assets/caila.png', label: 'CAILA'),
            const SizedBox(height: 20),
            _DashboardButton(imagePath: 'assets/materials.png', label: 'Code Compiler'),
            
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
    home: StudentDashboard(),
  ));
}
