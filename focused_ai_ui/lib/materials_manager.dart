import 'package:flutter/material.dart';
import 'teacher_dashboard.dart';


class MaterialItem {
  final String title;
  final String subtitle;
  final List<VersionEntry> versions;

  MaterialItem({required this.title, required this.subtitle, required this.versions});
}

class VersionEntry {
  final String timestamp;
  final String content;
  final String user;

  VersionEntry({required this.timestamp, required this.content, required this.user});
}

class MaterialsManagerScreen extends StatefulWidget {
  const MaterialsManagerScreen({super.key});

  @override
  State<MaterialsManagerScreen> createState() => _MaterialsManagerScreenState();
}

class _MaterialsManagerScreenState extends State<MaterialsManagerScreen> {
  List<MaterialItem> materials = [
    MaterialItem(
      title: 'Assignment 1',
      subtitle: 'English Class 1',
      versions: [
        VersionEntry(timestamp: 'June 13, 10:19 PM', content: 'Version A content for Assignment 1', user: 'All anonymous users'),
        VersionEntry(timestamp: 'June 13, 3:39 PM', content: 'Version B content for Assignment 1', user: 'All anonymous users'),
      ],
    ),
    MaterialItem(
      title: 'Lesson Plan 1',
      subtitle: 'Math Class 1',
      versions: [
        VersionEntry(timestamp: 'June 10, 11:34 PM', content: 'Math lesson plan first version', user: 'All anonymous users'),
      ],
    ),
    MaterialItem(
      title: 'Essay 1',
      subtitle: 'Writing Class 1',
      versions: [
        VersionEntry(timestamp: 'June 5, 9:45 PM', content: 'Essay draft 1', user: 'All anonymous users'),
      ],
    ),
  ];

  int selectedIndex = 0;
  int selectedVersionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selectedMaterial = materials[selectedIndex];
    final selectedVersion = selectedMaterial.versions[selectedVersionIndex];

    return Scaffold(
      backgroundColor: Colors.lightGreen[100],
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
                    child: Text('Materials Manager', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search course materials',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: materials.length,
                      itemBuilder: (context, index) {
                        final item = materials[index];
                        return ListTile(
                          title: Text(item.title),
                          subtitle: Text(item.subtitle),
                          selected: selectedIndex == index,
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                              selectedVersionIndex = 0;
                            });
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),

          // Middle Column (Details)
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.center,
              child: Text(
                selectedVersion.content,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Right Column - Version History
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Version history',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: 'All versions',
                    items: const [
                      DropdownMenuItem(
                          value: 'All versions', child: Text('All versions')),
                    ],
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: selectedMaterial.versions.length,
                      itemBuilder: (context, index) {
                        final version = selectedMaterial.versions[index];
                        return ListTile(
                          title: Text(version.timestamp),
                          subtitle: Text(index == 0 ? 'Current version\n${version.user}' : version.user),
                          selected: selectedVersionIndex == index,
                          onTap: () {
                            setState(() {
                              selectedVersionIndex = index;
                            });
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
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
    home: MaterialsManagerScreen(),
  ));
}
