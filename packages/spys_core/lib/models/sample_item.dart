// packages/spys_core/lib/models/sample_item.dart
class SampleItem {
  final String id;
  final String name;

  const SampleItem({required this.id, required this.name});

  @override
  String toString() => 'SampleItem(id: $id, name: $name)';
}
