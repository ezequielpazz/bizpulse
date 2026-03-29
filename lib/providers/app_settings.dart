import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BgType { solid, gradient, image }

class AppSettingsProvider extends ChangeNotifier {
  // ── Keys (visual existentes) ───────────────────────────────────────────────
  static const _kNotifMin    = 'notif_minutes_before';
  static const _kPrimary     = 'theme_primary_color';
  static const _kBgType      = 'theme_bg_type';
  static const _kBgColor1    = 'theme_bg_color1';
  static const _kBgColor2    = 'theme_bg_color2';
  static const _kFont        = 'theme_font';
  static const _kBgImagePath     = 'theme_bg_image_path';
  static const _kOverlayOpacity  = 'theme_overlay_opacity';
  static const _kButtonStyle     = 'theme_button_style';
  static const _kButtonColor     = 'theme_button_color';
  static const _kButtonTextColor = 'theme_button_text_color';
  static const _kBgColorSolid   = 'theme_bg_color_solid';
  static const _kTextColor      = 'theme_text_color';
  static const _kCardColor      = 'theme_card_color';
  // Negocio
  static const _kWorkDays       = 'biz_work_days';
  static const _kWorkStart      = 'biz_work_start';
  static const _kWorkEnd        = 'biz_work_end';
  static const _kApptDuration   = 'biz_appt_duration';
  static const _kWhatsappMsg    = 'biz_whatsapp_msg';
  static const _kBlockedDays    = 'biz_blocked_days';
  // Finanzas
  static const _kCurrency       = 'fin_currency';
  static const _kCurrencySymbol = 'fin_symbol';
  static const _kPriceRounding  = 'fin_rounding';
  // Notificaciones extendidas
  static const _kStockAlertQty  = 'notif_stock_alert_qty';
  static const _kCashCloseOn    = 'notif_cash_close_enabled';
  static const _kCashCloseTime  = 'notif_cash_close_time';
  static const _kWaReminder     = 'notif_whatsapp_enabled';
  // Privacidad
  static const _kPinEnabled     = 'priv_pin_enabled';
  static const _kPinCode        = 'priv_pin_code';
  static const _kAutoLockMin    = 'priv_auto_lock_min';
  static const _kStealth        = 'priv_stealth';
  // Datos
  static const _kBackupFreq     = 'data_backup_freq';
  static const _kExportFmt      = 'data_export_fmt';
  static const _kHistoryMonths  = 'data_history_months';
  // Apariencia extendida
  static const _kThemeMode      = 'ui_theme_mode';
  static const _kTextScale      = 'ui_text_scale';
  static const _kLanguage       = 'ui_language';
  static const _kBusinessType   = 'biz_type';
  static const _kOnboardingDone = 'onboarding_done';

  // ── Sección: Turnos ────────────────────────────────────────────────────────
  int notifMinutesBefore = 30;

  // ── Sección: Visual ────────────────────────────────────────────────────────
  Color   primaryColor = Colors.redAccent;
  BgType  bgType       = BgType.solid;
  Color   bgColor1     = const Color(0xFF121212);
  Color   bgColor2     = const Color(0xFF1A1A2E);
  String  fontFamily   = 'Roboto';
  String? bgImagePath;
  int     buttonStyle             = 0;
  double  backgroundOverlayOpacity = 0.45;
  Color?  _buttonColorOverride;
  Color get buttonColor => _buttonColorOverride ?? primaryColor;
  Color   buttonTextColor = Colors.white;
  Color   backgroundColor = const Color(0xFF121212);
  Color   textColor       = Colors.white;
  Color   cardColor       = const Color(0xFF1E1E1E);

  // ── Sección: Negocio ───────────────────────────────────────────────────────
  List<int>    workDays            = [1, 2, 3, 4, 5, 6]; // 1=Lun … 7=Dom
  String       workStart           = '09:00';
  String       workEnd             = '19:00';
  int          defaultApptDuration = 30;
  String       whatsappMsg         =
      'Hola {nombre}, te recordamos tu turno a las {hora}. ¡Te esperamos!';
  List<String> blockedDays         = [];

  // ── Sección: Finanzas ──────────────────────────────────────────────────────
  String currencyCode   = 'ARS';
  String currencySymbol = r'$';
  int    priceRounding  = 0;

  // ── Sección: Notificaciones extendidas ─────────────────────────────────────
  int    stockAlertQty           = 5;
  bool   cashCloseEnabled        = false;
  String cashCloseTime           = '20:00';
  bool   whatsappReminderEnabled = false;

  // ── Sección: Privacidad ────────────────────────────────────────────────────
  bool   pinEnabled      = false;
  String pinCode         = '';
  int    autoLockMinutes = 0;
  bool   stealthMode     = false;

  // ── Sección: Datos ─────────────────────────────────────────────────────────
  String backupFrequency        = 'manual';
  String exportFormat           = 'json';
  int    historyRetentionMonths = 0;

  // ── Sección: Apariencia extendida ──────────────────────────────────────────
  String themeModeKey = 'system';
  double textScale    = 1.0;
  String languageCode = 'es';

  // Onboarding
  String businessType   = '';
  bool   onboardingDone = false;

  bool get hasImageBackground => bgType == BgType.image;

  ThemeMode get themeMode {
    switch (themeModeKey) {
      case 'light': return ThemeMode.light;
      case 'dark':  return ThemeMode.dark;
      default:      return ThemeMode.system;
    }
  }

  // ── Carga inicial desde SharedPreferences ─────────────────────────────────
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();

    notifMinutesBefore = p.getInt(_kNotifMin) ?? 30;
    primaryColor       = Color(p.getInt(_kPrimary) ?? Colors.redAccent.toARGB32());
    bgType             = BgType.values.firstWhere(
      (e) => e.name == (p.getString(_kBgType) ?? 'solid'),
      orElse: () => BgType.solid,
    );
    bgColor1    = Color(p.getInt(_kBgColor1) ?? 0xFF121212);
    bgColor2    = Color(p.getInt(_kBgColor2) ?? 0xFF1A1A2E);
    fontFamily  = p.getString(_kFont) ?? 'Roboto';
    bgImagePath = p.getString(_kBgImagePath);
    buttonStyle              = p.getInt(_kButtonStyle) ?? 0;
    backgroundOverlayOpacity = p.getDouble(_kOverlayOpacity) ?? 0.45;
    final btnC = p.getInt(_kButtonColor);
    _buttonColorOverride = btnC != null ? Color(btnC) : null;
    buttonTextColor = Color(p.getInt(_kButtonTextColor) ?? 0xFFFFFFFF);
    backgroundColor = Color(p.getInt(_kBgColorSolid)   ?? 0xFF121212);
    textColor       = Color(p.getInt(_kTextColor)       ?? 0xFFFFFFFF);
    cardColor       = Color(p.getInt(_kCardColor)       ?? 0xFF1E1E1E);

    // Negocio
    final wdRaw = p.getString(_kWorkDays);
    workDays = wdRaw != null
        ? List<int>.from(jsonDecode(wdRaw) as List)
        : [1, 2, 3, 4, 5, 6];
    workStart           = p.getString(_kWorkStart) ?? '09:00';
    workEnd             = p.getString(_kWorkEnd) ?? '19:00';
    defaultApptDuration = p.getInt(_kApptDuration) ?? 30;
    whatsappMsg         = p.getString(_kWhatsappMsg) ??
        'Hola {nombre}, te recordamos tu turno a las {hora}. ¡Te esperamos!';
    final bdRaw = p.getString(_kBlockedDays);
    blockedDays = bdRaw != null
        ? List<String>.from(jsonDecode(bdRaw) as List)
        : [];

    // Finanzas
    currencyCode   = p.getString(_kCurrency) ?? 'ARS';
    currencySymbol = p.getString(_kCurrencySymbol) ?? r'$';
    priceRounding  = p.getInt(_kPriceRounding) ?? 0;

    // Notificaciones ext
    stockAlertQty           = p.getInt(_kStockAlertQty) ?? 5;
    cashCloseEnabled        = p.getBool(_kCashCloseOn) ?? false;
    cashCloseTime           = p.getString(_kCashCloseTime) ?? '20:00';
    whatsappReminderEnabled = p.getBool(_kWaReminder) ?? false;

    // Privacidad
    pinEnabled      = p.getBool(_kPinEnabled) ?? false;
    pinCode         = p.getString(_kPinCode) ?? '';
    autoLockMinutes = p.getInt(_kAutoLockMin) ?? 0;
    stealthMode     = p.getBool(_kStealth) ?? false;

    // Datos
    backupFrequency        = p.getString(_kBackupFreq) ?? 'manual';
    exportFormat           = p.getString(_kExportFmt) ?? 'json';
    historyRetentionMonths = p.getInt(_kHistoryMonths) ?? 0;

    // Apariencia ext
    themeModeKey = p.getString(_kThemeMode) ?? 'system';
    textScale    = p.getDouble(_kTextScale) ?? 1.0;
    languageCode = p.getString(_kLanguage) ?? 'es';

    businessType   = p.getString(_kBusinessType) ?? '';
    onboardingDone = p.getBool(_kOnboardingDone) ?? false;
  }

  // ── Escritura ──────────────────────────────────────────────────────────────
  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kNotifMin,    notifMinutesBefore);
    await p.setInt(_kPrimary,     primaryColor.toARGB32());
    await p.setString(_kBgType,   bgType.name);
    await p.setInt(_kBgColor1,    bgColor1.toARGB32());
    await p.setInt(_kBgColor2,    bgColor2.toARGB32());
    await p.setString(_kFont,       fontFamily);
    await p.setInt(_kButtonStyle,      buttonStyle);
    await p.setDouble(_kOverlayOpacity, backgroundOverlayOpacity);
    if (_buttonColorOverride != null) {
      await p.setInt(_kButtonColor, _buttonColorOverride!.toARGB32());
    } else {
      await p.remove(_kButtonColor);
    }
    await p.setInt(_kButtonTextColor, buttonTextColor.toARGB32());
    await p.setInt(_kBgColorSolid,    backgroundColor.toARGB32());
    await p.setInt(_kTextColor,       textColor.toARGB32());
    await p.setInt(_kCardColor,       cardColor.toARGB32());
    if (bgImagePath != null) {
      await p.setString(_kBgImagePath, bgImagePath!);
    } else {
      await p.remove(_kBgImagePath);
    }
    // Negocio
    await p.setString(_kWorkDays,    jsonEncode(workDays));
    await p.setString(_kWorkStart,   workStart);
    await p.setString(_kWorkEnd,     workEnd);
    await p.setInt(_kApptDuration,   defaultApptDuration);
    await p.setString(_kWhatsappMsg, whatsappMsg);
    await p.setString(_kBlockedDays, jsonEncode(blockedDays));
    // Finanzas
    await p.setString(_kCurrency,        currencyCode);
    await p.setString(_kCurrencySymbol,  currencySymbol);
    await p.setInt(_kPriceRounding,      priceRounding);
    // Notificaciones ext
    await p.setInt(_kStockAlertQty,    stockAlertQty);
    await p.setBool(_kCashCloseOn,     cashCloseEnabled);
    await p.setString(_kCashCloseTime, cashCloseTime);
    await p.setBool(_kWaReminder,      whatsappReminderEnabled);
    // Privacidad
    await p.setBool(_kPinEnabled,   pinEnabled);
    await p.setString(_kPinCode,    pinCode);
    await p.setInt(_kAutoLockMin,   autoLockMinutes);
    await p.setBool(_kStealth,      stealthMode);
    // Datos
    await p.setString(_kBackupFreq,  backupFrequency);
    await p.setString(_kExportFmt,   exportFormat);
    await p.setInt(_kHistoryMonths,  historyRetentionMonths);
    // Apariencia ext
    await p.setString(_kThemeMode, themeModeKey);
    await p.setDouble(_kTextScale, textScale);
    await p.setString(_kLanguage,  languageCode);

    await p.setString(_kBusinessType,   businessType);
    await p.setBool(_kOnboardingDone, onboardingDone);
  }

  // ── Setters ────────────────────────────────────────────────────────────────
  Future<void> setNotifMinutes(int v) async        { notifMinutesBefore = v.clamp(1, 1440); await _persist(); notifyListeners(); }
  Future<void> setPrimaryColor(Color c) async      { primaryColor = c; await _persist(); notifyListeners(); }
  Future<void> setBgType(BgType t) async           { bgType = t; await _persist(); notifyListeners(); }
  Future<void> setBgColor1(Color c) async          { bgColor1 = c; await _persist(); notifyListeners(); }
  Future<void> setBgColor2(Color c) async          { bgColor2 = c; await _persist(); notifyListeners(); }
  Future<void> setFontFamily(String f) async       { fontFamily = f; await _persist(); notifyListeners(); }
  Future<void> setBgImagePath(String? v) async     { bgImagePath = v; await _persist(); notifyListeners(); }
  Future<void> setButtonStyle(int s) async         { buttonStyle = s; await _persist(); notifyListeners(); }
  Future<void> setBackgroundOverlayOpacity(double v) async { backgroundOverlayOpacity = v.clamp(0.0, 0.8); await _persist(); notifyListeners(); }
  Future<void> setButtonColor(Color c) async       { _buttonColorOverride = c; await _persist(); notifyListeners(); }
  Future<void> resetButtonColor() async            { _buttonColorOverride = null; await _persist(); notifyListeners(); }
  Future<void> setButtonTextColor(Color c) async   { buttonTextColor = c; await _persist(); notifyListeners(); }
  Future<void> setBackgroundColor(Color c) async   { backgroundColor = c; await _persist(); notifyListeners(); }
  Future<void> setTextColor(Color c) async         { textColor = c; await _persist(); notifyListeners(); }
  Future<void> setCardColor(Color c) async         { cardColor = c; await _persist(); notifyListeners(); }
  // Negocio
  Future<void> setWorkDays(List<int> v) async          { workDays = v; await _persist(); notifyListeners(); }
  Future<void> setWorkStart(String v) async             { workStart = v; await _persist(); notifyListeners(); }
  Future<void> setWorkEnd(String v) async               { workEnd = v; await _persist(); notifyListeners(); }
  Future<void> setDefaultApptDuration(int v) async     { defaultApptDuration = v; await _persist(); notifyListeners(); }
  Future<void> setWhatsappMsg(String v) async           { whatsappMsg = v; await _persist(); notifyListeners(); }
  Future<void> setBlockedDays(List<String> v) async    { blockedDays = v; await _persist(); notifyListeners(); }
  // Finanzas
  Future<void> setCurrencyCode(String v) async          { currencyCode = v; await _persist(); notifyListeners(); }
  Future<void> setCurrencySymbol(String v) async        { currencySymbol = v; await _persist(); notifyListeners(); }
  Future<void> setPriceRounding(int v) async            { priceRounding = v; await _persist(); notifyListeners(); }
  // Notificaciones ext
  Future<void> setStockAlertQty(int v) async            { stockAlertQty = v; await _persist(); notifyListeners(); }
  Future<void> setCashCloseEnabled(bool v) async        { cashCloseEnabled = v; await _persist(); notifyListeners(); }
  Future<void> setCashCloseTime(String v) async         { cashCloseTime = v; await _persist(); notifyListeners(); }
  Future<void> setWhatsappReminderEnabled(bool v) async { whatsappReminderEnabled = v; await _persist(); notifyListeners(); }
  // Privacidad
  Future<void> setPinEnabled(bool v) async              { pinEnabled = v; await _persist(); notifyListeners(); }
  Future<void> setPinCode(String v) async               { pinCode = v; await _persist(); notifyListeners(); }
  Future<void> setAutoLockMinutes(int v) async          { autoLockMinutes = v; await _persist(); notifyListeners(); }
  Future<void> setStealthMode(bool v) async             { stealthMode = v; await _persist(); notifyListeners(); }
  // Datos
  Future<void> setBackupFrequency(String v) async       { backupFrequency = v; await _persist(); notifyListeners(); }
  Future<void> setExportFormat(String v) async          { exportFormat = v; await _persist(); notifyListeners(); }
  Future<void> setHistoryRetentionMonths(int v) async   { historyRetentionMonths = v; await _persist(); notifyListeners(); }
  // Apariencia ext
  Future<void> setThemeModeKey(String v) async          { themeModeKey = v; await _persist(); notifyListeners(); }
  Future<void> setTextScale(double v) async             { textScale = v; await _persist(); notifyListeners(); }
  Future<void> setLanguageCode(String v) async          { languageCode = v; await _persist(); notifyListeners(); }

  Future<void> setBusinessType(String v) async          { businessType = v; await _persist(); notifyListeners(); }
  Future<void> setOnboardingDone(bool v) async          { onboardingDone = v; await _persist(); notifyListeners(); }

  // ── Construcción del ThemeData ─────────────────────────────────────────────
  ThemeData buildTheme({Brightness brightness = Brightness.dark}) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
    ).copyWith(primary: primaryColor);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: _textTheme(brightness).copyWith(
        bodyLarge:  _textTheme(brightness).bodyLarge?.copyWith(color: textColor),
        bodyMedium: _textTheme(brightness).bodyMedium?.copyWith(color: textColor),
        bodySmall:  _textTheme(brightness).bodySmall?.copyWith(color: textColor),
      ),
      scaffoldBackgroundColor: bgType == BgType.solid
          ? backgroundColor
          : Colors.transparent,
      cardTheme: bgType == BgType.image
          ? CardThemeData(
              color: Colors.black.withValues(alpha: 0.55),
              surfaceTintColor: Colors.transparent,
            )
          : CardThemeData(color: cardColor),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Colors.black : scheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? Colors.black : scheme.surface,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
      ),
      elevatedButtonTheme: buildButtonTheme(),
    );
  }

  // ── Estilos de botón ───────────────────────────────────────────────────────
  ElevatedButtonThemeData buildButtonTheme() {
    switch (buttonStyle) {
      case 1: // Moderno — pastilla
        return ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            elevation: 0,
            backgroundColor: buttonColor,
            foregroundColor: buttonTextColor,
          ),
        );
      case 2: // Minimal — plano, solo borde
        return ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: buttonColor,
            side: BorderSide(color: buttonColor, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      case 3: // Bold — esquinas rectas
        return ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: const RoundedRectangleBorder(),
            elevation: 0,
            backgroundColor: buttonColor,
            foregroundColor: buttonTextColor,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
        );
      default: // 0 Clásico
        return ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: buttonTextColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 4,
          ),
        );
    }
  }

  BoxDecoration? backgroundDecoration() {
    switch (bgType) {
      case BgType.solid:
        return null;
      case BgType.gradient:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [bgColor1, bgColor2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case BgType.image:
        final path = bgImagePath;
        if (path == null || !File(path).existsSync()) return null;
        return BoxDecoration(
          image: DecorationImage(
            image: FileImage(File(path)),
            fit: BoxFit.cover,
          ),
        );
    }
  }

  TextTheme _textTheme([Brightness brightness = Brightness.dark]) {
    final base = ThemeData(brightness: brightness).textTheme;
    if (fontFamily == 'Roboto') return base;
    try {
      final family = GoogleFonts.getFont(fontFamily).fontFamily;
      if (family == null) return base;
      return base.apply(fontFamily: family);
    } catch (_) {
      return base;
    }
  }
}
