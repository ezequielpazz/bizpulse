import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _i = NotificationService._();
  factory NotificationService() => _i;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  static const _channelId = 'bizpulse_reminders';
  static const _channelName = 'Recordatorios de turnos';
  static const _channelDesc = 'Avisos antes de cada turno';

  // ── Inicialización estática (llamar con await en main()) ───────────────────

  static Future<void> initialize() => NotificationService()._init();

  Future<void> _init() async {
    if (_inited) return;
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Canal de alta prioridad
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await androidPlugin?.createNotificationChannel(channel);

    // Permisos Android 13+
    await androidPlugin?.requestNotificationsPermission();

    // Permiso de alarma exacta (Android 12+)
    await androidPlugin?.requestExactAlarmsPermission();

    _inited = true;
  }

  // ── Programar recordatorio ─────────────────────────────────────────────────

  Future<void> scheduleReminder({
    required int id,
    required String clientName,
    required DateTime whenLocal,
    required int minutesBefore,
  }) async {
    await _init();

    final fireAt = whenLocal.subtract(Duration(minutes: minutesBefore));
    if (fireAt.isBefore(DateTime.now())) return;

    final title = minutesBefore == 0
        ? 'Turno ahora — $clientName'
        : 'Turno en $minutesBefore min — $clientName';
    const body = 'Recordatorio de BizPulse';

    final scheduled = tz.TZDateTime.from(fireAt.toUtc(), tz.UTC);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          channelShowBadge: true,
          fullScreenIntent: false,
          styleInformation: BigTextStyleInformation(''),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // ── API heredada (compatibilidad con llamadas existentes) ──────────────────

  Future<void> scheduleOneShot({
    required String id,
    required DateTime whenLocal,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _init();
    if (whenLocal.isBefore(DateTime.now())) return;

    final notifId = int.parse(
      id.replaceAll(RegExp(r'[^0-9]'), '').padLeft(9, '1').substring(0, 9),
    );
    final scheduled = tz.TZDateTime.from(whenLocal.toUtc(), tz.UTC);

    await _plugin.zonedSchedule(
      notifId,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
          channelShowBadge: true,
          fullScreenIntent: false,
          styleInformation: BigTextStyleInformation(''),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  // ── Cancelar ───────────────────────────────────────────────────────────────

  Future<void> cancel(String id) async {
    final notifId = int.parse(
      id.replaceAll(RegExp(r'[^0-9]'), '').padLeft(9, '1').substring(0, 9),
    );
    await _plugin.cancel(notifId);
  }

  Future<void> cancelById(int id) => _plugin.cancel(id);

  // ── Test: notificación en 1 minuto ─────────────────────────────────────────

  static Future<void> scheduleTestIn1Minute() async {
    final when = DateTime.now().add(const Duration(minutes: 1));
    await NotificationService().scheduleReminder(
      id: 999999,
      clientName: 'Prueba',
      whenLocal: when,
      minutesBefore: 0,
    );
  }
}
