import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/cubits/auth/auth_cubit.dart';
import '../../business_logic/cubits/auth/auth_event.dart';
import '../../core/constants/app_colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final name = TextEditingController();
  final username = TextEditingController();
  final email = TextEditingController();
  final currentPassword = TextEditingController();
  final newPassword = TextEditingController();
  bool initialized = false;
  bool savingPassword = false;
  bool currentVisible = false;
  bool newVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.read<AuthCubit>().state;
    if (!initialized && state is AuthSuccess) {
      name.text = state.user.name;
      username.text = state.user.username;
      email.text = state.user.email;
      initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mon profil')),
    body: BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil actualisé'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      builder: (context, state) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: AppColors.secondary,
            child: Icon(Icons.person, size: 44, color: Colors.white),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'Nom complet',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: username,
            decoration: const InputDecoration(
              labelText: 'Nom d’utilisateur',
              prefixIcon: Icon(Icons.alternate_email),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: state is AuthLoading
                ? null
                : () => context.read<AuthCubit>().updateProfile(
                    name.text.trim(),
                    username.text.trim(),
                    email.text.trim(),
                  ),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Enregistrer mes identifiants'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(),
          ),
          Text('Sécurité', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: currentPassword,
            obscureText: !currentVisible,
            decoration: InputDecoration(
              labelText: 'Mot de passe actuel',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: currentVisible ? 'Masquer' : 'Afficher',
                onPressed: () =>
                    setState(() => currentVisible = !currentVisible),
                icon: Icon(
                  currentVisible ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newPassword,
            obscureText: !newVisible,
            decoration: InputDecoration(
              labelText: 'Nouveau mot de passe',
              helperText: 'Au moins 6 caractères.',
              prefixIcon: const Icon(Icons.password),
              suffixIcon: IconButton(
                tooltip: newVisible ? 'Masquer' : 'Afficher',
                onPressed: () => setState(() => newVisible = !newVisible),
                icon: Icon(
                  newVisible ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: savingPassword
                ? null
                : () async {
                    setState(() => savingPassword = true);
                    if (currentPassword.text.isEmpty) {
                      setState(() => savingPassword = false);
                      _snack('Saisis ton mot de passe actuel.', false);
                      return;
                    }
                    if (newPassword.text.length < 6) {
                      setState(() => savingPassword = false);
                      _snack(
                        'Le nouveau mot de passe doit contenir au moins 6 caractères.',
                        false,
                      );
                      return;
                    }
                    final error = await context
                        .read<AuthCubit>()
                        .updatePassword(currentPassword.text, newPassword.text);
                    if (!context.mounted) return;
                    setState(() => savingPassword = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error ?? 'Mot de passe modifié'),
                        backgroundColor: error == null
                            ? AppColors.notification
                            : AppColors.danger,
                      ),
                    );
                    if (error == null) {
                      currentPassword.clear();
                      newPassword.clear();
                    }
                  },
            icon: const Icon(Icons.security),
            label: const Text('Modifier le mot de passe'),
          ),
        ],
      ),
    ),
  );

  void _snack(String text, bool success) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: success ? AppColors.notification : AppColors.danger,
        ),
      );

  @override
  void dispose() {
    name.dispose();
    username.dispose();
    email.dispose();
    currentPassword.dispose();
    newPassword.dispose();
    super.dispose();
  }
}
