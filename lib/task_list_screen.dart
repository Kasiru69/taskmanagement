import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'task_provider.dart';
import 'auth_service.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import 'task.dart';

class TaskListScreen extends ConsumerStatefulWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  String _filterPriority = 'all';
  bool? _filterCompletion;
  late Future<List<Task>> tasksFuture; // Declare a Future variable

  @override
  void initState() {
    super.initState();
    tasksFuture = _fetchTasks();
  }

  void _applyFilter(String value) {
    setState(() {
      switch (value) {
        case 'all':
          _filterPriority = 'all';
          _filterCompletion = null;
          break;
        case 'high':
          _filterPriority = 'high';
          _filterCompletion = null;
          break;
        case 'completed':
          _filterCompletion = true;
          break;
      }
    });
  }

  Future<List<Task>> _fetchTasks() async {
    print("Fetching tasks...");
    final user = FirebaseAuth.instance.currentUser;
    DatabaseReference? _database = FirebaseDatabase.instance.ref().child('users/${user?.uid}/tasks');
    final DataSnapshot snapshot = await _database!.get();
    if (snapshot.value != null) {
      final Map<dynamic, dynamic>? tasksMap = snapshot.value as Map<dynamic, dynamic>?;

      if (tasksMap != null) {
        List<Task> tasks = [];
        for (var entry in tasksMap.entries) {
          final taskData = Map<String, dynamic>.from(entry.value);
          taskData['id'] = entry.key;
          print("yoo $taskData");
          tasks.add(Task.fromJson(taskData));
        }
        print("Fetched Tasks:");
        tasks.forEach((task) {
          print('Task ID: ${task.id}, Title: ${task.title}, Description: ${task.description}');
        });

        return tasks;
      }
    }
    print("No tasks found.");
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          PopupMenuButton<String>(
            onSelected: _applyFilter,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Tasks')),
              const PopupMenuItem(value: 'high', child: Text('High Priority')),
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: tasksFuture, // Provide the Future to FutureBuilder
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tasks available.'));
          }

          List<Task> filteredTasks = snapshot.data!;
          print("okk ${filteredTasks}");

          // Apply filter to tasks if needed
          filteredTasks = filteredTasks.where((task) {
            if (_filterPriority != 'all' && task.priority != _filterPriority) return false;
            if (_filterCompletion != null && task.isCompleted != _filterCompletion) return false;
            return true;
          }).toList();

          return ListView.builder(
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
              return Dismissible(
                key: Key(task.id),
                onDismissed: (_) {
                  ref.read(tasksProvider.notifier).deleteTask(task.id);
                  setState(() {
                    tasksFuture=_fetchTasks();
                  });
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (task.priority=="high")?Colors.orange:((task.priority=="medium")?Colors.amberAccent:Colors.greenAccent)
                    ),
                    child: ListTile(
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(task.description),
                      trailing: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) {
                            setState(() {
                              task.isCompleted=!task.isCompleted;
                              ref.read(tasksProvider.notifier).toggleTaskCompletion(task.id);
                            });
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditTaskScreen(task: task),
                          ),
                        ).then((_){
                          setState(() {
                            tasksFuture=_fetchTasks();
                          });
                        });
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTaskScreen(),
            ),
          ).then((_){
            setState(() {
              tasksFuture=_fetchTasks();
              print("yooo hineysingh ${tasksFuture}");
            });
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
