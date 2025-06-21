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

    request.fields['mainClassName'] = mainClassName;
    request.fields['language'] = language;
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
  final void Function(bool) onToggleTheme;
  final bool isDarkMode;

  const CodeExecutionScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<CodeExecutionScreen> createState() => _CodeExecutionScreenState();
}

class _CodeExecutionScreenState extends State<CodeExecutionScreen> with TickerProviderStateMixin {
  final CodeSubmissionService _service = CodeSubmissionService();

  final Map<String, Mode> _languageModes = {
    'java': java,
    'javascript': javascript,
    'python': python,
    'cpp': cpp,
  };

  final Map<String, IconData> _languageIcons = {
    'java': Icons.coffee,
    'javascript': Icons.javascript,
    'python': Icons.code,
    'cpp': Icons.code_outlined,
  };

  CodeController? _codeEditorController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _mainClassNameController = TextEditingController();

  PlatformFile? _activeFile;
  String _output = "Welcome to Code Compiler IDE\nReady to execute your code...";
  List<PlatformFile> _selectedFiles = [];
  String _selectedLanguage = 'java';
  bool _isCodeEditorReady = false;
  bool _isExecuting = false;
  late AnimationController _animationController;

  final List<String> _supportedLanguages = ['java', 'javascript', 'python', 'cpp'];

  @override
  void initState() {
    super.initState();
    _mainClassNameController.text = "HelloWorld";
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeCodeEditor();
  }

  void _initializeCodeEditor() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _codeEditorController = CodeController(
            text: _getDefaultCodeForLanguage(_selectedLanguage),
            language: _languageModes[_selectedLanguage]!,
          );
          _isCodeEditorReady = true;
        });
      }
    });
  }

  String _getDefaultCodeForLanguage(String language) {
    switch (language) {
      case 'java':
        return '''public class HelloWorld {
    public static void main(String[] args) {
        System.out.println("Hello, World!");
    }
}''';
      case 'javascript':
        return '''console.log("Hello, World!");

// Your JavaScript code here
function greet(name) {
    return `Hello, \${name}!`;
}

console.log(greet("Developer"));''';
      case 'python':
        return '''print("Hello, World!")

# Your Python code here
def greet(name):
    return f"Hello, {name}!"

print(greet("Developer"))''';
      case 'cpp':
        return '''#include <iostream>
using namespace std;

int main() {
    cout << "Hello, World!" << endl;
    return 0;
}''';
      default:
        return '';
    }
  }

  @override
  void dispose() {
    _codeEditorController?.dispose();
    _mainClassNameController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _updateCodeEditorText(String text) async {
    if (_codeEditorController != null && mounted) {
      // Wait for any pending operations to complete
      await Future.delayed(const Duration(milliseconds: 50));
      
      if (mounted && _codeEditorController != null) {
        try {
          // Clear the editor first, then set the new text
          _codeEditorController!.clear();
          await Future.delayed(const Duration(milliseconds: 10));
          _codeEditorController!.text = text;
          
          // Force a rebuild to ensure the UI reflects the change
          setState(() {});
        } catch (e) {
          print('Error updating code editor: $e');
          // Recreate the controller with the new text
          setState(() {
            _codeEditorController?.dispose();
            _codeEditorController = CodeController(
              text: text,
              language: _languageModes[_selectedLanguage]!,
            );
            _isCodeEditorReady = true;
          });
        }
      }
    }
  }

  Future<void> _pickFiles() async {
    // Ensure the code editor is ready before attempting to load a file
    if (!_isCodeEditorReady || _codeEditorController == null) {
      setState(() {
        _output = "⚠️ Please wait for the editor to finish loading before opening a file.";
      });
      return;
    }

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
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles = result.files;
          _activeFile = result.files.first;
          _output = "📁 Loading file: ${result.files.first.name}...";
        });

        String text = '';
        if (_activeFile!.bytes != null) {
          text = utf8.decode(_activeFile!.bytes!);
        } else if (_activeFile!.path != null) {
          text = await File(_activeFile!.path!).readAsString();
        }

        // Wait a bit longer to ensure editor is fully ready
        await Future.delayed(const Duration(milliseconds: 100));
        await _updateCodeEditorText(text);

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

        setState(() {
          _output = "✅ File loaded successfully: ${_activeFile!.name}";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _output = "❌ Error loading file: $e";
        });
      }
    }
  }

  Future<void> _runCode() async {
    if (_codeEditorController == null) {
      setState(() {
        _output = "⚠️ Code editor is not ready. Please wait a moment and try again.";
      });
      return;
    }

    final codeText = _codeEditorController!.text;
    if (codeText.isEmpty) {
      setState(() {
        _output = "⚠️ Please enter code or upload a file first.";
      });
      return;
    }
    if (_mainClassNameController.text.isEmpty) {
      setState(() {
        _output = "⚠️ Please enter the main file (or class) name.";
      });
      return;
    }
    
    setState(() {
      _isExecuting = true;
      _output = "🔄 Compiling and executing code...\nPlease wait...";
    });

    _animationController.repeat();

    final codeBytes = utf8.encode(codeText);
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

      if (mounted) {
        setState(() {
          _isExecuting = false;
          if (result['hasError']) {
            _output = "❌ Execution Failed\n";
            _output += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
            if (result['compilationErrors'] != null && result['compilationErrors'].isNotEmpty) {
              _output += "🔧 COMPILATION ERRORS:\n${result['compilationErrors']}\n";
              _output += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
            }
            if (result['programOutput'] != null && result['programOutput'].isNotEmpty) {
              _output += "⚠️ RUNTIME OUTPUT:\n${result['programOutput']}\n";
            }
          } else {
            _output = "✅ Execution Successful!\n";
            _output += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
            _output += "📤 PROGRAM OUTPUT:\n${result['programOutput']}";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExecuting = false;
          _output = "❌ Network Error: $e";
        });
      }
    }

    _animationController.stop();
    _animationController.reset();
  }

  Future<void> _saveCodeToFile() async {
    if (_codeEditorController == null) {
      setState(() {
        _output = "⚠️ Code editor is not ready. Please wait a moment and try again.";
      });
      return;
    }

    final code = _codeEditorController!.text;
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

    try {
      await FileSaver.instance.saveFile(
        name: filename,
        bytes: bytes,
        ext: fileExtension,
      );
      if (mounted) {
        setState(() {
          _output = "💾 File saved successfully as $filename.$fileExtension";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _output = "❌ Error saving file: $e";
        });
      }
    }
  }

  void _onLanguageChanged(String? newValue) {
    if (newValue != null && _languageModes.containsKey(newValue)) {
      setState(() {
        _selectedLanguage = newValue;
        _selectedFiles = [];
        _activeFile = null; // Clear active file when changing language
        _mainClassNameController.text = _getDefaultMainName(newValue);
        _isCodeEditorReady = false;
        _output = "🔄 Switching to ${newValue.toUpperCase()}...";
      });

      // Dispose of the old controller
      _codeEditorController?.dispose();
      _codeEditorController = null;
      
      // Create new controller with proper delay to ensure clean initialization
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          final newController = CodeController(
            text: _getDefaultCodeForLanguage(_selectedLanguage),
            language: _languageModes[_selectedLanguage]!,
          );
          
          setState(() {
            _codeEditorController = newController;
            _isCodeEditorReady = true;
            _output = "✅ Language changed to ${_selectedLanguage.toUpperCase()}\nReady to compile and run!";
          });
        }
      });
    }
  }

  String _getDefaultMainName(String language) {
    switch (language) {
      case 'java': return 'HelloWorld';
      case 'javascript': return 'main';
      case 'python': return 'main';
      case 'cpp': return 'main';
      default: return 'main';
    }
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF2D2D30) : const Color(0xFFF3F3F3),
        border: Border(
          bottom: BorderSide(
            color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Language Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? const Color(0xFF3C3C3C) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.isDarkMode ? const Color(0xFF555555) : const Color(0xFFCCCCCC),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _languageIcons[_selectedLanguage],
                  size: 18,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedLanguage,
                  onChanged: _onLanguageChanged,
                  underline: const SizedBox(),
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  items: _supportedLanguages.map((lang) {
                    return DropdownMenuItem(
                      value: lang,
                      child: Text(lang == 'cpp' ? 'C++' : lang.toUpperCase()),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Action Buttons
          _buildActionButton(
            icon: Icons.folder_open,
            label: 'Open File',
            onPressed: _isCodeEditorReady ? _pickFiles : null,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.save,
            label: 'Save',
            onPressed: _isCodeEditorReady ? _saveCodeToFile : null,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: _isExecuting ? Icons.hourglass_empty : Icons.play_arrow,
            label: _isExecuting ? 'Running...' : 'Run',
            onPressed: _isCodeEditorReady && !_isExecuting ? _runCode : null,
            isPrimary: true,
            isLoading: _isExecuting,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isPrimary = false,
    bool isLoading = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isPrimary ? Colors.white : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                ),
              ),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? const Color(0xFF4CAF50)
            : (widget.isDarkMode ? const Color(0xFF3C3C3C) : Colors.white),
        foregroundColor: isPrimary
            ? Colors.white
            : (widget.isDarkMode ? Colors.white70 : Colors.black87),
        elevation: isPrimary ? 2 : 1,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.terminal,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Code Compiler IDE',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF8F9FA),
        foregroundColor: widget.isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          Row(
            children: [
              Icon(
                Icons.light_mode,
                size: 20,
                color: widget.isDarkMode ? Colors.white54 : Colors.orange,
              ),
              Switch(
                value: widget.isDarkMode,
                onChanged: widget.onToggleTheme,
                activeColor: const Color(0xFF4CAF50),
              ),
              Icon(
                Icons.dark_mode,
                size: 20,
                color: widget.isDarkMode ? Colors.blue : Colors.black54,
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildToolbar(),
          // Main File Name Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.isDarkMode ? const Color(0xFF252526) : const Color(0xFFFAFAFA),
              border: Border(
                bottom: BorderSide(
                  color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.file_present,
                  color: widget.isDarkMode ? Colors.white54 : Colors.black54,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _mainClassNameController,
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                      fontFamily: 'monospace',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Main File (or Class) Name',
                      labelStyle: TextStyle(
                        color: widget.isDarkMode ? Colors.white54 : Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF3C3C3C) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Code Editor Section
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode ? const Color(0xFF2D2D30) : const Color(0xFFF8F9FA),
                      border: Border(
                        bottom: BorderSide(
                          color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.code,
                          size: 16,
                          color: widget.isDarkMode ? Colors.white54 : Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Editor',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isCodeEditorReady && _codeEditorController != null
                        ? CodeTheme(
                            data: widget.isDarkMode
                                ? CodeThemeData(styles: {
                                    'root': const TextStyle(
                                      color: Color(0xFFD4D4D4),
                                      backgroundColor: Color(0xFF1E1E1E),
                                    ),
                                    'keyword': const TextStyle(color: Color(0xFF569CD6)),
                                    'string': const TextStyle(color: Color(0xFFCE9178)),
                                    'comment': const TextStyle(color: Color(0xFF6A9955)),
                                    'number': const TextStyle(color: Color(0xFFB5CEA8)),
                                    'built_in': const TextStyle(color: Color(0xFF4EC9B0)),
                                    'class-name': const TextStyle(color: Color(0xFF4EC9B0)),
                                    'function': const TextStyle(color: Color(0xFFDCDCAA)),
                                  })
                                : CodeThemeData(styles: {
                                    'root': const TextStyle(
                                      color: Color(0xFF24292E),
                                      backgroundColor: Colors.white,
                                    ),
                                    'keyword': const TextStyle(color: Color(0xFFd73a49)),
                                    'string': const TextStyle(color: Color(0xFF032f62)),
                                    'comment': const TextStyle(color: Color(0xFF6a737d)),
                                    'number': const TextStyle(color: Color(0xFF005cc5)),
                                    'built_in': const TextStyle(color: Color(0xFF6f42c1)),
                                    'class-name': const TextStyle(color: Color(0xFF6f42c1)),
                                    'function': const TextStyle(color: Color(0xFF6f42c1)),
                                  }),
                            child: CodeField(
                              controller: _codeEditorController!,
                              textStyle: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 14,
                                height: 1.5,
                              ),
                              expands: true,
                            ),
                          )
                        : Container(
                            color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text(
                                    'Initializing code editor...',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          // Output Section
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF252526) : const Color(0xFFF8F9FA),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode ? const Color(0xFF2D2D30) : const Color(0xFFE8E8E8),
                      border: Border(
                        bottom: BorderSide(
                          color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFD0D0D0),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.terminal,
                          size: 16,
                          color: widget.isDarkMode ? Colors.white54 : Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Output Console',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() {
                              _output = "Console cleared.";
                            });
                          },
                          tooltip: 'Clear Output',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        child: Text(
                          _output,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            color: widget.isDarkMode ? const Color(0xFFCCCCCC) : const Color(0xFF333333),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark; // Start with dark theme

  void _toggleTheme(bool isDarkMode) {
    setState(() {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Compiler IDE',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF2196F3),
          background: const Color(0xFFF8F9FA),
          surface: Colors.white,
          onSurface: const Color(0xFF24292E),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FA),
          foregroundColor: Color(0xFF24292E),
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF2196F3),
          background: const Color(0xFF1E1E1E),
          surface: const Color(0xFF252526),
          onSurface: const Color(0xFFD4D4D4),
        ),
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Color(0xFFD4D4D4),
          elevation: 0,
        ),
      ),
      home: CodeExecutionScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}