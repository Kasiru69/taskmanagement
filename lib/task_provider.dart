import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'task.dart';

final tasksProvider = StateNotifierProvider<TaskNotifier, List<Task>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  return TaskNotifier(userId: user?.uid);
});

class TaskNotifier extends StateNotifier<List<Task>> {
  final String? userId;
  DatabaseReference? _database;

  TaskNotifier({this.userId}) : super([]) {
    if (userId != null) {
      _database = FirebaseDatabase.instance.ref().child('users/$userId/tasks');
      _fetchTasks();
    }
  }

  Future<List<Task>> _fetchTasks() async {
    print("Fetching tasks...");

    final DataSnapshot snapshot = await _database!.get(); // Fetch data once

    if (snapshot.value != null) {
      final Map<dynamic, dynamic>? tasksMap =
      snapshot.value as Map<dynamic, dynamic>?;  // No need for await here, as snapshot.value isn't a Future

      if (tasksMap != null) {
        final List<Task> tasks = tasksMap.entries.map((entry) {
          final taskData = Map<String, dynamic>.from(entry.value);
          taskData['id'] = entry.key;
          print(taskData);  // Print each task's data as it is processed
          return Task.fromJson(taskData);
        }).toList();
        print("Fetched Tasks:");
        tasks.forEach((task) {
          print('Task ID: ${task.id}, Title: ${task.title}, Description: ${task.description}');
        });

        return tasks;
      }
    }

    // Return empty list if no tasks were fetched
    print("No tasks found.");
    return [];
  }



  void addTask(Task task) async {
    print("hello");
    await _database?.push().set({
      'title': task.title,
      'description': task.description,
      'dueDate': task.dueDate.toIso8601String(),
      'priority': task.priority,
      'isCompleted': task.isCompleted,
    });
  }

  void updateTask(Task task) async {
    await _database?.child(task.id).update({
      'title': task.title,
      'description': task.description,
      'dueDate': task.dueDate.toIso8601String(),
      'priority': task.priority,
      'isCompleted': task.isCompleted,
    });
  }

  void deleteTask(String id) async {
    await _database?.child(id).remove();
  }

  void toggleTaskCompletion(String id) async {
    final taskRef = _database?.child(id);
    final snapshot = await taskRef?.get();
    if (snapshot?.exists ?? false) {
      final currentStatus = snapshot!.child('isCompleted').value as bool;
      await taskRef?.update({'isCompleted': !currentStatus});
    }
  }
}