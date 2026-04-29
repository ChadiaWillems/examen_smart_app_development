import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/cupertino.dart';
import 'package:medscan/screens/login_screen.dart';
import 'package:medscan/services/firestore_service.dart';
import 'package:medscan/widgets/settings/settings_acount_tile.dart';
import 'package:medscan/widgets/settings/settings_switch_tile.dart';
import 'package:medscan/widgets/settings/settings_time_tile.dart';
import 'package:medscan/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:medscan/providers/auth_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  bool _remindersEnabled = false;
  bool _soundsEnabled = true;

  String _morningTime = "08:00";
  String _afternoonTime = "13:00";
  String _eveningTime = "19:00";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapServices();
    });
  }

  Future<void> _bootstrapServices() async {
    try {
      await _notificationService.init();
      await _loadSettings();
    } catch (e) {
      print("Er ging iets mis bij het opstarten: $e");
    }
  }

  Future<void> _syncNotifications() async {
    if (!_remindersEnabled) {
      await _notificationService.cancelAll();
      return;
    }

    await _notificationService.cancelAll();

    await _notificationService.scheduleDailyNotification(
      id: 1,
      title: "Morgen dosis",
      body: "Tijd voor je ochtend medicijnen!",
      timeStr: _morningTime,
    );
    await _notificationService.scheduleDailyNotification(
      id: 2,
      title: "Middag dosis",
      body: "Tijd voor je middag medicijnen!",
      timeStr: _afternoonTime,
    );
    await _notificationService.scheduleDailyNotification(
      id: 3,
      title: "Avond dosis",
      body: "Tijd voor je avond medicijnen!",
      timeStr: _eveningTime,
    );
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot = await _firestoreService.getNotificationSettings(user.uid);
    if (snapshot.exists) {
      final data = snapshot.data();
      setState(() {
        _remindersEnabled = data?['remindersEnabled'] ?? false;
        _soundsEnabled = data?['soundsEnabled'] ?? true;
        _morningTime = data?['morningTime'] ?? "08:00";
        _afternoonTime = data?['afternoonTime'] ?? "13:00";
        _eveningTime = data?['eveningTime'] ?? "19:00";
      });
      _syncNotifications();
    }
  }

  DateTime _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return DateTime.now().copyWith(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
        second: 0,
        millisecond: 0,
      );
    } catch (e) {
      return DateTime.now().copyWith(hour: 8, minute: 0);
    }
  }

  void _showEditProfileDialog(String currentName, String currentUid) {
    final TextEditingController nameController = TextEditingController(
      text: currentName == 'Laden...' ? "" : currentName,
    );

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Profiel bewerken"),
        content: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CupertinoTextField(
            controller: nameController,
            placeholder: "Je naam",
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Annuleer"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Opslaan"),
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                await _firestoreService.updateUserProfile(currentUid, {
                  'name': nameController.text.trim(),
                });
                setState(() {});
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(AuthProvider auth) {
    if (!auth.isLoggedIn) {
      return SettingsAcountTile(
        name: 'Gast',
        email: 'Tik om in te loggen',
        onTap: () {
          Navigator.of(
            context,
          ).push(CupertinoPageRoute(builder: (context) => const LoginScreen()));
        },
      );
    }

    return SettingsAcountTile(
      name: auth.userName,
      email: auth.user?.email ?? 'Geen e-mail',
      onTap: () => _showEditProfileDialog(auth.userName, auth.user!.uid),
    );
  }

  Future<void> _deleteUserAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _notificationService.cancelAll();

      await _firestoreService.deleteUserProfile(user.uid);

      await user.delete();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showErrorAlert(
          "Beveiligingsregel: Je moet opnieuw inloggen voordat je je account kunt verwijderen.",
        );
      } else {
        _showErrorAlert("Er ging iets mis: ${e.message}");
      }
    } catch (e) {
      _showErrorAlert("Fout: $e");
    }
  }

  void _showErrorAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Fout"),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Account verwijderen?"),
        content: const Text(
          "Weet je het zeker? Al je medicatie-instellingen en herinneringen worden definitief gewist. Dit kan niet ongedaan worden gemaakt.",
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Annuleer"),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("Verwijder account"),
            onPressed: () async {
              await _deleteUserAccount();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Notificaties',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // --- Switch: Herinneringen ---
          SettingsSwitchTile(
            title: "Herinneringen",
            subtitle: "Krijg herinneringen voor medicijnen",
            icon: CupertinoIcons.bell_fill,
            iconColor: CupertinoColors.systemBlue,
            value: _remindersEnabled,
            onChanged: (bool newValue) async {
              if (auth.user == null) return;
              setState(() => _remindersEnabled = newValue);
              await _firestoreService.updateNotificationSettings(
                auth.user!.uid,
                {'remindersEnabled': newValue},
              );
              await _syncNotifications();
            },
          ),

          // --- Switch: Geluid ---
          SettingsSwitchTile(
            title: "Geluid",
            subtitle: "Geluid bij herinneringen",
            icon: CupertinoIcons.speaker_2_fill,
            iconColor: CupertinoColors.systemBlue,
            value: _soundsEnabled,
            onChanged: (bool newValue) async {
              if (auth.user == null) return;

              setState(() => _soundsEnabled = newValue);
              await _firestoreService.updateNotificationSettings(
                auth.user!.uid,
                {'soundsEnabled': newValue},
              );
              await _syncNotifications();
            },
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Herinnerings tijden',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // --- Tijd: Ochtend ---
          SettingsTimeTile(
            title: 'Ochtend dosis',
            icon: CupertinoIcons.sun_dust_fill,
            iconColor: CupertinoColors.systemOrange,
            time: _parseTimeString(_morningTime),
            onTimeChanged: (DateTime newTime) async {
              final currentUid = FirebaseAuth.instance.currentUser?.uid;
              if (currentUid == null) return;
              String formatted =
                  "${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}";
              setState(() => _morningTime = formatted);
              await _firestoreService.updateNotificationSettings(currentUid, {
                'morningTime': formatted,
              });
              await _syncNotifications();
            },
          ),

          // --- Tijd: Middag ---
          SettingsTimeTile(
            title: 'Middag dosis',
            icon: CupertinoIcons.sun_max_fill,
            iconColor: CupertinoColors.systemYellow,
            time: _parseTimeString(_afternoonTime),
            onTimeChanged: (DateTime newTime) async {
              final currentUid = FirebaseAuth.instance.currentUser?.uid;
              if (currentUid == null) return;

              String formatted =
                  "${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}";
              setState(() => _afternoonTime = formatted);
              await _firestoreService.updateNotificationSettings(currentUid, {
                'afternoonTime': formatted,
              });
              await _syncNotifications();
            },
          ),

          // --- Tijd: Avond ---
          SettingsTimeTile(
            title: 'Avond dosis',
            icon: CupertinoIcons.moon_stars_fill,
            iconColor: CupertinoColors.systemIndigo,
            time: _parseTimeString(_eveningTime),
            onTimeChanged: (DateTime newTime) async {
              final currentUid = FirebaseAuth.instance.currentUser?.uid;
              if (currentUid == null) return;

              String formatted =
                  "${newTime.hour.toString().padLeft(2, '0')}:${newTime.minute.toString().padLeft(2, '0')}";
              setState(() => _eveningTime = formatted);
              await _firestoreService.updateNotificationSettings(currentUid, {
                'eveningTime': formatted,
              });
              await _syncNotifications();
            },
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Account instellingen',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          _buildAccountTile(auth),

          if (auth.isLoggedIn)
            CupertinoListSection.insetGrouped(
              children: [
                CupertinoListTile(
                  title: const Text(
                    'Uitloggen',
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                  leading: const Icon(
                    CupertinoIcons.square_arrow_right,
                    color: CupertinoColors.destructiveRed,
                  ),
                  onTap: () async {
                    await auth.signOut();
                    if (mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                ),
                CupertinoListTile(
                  title: const Text(
                    'Account verwijderen',
                    style: TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                  leading: const Icon(
                    CupertinoIcons.trash,
                    color: CupertinoColors.destructiveRed,
                  ),
                  onTap: () => _showDeleteAccountDialog(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
