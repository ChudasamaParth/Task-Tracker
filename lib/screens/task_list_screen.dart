import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:track_task/screens/add_task.dart';

import '../model/task_model.dart';
import '../services/auth_service.dart';
import '../services/task_services.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();

  String _priorityFilter = 'All Priority';
  String _statusFilter = 'All Status';

  int _selectedTab = 0;

  static const Color _blue = Color(0xFF1670F8);
  static const Color _text = Color(0xFF26364B);
  static const Color _muted = Color(0xFF8493A8);

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<TaskModel> _filterTasks(List<TaskModel> tasks) {
    return tasks.where((task) {
      final priorityMatches =
          _priorityFilter == 'All Priority' ||
          task.priority.label == _priorityFilter;

      final statusMatches =
          _statusFilter == 'All Status' ||
          (_statusFilter == 'Completed' && task.isCompleted) ||
          (_statusFilter == 'Incomplete' && !task.isCompleted);

      return priorityMatches && statusMatches;
    }).toList();
  }

  Future<void> _openAddTask() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddTaskScreen()),
    );
  }

  /// Opens the same form pre-filled with [task]. The list updates by itself
  /// because it listens to the Firestore stream.
  Future<void> _openEditTask(TaskModel task) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddTaskScreen(task: task)),
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Task updated')));
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not log out. Please try again.')),
      );
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete "${task.title}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await _taskService.deleteTask(task.id);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not delete task.')));
    }
  }

  Widget _filterDropdown({
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Expanded(
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDCE4EF)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, size: 16),
            style: const TextStyle(
              color: _text,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            items: options
                .map(
                  (option) => DropdownMenuItem(
                    value: option,
                    child: Text(option, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final priorityColor = task.priority.color;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openEditTask(task),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Checkbox(
                  value: task.isCompleted,
                  activeColor: _blue,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (value) async {
                    if (value == null) return;

                    try {
                      await _taskService.setCompleted(task.id, value);
                    } catch (_) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not update task status.'),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _text,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    if (task.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        task.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              size: 14,
                              color: _muted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _formatDate(task.dueDate),
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: task.priority.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            task.priority.label,
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'Edit task',
                      icon: const Icon(Icons.edit_outlined, color: _blue),
                      iconSize: 20,
                      onPressed: () => _openEditTask(task),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'Delete task',
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      iconSize: 20,
                      onPressed: () => _deleteTask(task),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHome() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(
            children: [
              const Icon(Icons.filter_list, size: 17, color: _muted),
              const SizedBox(width: 5),
              _filterDropdown(
                value: _priorityFilter,
                options: const ['All Priority', 'Low', 'Medium', 'High'],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _priorityFilter = value);
                  }
                },
              ),
              const SizedBox(width: 8),
              _filterDropdown(
                value: _statusFilter,
                options: const ['All Status', 'Incomplete', 'Completed'],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _statusFilter = value);
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<TaskModel>>(
            stream: _taskService.watchTasks(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Could not load tasks.\nPlease check your connection.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final tasks = _filterTasks(snapshot.data ?? []);

              if (tasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.task_alt_rounded,
                        size: 54,
                        color: Colors.blueGrey.shade200,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'No tasks found',
                        style: TextStyle(
                          color: _text,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Add a task or change your filters.',
                        style: TextStyle(color: _muted, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(10),
                itemCount: tasks.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return _buildTaskCard(task);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfile() {
    // userChanges also emits when the display name is saved right after
    // registration, so the name appears without restarting the app.
    return StreamBuilder<User?>(
      stream: _authService.userChanges,
      initialData: _authService.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final name = user?.displayName?.trim();
        final hasName = name != null && name.isNotEmpty;
        final email = user?.email ?? '';

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: const Color(0xFFE8F0FF),
                  child: hasName
                      ? Text(
                          name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: _blue,
                          ),
                        )
                      : const Icon(
                          Icons.person_outline,
                          size: 42,
                          color: _blue,
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  hasName ? name : 'My Profile',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 180,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Log out'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 56,
        title: const Text(
          'Trackify',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            letterSpacing: 3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () => setState(() => _selectedTab = 1),
            icon: const Icon(Icons.person, size: 30),
          ),
        ],
      ),
      body: SafeArea(child: _selectedTab == 0 ? _buildHome() : _buildProfile()),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              onPressed: _openAddTask,
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              elevation: 3,
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              children: [
                _navItem(icon: Icons.home_rounded, label: 'Home', index: 0),
                _navItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  index: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final selected = _selectedTab == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 21, color: selected ? _blue : _muted),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? _blue : _muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
