class NotificationSettingsModel {
  bool appReminderEnabled;
  int appReminderHour;
  int appReminderMinute;

  bool sleepEnabled;
  int sleepAdvanceMinutes;

  bool feedEnabled;
  int feedAdvanceMinutes;

  bool sleepWindowEnabled;

  bool diaperPeeEnabled;
  bool diaperPoopEnabled;
  int diaperIntervalHours;

  NotificationSettingsModel({
    this.appReminderEnabled = false,
    this.appReminderHour = 9,
    this.appReminderMinute = 0,
    this.sleepEnabled = true,
    this.sleepAdvanceMinutes = 15,
    this.feedEnabled = true,
    this.feedAdvanceMinutes = 15,
    this.sleepWindowEnabled = true,
    this.diaperPeeEnabled = false,
    this.diaperPoopEnabled = false,
    this.diaperIntervalHours = 2,
  });

  Map<String, dynamic> toMap() {
    return {
      'appReminderEnabled': appReminderEnabled,
      'appReminderHour': appReminderHour,
      'appReminderMinute': appReminderMinute,
      'sleepEnabled': sleepEnabled,
      'sleepAdvanceMinutes': sleepAdvanceMinutes,
      'feedEnabled': feedEnabled,
      'feedAdvanceMinutes': feedAdvanceMinutes,
      'sleepWindowEnabled': sleepWindowEnabled,
      'diaperPeeEnabled': diaperPeeEnabled,
      'diaperPoopEnabled': diaperPoopEnabled,
      'diaperIntervalHours': diaperIntervalHours,
    };
  }

  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsModel(
      appReminderEnabled: map['appReminderEnabled'] ?? false,
      appReminderHour: map['appReminderHour'] ?? 9,
      appReminderMinute: map['appReminderMinute'] ?? 0,
      sleepEnabled: map['sleepEnabled'] ?? true,
      sleepAdvanceMinutes: map['sleepAdvanceMinutes'] ?? 15,
      feedEnabled: map['feedEnabled'] ?? true,
      feedAdvanceMinutes: map['feedAdvanceMinutes'] ?? 15,
      sleepWindowEnabled: map['sleepWindowEnabled'] ?? true,
      diaperPeeEnabled: map['diaperPeeEnabled'] ?? false,
      diaperPoopEnabled: map['diaperPoopEnabled'] ?? false,
      diaperIntervalHours: map['diaperIntervalHours'] ?? 2,
    );
  }

  NotificationSettingsModel copy() {
    return NotificationSettingsModel(
      appReminderEnabled: appReminderEnabled,
      appReminderHour: appReminderHour,
      appReminderMinute: appReminderMinute,
      sleepEnabled: sleepEnabled,
      sleepAdvanceMinutes: sleepAdvanceMinutes,
      feedEnabled: feedEnabled,
      feedAdvanceMinutes: feedAdvanceMinutes,
      sleepWindowEnabled: sleepWindowEnabled,
      diaperPeeEnabled: diaperPeeEnabled,
      diaperPoopEnabled: diaperPoopEnabled,
      diaperIntervalHours: diaperIntervalHours,
    );
  }
}
