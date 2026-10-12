import '../../domain/entities.dart';

DateTime _parse(String s) => DateTime.parse(s).toUtc();
String _iso(DateTime d) => d.toUtc().toIso8601String();

Map<String, dynamic> customerToJson(Customer c) =>
    {'id': c.id, 'name': c.name, 'contactInfo': c.contactInfo, 'updatedAt': _iso(c.updatedAt), 'deleted': false};

Customer customerFromJson(Map<String, dynamic> j) => Customer(
    id: j['id'] as String,
    name: j['name'] as String,
    contactInfo: (j['contactInfo'] as String?) ?? '',
    updatedAt: _parse(j['updatedAt'] as String));

Map<String, dynamic> siteToJson(Site s) => {
      'id': s.id,
      'customerId': s.customerId,
      'name': s.name,
      'address': s.address,
      'updatedAt': _iso(s.updatedAt),
      'deleted': false,
    };

Site siteFromJson(Map<String, dynamic> j) => Site(
    id: j['id'] as String,
    customerId: j['customerId'] as String,
    customerName: (j['customerName'] as String?) ?? '',
    name: j['name'] as String,
    address: (j['address'] as String?) ?? '',
    updatedAt: _parse(j['updatedAt'] as String));

Map<String, dynamic> noteToJson(FieldNote n) => {
      'id': n.id,
      'siteId': n.siteId,
      'title': n.title,
      'description': n.description,
      'latitude': n.latitude,
      'longitude': n.longitude,
      'noteDateTime': _iso(n.dateTime),
      'status': n.status.apiValue,
      'updatedAt': _iso(n.updatedAt),
      'deleted': false,
    };

FieldNote noteFromJson(Map<String, dynamic> j) => FieldNote(
    id: j['id'] as String,
    siteId: j['siteId'] as String,
    siteName: (j['siteName'] as String?) ?? '',
    customerId: (j['customerId'] as String?) ?? '',
    customerName: (j['customerName'] as String?) ?? '',
    title: j['title'] as String,
    description: (j['description'] as String?) ?? '',
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
    dateTime: _parse(j['noteDateTime'] as String),
    status: NoteStatus.fromApi(j['status'] as String?),
    photoUrl: j['photoUrl'] as String?,
    updatedAt: _parse(j['updatedAt'] as String));
