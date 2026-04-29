import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/cupertino.dart';
import 'package:medscan/screens/home_screen.dart';
import 'package:medscan/screens/login_screen.dart';
import 'package:medscan/screens/schedule_screen.dart';
import 'package:medscan/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:medscan/providers/auth_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class GenericBottomNav extends StatefulWidget {
  const GenericBottomNav({super.key});

  static CupertinoTabController controller = CupertinoTabController(
    initialIndex: 0,
  );

  @override
  State<GenericBottomNav> createState() => _GenericBottomNavState();
}

class _GenericBottomNavState extends State<GenericBottomNav> {
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      setState(() {
        _isOffline = results.contains(ConnectivityResult.none);
      });
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (auth.isLoading) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final user = auth.user;

    return Stack(
      children: [
        CupertinoTabScaffold(
          controller: GenericBottomNav.controller,
          tabBar: CupertinoTabBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.clock),
                label: 'Schedule',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.settings),
                label: 'Settings',
              ),
            ],
          ),
          tabBuilder: (context, index) {
            return CupertinoTabView(
              builder: (context) {
                switch (index) {
                  case 0:
                    return const HomeScreen();
                  case 1:
                    return user == null
                        ? const LoginScreen()
                        : const ScheduleScreen();
                  case 2:
                    return const SettingsScreen();
                  default:
                    return const HomeScreen();
                }
              },
            );
          },
        ),

        // --- OFFLINE INDICATOR ---
        if (_isOffline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                color: CupertinoColors.systemOrange.withOpacity(0.9),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.wifi_slash,
                      size: 14,
                      color: CupertinoColors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Offline modus - Wijzigingen worden later gesynchroniseerd',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
