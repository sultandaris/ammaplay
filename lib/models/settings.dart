// Settings data model
class AppSettings {
  final String sound;
  final String notifications;
  final String fontSize;

  const AppSettings({
    this.sound = 'on',
    this.notifications = 'on',
    this.fontSize = 'medium',
  });

  // Create a copy with updated values
  AppSettings copyWith({
    String? sound,
    String? notifications,
    String? fontSize,
  }) {
    return AppSettings(
      sound: sound ?? this.sound,
      notifications: notifications ?? this.notifications,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  // Convert to Map for database storage
  Map<String, String> toMap() {
    return {
      'sound': sound,
      'notifications': notifications,
      'font_size': fontSize,
    };
  }

  // Create from Map (from database)
  factory AppSettings.fromMap(Map<String, String> map) {
    return AppSettings(
      sound: map['sound'] ?? 'on',
      notifications: map['notifications'] ?? 'on',
      fontSize: map['font_size'] ?? 'medium',
    );
  }

  @override
  String toString() {
    return 'AppSettings(sound: $sound, notifications: $notifications, fontSize: $fontSize)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.sound == sound &&
        other.notifications == notifications &&
        other.fontSize == fontSize;
  }

  @override
  int get hashCode =>
      sound.hashCode ^ notifications.hashCode ^ fontSize.hashCode;
}
