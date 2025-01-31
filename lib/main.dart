import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'task_list_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_screen.dart';
import 'auth_service.dart';
import 'auth_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: authState.when(
        data: (user) => user != null ? const TaskListScreen() : const LoginScreen(),
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}