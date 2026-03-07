class SwapOptionModel {
  SwapOptionModel({
    required this.classroomName,
    required this.courseName,
    required this.facultyId,
    required this.facultyName,
    required this.hasProjector,
    required this.capacity,
    required this.colorHint,
  });

  final String classroomName;
  final String courseName;
  final String facultyId;
  final String facultyName;
  final bool hasProjector;
  final int? capacity;
  final String colorHint;

  factory SwapOptionModel.fromJson(Map<String, dynamic> json) {
    return SwapOptionModel(
      classroomName: json['classroomName'] as String,
      courseName: (json['courseName'] ?? '') as String,
      facultyId: (json['facultyId'] ?? '') as String,
      facultyName: (json['facultyName'] ?? '') as String,
      hasProjector: (json['hasProjector'] ?? false) as bool,
      capacity: json['capacity'] as int?,
      colorHint: (json['colorHint'] ?? '') as String,
    );
  }
}

class SwapOptionsResult {
  SwapOptionsResult({
    required this.available,
    required this.message,
    required this.weekdayIndex,
    required this.periodIndex,
    required this.startTime,
    required this.endTime,
    required this.requesterEntry,
    required this.options,
  });

  final bool available;
  final String message;
  final int? weekdayIndex;
  final int? periodIndex;
  final String? startTime;
  final String? endTime;
  final SwapOptionModel? requesterEntry;
  final List<SwapOptionModel> options;

  factory SwapOptionsResult.fromJson(Map<String, dynamic> json) {
    final requesterJson = json['requesterEntry'] as Map<String, dynamic>?;
    final optionsJson = json['options'] as List<dynamic>? ?? <dynamic>[];

    return SwapOptionsResult(
      available: (json['available'] ?? false) as bool,
      message: (json['message'] ?? '') as String,
      weekdayIndex: json['weekdayIndex'] as int?,
      periodIndex: json['periodIndex'] as int?,
      startTime:
          (json['timeRange'] as Map<String, dynamic>?)?['startTime'] as String?,
      endTime:
          (json['timeRange'] as Map<String, dynamic>?)?['endTime'] as String?,
      requesterEntry:
          requesterJson != null ? SwapOptionModel.fromJson(requesterJson) : null,
      options: optionsJson
          .map((e) => SwapOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SwapRequestModel {
  SwapRequestModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.projectorRequired,
    required this.requesterFacultyId,
    required this.requesterFacultyName,
    required this.requesterClassroomName,
    required this.targetClassroomName,
    required this.targetFacultyId,
    required this.targetFacultyName,
    required this.reason,
    required this.status,
  });

  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final bool projectorRequired;
  final String requesterFacultyId;
  final String requesterFacultyName;
  final String requesterClassroomName;
  final String targetClassroomName;
  final String targetFacultyId;
  final String targetFacultyName;
  final String reason;
  final String status;

  factory SwapRequestModel.fromJson(Map<String, dynamic> json) {
    return SwapRequestModel(
      id: json['_id'] as String,
      date: (json['date'] ?? '') as String,
      startTime: (json['startTime'] ?? '') as String,
      endTime: (json['endTime'] ?? '') as String,
      projectorRequired: (json['projectorRequired'] ?? false) as bool,
      requesterFacultyId: (json['requesterFacultyId'] ?? '') as String,
      requesterFacultyName: (json['requesterFacultyName'] ?? '') as String,
      requesterClassroomName:
          (json['requesterClassroomName'] ?? '') as String,
      targetClassroomName: (json['targetClassroomName'] ?? '') as String,
      targetFacultyId: (json['targetFacultyId'] ?? '') as String,
      targetFacultyName: (json['targetFacultyName'] ?? '') as String,
      reason: (json['reason'] ?? '') as String,
      status: (json['status'] ?? '') as String,
    );
  }
}
