import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../../features/pet/domain/entities/pet.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const double _alertThreshold = 30.0;

  // IDs notificaciones inmediatas (stat ya por debajo del umbral)
  static const int _hungerImmediate = 1;
  static const int _sleepImmediate = 2;
  static const int _playImmediate = 3;
  static const int _cleanlinessImmediate = 4;
  static const int _healthImmediate = 5;

  // IDs notificaciones programadas (stat llegará al umbral mientras app está cerrada)
  static const int _hungerScheduled = 11;
  static const int _sleepScheduled = 12;
  static const int _playScheduled = 13;
  static const int _cleanlinessScheduled = 14;
  static const int _healthScheduled = 15;

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      'pet_alerts',
      'Pet Alerts',
      description: 'Alerts when your pet needs attention',
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Dispara notificaciones inmediatas para stats ya bajo el umbral y
  /// programa notificaciones futuras para las que aún están bien.
  /// Llamar cada vez que se aplica el decay (al abrir la app).
  void scheduleStatAlerts({
    required String petName,
    required PetStats stats,
    required double hungerRate,
    required double sleepRate,
    required double playRate,
    required double cleanlinessRate,
    required double healthRate,
  }) {
    _handleStat(
      immediateId: _hungerImmediate,
      scheduledId: _hungerScheduled,
      value: stats.hunger,
      ratePerHour: hungerRate,
      title: '🍗 $petName tiene hambre',
      body: 'Su nivel de hambre está al ${stats.hunger.toInt()}%',
    );
    _handleStat(
      immediateId: _sleepImmediate,
      scheduledId: _sleepScheduled,
      value: stats.sleep,
      ratePerHour: sleepRate,
      title: '💤 $petName está cansado/a',
      body: 'Su nivel de sueño está al ${stats.sleep.toInt()}%',
    );
    _handleStat(
      immediateId: _playImmediate,
      scheduledId: _playScheduled,
      value: stats.play,
      ratePerHour: playRate,
      title: '🎮 $petName quiere jugar',
      body: 'Su nivel de diversión está al ${stats.play.toInt()}%',
    );
    _handleStat(
      immediateId: _cleanlinessImmediate,
      scheduledId: _cleanlinessScheduled,
      value: stats.cleanliness,
      ratePerHour: cleanlinessRate,
      title: '🧼 $petName necesita un baño',
      body: 'Su nivel de limpieza está al ${stats.cleanliness.toInt()}%',
    );
    if (healthRate > 0) {
      _handleStat(
        immediateId: _healthImmediate,
        scheduledId: _healthScheduled,
        value: stats.health,
        ratePerHour: healthRate,
        title: '❤️ $petName necesita atención',
        body: 'Su nivel de salud está al ${stats.health.toInt()}%',
      );
    } else {
      unawaited(_plugin.cancel(_healthScheduled));
      unawaited(_plugin.cancel(_healthImmediate));
    }
  }

  void _handleStat({
    required int immediateId,
    required int scheduledId,
    required double value,
    required double ratePerHour,
    required String title,
    required String body,
  }) {
    if (value < _alertThreshold) {
      // Ya está bajo el umbral — cancela la programada y dispara inmediato
      unawaited(_plugin.cancel(scheduledId));
      unawaited(_send(immediateId, title, body));
    } else {
      // Está bien — cancela la inmediata anterior y programa para cuando llegue al umbral
      unawaited(_plugin.cancel(immediateId));
      if (ratePerHour > 0) {
        final hoursUntilThreshold = (value - _alertThreshold) / ratePerHour;
        final scheduledTime = tz.TZDateTime.now(tz.local).add(
          Duration(milliseconds: (hoursUntilThreshold * 3600000).round()),
        );
        unawaited(_sendScheduled(scheduledId, title, body, scheduledTime));
      }
    }
  }

  Future<void> _send(int id, String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'pet_alerts',
      'Pet Alerts',
      channelDescription: 'Alerts when your pet needs attention',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> _sendScheduled(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduledTime,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'pet_alerts',
      'Pet Alerts',
      channelDescription: 'Alerts when your pet needs attention',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
