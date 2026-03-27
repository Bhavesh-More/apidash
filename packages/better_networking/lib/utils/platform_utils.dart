import 'dart:io';

const bool isweb = bool.fromEnvironment('dart.library.js_interop');

/// Platform detection utilities for the better_networking package.
class PlatformUtils {
  /// Returns true if running on desktop platforms (macOS, Windows, Linux).
  static bool get isDesktop =>
      !isweb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  /// Returns true if running on mobile platforms (iOS, Android).
  static bool get isMobile => !isweb && (Platform.isIOS || Platform.isAndroid);

  /// Returns true if running on web.
  static bool get isWeb => isweb;

  /// Returns true if OAuth should use localhost callback server.
  /// This is true for desktop platforms.
  static bool get shouldUseLocalhostCallback => isDesktop;
}
