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

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _mainClassNameController = TextEditingController();

  Map<String, CodeController> _controllers = {}; // holds controllers for each file
  String? _activeFileName; // tracks which file is being edited
  List<PlatformFile> _selectedFiles = [];
  PlatformFile? _activeFile;

  String _output = "Welcome to Code Compiler\nReady to execute your code...";
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
      // Set the default active file name based on selected language
      final defaultFileName = _getDefaultMainName(_selectedLanguage);
      
      setState(() {
        _activeFileName = defaultFileName;
        _controllers[defaultFileName] = CodeController(
          text: _getDefaultCodeForLanguage(_selectedLanguage),
          language: _languageModes[_selectedLanguage]!,
        );
        _isCodeEditorReady = true;
      });
    }
  });
}

void _removeTab(String filename) {
  if (_controllers.length <= 1) {
    // Don't allow removing the last tab
    setState(() {
      _output = "⚠️ Cannot remove the last remaining file tab.";
    });
    return;
  }

  // Dispose the controller for the file being removed
  _controllers[filename]?.dispose();
  _controllers.remove(filename);

  // If we're removing the active tab, switch to another tab
  if (_activeFileName == filename) {
    final remainingFiles = _controllers.keys.toList();
    if (remainingFiles.isNotEmpty) {
      _activeFileName = remainingFiles.first;
    }
  }

  // Update selected files list if applicable
  _selectedFiles.removeWhere((file) => file.name == filename);
  if (_activeFile?.name == filename) {
    _activeFile = _selectedFiles.isNotEmpty ? _selectedFiles.first : null;
  }

  setState(() {
    _output = "🗑️ Removed file tab: $filename";
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
    if (_activeFileName != null && _controllers[_activeFileName!] != null) {
      _controllers[_activeFileName!]!.dispose();
    }

    _mainClassNameController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  IconData _getFileIcon(String filename) {
    if (filename.endsWith('.java')) return Icons.coffee;
    if (filename.endsWith('.js')) return Icons.javascript;
    if (filename.endsWith('.py')) return Icons.code;
    if (filename.endsWith('.cpp')) return Icons.code_outlined;
    return Icons.description;
  }


  Future<void> _updateCodeEditorText(String text) async {
    if (_activeFileName != null && _controllers[_activeFileName!] != null && mounted) {
      await Future.delayed(const Duration(milliseconds: 50));

      if (mounted && _controllers[_activeFileName!] != null) {
        try {
          _controllers[_activeFileName!]!.clear();
          await Future.delayed(const Duration(milliseconds: 10));
          _controllers[_activeFileName!]!.text = text;

          setState(() {});
        } catch (e) {
          print('Error updating code editor: $e');
          setState(() {
            _controllers[_activeFileName!]?.dispose();
            _controllers[_activeFileName!] = CodeController(
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
    if (!_isCodeEditorReady) {
      setState(() {
        _output = "⚠️ Please wait for the editor to finish loading before opening files.";
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
        allowMultiple: true,  // Allow multiple files now
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles = result.files;
          // Set the first file as active initially
          _activeFile = result.files.first;
          _activeFileName = _activeFile!.name;
          _output = "📁 Loading ${_selectedFiles.length} file(s)...";
        });

        // Load all files and create controllers
        for (var file in _selectedFiles) {
          String content = '';
          if (file.bytes != null) {
            content = utf8.decode(file.bytes!);
          } else if (file.path != null) {
            content = await File(file.path!).readAsString();
          }

          _controllers[file.name] = CodeController(
            text: content,
            language: _languageModes[_selectedLanguage]!,
          );
        }

        // Update main class name based on active file extension
        if (_activeFileName != null) {
          if (_selectedLanguage == 'java' && _activeFileName!.endsWith('.java')) {
            _mainClassNameController.text = _activeFileName!.substring(0, _activeFileName!.length - 5);
          } else if (_selectedLanguage == 'javascript' && _activeFileName!.endsWith('.js')) {
            _mainClassNameController.text = _activeFileName!.substring(0, _activeFileName!.length - 3);
          } else if (_selectedLanguage == 'python' && _activeFileName!.endsWith('.py')) {
            _mainClassNameController.text = _activeFileName!.substring(0, _activeFileName!.length - 3);
          } else if (_selectedLanguage == 'cpp' && _activeFileName!.endsWith('.cpp')) {
            _mainClassNameController.text = _activeFileName!.substring(0, _activeFileName!.length - 4);
          }
        }

        setState(() {
          _isCodeEditorReady = true;
          _output = "✅ Loaded ${_selectedFiles.length} file(s), active file: $_activeFileName";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _output = "❌ Error loading files: $e";
        });
      }
    }
  }


  Future<void> _runCode() async {
    if (_activeFileName == null || _controllers[_activeFileName!] == null) {
      setState(() {
        _output = "⚠️ Code editor is not ready. Please wait a moment and try again.";
      });
      return;
    }

    // Basic validation: check if at least one file has content
    bool hasNonEmptyFile = _controllers.values.any((controller) => controller.text.isNotEmpty);
    if (!hasNonEmptyFile) {
      setState(() {
        _output = "⚠️ Please enter code or upload files first.";
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

    // Prepare multipart files for all controllers
    final List<http.MultipartFile> multipartFiles = [];
    for (final entry in _controllers.entries) {
      final fileNameWithoutExt = entry.key;
      final fileContent = entry.value.text;

      final extension = _getExtensionsForLanguage(_selectedLanguage).first;
      final fileName = fileNameWithoutExt.endsWith('.$extension')
          ? fileNameWithoutExt
          : '$fileNameWithoutExt.$extension';

      final bytes = utf8.encode(fileContent);

      final multipartFile = http.MultipartFile.fromBytes(
        'javaFiles',
        bytes,
        filename: fileName,
        contentType: MediaType('text', 'plain', {'charset': 'utf-8'}),
      );

      multipartFiles.add(multipartFile);
    }

    try {
      final result = await _service.executeCode(
        codeFiles: multipartFiles,
        mainClassName: _mainClassNameController.text,
        language: _selectedLanguage,
      );

      if (mounted) {
        setState(() {
          _isExecuting = false;
          if (result['hasError']) {
            _output = "❌ Execution Failed\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
            if (result['compilationErrors'] != null && result['compilationErrors'].isNotEmpty) {
              _output += "🔧 COMPILATION ERRORS:\n${result['compilationErrors']}\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
            }
            if (result['programOutput'] != null && result['programOutput'].isNotEmpty) {
              _output += "⚠️ RUNTIME OUTPUT:\n${result['programOutput']}\n";
            }
          } else {
            _output = "✅ Execution Successful!\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n📤 PROGRAM OUTPUT:\n${result['programOutput']}";
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
    if (_controllers[_activeFileName] == null) {
      setState(() {
        _output = "⚠️ Code editor is not ready. Please wait a moment and try again.";
      });
      return;
    }

    final code = _controllers[_activeFileName]!.text;
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
    if (newValue != null && _languageModes.containsKey(newValue) && newValue != _selectedLanguage) {
      // Show confirmation dialog before switching languages
      _showLanguageSwitchConfirmation(newValue);
    }
  }

  void _showLanguageSwitchConfirmation(String newLanguage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF2D2D30) : Colors.white,
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Switch Language?',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to switch from ${_selectedLanguage.toUpperCase()} to ${newLanguage.toUpperCase()}.',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_forever,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All current files and code will be lost!',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This action cannot be undone. Make sure to save your work before proceeding.',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white54 : Colors.black54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog without switching
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _performLanguageSwitch(newLanguage); // Perform the actual switch
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: const Text(
                'Switch Language',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLanguageSwitch(String newLanguage) {
    setState(() {
      _selectedLanguage = newLanguage;
      _selectedFiles = [];
      _activeFile = null;
      _mainClassNameController.text = _getDefaultMainName(newLanguage);
      _isCodeEditorReady = false;
      _output = "🔄 Switching to ${newLanguage.toUpperCase()}...";
    });

    // Dispose old controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();

    // Create new controller with proper delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        final defaultFileName = _getDefaultMainName(_selectedLanguage);
        final newController = CodeController(
          text: _getDefaultCodeForLanguage(_selectedLanguage),
          language: _languageModes[_selectedLanguage]!,
        );

        setState(() {
          _controllers[defaultFileName] = newController;
          _activeFileName = defaultFileName;
          _isCodeEditorReady = true;
          _output = "✅ Language changed to ${_selectedLanguage.toUpperCase()}\nReady to compile and run!";
        });
      }
    });
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

  List<String> _getExtensionsForLanguage(String lang) {
    switch (lang) {
      case 'java': return ['java'];
      case 'javascript': return ['js'];
      case 'python': return ['py'];
      case 'cpp': return ['cpp'];
      default: return ['txt'];
    }
  }

  Widget _buildFileTabs() {
  if (_controllers.isEmpty) return const SizedBox.shrink();
  
  return Container(
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: widget.isDarkMode ? const Color(0xFF2D2D30) : const Color(0xFFF3F3F3),
      border: Border(
        bottom: BorderSide(
          color: widget.isDarkMode ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
          width: 1,
        ),
      ),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _controllers.keys.map((filename) {
          final isActive = filename == _activeFileName;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _activeFileName = filename;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? const Color(0xFF4CAF50) 
                        : (widget.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                    border: isActive ? Border.all(color: const Color(0xFF4CAF50), width: 2) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getFileIcon(filename),
                        size: 14,
                        color: isActive ? Colors.white : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          filename,
                          style: TextStyle(
                            color: isActive ? Colors.white : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _removeTab(filename),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.close,
                            size: 12,
                            color: isActive ? Colors.white : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
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
              'Code Compiler',
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
          _buildFileTabs(),
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
                    child: _isCodeEditorReady && _controllers[_activeFileName] != null
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
                              controller: _controllers[_activeFileName]!,
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
      title: 'Code Compiler',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF2196F3),
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