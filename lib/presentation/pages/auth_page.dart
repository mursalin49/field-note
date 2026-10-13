import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth_bloc.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _register = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    final bloc = context.read<AuthBloc>();
    _register
        ? bloc
            .add(AuthRegisterRequested(_name.text, _email.text, _password.text))
        : bloc.add(AuthLoginRequested(_email.text, _password.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_register) _registerHeader() else _loginHero(),
                    Transform.translate(
                      offset: _register ? Offset.zero : const Offset(0, -48),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: _register
                              ? BorderRadius.zero
                              : const BorderRadius.vertical(
                                  top: Radius.circular(32)),
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                        child: Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _register ? 'Create account' : 'Welcome back',
                                style: const TextStyle(
                                  color: Color(0xFF15181C),
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _register
                                    ? 'Set up once while online. After that you can work anywhere, even without signal.'
                                    : 'Log in to restore your customers, sites and notes.',
                                style: const TextStyle(
                                    color: Color(0xFF69737C), fontSize: 13),
                              ),
                              const SizedBox(height: 24),
                              if (_register) ...[
                                _fieldLabel('Full name'),
                                TextFormField(
                                  controller: _name,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: _fieldDecoration(
                                    hint: 'Your name',
                                    icon: Icons.person_outline,
                                  ),
                                  validator: (value) =>
                                      (value == null || value.trim().isEmpty)
                                          ? 'Name is required'
                                          : null,
                                ),
                                const SizedBox(height: 14),
                              ],
                              _fieldLabel(_register ? 'Work email' : 'Email'),
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                enableSuggestions: false,
                                textCapitalization: TextCapitalization.none,
                                decoration: _fieldDecoration(
                                  hint: 'name@company.com',
                                  icon: Icons.mail_outline,
                                ),
                                validator: (value) => (value == null ||
                                        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                            .hasMatch(value.trim()))
                                    ? 'Enter a valid email'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              _fieldLabel('Password'),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                decoration: _fieldDecoration(
                                  hint: 'Enter your password',
                                  icon: Icons.lock_outline,
                                  suffix: IconButton(
                                    icon: Icon(_obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (value) =>
                                    (value == null || value.length < 6)
                                        ? 'At least 6 characters'
                                        : null,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              if (_register) ...[
                                const SizedBox(height: 14),
                                _fieldLabel('Confirm password'),
                                TextFormField(
                                  controller: _confirmPassword,
                                  obscureText: _obscure,
                                  decoration: _fieldDecoration(
                                    hint: 'Repeat password',
                                    icon: Icons.lock_outline,
                                  ),
                                  validator: (value) => value != _password.text
                                      ? 'Passwords do not match'
                                      : null,
                                ),
                              ],
                              if (state.error != null) ...[
                                const SizedBox(height: 12),
                                Text(state.error!,
                                    style: const TextStyle(
                                        color: Color(0xFFC9301C)),
                                    textAlign: TextAlign.center),
                              ],
                              SizedBox(height: _register ? 24 : 22),
                              SizedBox(
                                height: 56,
                                child: FilledButton(
                                  onPressed: state.busy ? null : _submit,
                                  child: state.busy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : Text(_register
                                          ? 'Create account'
                                          : 'Log in'),
                                ),
                              ),
                              if (_register) ...[
                                const SizedBox(height: 14),
                                _offlineNotice(register: true),
                              ],
                              const SizedBox(height: 10),
                              Center(
                                child: TextButton(
                                  onPressed: state.busy
                                      ? null
                                      : () => setState(() {
                                            _register = !_register;
                                            _confirmPassword.clear();
                                          }),
                                  style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFFD9430D)),
                                  child: Text(_register
                                      ? 'Already registered? Log in'
                                      : 'New here? Create an account'),
                                ),
                              ),
                              if (!_register) ...[
                                const SizedBox(height: 14),
                                Center(child: _offlineNotice()),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginHero() => Container(
        height: 360,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF15181C), Color(0xFF262C33)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Positioned.fill(child: _TopographicContours()),
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 72, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BrandMark(),
                    SizedBox(height: 24),
                    Text('Field Notes',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7)),
                    SizedBox(height: 8),
                    Text('Record every site visit,\nonline or offline.',
                        style: TextStyle(
                            color: Color(0xFFB9C0C7),
                            fontSize: 15,
                            height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _registerHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => setState(() => _register = false),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE2E5E3)),
              ),
              icon: const Icon(Icons.arrow_back, size: 20),
            ),
            const SizedBox(height: 18),
            const Text('Create account',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF15181C))),
          ],
        ),
      );

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(text,
            style: const TextStyle(
                color: Color(0xFF69737C),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );

  InputDecoration _fieldDecoration(
          {required String hint, required IconData icon, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffix,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      );

  Widget _offlineNotice({bool register = false}) {
    if (!register) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFECEEEC),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sync, size: 17, color: Color(0xFF15181C)),
            SizedBox(width: 8),
            Text('Works offline, syncs later',
                style: TextStyle(
                    color: Color(0xFF15181C),
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDE4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wifi_off_outlined, color: Color(0xFFD9430D), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Internet needed for this step only.',
                    style: TextStyle(
                        color: Color(0xFF15181C),
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                SizedBox(height: 3),
                Text('Your data stays safe on this device afterwards.',
                    style: TextStyle(color: Color(0xFF69737C), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFFF5A1F),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.description_outlined,
            color: Colors.white, size: 28),
      );
}

class _TopographicContours extends StatelessWidget {
  const _TopographicContours();

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _TopographicContourPainter());
}

class _TopographicContourPainter extends CustomPainter {
  const _TopographicContourPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.82, size.height * 0.06);
    const contourCount = 13;

    for (var contour = 0; contour < contourCount; contour++) {
      final radius = 42.0 + contour * 20.5;
      final isAccent = contour == 6;
      final path = Path();

      for (var step = 0; step <= 180; step++) {
        final angle = step / 180 * math.pi * 2;
        final wobble = math.sin(angle * 3 + contour * 0.32) * 4.5 +
            math.cos(angle * 5 - contour * 0.21) * 2.5 +
            math.sin(angle * 7 + 0.8) * 1.2;
        final currentRadius = radius + wobble;
        final point = Offset(
          center.dx + math.cos(angle) * currentRadius,
          center.dy + math.sin(angle) * currentRadius * 0.78,
        );

        if (step == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isAccent ? 1.5 : 1
        ..color = isAccent
            ? const Color(0xFFFF5A1F).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.09);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TopographicContourPainter oldDelegate) => false;
}
