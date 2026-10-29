import 'package:equatable/equatable.dart';

/// A compound contact (security manager, supervisors, maintenance…) managed
/// from the admin app. Groups are shown in [groupOrder] order.
class ImportantNumber extends Equatable {
  final String id;

  /// One of [groupOrder]; unknown values are treated as `other`.
  final String group;
  final String name;
  final String role;
  final String phone;

  const ImportantNumber({
    required this.id,
    required this.group,
    required this.name,
    required this.role,
    required this.phone,
  });

  static const groupOrder = [
    'security',
    'maintenance',
    'management',
    'emergency',
    'other',
  ];

  factory ImportantNumber.fromMap(Map<String, dynamic> data) {
    final group = data['group']?.toString() ?? '';
    return ImportantNumber(
      id: data['id']?.toString() ?? '',
      group: groupOrder.contains(group) ? group : 'other',
      name: data['name']?.toString() ?? '',
      role: data['role']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
    );
  }

  /// The number in international digits for WhatsApp (Egypt: 01x… → 201x…).
  String get whatsappDigits {
    var d = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('00')) d = d.substring(2);
    if (d.startsWith('0')) d = '20${d.substring(1)}';
    return d;
  }

  @override
  List<Object?> get props => [id, group, name, role, phone];
}
