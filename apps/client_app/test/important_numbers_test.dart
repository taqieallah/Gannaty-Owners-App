import 'package:compound_core/compound_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parse keeps the admin order and skips incomplete entries', () {
    final numbers = ImportantNumbersRepository.parse({
      'items': [
        {'id': '1', 'group': 'maintenance', 'name': 'B', 'phone': '0101'},
        {'id': '2', 'group': 'security', 'name': 'A', 'phone': '0102'},
        {'id': '3', 'group': 'security', 'name': '', 'phone': '0103'},
        {'id': '4', 'group': 'weird', 'name': 'C', 'phone': '0104'},
        'not a map',
      ],
    });

    expect(numbers.map((n) => n.id), ['1', '2', '4']);
    expect(numbers.last.group, 'other');
    expect(ImportantNumbersRepository.parse(null), isEmpty);
    expect(ImportantNumbersRepository.parse({'items': 'x'}), isEmpty);
  });

  test('whatsappDigits turns Egyptian numbers international', () {
    ImportantNumber n(String phone) => ImportantNumber(
      id: '',
      group: 'security',
      name: 'x',
      role: '',
      phone: phone,
    );

    expect(n('010 1234 5678').whatsappDigits, '201012345678');
    expect(n('+20 101 234 5678').whatsappDigits, '201012345678');
    expect(n('00201012345678').whatsappDigits, '201012345678');
  });
}
