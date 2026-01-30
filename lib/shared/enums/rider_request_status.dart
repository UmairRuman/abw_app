// lib/shared/enums/rider_request_status.dart

enum RiderRequestStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case RiderRequestStatus.pending:
        return 'Pending';
      case RiderRequestStatus.approved:
        return 'Approved';
      case RiderRequestStatus.rejected:
        return 'Rejected';
    }
  }

  static RiderRequestStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return RiderRequestStatus.pending;
      case 'approved':
        return RiderRequestStatus.approved;
      case 'rejected':
        return RiderRequestStatus.rejected;
      default:
        return RiderRequestStatus.pending;
    }
  }
}