import 'entities.dart';

/// Thrown by data sources; carries a user-friendly message.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  bool get isNetwork => statusCode == null;

  /// Retry later (keep the queued change) vs. permanent rejection (drop it).
  bool get retryable => statusCode == null || statusCode! >= 500 || const [401, 408, 429].contains(statusCode);

  @override
  String toString() => message;
}

abstract class AuthRepository {
  Future<AppUser?> currentUser();
  Future<AppUser> login(String email, String password);
  Future<AppUser> register(String name, String email, String password);
  Future<void> logout();
  Future<void> expireSession();
  Stream<void> get sessionExpired;
}

abstract class CustomerRepository {
  Stream<List<Customer>> watchCustomers();
  Stream<Customer?> watchCustomer(String id);
  Future<void> save(Customer customer);
  Future<void> delete(String id);
}

abstract class SiteRepository {
  Stream<List<Site>> watchSites({String? customerId});
  Stream<Site?> watchSite(String id);
  Future<void> save(Site site);
  Future<void> delete(String id);
}

abstract class NoteRepository {
  Stream<List<FieldNote>> watchNotes(NotesFilter filter);
  Stream<FieldNote?> watchNote(String id);
  Future<void> save(FieldNote note);
  Future<void> delete(String id);
}

abstract class SettingsRepository {
  NoteStatus get defaultStatus;
  Future<void> setDefaultStatus(NoteStatus status);
}

abstract class SyncRepository {
  Future<void> sync();
  Stream<int> watchPendingCount();
  Stream<void> get localChanges;
  Stream<bool> get onlineChanges;
  Future<bool> get isOnline;
  DateTime? get lastSync;
}
