import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:medscan/screens/login_screen.dart';
import 'package:medscan/services/firestore_service.dart';
import 'package:medscan/widgets/generic/generic_bottom_nav.dart';
import 'package:medscan/widgets/medicine/medicine_dosing_schedule_card.dart';
import 'package:medscan/widgets/medicine/medicine_header.dart';
import 'package:medscan/widgets/medicine/medicine_warnings.dart';

class MedicineScreen extends StatefulWidget {
  final String medicineName;

  const MedicineScreen({super.key, required this.medicineName});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  String _buttonStatus = 'idle';

  Future<void> _handleSaveToSchedule(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    setState(() => _buttonStatus = 'loading');

    try {
      await FirestoreService().addMedicineToUserSchedule(
        medicineName: widget.medicineName,
        medicineData: data,
      );

      setState(() => _buttonStatus = 'success');
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        GenericBottomNav.controller.index = 1;
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      setState(() => _buttonStatus = 'idle');
      if (mounted) {
        _showErrorAlert(context);
      }
    }
  }

  void _showLoginRequiredPopup(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Inloggen vereist'),
        content: const Text(
          'Je moet ingelogd zijn om medicijnen aan je persoonlijke schema toe te voegen.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annuleren'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Inloggen'),
            onPressed: () async {
              Navigator.pop(context);
              await Navigator.of(context).push(
                CupertinoPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showErrorAlert(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Fout'),
        content: const Text(
          'Kon het medicijn niet opslaan. Controleer je verbinding of probeer het later opnieuw.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonContent() {
    if (_buttonStatus == 'idle') {
      return const Text(
        'Opslaan in schema',
        style: TextStyle(
          color: CupertinoColors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (_buttonStatus == 'loading') {
      return const CupertinoActivityIndicator(color: CupertinoColors.white);
    } else {
      return const Icon(
        CupertinoIcons.check_mark,
        color: CupertinoColors.white,
        size: 30,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Resultaat')),
      child: Stack(
        children: [
          SafeArea(
            child: DefaultTextStyle(
              style: CupertinoTheme.of(context).textTheme.textStyle,
              child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: firestoreService.getMedicineById(widget.medicineName),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('Niet gevonden.'));
                  }

                  final data = snapshot.data!.data()!;
                  final List warnings = data['warnings'] ?? [];

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 200),
                    children: [
                      MedicineHeader(
                        medicineName: widget.medicineName,
                        strength: data['strength'] ?? '',
                        category: data['category'] ?? '',
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Doseringsschema",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: MedicineDosingScheduleCard(
                              label: "Ochtend",
                              amount: data['morning'] ?? 0,
                              icon: CupertinoIcons.sun_max,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MedicineDosingScheduleCard(
                              label: "Middag",
                              amount: data['afternoon'] ?? 0,
                              icon: CupertinoIcons.sun_haze,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MedicineDosingScheduleCard(
                              label: "Avond",
                              amount: data['evening'] ?? 0,
                              icon: CupertinoIcons.moon,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      MedicineWarnings(warnings: List<String>.from(warnings)),
                    ],
                  );
                },
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                border: const Border(
                  top: BorderSide(
                    color: CupertinoColors.systemGrey5,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StreamBuilder<User?>(
                      stream: FirebaseAuth.instance.authStateChanges(),
                      builder: (context, snapshot) {
                        final bool isLoggedIn = snapshot.hasData;
                        return GestureDetector(
                          onTap: _buttonStatus != 'idle'
                              ? null
                              : () async {
                                  if (!isLoggedIn) {
                                    _showLoginRequiredPopup(context);
                                  } else {
                                    final medicineDoc = await FirestoreService()
                                        .getMedicineById(widget.medicineName);
                                    if (medicineDoc.exists && context.mounted) {
                                      _handleSaveToSchedule(
                                        context,
                                        medicineDoc.data()!,
                                      );
                                    }
                                  }
                                },
                          child: Semantics(
                            label: _buttonStatus == 'idle'
                                ? 'Opslaan in schema'
                                : 'Bezig met opslaan',
                            button: true,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              // Breedte past zich aan op basis van status
                              width: _buttonStatus == 'idle'
                                  ? MediaQuery.of(context).size.width - 32
                                  : 60,
                              height: 55,
                              decoration: BoxDecoration(
                                color: _buttonStatus == 'success'
                                    ? CupertinoColors.activeGreen
                                    : const Color(0xFF1B5AEE),
                                borderRadius: BorderRadius.circular(
                                  _buttonStatus == 'idle' ? 12 : 30,
                                ),
                              ),
                              child: Center(child: _buildButtonContent()),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text(
                        'Annuleren',
                        style: TextStyle(
                          color: CupertinoColors.destructiveRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
