import 'package:uuid/uuid.dart';

/// Generates a unique request ID using UUID v4.
String generateRequestId() {
  const uuid = Uuid();
  return 'req_${uuid.v4()}';
}
