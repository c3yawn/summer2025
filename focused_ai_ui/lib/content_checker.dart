import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ContentCheckerScreen(),
  ));
}

class ContentCheckerScreen extends StatefulWidget {
  const ContentCheckerScreen({super.key});

  @override
  State<ContentCheckerScreen> createState() => _ContentCheckerScreenState();
}

class _ContentCheckerScreenState extends State<ContentCheckerScreen> {
  int selectedEssayIndex = 0;

  final List<Map<String, String>> essays = [
    {
      'title': 'Essay 1',
      'subtitle': 'Student 1',
      'content': '''Lorem Ipsum Essay\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Sed at nisl nec libero luctus cursus. ...''',
    },
    {
      'title': 'Essay 2',
      'subtitle': 'Student 2',
      'content': 'Essay 2 content...',
    },
    // Add more essays as needed
  ];

  @override
  Widget build(BuildContext context) {
    final currentEssay = essays[selectedEssayIndex];

    return Scaffold(
      backgroundColor: Colors.lightGreen[100],
      appBar: AppBar(
        backgroundColor: Colors.lightGreen[300],
        title: const Text('FocusEd AI'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Icon(Icons.account_circle),
          )
        ],
      ),
      body: Row(
        children: [
          // Left Sidebar
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.lightGreen[200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('Content Checker',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search course materials',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: essays.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(essays[index]['title']!),
                          subtitle: Text(essays[index]['subtitle']!),
                          selected: selectedEssayIndex == index,
                          onTap: () {
                            setState(() {
                              selectedEssayIndex = index;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Middle Column - Essay Content
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Text(
                  currentEssay['content']!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),

          // Right Column - CAILA Logs and Report
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.green[50],
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CAILA Logs:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'PLACEHOLDER',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const Divider(height: 30, thickness: 1),
                  const Text('Report:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'Writing Composition Breakdown:\nStudent written: PLACEHOLDER%\nCAILA generated: PLACEHOLDER%',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
