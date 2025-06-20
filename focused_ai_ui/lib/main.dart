import 'dart:convert';
import 'dart:io';
import 'package:highlight/highlight_core.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/cpp.dart';

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

  final Map<String, Mode> _languageModes = {
    'java': java,
    'javascript': javascript,
    'python': python,
    'cpp': cpp,
  };

  // final TextEditingController _codeEditorController = TextEditingController();
  late final CodeController _codeEditorController;
  final TextEditingController _mainClassNameController = TextEditingController();

  PlatformFile? _activeFile; // currently selected file (if any)
  String _output = "Ready to execute code...";
  List<PlatformFile> _selectedFiles = [];
  String _selectedLanguage = 'java'; // default selection

  final List<String> _supportedLanguages = ['java', 'javascript', 'python', 'cpp'];

  @override
  void initState() {
    super.initState();

    _mainClassNameController.text = "HelloWorld";

    _codeEditorController = CodeController(
      text: '',
      language: _languageModes['java']!, // default
    );
  }

  @override
  void dispose() {
    _codeEditorController.dispose();
    _mainClassNameController.dispose();
    super.dispose();
  }

  // Opens the file picker with dynamic allowed extensions based on language
  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _selectedLanguage == 'java' 
            ? ['java'] 
            : _selectedLanguage == 'javascript'
              ? ['js']
              : _selectedLanguage == 'python'
                ? ['py']
                : ['cpp'],
        allowMultiple: false, // only one file for editable use case
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles = result.files;
          _activeFile = result.files.first;
        });

        if(_activeFile!.bytes != null) {
          _codeEditorController.text = utf8.decode(_activeFile!.bytes!);
        } else if (_activeFile!.path != null) {
          final content = await File(_activeFile!.path!).readAsString();
          _codeEditorController.text = content;
        }
        
        final fileName = _activeFile!.name;
        if (_selectedLanguage == 'java' && fileName.endsWith('.java')) {
          _mainClassNameController.text = fileName.substring(0, fileName.length - 5);
        } else if (_selectedLanguage == 'javascript' && fileName.endsWith('.js')) {
          _mainClassNameController.text = fileName.substring(0, fileName.length - 3);
        } else if (_selectedLanguage == 'python' && fileName.endsWith('.py')) {
          _mainClassNameController.text = fileName.substring(0, fileName.length - 3);
        } else if (_selectedLanguage == 'cpp' && fileName.endsWith('.cpp')) {
          _mainClassNameController.text = fileName.substring(0, fileName.length - 4);
        }
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
        _output = "Please enter the main file (or class) name.";
      });
      return;
    }
    if (_mainClassNameController.text.isEmpty) {
      setState(() {
        _output = "Code editor is empty. Please write or upload code first.";
      });
      return;
    }
    setState(() {
      _output = "Executing code...";
    });

    final codeBytes = utf8.encode(_codeEditorController.text);
    final String fileExtension = _selectedLanguage == 'java'
        ? '.java'
        : _selectedLanguage == 'javascript'
            ? '.js'
            : _selectedLanguage == 'python'
                ? '.py'
                : '.cpp';
    
    final String filename = _mainClassNameController.text + fileExtension;

    final multipartFile = http.MultipartFile.fromBytes(
      'javaFiles',
      codeBytes,
      filename: filename,
      contentType: MediaType('text', 'plain', {'charset': 'utf-8'}),
    );

    try {
      final result = await _service.executeCode(
        codeFiles: [multipartFile],
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

  Future<void> _saveCodeToFile() async {
  final code = _codeEditorController.text;
  final fileExtension = _selectedLanguage == 'java'
      ? 'java'
      : _selectedLanguage == 'javascript'
          ? 'js'
          : _selectedLanguage == 'python'
              ? 'py'
              : 'cpp';

  final filename = _mainClassNameController.text.isNotEmpty
      ? _mainClassNameController.text
      : 'my_code';

  final bytes = Uint8List.fromList(code.codeUnits);

  await FileSaver.instance.saveFile(
    name: filename,
    bytes: bytes,
    ext: fileExtension,
  );
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
                      if (newValue != null && _languageModes.containsKey(newValue)) {
                        setState(() {
                          _selectedLanguage = newValue;
                          _selectedFiles = [];
                          _mainClassNameController.text = "";
                          _codeEditorController.language = _languageModes[_selectedLanguage]!;
                        });
                      }
                    },
                    items: _supportedLanguages.map((lang) {
                      return DropdownMenuItem(
                        value: lang,
                        child: Text(lang == 'cpp' ? 'C++' : lang.toUpperCase()),
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
            TextField(
              controller: _mainClassNameController,
              decoration: const InputDecoration(
                labelText: 'Main File (or Class) Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Code Editor:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child:CodeTheme(
                data: CodeThemeData(styles: {
                  'root': TextStyle(color: Color(0xfff8f8f2), backgroundColor: Color(0xff272822)),
                  'keyword': TextStyle(color: Color(0xffff6188)),
                  'string': TextStyle(color: Color(0xffa9dc76)),
                  'comment': TextStyle(color: Color(0xff6272a4)),
                  'number': TextStyle(color: Color(0xffffd866)),
                  'built_in': TextStyle(color: Color(0xff78dce8)),
                  'class-name': TextStyle(color: Color(0xffff6188)),
                }),
              child: CodeField(
                controller: _codeEditorController,
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                expands: true,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _runCode,
              child: const Text('Compile and Run Code'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _saveCodeToFile,
              child: const Text('Download Edited Code'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(child: Text(_output)),
            ),
          ],
        ),
      ),
    );
  }
}

  Mode _getLanguage(String lang) {
      switch (lang) {
          case 'java': return java;
          case 'javascript': return javascript;
          case 'python': return python;
          case 'cpp': return cpp;
          default: return java;
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