import 'package:flutter_test/flutter_test.dart';
import 'package:shop/data/models/shop_model.dart';

void main() {
  test('Shop.fromJson convertit correctement la réponse API', () {
    final shop = Shop.fromJson({
      'id': 7,
      'name': 'Boutique Centrale',
      'description': 'Point principal',
      'currency': 'XAF',
      'employees_count': 3,
      'is_active': true,
    });

    expect(shop.id, 7);
    expect(shop.name, 'Boutique Centrale');
    expect(shop.employeesCount, 3);
    expect(shop.isActive, isTrue);
  });
}
