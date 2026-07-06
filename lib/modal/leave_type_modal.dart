class LeaveTypesResponse {
  final String status;
  final List<String> leaveTypes;

  LeaveTypesResponse({
    required this.status,
    required this.leaveTypes,
  });

  factory LeaveTypesResponse.fromJson(Map<String, dynamic> json) {
    final message = json['message'] ?? {};
    final leaveTypesList = message['leave_types'] as List? ?? [];
    return LeaveTypesResponse(
      status: message['status'] ?? '',
      leaveTypes: leaveTypesList.map((e) => e.toString()).toList(),
    );
  }
}
