import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_task/model/task_model.dart';


import 'auth_service.dart';

/// Stores each user's tasks at: users/{uid}/tasks/{taskId}
class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  CollectionReference<Map<String, dynamic>> get _tasks {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      throw StateError('You must be signed in to use tasks.');
    }
    return _db.collection('users').doc(uid).collection('tasks');
  }

  /// Live list of the user's tasks, earliest due date first.
  /// Priority/status filtering is done in the UI, which avoids needing
  /// composite Firestore indexes.
  Stream<List<TaskModel>> watchTasks() {
    return _tasks
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(TaskModel.fromDoc).toList());
  }

  Future<void> addTask(TaskModel task) {
    return _tasks.add({
      ...task.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTask(TaskModel task) {
    return _tasks.doc(task.id).update(task.toMap());
  }

  Future<void> setCompleted(String taskId, bool isCompleted) {
    return _tasks.doc(taskId).update({'isCompleted': isCompleted});
  }

  Future<void> deleteTask(String taskId) {
    return _tasks.doc(taskId).delete();
  }
}