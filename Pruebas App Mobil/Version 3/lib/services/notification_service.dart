import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../main.dart';
import '../screens/features/chat_detail_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  Map<String, dynamic>? _pendingNotificationData;

  Future<void> initialize() async {
    // 1. Request permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permissions');
    }

    // 2. Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          _handleNotificationClick(data);
        }
      },
    );

    // 3. Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificaciones de ARte',
      description: 'Este canal se usa para avisos importantes y mensajes.',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Handle Notification Clicks (Push Notifications)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClick(message.data);
    });

    // Push notification initial message
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage.data);
    }

    // Local notification launch details
    final NotificationAppLaunchDetails? launchDetails = 
        await _localNotifications.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      final payload = launchDetails.notificationResponse?.payload;
      if (payload != null) {
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _handleNotificationClick(data);
        } catch (e) {
          debugPrint('Error parsing launch notification payload: $e');
        }
      }
    }

    // 5. Handle Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && !kIsWeb) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // 6. Monitor auth state to save token and start listeners
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        debugPrint('User logged in, updating FCM token and starting chat listener');
        saveTokenToFirestore();
        startChatListener();
      } else {
        debugPrint('User logged out, cancelling chat listener');
        _chatSubscription?.cancel();
      }
    });

    _fcm.onTokenRefresh.listen((newToken) {
      _updateTokenInDb(newToken);
    });
  }

  void _handleNotificationClick(Map<String, dynamic> data) async {
    debugPrint('Handling notification click with data: $data');
    
    // If navigator is not ready yet, save it for later
    if (MyApp.navigatorKey.currentState == null) {
      debugPrint('Navigator not ready, saving notification for later');
      _pendingNotificationData = data;
      return;
    }

    if (data['type'] == 'chat' && data['chatId'] != null) {
      final chatId = data['chatId'].toString();
      
      try {
        debugPrint('Navigating to chat: $chatId');
        final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
        
        if (chatDoc.exists) {
          final participants = List<String>.from(chatDoc.data()?['participants'] ?? []);
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          
          if (currentUserId == null) {
            debugPrint('User not logged in, cannot navigate to chat yet');
            _pendingNotificationData = data; // Keep it for after login
            return;
          }
          
          final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
          
          if (otherUserId.isNotEmpty) {
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
            final userName = userDoc.data()?['userName'] ?? userDoc.data()?['fullName'] ?? 'Chat';
            final avatarUrl = userDoc.data()?['profileImageUrl'] ?? userDoc.data()?['avatarUrl'];

            // Clear pending data as we are processing it
            _pendingNotificationData = null;

            debugPrint('Pushing ChatDetailScreen for $userName');
            MyApp.navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => ChatDetailScreen(
                  chatId: chatId,
                  chatName: userName,
                  avatarUrl: avatarUrl,
                ),
              ),
            );
          } else {
            debugPrint('Could not find other participant in chat $chatId');
          }
        } else {
          debugPrint('Chat document $chatId does not exist');
        }
      } catch (e) {
        debugPrint('Error navigating to chat: $e');
      }
    } else {
      debugPrint('Notification data type not handled or missing chatId: ${data['type']}');
    }
  }

  void processPendingNotification() {
    if (_pendingNotificationData != null) {
      debugPrint('Found pending notification, waiting a moment for navigator...');
      // Small delay to ensure navigator is fully settled
      Future.delayed(const Duration(milliseconds: 500), () {
        if (MyApp.navigatorKey.currentState != null) {
          debugPrint('Navigator ready, processing pending notification now');
          _handleNotificationClick(_pendingNotificationData!);
        } else {
          debugPrint('Navigator still not ready after delay');
        }
      });
    }
  }

  StreamSubscription<QuerySnapshot>? _chatSubscription;

  void startChatListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _chatSubscription?.cancel();
    _chatSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified || change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final lastSenderId = data['lastSenderId'];
          final lastMessage = data['lastMessage'];
          final lastMessageTime = data['lastMessageTime'] as Timestamp?;

          if (lastSenderId != null && 
              lastSenderId != user.uid && 
              lastMessageTime != null &&
              DateTime.now().difference(lastMessageTime.toDate()).inSeconds < 10) {
            
            _showLocalNotification(
              id: change.doc.id.hashCode,
              title: "Nuevo mensaje",
              body: lastMessage ?? "Has recibido un mensaje",
              payload: jsonEncode({'type': 'chat', 'chatId': change.doc.id}),
            );
          }
        }
      }
    });
  }

  void _showLocalNotification({required int id, required String title, required String body, String? payload}) {
    _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Notificaciones de ARte',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> saveTokenToFirestore() async {
    String? token = await _fcm.getToken();
    if (token != null) {
      await _updateTokenInDb(token);
    }
  }

  Future<void> _updateTokenInDb(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    }
  }
}
