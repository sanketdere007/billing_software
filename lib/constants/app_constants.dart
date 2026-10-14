/// Centralized Application Configuration & Constants
///
/// Use this single location to update the application title and version number
/// manually in the future.
class AppConstants {
  AppConstants._();

  /// Application Name displayed in Windows Title Bar and across the app
  static const String appName = 'SankySoft Billing';

  /// Application Semantic Version (Major.Minor.Patch)
  static const String appVersion = '1.0.1';

  /// Application Build Number
  static const String appBuildNumber = '1';

  /// Standard version display text: e.g. "Version 1.0.1"
  static const String versionDisplay = 'Version $appVersion';
}
