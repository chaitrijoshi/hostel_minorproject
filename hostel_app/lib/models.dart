class Hostel {
  final int id;
  final String name;
  final String address;
  final int wardenCount;
  final int studentCount;
  final int guardCount;

  Hostel({
    required this.id,
    required this.name,
    required this.address,
    required this.wardenCount,
    required this.studentCount,
    required this.guardCount,
  });

  factory Hostel.fromJson(Map<String, dynamic> json) => Hostel(
        id: json['id'],
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        wardenCount: json['warden_count'] ?? 0,
        studentCount: json['student_count'] ?? 0,
        guardCount: json['guard_count'] ?? 0,
      );
}

class Warden {
  final int id;
  final String name;
  final String username;
  final String hostelName;
  final bool pendingFirstLogin;

  Warden({
    required this.id,
    required this.name,
    required this.username,
    required this.hostelName,
    required this.pendingFirstLogin,
  });

  factory Warden.fromJson(Map<String, dynamic> json) => Warden(
        id: json['id'],
        name: (json['warden_name'] ?? '').toString(),
        username: json['warden_username'] ?? '',
        hostelName: json['hostel_name'] ?? '',
        pendingFirstLogin: json['login_active'] ?? false,
      );
}

class Student {
  final int id;
  final String name;
  final String username;
  final String hostelName;
  final bool pendingFirstLogin;
  final String enrollmentNo;
  final String roomNo;
  final String phone;
  final String parentContact;

  Student({
    required this.id,
    required this.name,
    required this.username,
    required this.hostelName,
    required this.pendingFirstLogin,
    required this.enrollmentNo,
    required this.roomNo,
    required this.phone,
    required this.parentContact,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        id: json['id'],
        name: (json['student_name'] ?? '').toString(),
        username: json['student_username'] ?? '',
        hostelName: json['hostel_name'] ?? '',
        pendingFirstLogin: json['login_active'] ?? false,
        enrollmentNo: json['enrollment_no'] ?? '',
        roomNo: json['room_no'] ?? '',
        phone: json['phone'] ?? '',
        parentContact: json['parent_contact'] ?? '',
      );
}

class Guard {
  final int id;
  final String name;
  final String username;
  final String hostelName;
  final bool pendingFirstLogin;
  final String shiftTime;

  Guard({
    required this.id,
    required this.name,
    required this.username,
    required this.hostelName,
    required this.pendingFirstLogin,
    required this.shiftTime,
  });

  factory Guard.fromJson(Map<String, dynamic> json) => Guard(
        id: json['id'],
        name: (json['guard_name'] ?? '').toString(),
        username: json['guard_username'] ?? '',
        hostelName: json['hostel_name'] ?? '',
        pendingFirstLogin: json['login_active'] ?? false,
        shiftTime: json['shift_time'] ?? '',
      );
}

class EntryExitLog {
  final int id;
  final String studentName;
  final String roomNo;
  final String? guardName;
  final String? entryTime;
  final String? exitTime;
  final String status;
  final String remarks;
  final String createdAt;

  EntryExitLog({
    required this.id,
    required this.studentName,
    required this.roomNo,
    required this.guardName,
    required this.entryTime,
    required this.exitTime,
    required this.status,
    required this.remarks,
    required this.createdAt,
  });

  factory EntryExitLog.fromJson(Map<String, dynamic> json) =>
      EntryExitLog(
        id: json['id'],
        studentName: (json['student_name'] ?? '').toString(),
        roomNo: (json['room_no'] ?? '').toString(),
        guardName: json['guard_name']?.toString(),
        entryTime: json['entry_time']?.toString(),
        exitTime: json['exit_time']?.toString(),
        status: json['status'] ?? '',
        remarks: json['remarks'] ?? '',
        createdAt: json['created_at'] ?? '',
      );
}


// ============================================================
// ENTRY / EXIT REQUEST
// ============================================================


class EntryExitRequest {
  final int id;
  final int? student;
  final String studentName;
  final String enrollmentNo;
  final String roomNo;
  final String requestType;
  final String destination;
  final String? expectedReturnTime;
  final String requestTime;
  final String? entryTime;
  final String status;

  EntryExitRequest({
    required this.id,
    required this.student,
    required this.studentName,
    required this.enrollmentNo,
    required this.roomNo,
    required this.requestType,
    required this.destination,
    required this.expectedReturnTime,
    required this.requestTime,
    required this.entryTime,
    required this.status,
  });

  factory EntryExitRequest.fromJson(
    Map<String, dynamic> json,
  ) {
    return EntryExitRequest(
      id: json['id'] ?? 0,
      student: json['student'],
      studentName:
          (json['student_name'] ?? '').toString(),
      enrollmentNo:
          (json['enrollment_no'] ?? '').toString(),
      roomNo: (json['room_no'] ?? '').toString(),
      requestType:
          (json['request_type'] ?? '').toString(),
      destination:
          (json['destination'] ?? '').toString(),
      expectedReturnTime:
          json['expected_return_time']?.toString(),
      requestTime:
          (json['request_time'] ?? '').toString(),
      entryTime:
          json['entry_time']?.toString(),
      status:
          (json['status'] ?? 'PENDING').toString(),
    );
  }
}

// ============================================================
// VISITOR LOG
// ============================================================

class VisitorLog {
  final int id;
  final String name;
  final String phone;
  final String purpose;
  final String studentName;
  final String? guardName;
  final String? entryTime;
  final String? exitTime;
  final String status;

  VisitorLog({
    required this.id,
    required this.name,
    required this.phone,
    required this.purpose,
    required this.studentName,
    required this.guardName,
    required this.entryTime,
    required this.exitTime,
    required this.status,
  });

  factory VisitorLog.fromJson(Map<String, dynamic> json) =>
      VisitorLog(
        id: json['id'],
        name: json['name'] ?? '',
        phone: json['phone'] ?? '',
        purpose: json['purpose'] ?? '',
        studentName: (json['student_name'] ?? '').toString(),
        guardName: json['guard_name']?.toString(),
        entryTime: json['entry_time']?.toString(),
        exitTime: json['exit_time']?.toString(),
        status: json['status'] ?? '',
      );
}


// ============================================================
// NOTIFICATION
// ============================================================

class AppNotification {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'],
        title: json['title'] ?? '',
        message: json['message'] ?? '',
        isRead: json['is_read'] ?? false,
        createdAt: json['created_at'] ?? '',
      );
}