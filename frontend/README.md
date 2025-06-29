# Code Compiler Frontend

Flutter web application that provides an interactive code editor supporting Java, JavaScript, Python, and C++ with real-time compilation and execution.

## 🎯 Features

- **Multi-language support**: Java, JavaScript, Python, C++
- **Interactive code editor** with syntax highlighting
- **Multi-file projects** with tabbed interface
- **Real-time compilation** and execution
- **File upload/download** functionality
- **Dark/light theme** toggle
- **Responsive design** for desktop and mobile

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** (3.0+) - [Installation Guide](https://flutter.dev/docs/get-started/install)
- **Chrome Browser** (for web development)
- **VS Code** with Flutter and Dart extensions (recommended)
- **Backend service running** - See [Backend README](../backend/README.md) for setup

### Installation

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd summer2025/frontend/
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint (IMPORTANT):**
   ```bash
   # Edit lib/main.dart and find line ~56
   # Change from:
   final String baseUrl = 'http://3.239.74.119:8080/code';
   
   # To (for local development):
   final String baseUrl = 'http://localhost:8080/code';
   ```

4. **Start the backend service first:**
   ```bash
   # In another terminal, start the Spring Boot backend
   cd ../backend/
   ./gradlew bootRun
   
   # Wait for: "Started CodecompilerApplication in X.XXX seconds"
   ```

5. **Run the Flutter application:**
   ```bash
   # Back in frontend directory
   flutter run -d chrome --web-port 3000
   ```

6. **Open in browser:**
   Navigate to `http://localhost:3000`

## ⚠️ Important Setup Notes

### Backend Dependency
**The frontend REQUIRES the backend service to be running first!** 

Before starting Flutter:
1. ✅ Backend service must be running on `http://localhost:8080`
2. ✅ All Docker containers must be built (see Backend README)
3. ✅ Health check should return: `{"status":"healthy"}`

### API Endpoint Configuration
**CRITICAL**: The default configuration points to a remote server. For local development, you MUST update the API endpoint.

**File:** `lib/main.dart` (around line 56)
```dart
class CodeSubmissionService {
  // ⚠️ UPDATE THIS for local development:
  final String baseUrl = 'http://localhost:8080/code';
  
  // ❌ Don't use remote server for development:
  // final String baseUrl = 'http://3.239.74.119:8080/code';
}
```

### CORS Configuration

The app runs on port 3000 to satisfy CORS requirements:
```bash
flutter run -d chrome --web-port 3000
```

## 📁 Project Structure

```
frontend/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── services/
│   │   └── code_submission_service.dart   # API communication
│   ├── widgets/                           # Reusable UI components
│   └── screens/                           # Main app screens
├── web/
│   ├── index.html                         # Web entry point
│   └── manifest.json                      # PWA configuration
├── pubspec.yaml                           # Dependencies
└── README.md
```

## 🎨 User Interface

### Main Components

- **Code Editor**: Multi-tab editor with syntax highlighting
- **Language Selector**: Dropdown to switch between Java, JS, Python, C++
- **Toolbar**: File operations (New, Open, Save, Run)
- **Output Console**: Displays compilation results and program output
- **Theme Toggle**: Switch between dark and light modes

### Supported File Types

- **Java**: `.java` files
- **JavaScript**: `.js` files  
- **Python**: `.py` files
- **C++**: `.cpp` files

## 🔌 API Integration

### Request Format

The frontend sends multipart form requests to the backend:

```http
POST /code/execute
Content-Type: multipart/form-data

Fields:
- language: "cpp"
- mainClassName: "main"
- javaFiles: [uploaded source files]
```

### Response Handling

```dart
{
  "status": "Success|Compilation Failed|Runtime Error",
  "compilationErrors": "string",
  "programOutput": "string", 
  "hasError": boolean
}
```

## 🧪 Development

### Running in Development Mode

```bash
# Hot reload for faster development
flutter run -d chrome --web-port 3000

# Build for production
flutter build web

# Run tests
flutter test
```

### Key Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0                    # API requests
  file_picker: ^6.1.1            # File upload
  file_saver: ^0.2.9             # File download
  flutter_code_editor: ^0.3.0    # Code editor
  flutter_highlight: ^0.7.0      # Syntax highlighting
  highlight: ^0.7.0              # Language definitions
```

### Adding New Language Support

1. **Update language list** in main screen:
   ```dart
   final List<String> _supportedLanguages = ['java', 'javascript', 'python', 'cpp', 'newlang'];
   ```

2. **Add syntax highlighting** support:
   ```dart
   import 'package:highlight/languages/newlang.dart';
   
   final Map<String, Mode> _languageModes = {
     'newlang': newlang,
   };
   ```

3. **Add default code template**:
   ```dart
   String _getDefaultCodeForLanguage(String language) {
     switch (language) {
       case 'newlang':
         return '''// New language template
console.log("Hello World");''';
     }
   }
   ```

## 🎯 Usage Guide

### Writing Code

1. **Select language** from dropdown (Java, JavaScript, Python, C++)
2. **Write code** in the editor with syntax highlighting
3. **Create multiple files** using "New File" button
4. **Upload existing files** using "Open File" button

### Running Code

1. **Click "Run"** button to compile and execute
2. **View results** in the output console
3. **See compilation errors** if any issues occur
4. **Download results** using "Save" button

### Managing Files

- **Switch between files** using tabs
- **Rename files** by changing the filename field
- **Close files** using the X button on tabs
- **Upload multiple files** for complex projects

## 🏃‍♂️ Starting the Application

### Step-by-Step Startup

1. **Start Backend Service First:**
   ```bash
   # Terminal 1: Start backend
   cd summer2025/backend/
   ./gradlew bootRun
   
   # Wait for this message:
   # "Started CodecompilerApplication in X.XXX seconds"
   ```

2. **Verify Backend is Running:**
   ```bash
   # Test health endpoint
   curl http://localhost:8080/code/health
   # Should return: {"status":"healthy","service":"Docker Code Compiler",...}
   ```

3. **Configure Frontend API Endpoint:**
   ```bash
   # Edit lib/main.dart line ~56
   # Make sure it shows:
   final String baseUrl = 'http://localhost:8080/code';
   ```

4. **Start Frontend:**
   ```bash
   # Terminal 2: Start frontend  
   cd summer2025/frontend/
   flutter run -d chrome --web-port 3000
   ```

5. **Verify Everything Works:**
   - Open browser to `http://localhost:3000`
   - Try compiling any code
   - Check backend terminal for debug messages like:
     ```
     === DOCKER CODE COMPILER SERVICE ===
     Received compilation request - Language: java, Main: HelloWorld, Files: 1
     ```

### Quick Test
Submit this broken Java code to verify real error checking works:
```java
public class Test {
    public static void main(String[] args) {
        System.out.println("Missing semicolon")  // Missing semicolon
    }
}
```
You should see **real compilation errors**, not "Success"!

### Common Issues

**"Mock lambda response" or old data:**
- ✅ Check that `baseUrl` in `lib/main.dart` points to `http://localhost:8080`
- ✅ Restart Flutter after changing the API endpoint
- ✅ Clear browser cache or use incognito mode
- ✅ Verify backend service is running: `curl http://localhost:8080/code/health`

**Backend connection errors:**
- ✅ Start backend service first: `cd ../backend && ./gradlew bootRun`
- ✅ Wait for "Started CodecompilerApplication" message
- ✅ Check port 8080 is available: `netstat -ano | findstr :8080`

**CORS errors:**
- ✅ Ensure you're running on port 3000: `flutter run -d chrome --web-port 3000`
- ✅ Check that backend has CORS enabled for localhost:3000
- ✅ Backend should show CORS config in `src/main/java/.../config/CorsConfig.java`

**Flutter not found:**
```bash
# Verify Flutter installation
flutter --version

# If not found, add Flutter to your PATH
export PATH="$PATH:/path/to/flutter/bin"
```

**Dependencies issues:**
```bash
# Clean and reinstall dependencies
flutter clean
flutter pub get
```

**Hot reload not working:**
- Save the file (Ctrl+S)
- Check terminal for error messages
- Restart the app if needed

**Compilation always shows "Success" regardless of code:**
- ✅ You're probably hitting the remote server instead of local
- ✅ Double-check `baseUrl` in `lib/main.dart` is set to localhost
- ✅ Look for "=== DOCKER CODE COMPILER SERVICE ===" in backend console

### Debug Mode

Run with verbose logging:
```bash
flutter run -d chrome --web-port 3000 --verbose
```

## 🚀 Deployment

### Development Build
```bash
flutter run -d chrome --web-port 3000
```

### Production Build
```bash
# Build optimized web version
flutter build web --release

# Serve the built files
cd build/web/
python -m http.server 3000
```

### Deploy to Web Hosting

The built files in `build/web/` can be deployed to:
- **Netlify**: Drag and drop `build/web` folder
- **Firebase Hosting**: `firebase deploy`
- **GitHub Pages**: Upload `build/web` contents
- **Any static web host**: Upload `build/web` folder

## 🔒 Security Notes

- **Input validation**: Code is sent to secure backend containers
- **No local execution**: All code runs in isolated Docker containers
- **CORS protection**: Frontend restricted to specific ports
- **File size limits**: Enforced on both frontend and backend

## 🤝 Contributing

### Development Workflow

```bash
# Make changes to the code
# Test locally
flutter run -d chrome --web-port 3000

# Commit changes
git add .
git commit -m "Description of changes"
git push
```

### Code Style

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart)
- Use meaningful variable names
- Add comments for complex logic
- Keep widgets focused and reusable

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Guide](https://dart.dev/guides)
- [Flutter Web Development](https://flutter.dev/web)
- [Project Technical Overview](../docs/technical-overview.md)

## 🆘 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Flutter documentation
3. Check browser console for errors
4. Verify backend service is running

---

**Note:** This frontend is designed to work with the Code Compiler backend service. Ensure the backend is running and accessible before using the application.