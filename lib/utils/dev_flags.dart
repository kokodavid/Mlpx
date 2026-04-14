class DevFlags {
  const DevFlags._();

  // Enable with:
  // flutter run --dart-define=ALLOW_LOCKED_COURSE_ACCESS=true
  static const bool allowLockedCourseAccess = bool.fromEnvironment(
    'ALLOW_LOCKED_COURSE_ACCESS',
    defaultValue: false,
  );
}
