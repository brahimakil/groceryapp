import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../consts/firebase_consts.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    final User? user = authInstance.currentUser;
    if (user == null) {
      _notifications = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final QuerySnapshot notificationSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      _notifications = notificationSnapshot.docs
          .map((doc) => NotificationModel.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();

      // Remove any sample notifications that might exist from previous versions
      await _removeSampleNotifications();
      
    } catch (error) {
      print('Error fetching notifications: $error');
      _notifications = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove any sample/fake notifications that might exist in Firebase
  Future<void> _removeSampleNotifications() async {
    final User? user = authInstance.currentUser;
    if (user == null) return;

    try {
      final sampleTitles = [
      
      ];

      final batch = FirebaseFirestore.instance.batch();
      bool hasChanges = false;

      for (final notification in _notifications) {
        if (sampleTitles.contains(notification.title)) {
          final docRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('notifications')
              .doc(notification.id);
          
          batch.delete(docRef);
          hasChanges = true;
        }
      }

      if (hasChanges) {
        await batch.commit();
        
        // Remove from local state
        _notifications.removeWhere((n) => sampleTitles.contains(n.title));
        notifyListeners();
        
        print('Removed sample notifications from Firebase');
      }
    } catch (error) {
      print('Error removing sample notifications: $error');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final User? user = authInstance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (error) {
      print('Error marking notification as read: $error');
    }
  }

  Future<void> markAllAsRead() async {
    final User? user = authInstance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      
      for (final notification in _notifications.where((n) => !n.isRead)) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notification.id);
        
        batch.update(docRef, {'isRead': true});
      }

      await batch.commit();

      // Update local state
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      
      notifyListeners();
    } catch (error) {
      print('Error marking all notifications as read: $error');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final User? user = authInstance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      // Update local state
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (error) {
      print('Error deleting notification: $error');
    }
  }

  Future<void> clearAllNotifications() async {
    final User? user = authInstance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      
      for (final notification in _notifications) {
        final docRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notification.id);
        
        batch.delete(docRef);
      }

      await batch.commit();

      // Clear local state
      _notifications.clear();
      notifyListeners();
    } catch (error) {
      print('Error clearing all notifications: $error');
    }
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  // Method to add a real notification (can be called from other parts of the app)
  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? data,
  }) async {
    final User? user = authInstance.currentUser;
    if (user == null) return;

    try {
      final notification = {
        'title': title,
        'message': message,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'data': data,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add(notification);

      // Refresh notifications
      await fetchNotifications();
    } catch (error) {
      print('Error adding notification: $error');
    }
  }

  Future<void> forceClearSampleNotifications() async {
    final User? user = authInstance.currentUser;
    if (user == null) return;

    try {
      print('Starting force cleanup of sample notifications...');
      
      // Get all notifications
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();

      final sampleTitles = [
        
      ];

      final batch = FirebaseFirestore.instance.batch();
      int deletedCount = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final title = data['title'] as String?;
        
        if (title != null && sampleTitles.contains(title)) {
          batch.delete(doc.reference);
          deletedCount++;
          print('Deleting sample notification: $title');
        }
      }

      if (deletedCount > 0) {
        await batch.commit();
        print('Successfully deleted $deletedCount sample notifications');
        
        // Clear local state and refresh
        _notifications.clear();
        await fetchNotifications();
      } else {
        print('No sample notifications found to delete');
      }
    } catch (error) {
      print('Error in forceClearSampleNotifications: $error');
    }
  }
} 