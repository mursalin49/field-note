import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/di.dart';
import '../../core/permissions.dart';
import '../../data/local/photo_storage.dart';
import '../../domain/entities.dart';
import '../blocs/notes_bloc.dart';
import '../blocs/settings_cubit.dart';
import '../blocs/sites_bloc.dart';
import '../widgets/dialogs.dart';
import '../widgets/stored_photo.dart';

class NoteFormPage extends StatefulWidget {
  const NoteFormPage({super.key, this.note, this.siteId});
  final FieldNote? note; // null => create
  final String? siteId; // preselected site for new notes
  @override
  State<NoteFormPage> createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<NoteFormPage> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.note?.title);
  late final _desc = TextEditingController(text: widget.note?.description);
  late String? _siteId = widget.note?.siteId ?? widget.siteId;
  // new notes start with the "Default Note Status" from Settings
  late NoteStatus _status =
      widget.note?.status ?? context.read<SettingsCubit>().state;
  late DateTime _dt = (widget.note?.dateTime ?? DateTime.now()).toLocal();
  late double? _lat = widget.note?.latitude;
  late double? _lng = widget.note?.longitude;
  late String? _photoPath = widget.note?.photoPath;
  bool _locating = false;

  bool get _isEdit => widget.note != null;

  @override
  void initState() {
    super.initState();
    if (!_isEdit) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _locate()); // auto-tag new notes
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _showFailure(DeviceFailure f) {
    if (!mounted) return;
    showSnack(context, f.message,
        actionLabel: f.open == null ? null : 'Settings',
        onAction: f.open == null ? null : () => f.open!());
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    try {
      final pos = await DeviceServices.currentPosition();
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
        });
      }
    } on DeviceFailure catch (f) {
      _showFailure(f);
    } catch (_) {
      if (mounted) {
        showSnack(context,
            'Could not get your location. Try again outside or in a better signal area.');
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      if (source == ImageSource.camera && !kIsWeb) {
        await DeviceServices.ensureCamera();
      }
      final picked = await ImagePicker()
          .pickImage(source: source, maxWidth: 1600, imageQuality: 80);
      if (picked == null) return;
      final storage = getIt<PhotoStorage>();
      final saved = kIsWeb
          ? await storage.persistBytes(await picked.readAsBytes(),
              mimeType: picked.mimeType ?? 'image/jpeg')
          : await storage.persist(picked.path);
      if (mounted) setState(() => _photoPath = saved);
    } on DeviceFailure catch (f) {
      _showFailure(f);
    } catch (_) {
      if (mounted) showSnack(context, 'Could not load the photo.');
    }
  }

  Future<void> _pickDateTime() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _dt,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100));
    if (d == null || !mounted) return;
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_dt));
    if (t == null) return;
    setState(() => _dt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final old = widget.note;
    final note = FieldNote(
      id: old?.id ?? const Uuid().v4(),
      siteId: _siteId!,
      title: _title.text.trim(),
      description: _desc.text.trim(),
      latitude: _lat,
      longitude: _lng,
      dateTime: _dt.toUtc(),
      status: _status,
      photoPath: _photoPath,
      photoUrl: old?.photoUrl,
      updatedAt: DateTime.now().toUtc(),
    );
    context.read<NotesBloc>().add(NoteSaved(note));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final sites = context.watch<SitesBloc>().state.sites;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE2E5E3)),
          ),
        ),
        centerTitle: true,
        title: Text(_isEdit ? 'Edit note' : 'New note'),
        actions: [
          TextButton(
            onPressed: _save,
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFD9430D)),
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            _fieldLabel('Site'),
            DropdownButtonFormField<String>(
              initialValue: sites.any((s) => s.id == _siteId) ? _siteId : null,
              isExpanded: true,
              decoration: _fieldDecoration(
                  icon: Icons.place_outlined, hint: 'Choose a site'),
              items: [
                for (final s in sites)
                  DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name, overflow: TextOverflow.ellipsis))
              ],
              validator: (v) => v == null ? 'Select a site' : null,
              onChanged: (v) => setState(() => _siteId = v),
            ),
            const SizedBox(height: 14),
            _fieldLabel('Title'),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: _fieldDecoration(hint: 'What did you observe?'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 14),
            _fieldLabel('Description'),
            TextFormField(
              controller: _desc,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 5,
              decoration: _fieldDecoration(
                  hint: 'Add details, measurements or follow-up notes…'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _fieldLabel('Status'),
                const Spacer(),
                const Text('Default from Settings',
                    style: TextStyle(
                        color: Color(0xFFD9430D),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFECEEEC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  for (final status in NoteStatus.values)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _status = status),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _status == status
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: _status == status
                                ? const [
                                    BoxShadow(
                                        color: Color(0x12000000),
                                        blurRadius: 6,
                                        offset: Offset(0, 2))
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            status.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _status == status
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _status == status
                                  ? const Color(0xFF15181C)
                                  : const Color(0xFF69737C),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _fieldLabel('Date & time'),
            InkWell(
              onTap: _pickDateTime,
              borderRadius: BorderRadius.circular(14),
              child: _formSurface(
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined,
                        size: 19, color: Color(0xFF69737C)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(DateFormat('d MMM y, h:mm a').format(_dt),
                          style: const TextStyle(
                              color: Color(0xFF15181C), fontSize: 14)),
                    ),
                    const Icon(Icons.edit_calendar_outlined,
                        size: 18, color: Color(0xFFA5ADB4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _fieldLabel('Location'),
            _formSurface(
              child: Row(
                children: [
                  const Icon(Icons.my_location,
                      size: 19, color: Color(0xFF69737C)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _lat == null || _lng == null
                          ? (_locating ? 'Getting location…' : 'Not recorded')
                          : '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                      style: const TextStyle(
                          color: Color(0xFF15181C), fontSize: 14),
                    ),
                  ),
                  if (_locating)
                    const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    TextButton(
                      onPressed: _locate,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEDE4),
                        foregroundColor: const Color(0xFFD9430D),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: Text(_lat == null ? 'Use GPS' : 'Update GPS'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _fieldLabel('Photo (optional)'),
            if (_photoPath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: StoredPhoto(
                    path: _photoPath!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: _photoAction(
                    icon: Icons.photo_camera_outlined,
                    label: 'Camera',
                    onTap: () => _pickPhoto(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _photoAction(
                    icon: Icons.photo_outlined,
                    label: 'Gallery',
                    onTap: () => _pickPhoto(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            if (widget.note?.photoUrl != null && _photoPath == null) ...[
              const SizedBox(height: 8),
              const Text(
                  'A photo is stored on the server and will download when you are online.',
                  style: TextStyle(color: Color(0xFF69737C), fontSize: 12)),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
          child: SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Save note'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(label,
            style: const TextStyle(
                color: Color(0xFF69737C),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  InputDecoration _fieldDecoration({String? hint, IconData? icon}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  Widget _formSurface({required Widget child}) => Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E5E3)),
        ),
        child: child,
      );

  Widget _photoAction(
          {required IconData icon,
          required String label,
          required VoidCallback onTap}) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF15181C),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFFF5A1F), width: 1.2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 20),
        ),
      );
}
