import '../models/laundry_item.dart';

class LaundryRepository {
  final List<LaundryItem> _items = [
    LaundryItem(
      id: 'LD001',
      residentName: 'Ahmed',
      serviceType: 'Lavage',
      status: LaundryStatus.deposited,
      price: 15.0,
    ),
    LaundryItem(
      id: 'LD002',
      residentName: 'Sara',
      serviceType: 'Nettoyage à sec',
      status: LaundryStatus.processing,
      price: 25.0,
    ),
    LaundryItem(
      id: 'LD003',
      residentName: 'Yasmine',
      serviceType: 'Repassage',
      status: LaundryStatus.ready,
      price: 10.0,
    ),
  ];

  List<LaundryItem> getAll() {
    return List.unmodifiable(_items);
  }
  List<LaundryItem> getByResidentId(int residentId) {
    return List.unmodifiable(
      _items.where(
            (item) => item.residentId == residentId,
      ),
    );
  }

  void add(LaundryItem item) {
    _items.add(item);
  }

  void update(LaundryItem updatedItem) {
    final index = _items.indexWhere(
          (item) => item.id == updatedItem.id,
    );

    if (index != -1) {
      _items[index] = updatedItem;
    }
  }

  void delete(String id) {
    _items.removeWhere(
          (item) => item.id == id,
    );
  }
}