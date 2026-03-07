class ClassroomModel {
  ClassroomModel({
    required this.id,
    required this.roomNumber,
    required this.name,
    required this.type,
    required this.capacity,
    required this.hasProjector,
  });

  final String id;
  final String roomNumber;
  final String name;
  final String type;
  final int capacity;
  final bool hasProjector;

  factory ClassroomModel.fromJson(Map<String, dynamic> json) {
    return ClassroomModel(
      id: json['_id'] as String,
      roomNumber: json['roomNumber'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      capacity: json['capacity'] as int,
      hasProjector: json['hasProjector'] as bool,
    );
  }
}
