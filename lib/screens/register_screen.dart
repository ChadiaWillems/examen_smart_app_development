import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/cupertino.dart';
import 'package:medscan/widgets/generic/generic_button.dart';
import 'package:provider/provider.dart';
import 'package:medscan/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (!_validateFields()) return;

    setState(() => _isLoading = true);

    try {
      await Provider.of<AuthProvider>(context, listen: false).signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );

      print("Registratie succesvol!");

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Er is iets misgegaan.";

      if (e.code == 'email-already-in-use')
        errorMsg = "Dit e-mailadres is al in gebruik.";

      if (e.code == 'weak-password') errorMsg = "Het wachtwoord is te zwak.";

      _showError(errorMsg);
    } catch (e) {
      _showError("Fout: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateFields() {
    setState(() {
      _nameError = _nameController.text.isEmpty ? "Naam is verplicht" : null;
      _emailError = !_emailController.text.contains('@')
          ? "Voer een geldig e-mailadres in. Moet een '@' bevatten."
          : null;
      _passwordError = _passwordController.text.length < 6
          ? "Minimaal 6 tekens"
          : null;
      _confirmPasswordError =
          _passwordController.text != _confirmPasswordController.text
          ? "Wachtwoorden komen niet overeen"
          : null;
    });

    return _nameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null;
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Registratie mislukt'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorText(String? error) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Text(
        error,
        style: const TextStyle(
          color: CupertinoColors.destructiveRed,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Account aanmaken'),
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Naam",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: _nameController,
                  placeholder: 'John Doe',
                  padding: const EdgeInsets.all(12),
                  textCapitalization: TextCapitalization.words,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                    border: _nameError != null
                        ? Border.all(color: CupertinoColors.destructiveRed)
                        : null,
                  ),
                ),
                _buildErrorText(_nameError),
                const SizedBox(height: 20),
                const Text(
                  "E-mail",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: _emailController,
                  placeholder: 'johndoe@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                    border: _emailError != null
                        ? Border.all(color: CupertinoColors.destructiveRed)
                        : null,
                  ),
                ),
                _buildErrorText(_emailError),
                const SizedBox(height: 20),
                const Text(
                  "Wachtwoord",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: _passwordController,
                  placeholder: 'Minimaal 6 tekens',
                  obscureText: true,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                    border: _passwordError != null
                        ? Border.all(color: CupertinoColors.destructiveRed)
                        : null,
                  ),
                ),
                _buildErrorText(_passwordError),
                const SizedBox(height: 20),
                const Text(
                  "Bevestig wachtwoord",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: _confirmPasswordController,
                  placeholder: 'Bevestig je wachtwoord',
                  obscureText: true,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                    border: _confirmPasswordError != null
                        ? Border.all(color: CupertinoColors.destructiveRed)
                        : null,
                  ),
                ),
                _buildErrorText(_confirmPasswordError),
                const SizedBox(height: 40),
                Center(
                  child: _isLoading
                      ? const CupertinoActivityIndicator()
                      : GenericButton(
                          label: 'Registreren',
                          onPressed: _handleRegister,
                        ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
