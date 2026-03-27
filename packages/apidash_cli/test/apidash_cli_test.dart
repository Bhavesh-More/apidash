import 'package:apidash_cli/apidash_cli.dart';
import 'package:test/test.dart';

void main() {
  test('creates cli runner', () {
    final runner = CliRunner();
    expect(runner.executableName, 'apidash');
  });
}
