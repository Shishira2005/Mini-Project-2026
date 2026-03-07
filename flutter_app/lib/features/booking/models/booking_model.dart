class BookingModel {
  BookingModel({
    required this.id,
    required this.roomId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.requestedBy,
    required this.purpose,
    required this.status,
    this.createdByRole,
    this.createdByLoginId,
    this.batch,
    this.roomNumber,
    this.roomName,
  });

  final String id;
  final String roomId;
  final String date;
  final String startTime;
  final String endTime;
  final String requestedBy;
  final String purpose;
  final String status;
  final String? createdByRole;
  final String? createdByLoginId;
  final String? batch;
  final String? roomNumber;
  final String? roomName;

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final room = json['room'];
    String roomId;
    String? roomNumber;
    String? roomName;

    if (room is Map<String, dynamic>) {
      roomId = room['_id'] as String;
      roomNumber = room['roomNumber'] as String?;
      roomName = room['name'] as String?;
    } else {
      roomId = json['room'] as String;
    }

    return BookingModel(
      id: json['_id'] as String,
      roomId: roomId,
      date: json['date'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      requestedBy: json['requestedBy'] as String,
      purpose: json['purpose'] as String,
      status: json['status'] as String,
      createdByRole: json['createdByRole'] as String?,
      createdByLoginId: json['createdByLoginId'] as String?,
      batch: json['batch'] as String?,
      roomNumber: roomNumber,
      roomName: roomName,
    );
  }
}
