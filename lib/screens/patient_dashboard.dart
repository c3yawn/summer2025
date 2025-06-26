import 'package:flutter/material.dart';
import 'package:care_connnect_prototype_v1/widgets/app_drawer.dart';
import 'package:care_connnect_prototype_v1/widgets/task_card.dart';
import 'package:care_connnect_prototype_v1/models/task.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({Key? key}) : super(key: key);

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Mock data for demonstration
  final List<Task> _todayTasks = [
    Task(
      id: '1',
      title: 'Take Morning Medication',
      description: 'Metformin 500mg, Lisinopril 10mg',
      time: '8:00 AM',
      type: TaskType.medication,
      isCompleted: true,
    ),
    Task(
      id: '2',
      title: 'Blood Sugar Check',
      description: 'Check and log blood sugar levels',
      time: '9:00 AM',
      type: TaskType.health,
      isCompleted: false,
    ),
    Task(
      id: '3',
      title: 'Morning Walk',
      description: '30 minutes light exercise',
      time: '10:00 AM',
      type: TaskType.exercise,
      isCompleted: false,
    ),
    Task(
      id: '4',
      title: 'Lunch',
      description: 'Balanced meal with vegetables',
      time: '12:00 PM',
      type: TaskType.meal,
      isCompleted: false,
    ),
  ];

  String _selectedMood = '';
  final List<Map<String, dynamic>> _moodOptions = [
    {'emoji': '😊', 'label': 'Happy', 'value': 'happy'},
    {'emoji': '😐', 'label': 'Neutral', 'value': 'neutral'},
    {'emoji': '😔', 'label': 'Sad', 'value': 'sad'},
    {'emoji': '😰', 'label': 'Anxious', 'value': 'anxious'},
    {'emoji': '😴', 'label': 'Tired', 'value': 'tired'},
  ];

  void _handleEmergencySOS() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text(
          'Are you sure you want to send an emergency alert to your caregiver? '
              'They will be notified of your current location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendSOSAlert();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, Send SOS'),
          ),
        ],
      ),
    );
  }

  void _sendSOSAlert() {
    // Simulate sending SOS
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency alert sent to your caregiver'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleTaskCompletion(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
    });

    if (task.isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${task.title} marked as completed'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _handleMoodSelection(String mood) {
    setState(() {
      _selectedMood = mood;
    });

    // Save mood to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mood logged successfully'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedTasks = _todayTasks.where((t) => t.isCompleted).length;
    final totalTasks = _todayTasks.length;
    final completionRate = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('My Health'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Show notifications
            },
          ),
        ],
      ),
      drawer: const AppDrawer(userRole: 'patient'),
      body: RefreshIndicator(
        onRefresh: () async {
          // Simulate refresh
          await Future.delayed(const Duration(seconds: 2));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Text(
                'Good morning, John!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'How are you feeling today?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              // Mood Selector
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log your mood',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: _moodOptions.map((mood) {
                          final isSelected = _selectedMood == mood['value'];
                          return GestureDetector(
                            onTap: () => _handleMoodSelection(mood['value']),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor.withOpacity(0.2)
                                        : Colors.grey[100],
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                      color: Theme.of(context).primaryColor,
                                      width: 2,
                                    )
                                        : null,
                                  ),
                                  child: Text(
                                    mood['emoji'],
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  mood['label'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Progress Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Today\'s Progress',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '$completedTasks of $totalTasks',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: completionRate,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(completionRate * 100).toInt()}% Complete',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Today's Tasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today\'s Tasks',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      // Show all tasks
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Task List
              ..._todayTasks.map((task) => TaskCard(
                task: task,
                onTap: () => _handleTaskCompletion(task),
              )),

              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      'Call Caregiver',
                      Icons.phone,
                      Colors.blue,
                          () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Calling caregiver...')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Message',
                      Icons.message,
                      Colors.green,
                          () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening messages...')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      'Health Log',
                      Icons.favorite,
                      Colors.orange,
                          () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening health log...')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      'Schedule',
                      Icons.calendar_today,
                      Colors.purple,
                          () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening schedule...')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleEmergencySOS,
        backgroundColor: Colors.red,
        child: const Icon(Icons.sos),
      ),
    );
  }

  Widget _buildQuickActionCard(
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}