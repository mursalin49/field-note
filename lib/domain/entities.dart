import 'package:equatable/equatable.dart';

enum NoteStatus {
  draft('DRAFT', 'Draft'),
  inProgress('IN_PROGRESS', 'In progress'),
  completed('COMPLETED', 'Completed');

  const NoteStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static NoteStatus fromApi(String? v) =>
      NoteStatus.values.firstWhere((s) => s.apiValue == v, orElse: () => NoteStatus.draft);
}

class AppUser extends Equatable {
  const AppUser({required this.id, required this.name, required this.email});
  final int id;
  final String name;
  final String email;
  @override
  List<Object?> get props => [id, name, email];
}

class Customer extends Equatable {
  const Customer({required this.id, required this.name, this.contactInfo = '', required this.updatedAt});
  final String id;
  final String name;
  final String contactInfo;
  final DateTime updatedAt;
  @override
  List<Object?> get props => [id, name, contactInfo, updatedAt];
}

class Site extends Equatable {
  const Site({
    required this.id,
    required this.customerId,
    this.customerName = '', // read-only, JOINed from customers
    required this.name,
    this.address = '',
    required this.updatedAt,
  });
  final String id;
  final String customerId;
  final String customerName;
  final String name;
  final String address;
  final DateTime updatedAt;
  @override
  List<Object?> get props => [id, customerId, customerName, name, address, updatedAt];
}

class FieldNote extends Equatable {
  const FieldNote({
    required this.id,
    required this.siteId,
    this.siteName = '', // read-only, JOINed
    this.customerId = '', // read-only, JOINed
    this.customerName = '', // read-only, JOINed
    required this.title,
    this.description = '',
    this.latitude,
    this.longitude,
    required this.dateTime,
    required this.status,
    this.photoPath,
    this.photoUrl,
    required this.updatedAt,
  });
  final String id;
  final String siteId;
  final String siteName;
  final String customerId;
  final String customerName;
  final String title;
  final String description;
  final double? latitude;
  final double? longitude;
  final DateTime dateTime;
  final NoteStatus status;
  final String? photoPath; // local file
  final String? photoUrl; // server path (relative)
  final DateTime updatedAt;

  bool get hasLocation => latitude != null && longitude != null;

  @override
  List<Object?> get props => [id, siteId, siteName, customerId, customerName, title, description, latitude,
        longitude, dateTime, status, photoPath, photoUrl, updatedAt];
}

class NotesFilter extends Equatable {
  const NotesFilter({this.query = '', this.status, this.siteId});
  final String query;
  final NoteStatus? status;
  final String? siteId;

  NotesFilter copyWith({String? query, NoteStatus? status, String? siteId, bool clearStatus = false, bool clearSite = false}) =>
      NotesFilter(
        query: query ?? this.query,
        status: clearStatus ? null : (status ?? this.status),
        siteId: clearSite ? null : (siteId ?? this.siteId),
      );

  bool get isActive => query.trim().isNotEmpty || status != null || siteId != null;

  @override
  List<Object?> get props => [query, status, siteId];
}
