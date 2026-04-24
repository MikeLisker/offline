class AppUsageData {
  final String packageName;
  final String appName;
  final Duration usageTime;
  final DateTime lastTimeUsed;
  final bool isDistracting; // Apps que restan energía

  AppUsageData({
    required this.packageName,
    required this.appName,
    required this.usageTime,
    required this.lastTimeUsed,
    this.isDistracting = false,
  });

  @override
  String toString() =>
      'AppUsage($appName: ${usageTime.inMinutes}m, distracting: $isDistracting)';
}

// Apps categorizadas como "distractoras"
final List<String> DISTRACTING_APPS = [
  'com.instagram.android',
  'com.facebook.katana',
  'com.twitter.android',
  'com.snapchat.android',
  'com.tiktok.android',
  'com.google.android.youtube',
  'com.whatsapp',
  'com.telegram',
  'com.discord',
  'com.reddit.frontpage',
];

bool isAppDistracting(String packageName) {
  return DISTRACTING_APPS.any((pkg) => packageName.contains(pkg));
}
