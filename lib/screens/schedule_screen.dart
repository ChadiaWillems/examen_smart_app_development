import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:medscan/services/firestore_service.dart';
import 'package:medscan/widgets/schedule/schedule_medicine_card.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  FirestoreService _firestoreService = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  List<DateTime> _generateDisplayDays() {
    DateTime today = DateTime.now();
    return List.generate(7, (index) {
      return today.add(Duration(days: index - 3));
    });
  }

  Widget _buildCalendarHeader() {
    final displayDays = _generateDisplayDays();
    final today = DateTime.now();

    final List<String> dayNames = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za', 'Zo'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        border: Border(bottom: BorderSide(color: CupertinoColors.systemGrey6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: displayDays.map((date) {
          bool isToday =
              date.day == today.day &&
              date.month == today.month &&
              date.year == today.year;

          String dayLabel = dayNames[date.weekday - 1];

          return Expanded(
            child: Column(
              children: [
                Text(
                  dayLabel,
                  style: TextStyle(
                    color: isToday
                        ? CupertinoColors.black
                        : CupertinoColors.systemGrey,
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isToday
                        ? CupertinoColors.activeBlue.withOpacity(0.1)
                        : CupertinoColors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isToday
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.black,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isToday)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: CupertinoColors.activeBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, String name) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Medicijn verwijderen"),
        content: Text(
          "Weet je zeker dat je $name uit je schema wilt verwijderen?",
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Annuleer"),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("Verwijder"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection(
    String moment,
    String timeLabel,
    IconData icon,
    bool isLastSection,
  ) {
    final double timeWidth = MediaQuery.of(context).size.width * 0.15;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firestoreService.getScheduleMoment(uid, moment),
      builder: (context, snapshot) {
        List items = [];
        if (snapshot.hasData && snapshot.data!.exists) {
          items = snapshot.data!.data()?['items'] ?? [];
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: timeWidth,
                child: Column(
                  children: [
                    Icon(icon, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    Expanded(
                      child: Container(
                        width: 1,
                        color: (isLastSection && items.isEmpty)
                            ? CupertinoColors.transparent
                            : CupertinoColors.systemGrey4,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: items.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment
                                .start,
                            children: [
                              Icon(
                                CupertinoIcons.info,
                                size: 16,
                                color: CupertinoColors.systemGrey2,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  "Nog geen medicijnen gepland voor dit moment.",
                                  style: TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: items.asMap().entries.map((entry) {
                            int index = entry.key;
                            var data = entry.value;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Dismissible(
                                key: Key('${data['name']}_$index'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.destructiveRed,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.trash,
                                    color: CupertinoColors.white,
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  return await _showDeleteConfirmation(
                                    context,
                                    data['name'] ?? 'dit medicijn',
                                  );
                                },
                                onDismissed: (direction) {
                                  _firestoreService.removeMedicineFromSchedule(
                                    uid,
                                    moment,
                                    index,
                                    items,
                                  );
                                },
                                child: ScheduleMedicineCard(
                                  medicineName: data['name'] ?? 'Onbekend',
                                  dosage: data['strength'] ?? '',
                                  isTaken: data['isTaken'] ?? false,
                                  onToggleTaken: () =>
                                      _firestoreService.toggleDoseInArray(
                                        uid,
                                        moment,
                                        index,
                                        items,
                                      ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      child: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _firestoreService.getNotificationSettingsStream(uid),
          builder: (context, settingsSnapshot) {
            String mTime = "08:00";
            String aTime = "13:00";
            String eTime = "19:00";

            if (settingsSnapshot.hasData && settingsSnapshot.data!.exists) {
              final data = settingsSnapshot.data!.data();
              mTime = data?['morningTime'] ?? "08:00";
              aTime = data?['afternoonTime'] ?? "13:00";
              eTime = data?['eveningTime'] ?? "19:00";
            }

            return ListView(
              children: [
                _buildCalendarHeader(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildScheduleSection(
                        'morning',
                        mTime,
                        CupertinoIcons.sun_max,
                        false,
                      ),
                      _buildScheduleSection(
                        'afternoon',
                        aTime,
                        CupertinoIcons.cloud,
                        false,
                      ),
                      _buildScheduleSection(
                        'evening',
                        eTime,
                        CupertinoIcons.moon,
                        true,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
