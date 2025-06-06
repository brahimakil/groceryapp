import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../services/utils.dart';
import '../../widgets/text_widget.dart';

class NotificationsScreen extends StatefulWidget {
  static const routeName = "/NotificationsScreen";
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Force immediate cleanup of sample notifications
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      
      // Force clear sample notifications first
      await provider.forceClearSampleNotifications();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = Utils(context).color;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          icon: Icon(
            IconlyLight.arrowLeft,
            color: color,
          ),
        ),
        title: TextWidget(
          text: 'Notifications',
          color: color,
          textSize: 20,
          isTitle: true,
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return PopupMenuButton<String>(
                icon: Icon(
                  IconlyLight.moreCircle,
                  color: color,
                ),
                onSelected: (value) async {
                  switch (value) {
                    case 'mark_all_read':
                      if (notificationProvider.unreadCount > 0) {
                        HapticFeedback.lightImpact();
                        await notificationProvider.markAllAsRead();
                      }
                      break;
                    case 'clear_all':
                      HapticFeedback.mediumImpact();
                      _showClearAllDialog(context, notificationProvider);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (notificationProvider.unreadCount > 0)
                    PopupMenuItem<String>(
                      value: 'mark_all_read',
                      child: Row(
                        children: [
                          Icon(IconlyLight.tickSquare, color: color, size: 18),
                          const SizedBox(width: 8),
                          Text('Mark all read'),
                        ],
                      ),
                    ),
                  if (notificationProvider.notifications.isNotEmpty)
                    PopupMenuItem<String>(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(IconlyLight.delete, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Text('Clear all', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<NotificationProvider>(
          builder: (context, notificationProvider, child) {
            if (notificationProvider.isLoading) {
              return _buildLoadingState(theme);
            }

            if (notificationProvider.notifications.isEmpty) {
              return _buildEmptyState(theme, color);
            }

            return _buildNotificationsList(notificationProvider, theme, color);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            "Loading notifications...",
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              IconlyLight.notification,
              size: 60,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No notifications yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll notify you when something arrives!",
            style: TextStyle(
              fontSize: 16,
              color: color.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(NotificationProvider provider, ThemeData theme, Color color) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.notifications.length,
      itemBuilder: (context, index) {
        final notification = provider.notifications[index];
        return _buildNotificationItem(notification, provider, theme, color);
      },
    );
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    NotificationProvider provider,
    ThemeData theme,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notification.isRead 
            ? theme.cardColor 
            : theme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead 
              ? Colors.grey.withOpacity(0.2)
              : theme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            IconlyLight.delete,
            color: Colors.white,
          ),
        ),
        onDismissed: (direction) {
          HapticFeedback.mediumImpact();
          provider.deleteNotification(notification.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification deleted'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: _buildNotificationIcon(notification, theme),
          title: Text(
            notification.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
              color: color,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 14,
                  color: color.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getTimeAgo(notification.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: color.withOpacity(0.5),
                ),
              ),
            ],
          ),
          trailing: !notification.isRead
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () {
            HapticFeedback.lightImpact();
            if (!notification.isRead) {
              provider.markAsRead(notification.id);
            }
          },
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationModel notification, ThemeData theme) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case 'order':
        iconData = IconlyBold.bag;
        iconColor = Colors.green;
        break;
      case 'promotion':
        iconData = IconlyBold.discount;
        iconColor = Colors.orange;
        break;
      case 'system':
      default:
        iconData = IconlyBold.infoSquare;
        iconColor = theme.primaryColor;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, NotificationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.clearAllNotifications();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
} 