import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'task.dart';
import 'task_provider.dart';

class EditTaskScreen extends ConsumerStatefulWidget {
  final Task task;
  const EditTaskScreen({Key? key, required this.task}) : super(key: key);

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends ConsumerState<EditTaskScreen> {
  late String _title;
  late String _description;
  late String _priority;
  late DateTime _dueDate;

  @override
  void initState() {
    super.initState();
    _title = widget.task.title;
    _description = widget.task.description;
    _priority = widget.task.priority;
    _dueDate = widget.task.dueDate;
  }

  void _updateTask() {
    final updatedTask = widget.task.copyWith(
      title: _title,
      description: _description,
      priority: _priority,
      dueDate: _dueDate,
    );

    ref.read(tasksProvider.notifier).updateTask(updatedTask);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextFormField(
              initialValue: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (value) => setState(() => _title = value),
            ),
            TextFormField(
              initialValue: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              onChanged: (value) => setState(() => _description = value),
            ),
            DropdownButtonFormField<String>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: ['low', 'medium', 'high']
                  .map((p) => DropdownMenuItem(
                value: p,
                child: Text(p),
              )).toList(),
              onChanged: (value) =>
                  setState(() => _priority = value ?? 'medium'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (pickedDate != null) {
                  setState(() => _dueDate = pickedDate);
                }
              },
              child: Text('Due Date: ${_dueDate.toLocal().toString().split(' ')[0]}'),
            ),
            ElevatedButton(
              onPressed: _updateTask,
              child: const Text('Update Task'),
            ),
          ],
        ),
      ),
    );
  }
}