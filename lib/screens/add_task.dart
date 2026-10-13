import 'package:flutter/material.dart';

import '../model/task_model.dart';
import '../services/task_services.dart';

/// Add a new task, or edit an existing one when [task] is provided.
class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key, this.task});

  final TaskModel? task;

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  static const Color _blue = Color(0xFF1670F8);
  static const Color _text = Color(0xFF26364B);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final TaskService _taskService = TaskService();

  DateTime? _dueDate;
  TaskPriority _priority = TaskPriority.medium;
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    final task = widget.task;
    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description;
      _priority = task.priority;
      _setDueDate(task.dueDate);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

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

  void _setDueDate(DateTime date) {
    _dueDate = date;
    _dateController.text = _formatDate(date);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // When editing, an already-overdue task must still be selectable.
    final earliest = (_dueDate != null && _dueDate!.isBefore(today))
        ? DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day)
        : today;

    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? today,
      firstDate: earliest,
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() => _setDueDate(picked));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    if (_isSaving) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();

      if (_isEditing) {
        await _taskService.updateTask(
          widget.task!.copyWith(
            title: title,
            description: description,
            dueDate: _dueDate,
            priority: _priority,
          ),
        );
      } else {
        await _taskService.addTask(
          TaskModel(
            title: title,
            description: description,
            dueDate: _dueDate!,
            priority: _priority,
            createdAt: DateTime.now(),
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _showMessage(
        _isEditing
            ? 'Could not update task. Please try again.'
            : 'Could not save task. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _label(String text, {bool required = false}) {
    return Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: _text,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }

  InputDecoration _decoration({required String hint, Widget? suffixIcon}) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      border: border(Colors.grey.shade300),
      enabledBorder: border(Colors.grey.shade300),
      focusedBorder: border(_blue, 1.5),
      errorBorder: border(Colors.red.shade400),
      focusedErrorBorder: border(Colors.red.shade400, 1.5),
    );
  }

  Widget _priorityOption(TaskPriority value) {
    final selected = _priority == value;

    return Expanded(
      child: GestureDetector(
        onTap: _isSaving ? null : () => setState(() => _priority = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? value.background : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? value.color : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            value.label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? value.color : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        title: Text(_isEditing ? 'Edit Task' : 'Add Task'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('Title', required: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      enabled: !_isSaving,
                      maxLength: 80,
                      decoration: _decoration(hint: 'Enter task title'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    _label('Description'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: !_isSaving,
                      minLines: 4,
                      maxLines: 6,
                      decoration: _decoration(hint: 'Enter task description'),
                    ),
                    const SizedBox(height: 20),

                    _label('Due Date', required: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      enabled: !_isSaving,
                      onTap: _pickDate,
                      decoration: _decoration(
                        hint: 'Select date',
                        suffixIcon: const Icon(Icons.calendar_month_outlined),
                      ),
                      validator: (_) =>
                          _dueDate == null ? 'Due date is required' : null,
                    ),
                    const SizedBox(height: 20),

                    _label('Priority', required: true),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _priorityOption(TaskPriority.low),
                        const SizedBox(width: 10),
                        _priorityOption(TaskPriority.medium),
                        const SizedBox(width: 10),
                        _priorityOption(TaskPriority.high),
                      ],
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isEditing ? 'Update Task' : 'Save',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
