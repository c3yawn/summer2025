import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class CodeSubmissionService {
  final String baseUrl = 'http://localhost:8080/code';

  Future<Map<String, dynamic>> executeJavaCode({
    required List<http.MultipartFile> javaFiles,
    required String mainClassName,
  }) async {
    final uri = Uri.parse('$baseUrl/execute');
    final request = http.MultipartRequest('POST', uri);

    // Add each pre-prepared MultipartFile to the request
    request.files.addAll(javaFiles);

    // Add other form fields (mainClassName)
    request.fields['mainClassName'] = mainClassName;

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        return {
          'status': 'HTTP Error',
          'compilationErrors': '',
          'programOutput': 'Server responded with status ${response.statusCode}: $responseBody',
          'hasError': true,
        };
      }
    } catch (e) {
      return {
        'status': 'Network Error',
        'compilationErrors': '',
        'programOutput': 'Failed to connect to the server: $e',
        'hasError': true,
      };
    }
  }
}

class CodeExecutionScreen extends StatefulWidget {
  const CodeExecutionScreen({super.key});

  @override
  State<CodeExecutionScreen> createState() => _CodeExecutionScreenState();
}

class _CodeExecutionScreenState extends State<CodeExecutionScreen> {
  final CodeSubmissionService _service = CodeSubmissionService();
  String _output = "Ready to execute code...";
  List<PlatformFile> _selectedFiles = []; // To store selected files
  TextEditingController _mainClassNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mainClassNameController.text = "HelloWorld";
  }

  @override
  void dispose() {
    _mainClassNameController.dispose();
    super.dispose();
  }

  // Function to open file picker
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['java'], // Only allow .java files
        allowMultiple: true, // Allow selecting multiple files
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles = result.files;
        });
        // Optionally, try to infer mainClassName if only one file is selected
        if (_selectedFiles.length == 1) {
          String? fileName = _selectedFiles.first.name;
          if (fileName.endsWith('.java')) {
            _mainClassNameController.text = fileName.substring(0, fileName.length - 5);
          }
        }
      } else {
        // User canceled the picker
        setState(() {
          _selectedFiles = [];
        });
      }
    } catch (e) {
      setState(() {
        _output = "Error picking files: $e";
      });
      print("Error picking files: $e"); // Log to console
    }
  }

  // Function to run code
  Future<void> _runCode() async {
    if (_selectedFiles.isEmpty) {
      setState(() {
        _output = "Please select Java files first.";
      });
      return;
    }

    if (_mainClassNameController.text.isEmpty) {
      setState(() {
        _output = "Please enter the main class name.";
      });
      return;
    }

    setState(() {
      _output = "Executing code...";
    });

    List<http.MultipartFile> filesToSend = [];
    for (var platformFile in _selectedFiles) {
      if (platformFile.bytes != null) { // For web, bytes are directly available
        filesToSend.add(
          http.MultipartFile.fromBytes(
            'javaFiles',
            platformFile.bytes!,
            filename: platformFile.name,
            contentType: MediaType('text', 'plain', {'charset': 'utf-8'}), // Or 'text/x-java-source'
          ),
        );
      } else if (platformFile.path != null) { // For mobile/desktop, read from path
        filesToSend.add(
          await http.MultipartFile.fromPath(
            'javaFiles',
            platformFile.path!,
            filename: platformFile.name,
            contentType: MediaType('text', 'plain', {'charset': 'utf-8'}),
          ),
        );
      }
    }

    try {
      final result = await _service.executeJavaCode(
        javaFiles: filesToSend,
        mainClassName: _mainClassNameController.text,
      );

      setState(() {
        if (result['hasError']) {
          _output = "Error Status: ${result['status']}\n";
          if (result['compilationErrors'] != null && result['compilationErrors'].isNotEmpty) {
            _output += "Compilation Errors:\n${result['compilationErrors']}\n";
          }
          if (result['programOutput'] != null && result['programOutput'].isNotEmpty) {
            _output += "Program Output/Runtime Errors:\n${result['programOutput']}\n";
          }
        } else {
          _output = "Execution Successful!\nProgram Output:\n${result['programOutput']}";
        }
      });
    } catch (e) {
      setState(() {
        _output = "Unexpected error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Java Compiler')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickFiles,
              child: const Text('Select Java Program Files'),
            ),
            const SizedBox(height: 10),
            Text(
              _selectedFiles.isEmpty
                  ? 'No files selected.'
                  : 'Selected Files: ${_selectedFiles.map((f) => f.name).join(', ')}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _mainClassNameController,
              decoration: const InputDecoration(
                labelText: 'Which class contains your main method?',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _runCode,
              child: const Text('Compile and Run Selected Code'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_output),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Java Compiler',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CodeExecutionScreen(),
    );
  }
}