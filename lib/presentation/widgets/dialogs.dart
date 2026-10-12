import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities.dart';

Future<bool> confirmDialog(BuildContext context,
    {required String title, required String message, String action = 'Delete'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
      ],
    ),
  );
  return r ?? false;
}

void showSnack(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
    ));
}

Future<void> showCustomerForm(BuildContext context,
    {Customer? customer, required void Function(Customer) onSave}) {
  return showDialog(context: context, builder: (_) => _CustomerForm(customer: customer, onSave: onSave));
}

class _CustomerForm extends StatefulWidget {
  const _CustomerForm({this.customer, required this.onSave});
  final Customer? customer;
  final void Function(Customer) onSave;
  @override
  State<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<_CustomerForm> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.customer?.name);
  late final _contact = TextEditingController(text: widget.customer?.contactInfo);

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.customer == null ? 'New customer' : 'Edit customer'),
      content: Form(
        key: _key,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contact,
            decoration: const InputDecoration(labelText: 'Contact information', hintText: 'Phone, email…'),
            maxLines: 2,
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (!_key.currentState!.validate()) return;
            widget.onSave(Customer(
              id: widget.customer?.id ?? const Uuid().v4(),
              name: _name.text.trim(),
              contactInfo: _contact.text.trim(),
              updatedAt: DateTime.now().toUtc(),
            ));
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

Future<void> showSiteForm(BuildContext context,
    {required String customerId, Site? site, required void Function(Site) onSave}) {
  return showDialog(context: context, builder: (_) => _SiteForm(customerId: customerId, site: site, onSave: onSave));
}

class _SiteForm extends StatefulWidget {
  const _SiteForm({required this.customerId, this.site, required this.onSave});
  final String customerId;
  final Site? site;
  final void Function(Site) onSave;
  @override
  State<_SiteForm> createState() => _SiteFormState();
}

class _SiteFormState extends State<_SiteForm> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.site?.name);
  late final _address = TextEditingController(text: widget.site?.address);

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.site == null ? 'New site' : 'Edit site'),
      content: Form(
        key: _key,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Site name'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Site name is required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Address'),
            maxLines: 2,
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (!_key.currentState!.validate()) return;
            widget.onSave(Site(
              id: widget.site?.id ?? const Uuid().v4(),
              customerId: widget.customerId,
              name: _name.text.trim(),
              address: _address.text.trim(),
              updatedAt: DateTime.now().toUtc(),
            ));
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
