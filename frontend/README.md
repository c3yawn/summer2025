# Code Compiler Frontend

Flutter web application that provides an interactive code editor with intelligent performance optimization, supporting Java, JavaScript, Python, and C++ through a sophisticated three-tier execution system.

## 🎯 Features

- **Multi-language support**: Java, JavaScript, Python, C++ with optimized execution paths
- **Intelligent performance system**: Automatic optimization based on code complexity and caching
- **Interactive code editor** with syntax highlighting and multi-file support
- **Real-time performance feedback**: Shows execution path (cache hit, fast path, or cloud execution)
- **Performance monitoring**: Live statistics and execution time tracking
- **Smart caching**: Instant results for repeated code submissions
- **Fast local execution**: 1-3 second execution for simple Python/JavaScript scripts
- **File upload/download** functionality with drag-and-drop support
- **Dark/light theme** toggle with modern UI design
- **Responsive design** optimized for desktop development workflow

## 🚀 Performance Architecture Integration

The frontend seamlessly integrates with the backend's three-tier performance system:

```
Frontend Request → Backend Performance Engine
                ↓
        ┌─────────────┐
        │ Cache Hit   │ → Instant results (0.05s)
        └─────────────┘
                ↓
        ┌─────────────┐
        │ Fast Path   │ → Quick execution (1-3s)
        └─────────────┘
                ↓
        ┌─────────────┐
        │ ECS Cloud   │ → Full compilation (25-35s)
        └─────────────┘
```

### Performance Indicators

The UI provides real-time feedback on execution performance:
- **🚀 Cache Hit**: Green indicator, sub-second execution
- **⚡ Fast Path**: Blue indicator, 1-3 second execution  
- **🐳 Cloud ECS**: Orange indicator, 25-35 second execution
- **📊 Statistics**: Live performance metrics in status bar

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** (3.10+) - [Installation Guide](https://flutter.dev/docs/get-started/install)
- **Chrome Browser** (latest version for optimal performance)
- **VS Code** with Flutter and Dart extensions (recommended)
- **Backend service running** - See [Backend README](../backend/README.md) for complete setup

### Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd summer2025/frontend/
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint for your environment:**
   
   **For Local Development (IMPORTANT):**
   ```dart
   // Edit lib/main.dart around line 56
   final String baseUrl = 'http://localhost:8080/code';
   ```
   
   **For Production/Cloud:**
   ```dart
   // Use your deployed backend URL
   final String baseUrl = 'https://your-backend-url.com/code';
   ```

4. **Start the enhanced backend service:**
   ```bash
   # In another terminal, start the optimized Spring Boot backend
   cd ../backend/
   ./gradlew bootRun
   
   # Wait for: "Started CodeCompilerApplication in X.XXX seconds"
   # Look for performance system initialization:
   # "🔥 Initializing warm pool..."
   # "🚀 Cache system ready"
   ```

5. **Verify backend performance system:**
   ```bash
   # Test health endpoint with performance statistics
   curl http://localhost:8080/code/health
   
   # Should return comprehensive performance metrics:
   # {
   #   "status": "healthy",
   #   "service": "ECS Code Compiler with Warm Pool",
   #   "cache": { "total_entries": 0, "valid_entries": 0 },
   #   "fast_execution": { "supported_languages": ["python", "javascript"] }
   # }
   ```

6. **Run the Flutter application:**
   ```bash
   # Back in frontend directory
   flutter run -d chrome --web-port 3000
   ```

7. **Open and test the application:**
   - Navigate to `http://localhost:3000`
   - Try the performance test suite (see Testing section below)

## ⚡ Performance Testing Guide

### Test Suite for All Performance Tiers

Once your app is running, test each performance tier:

#### Test 1: Cache Performance (Instant Results)
```python
# Submit this Python code:
print("Cache test - this should be instant on repeat!")
print("Testing intelligent caching system")

# First submission: Will take 1-3s (fast path)
# Second submission: Should be ~0.05s (cache hit)
# Look for green "Cache Hit" indicator
```

#### Test 2: Fast Path Performance (1-3 seconds)
```javascript
// Submit this JavaScript code:
console.log("Fast path test!");
console.log("Local execution for simple scripts");
console.log("Should complete in 1-3 seconds");

// Look for blue "Fast Path" indicator
// Check execution time in status bar
```

#### Test 3: ECS Cloud Performance (25-35 seconds)
```java
// Submit this Java code:
public class PerformanceTest {
    public static void main(String[] args) {
        System.out.println("ECS Cloud execution test!");
        System.out.println("Full compilation in optimized containers");
        System.out.println("Should complete in 25-35 seconds");
    }
}

// Look for orange "ECS Cloud" indicator
// Monitor progress in status bar
```

#### Test 4: Large File ECS Test
```cpp
// Submit this C++ code:
#include <iostream>
#include <vector>
#include <algorithm>

int main() {
    std::cout << "Large file ECS test!" << std::endl;
    std::vector<int> numbers = {3, 1, 4, 1, 5, 9, 2, 6, 5};
    std::sort(numbers.begin(), numbers.end());
    
    std::cout << "Sorted numbers: ";
    for(int num : numbers) {
        std::cout << num << " ";
    }
    std::cout << std::endl;
    return 0;
}

// Tests optimized container performance
// Should use ECS path with optimized startup
```

## 📱 Enhanced User Interface

### Performance Dashboard

The frontend now includes a comprehensive performance dashboard:

- **Execution Path Indicator**: Visual feedback on which tier handled your request
- **Performance Metrics**: Real-time statistics display
- **Cache Status**: Shows cache hit rate and storage
- **Fast Path Eligibility**: Indicates when code qualifies for fast execution
- **Execution Timer**: Precise timing for each request
- **Performance History**: Recent execution times and paths

### Smart Code Editor Features

- **Language Detection**: Automatic optimization hints based on selected language
- **File Size Indicators**: Shows fast path eligibility in real-time
- **Performance Suggestions**: Recommendations for optimal execution
- **Multi-tab Interface**: Organized project management
- **Syntax Highlighting**: Language-specific highlighting with performance context

### Status Bar Information

The enhanced status bar displays:
```
🚀 Last: Cache Hit (0.05s) | Cache: 15 entries | Fast Path: Ready | ECS: Optimized
```

## 📁 Enhanced Project Structure

```
frontend/
├── lib/
│   ├── main.dart                          # App entry point with performance integration
│   ├── services/
│   │   ├── code_submission_service.dart   # Enhanced API communication
│   │   ├── performance_service.dart       # Performance monitoring
│   │   └── cache_service.dart             # Client-side cache management
│   ├── widgets/
│   │   ├── performance_dashboard.dart     # Performance metrics display
│   │   ├── execution_indicator.dart       # Execution path visualization
│   │   ├── code_editor_enhanced.dart      # Enhanced editor with perf hints
│   │   └── status_bar.dart               # Performance status bar
│   ├── models/
│   │   ├── compilation_result.dart        # Enhanced result model
│   │   └── performance_metrics.dart       # Performance data models
│   └── screens/
│       └── main_screen.dart              # Main app screen with performance UI
├── web/
│   ├── index.html                         # Web entry point
│   └── manifest.json                      # PWA configuration
├── pubspec.yaml                           # Dependencies with performance libs
└── README.md
```

## 🔌 Enhanced API Integration

### Request Format with Performance Optimization

```dart
// The frontend automatically optimizes requests based on content
Future<CompilationResult> submitCode({
  required String language,
  required List<File> files,
  String? mainClassName,
}) async {
  // Automatic fast path detection
  if (_canUseFastPath(language, files)) {
    _showFastPathIndicator();
  }
  
  // Enhanced multipart request
  var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/execute'));
  request.fields['language'] = language;
  if (mainClassName != null) request.fields['mainClassName'] = mainClassName;
  
  // Add files with size optimization
  for (var file in files) {
    request.files.add(await http.MultipartFile.fromPath('javaFiles', file.path));
  }
  
  return await _sendWithPerformanceTracking(request);
}
```

### Enhanced Response Handling

```dart
class CompilationResult {
  final bool success;
  final String output;
  final String error;
  final String executionPath;      // NEW: cache_hit|fast_path|ecs_execution
  final int executionTimeMs;       // NEW: Precise timing
  final String cacheStatus;        // NEW: hit|miss
  final Map<String, dynamic> performanceMetrics; // NEW: Detailed metrics
}
```

### Performance Monitoring Integration

```dart
// Real-time performance statistics
Future<PerformanceStats> getPerformanceStats() async {
  final response = await http.get(Uri.parse('$baseUrl/health'));
  return PerformanceStats.fromJson(jsonDecode(response.body));
}

// Cache management
Future<void> clearCache() async {
  await http.post(Uri.parse('$baseUrl/cache/clear'));
  _updateCacheStatus();
}

// Fast path testing
Future<bool> canUseFastPath(String language, List<File> files) async {
  // Test if code qualifies for fast path execution
  var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/fast/test'));
  request.fields['language'] = language;
  // Add files...
  
  final response = await request.send();
  final result = jsonDecode(await response.stream.bytesToString());
  return result['can_execute_fast'] ?? false;
}
```

## 🎨 Performance-Aware UI Components

### Execution Path Indicator

```dart
class ExecutionPathIndicator extends StatelessWidget {
  final String executionPath;
  final int executionTime;
  
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getPathColor(executionPath),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getPathIcon(executionPath), size: 16),
          SizedBox(width: 4),
          Text('${_getPathLabel(executionPath)} (${executionTime}ms)'),
        ],
      ),
    );
  }
  
  Color _getPathColor(String path) {
    switch (path) {
      case 'cache_hit': return Colors.green;
      case 'fast_path': return Colors.blue;
      case 'ecs_execution': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
```

### Performance Dashboard Widget

```dart
class PerformanceDashboard extends StatefulWidget {
  // Displays real-time performance metrics
  // Shows cache hit rates, average execution times
  // Provides performance optimization suggestions
}
```

## 🧪 Development & Testing

### Running with Performance Monitoring

```bash
# Start with verbose performance logging
flutter run -d chrome --web-port 3000 --verbose

# Monitor backend performance logs simultaneously
tail -f ../backend/logs/performance.log
```

### Performance Testing Framework

```dart
// Automated performance testing
class PerformanceTestSuite {
  static Future<void> runAllTests() async {
    await testCachePerformance();    // Verify sub-second cache hits
    await testFastPathPerformance(); // Verify 1-3s fast execution
    await testECSPerformance();      // Verify 25-35s cloud execution
    await testCacheInvalidation();   // Verify cache management
  }
}
```

### Key Dependencies for Performance

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0                    # Enhanced API requests
  file_picker: ^6.1.1            # File upload with performance hints
  file_saver: ^0.2.9             # File download
  flutter_code_editor: ^0.3.0    # Code editor with perf indicators
  flutter_highlight: ^0.7.0      # Syntax highlighting
  charts_flutter: ^0.12.0        # Performance charts
  shared_preferences: ^2.2.0     # Client-side caching
  connectivity_plus: ^4.0.2      # Network monitoring
  stopwatch: ^2.0.1              # Precise timing
```

## 🎯 Usage Guide with Performance Optimization

### Smart Code Writing

1. **Language Selection**: The UI shows performance characteristics for each language
   - **Python/JavaScript**: Fast path eligible for files < 2KB
   - **Java/C++**: Optimized cloud execution with precompiled containers

2. **File Size Optimization**: 
   - Green indicator: Eligible for fast path (< 2KB)
   - Blue indicator: Medium files (cloud optimized)
   - Orange indicator: Large files (full cloud compilation)

3. **Smart Caching**:
   - Identical code automatically cached
   - Cache status shown in real-time
   - Manual cache management available

### Optimized Execution Workflow

1. **Write Code**: Editor provides performance hints in real-time
2. **Performance Preview**: See estimated execution path before running
3. **Execute**: Monitor live performance metrics during execution
4. **Results**: View detailed performance breakdown with results
5. **Optimization Suggestions**: Get recommendations for faster execution

### Performance Management

- **Cache Management**: Clear cache when testing different versions
- **Fast Path Verification**: Check if code qualifies for local execution
- **Performance History**: Review past execution times and optimization
- **System Health**: Monitor backend performance in real-time

## 🏃‍♂️ Enhanced Startup Process

### Complete System Verification

1. **Start Enhanced Backend:**
   ```bash
   cd summer2025/backend/
   ./gradlew bootRun
   
   # Look for these startup messages:
   # "🔥 Initializing warm pool..."
   # "🚀 Cache system ready"
   # "⚡ Fast execution service initialized"
   # "🐳 ECS cluster: ACTIVE"
   ```

2. **Verify All Performance Systems:**
   ```bash
   # Test comprehensive health check
   curl http://localhost:8080/code/health
   
   # Test cache system
   curl http://localhost:8080/code/cache/stats
   
   # Test fast path capabilities  
   curl http://localhost:8080/code/fast/stats
   ```

3. **Configure Frontend for Performance:**
   ```dart
   // Ensure lib/main.dart points to your backend
   final String baseUrl = 'http://localhost:8080/code';
   
   // Enable performance monitoring
   final bool enablePerformanceTracking = true;
   final bool showDetailedMetrics = true;
   ```

4. **Start Frontend with Performance Mode:**
   ```bash
   flutter run -d chrome --web-port 3000 --enable-performance-monitoring
   ```

5. **Verify Complete Integration:**
   - ✅ Performance dashboard loads with metrics
   - ✅ Cache statistics display in status bar
   - ✅ Fast path indicator shows for small Python/JS files
   - ✅ ECS indicator appears for Java/C++ files
   - ✅ Execution times display accurately

## 🔍 Performance Troubleshooting

### Frontend Performance Issues

**Performance metrics not showing:**
```bash
# Verify backend performance endpoints
curl http://localhost:8080/code/health
curl http://localhost:8080/code/cache/stats
curl http://localhost:8080/code/fast/stats

# Check frontend API configuration
grep -n "baseUrl" lib/main.dart
```

**Fast path not activating:**
```bash
# Test fast path eligibility endpoint
curl -X POST http://localhost:8080/code/fast/test \
  -F "language=python" \
  -F "javaFiles=@small_test.py"

# Verify file size < 2KB and language is Python/JavaScript
```

**Cache not working:**
```bash
# Check cache statistics
curl http://localhost:8080/code/cache/stats

# Clear and test cache
curl -X POST http://localhost:8080/code/cache/clear
```

**Slow ECS execution (>60s):**
```bash
# Verify optimized containers are deployed
curl http://localhost:8080/code/health | grep cluster_active

# Check ECS optimization status
aws ecs describe-task-definition --task-definition java-compiler-task
```

### Performance Optimization Tips

1. **For Fastest Results**: Use identical code that's already cached
2. **For Quick Development**: Keep Python/JS files under 2KB for fast path
3. **For Complex Projects**: Use optimized ECS with proper resource allocation
4. **For Multiple Files**: Organize efficiently to minimize compilation overhead

## 🚀 Production Deployment

### Performance-Optimized Build

```bash
# Build with performance optimizations
flutter build web --release --dart-define=ENABLE_PERFORMANCE_TRACKING=true

# Enable service worker for client-side caching
flutter build web --pwa-strategy=offline-first
```

### Production Configuration

```dart
// Production API configuration
class ProductionConfig {
  static const String baseUrl = 'https://your-optimized-backend.com/code';
  static const bool enablePerformanceTracking = true;
  static const bool enableClientSideCache = true;
  static const int cacheMaxEntries = 100;
  static const Duration cacheTimeout = Duration(minutes: 30);
}
```

### Performance Monitoring in Production

```javascript
// Add to web/index.html for production monitoring
<script>
  // Performance monitoring integration
  window.performanceObserver = new PerformanceObserver((list) => {
    const entries = list.getEntries();
    entries.forEach(entry => {
      if (entry.name.includes('code-execution')) {
        console.log(`Execution time: ${entry.duration}ms`);
      }
    });
  });
  window.performanceObserver.observe({entryTypes: ['measure', 'navigation']});
</script>
```

## 📊 Performance Analytics

### Built-in Performance Metrics

The frontend automatically tracks:
- **Execution Path Distribution**: Percentage using cache vs fast path vs ECS
- **Average Response Times**: For each execution tier
- **Cache Hit Rate**: Effectiveness of intelligent caching
- **Network Performance**: API response times and reliability
- **User Workflow**: Most common language and file patterns

### Performance Dashboard

Real-time metrics displayed include:
```
Performance Summary:
├── Cache Hits: 73% (avg 0.05s)
├── Fast Path: 18% (avg 1.2s)  
├── ECS Cloud: 9% (avg 28s)
└── Overall Satisfaction: 94%
```

## 🤝 Contributing to Performance

### Performance-Focused Development

```bash
# Run performance test suite
flutter test test/performance/

# Profile frontend performance
flutter run --profile -d chrome --web-port 3000

# Monitor backend integration
flutter run --verbose | grep "Performance"
```

### Adding Performance Features

1. **New Performance Metrics**: Add tracking for additional execution paths
2. **Enhanced Caching**: Implement client-side intelligent caching
3. **Predictive Loading**: Pre-fetch based on user patterns
4. **Performance Suggestions**: AI-driven optimization recommendations

## 📚 Performance Resources

- [Flutter Performance Best Practices](https://flutter.dev/docs/perf)
- [Web Performance Optimization](https://developers.google.com/web/fundamentals/performance)
- [Backend Performance Documentation](../backend/README.md#performance-optimization)
- [System Architecture Performance Guide](../docs/performance-architecture.md)

---

**🎯 Performance Achievement**: This frontend delivers an intelligent user experience that automatically optimizes between instant cache results (0.05s), fast local execution (1-3s), and optimized cloud compilation (25-35s) based on code complexity and caching status.