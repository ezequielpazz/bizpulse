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

  static const _dailyChannelId = 'bizpulse_daily';
  static const _dailyChannelName = 'Resumen diario';
  static const _dailyChannelDesc = 'Notificación matutina con los turnos del día';
  static const _dailyNotifId = 88888;

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

    // Canal de alta prioridad (recordatorios de turnos)
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

    // Canal resumen diario
    const dailyChannel = AndroidNotificationChannel(
      _dailyChannelId,
      _dailyChannelName,
      description: _dailyChannelDesc,
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
      showBadge: true,
    );
    await androidPlugin?.createNotificationChannel(dailyChannel);

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

  // ── Resumen diario a las 8 AM ──────────────────────────────────────────────

  /// Programa (o reprograma) la notificación diaria de las 8 AM.
  /// Se llama una vez al abrir la app — si ya existe, la reemplaza.
  Future<void> scheduleDailySummary() async {
    await _init();

    // Calcula el próximo lunes a las 8:00 AM local
    final now = DateTime.now();
    var fireAt = DateTime(now.year, now.month, now.day, 8, 0);
    if (fireAt.isBefore(now)) {
      fireAt = fireAt.add(const Duration(days: 1));
    }

    final scheduled = tz.TZDateTime.from(fireAt.toUtc(), tz.UTC);

    await _plugin.zonedSchedule(
      _dailyNotifId,
      '¡Buenos días! ☀️',
      'Revisá tus turnos de hoy en BizPulse.',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          _dailyChannelName,
          channelDescription: _dailyChannelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          enableVibration: false,
          playSound: false,
          channelShowBadge: true,
          styleInformation: const BigTextStyleInformation(
            'Abrí BizPulse para ver tu agenda del día.',
          ),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailySummary() => _plugin.cancel(_dailyNotifId);

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
