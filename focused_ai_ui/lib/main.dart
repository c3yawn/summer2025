import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class CodeSubmissionService {
  final String baseUrl = 'http://localhost:8080/code';

  Future<Map<String, dynamic>> executeCode({
    required List<http.MultipartFile> codeFiles,
    required String mainClassName,
    required String language,
  }) async {
    final uri = Uri.parse('$baseUrl/execute');
    final request = http.MultipartRequest('POST', uri);

    // Add form fields for main file name and language
    request.fields['mainClassName'] = mainClassName;
    request.fields['language'] = language;

    // Add the uploaded files (named "javaFiles" for compatibility)
    request.files.addAll(codeFiles);

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
  List<PlatformFile> _selectedFiles = [];
  TextEditingController _mainClassNameController = TextEditingController();

  String _selectedLanguage = 'java'; // default selection
  final List<String> _supportedLanguages = ['java', 'javascript', 'python'];

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

  // Opens the file picker with dynamic allowed extensions based on language
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _selectedLanguage == 'java' ? ['java'] 
        : _selectedLanguage == 'javascript'
        ? ['js']
        : ['py'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles = result.files;
        });
        // Auto-set the main file name if only one file is selected
        if (_selectedFiles.length == 1) {
          String fileName = _selectedFiles.first.name;
          if (_selectedLanguage == 'java' && fileName.endsWith('.java')) {
            _mainClassNameController.text = fileName.substring(0, fileName.length - 5);
          } else if (_selectedLanguage == 'javascript' && fileName.endsWith('.js')) {
            _mainClassNameController.text = fileName.substring(0, fileName.length - 3);
          } else if (_selectedLanguage == 'python' && fileName.endsWith('.py')) {
            _mainClassNameController.text = fileName.substring(0, fileName.length - 3);
          }
        }

      } else {
        setState(() {
          _selectedFiles = [];
        });
      }
    } catch (e) {
      setState(() {
        _output = "Error picking files: $e";
      });
      print("Error picking files: $e");
    }
  }

  // Executes the selected code
  Future<void> _runCode() async {
    if (_selectedFiles.isEmpty) {
      setState(() {
        _output = "Please select code files first.";
      });
      return;
    }
    if (_mainClassNameController.text.isEmpty) {
      setState(() {
        _output = "Please enter the main file (or class) name.";
      });
      return;
    }
    setState(() {
      _output = "Executing code...";
    });

    // Prepare files to send
    List<http.MultipartFile> filesToSend = [];
    for (var platformFile in _selectedFiles) {
      if (platformFile.bytes != null) {
        filesToSend.add(
          http.MultipartFile.fromBytes(
            'javaFiles',
            platformFile.bytes!,
            filename: platformFile.name,
            contentType: MediaType('text', 'plain', {'charset': 'utf-8'}),
          ),
        );
      } else if (platformFile.path != null) {
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
      final result = await _service.executeCode(
        codeFiles: filesToSend,
        mainClassName: _mainClassNameController.text,
        language: _selectedLanguage,
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
      appBar: AppBar(
        title: const Text('Code Compiler'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row with dropdown and file picker button
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedLanguage = newValue!;
                        // Reset file selection and main file name when language changes
                        _selectedFiles = [];
                        _mainClassNameController.text = "";
                      });
                    },
                    items: _supportedLanguages.map((lang) {
                      return DropdownMenuItem(
                        value: lang,
                        child: Text(lang.toUpperCase()),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _pickFiles,
                  child: const Text('Select Code Files'),
                ),
              ],
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
                labelText: 'Main File (or Class) Name',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _runCode,
              child: const Text('Compile and Run Code'),
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
      title: 'Code Compiler',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CodeExecutionScreen(),
    );
  }
}