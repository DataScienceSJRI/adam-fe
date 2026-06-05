import 'package:adam/data/repositories/notifications_api.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  String? _playerId;
  bool _isObserverAttached = false;

  Future<void> init({String? userId}) async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    OneSignal.initialize("74ebcb76-b454-4145-9510-09f5d6041e25");

    await OneSignal.Notifications.requestPermission(true);
    OneSignal.Notifications.addClickListener((event) async {
      print("🔔 Notification clicked");
    });
    if (userId != null) {
      await OneSignal.login(userId);
    }

    _playerId = OneSignal.User.pushSubscription.id;

    print("🆔 Player ID: $_playerId");
  }

  Future<String?> getPlayerId() async {
    _playerId ??= OneSignal.User.pushSubscription.id;
    return _playerId;
  }

  void startTokenSync({
    required String jwt,
    required String userId,
  }) async {
    print("🚀 startTokenSync called");

    if (_isObserverAttached) return;
    _isObserverAttached = true;

    final currentId = OneSignal.User.pushSubscription.id;

    if (currentId != null) {
      print("⚡ Found existing Player ID: $currentId");

      await NotificationApi.registerToken(
        jwt: jwt,
        playerId: currentId,
        userId: userId,
      );

      print("✅ Token synced instantly");
    }

    OneSignal.User.pushSubscription.addObserver((state) async {
      final newPlayerId = state.current.id;

      if (newPlayerId != null) {
        print("🔄 New Player ID: $newPlayerId");

        await NotificationApi.registerToken(
          jwt: jwt,
          playerId: newPlayerId,
          userId: userId,
        );

        print("✅ Token auto-synced");
      }
    });

    print("🎯 Observer attached");
  }
}
