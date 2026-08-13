import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/cubits/auth/auth_cubit.dart';
import '../../core/constants/app_colors.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final code = TextEditingController();
  final password = TextEditingController();
  final confirmation = TextEditingController();
  bool codeSent = false, loading = false, visible = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Récupération du compte')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              children: [
                Icon(
                  codeSent ? Icons.mark_email_read_outlined : Icons.lock_reset,
                  color: Colors.white,
                  size: 54,
                ),
                const SizedBox(height: 10),
                Text(
                  codeSent
                      ? 'Consulte ton adresse email'
                      : 'Mot de passe oublié ?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  codeSent
                      ? 'Le code reçu reste valable pendant 15 minutes.'
                      : 'Nous allons t’envoyer un code de récupération sécurisé.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Form(
            key: form,
            child: Column(
              children: [
                TextFormField(
                  controller: email,
                  enabled: !codeSent,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Adresse email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) => (value ?? '').contains('@')
                      ? null
                      : 'Saisis une adresse email valide.',
                ),
                if (codeSent) ...[
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: code,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Code à 6 chiffres',
                      prefixIcon: Icon(Icons.pin_outlined),
                      counterText: '',
                    ),
                    validator: (value) => (value ?? '').length == 6
                        ? null
                        : 'Le code doit contenir 6 chiffres.',
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: password,
                    obscureText: !visible,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => visible = !visible),
                        icon: Icon(
                          visible ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                    validator: (value) => (value ?? '').length >= 6
                        ? null
                        : 'Au moins 6 caractères sont nécessaires.',
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: confirmation,
                    obscureText: !visible,
                    decoration: const InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) => value == password.text
                        ? null
                        : 'Les mots de passe ne correspondent pas.',
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: loading ? null : _submit,
                    icon: loading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            codeSent
                                ? Icons.check_circle_outline
                                : Icons.send_outlined,
                          ),
                    label: Text(
                      codeSent
                          ? 'Réinitialiser le mot de passe'
                          : 'Envoyer le code',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    if (!form.currentState!.validate()) return;
    setState(() => loading = true);
    final repository = context.read<AuthCubit>().authRepository;
    try {
      final message = codeSent
          ? await repository.resetPassword(
              email.text.trim(),
              code.text.trim(),
              password.text,
            )
          : await repository.forgotPassword(email.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.notification,
        ),
      );
      if (codeSent) {
        Navigator.pop(context);
      } else {
        setState(() => codeSent = true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    code.dispose();
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }
}
