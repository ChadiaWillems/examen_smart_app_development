import 'package:flutter/cupertino.dart';
import 'package:medscan/providers/auth_provider.dart';
import 'package:medscan/screens/scanner_screen.dart';
import 'package:medscan/widgets/generic/generic_header.dart';
import 'package:medscan/widgets/generic/generic_welcome_header.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double buttonSize = screenWidth * 0.55;
    final double iconSize = buttonSize * 0.33;
    final double fontSize = buttonSize * 0.085;

    return CupertinoPageScaffold(
      navigationBar: const GenericHeader(),
      child: SafeArea(
        child: Column(
          children: [
            GenericWelcomeHeader(userName: auth.userName),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const ScannerScreen(),
                          ),
                        );
                      },
                      child: Semantics(
                        label: 'Scan medicijn',
                        button: true,
                        hint: 'Dubbeltik om de medicijnscanner te openen',
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Hero(
                            tag: 'scanner-hero',
                            child: Container(
                              width: buttonSize,
                              height: buttonSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1B5AEE),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF1B5AEE,
                                    ).withOpacity(0.4),
                                    blurRadius: 30,
                                    offset: Offset(0, buttonSize * 0.15),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.camera_fill,
                                    size: iconSize,
                                    color: CupertinoColors.white,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'Scan medicijn',
                                    style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration
                                          .none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.05,
                    ),
                    Container(
                      child: const Text(
                        'Tap om te scannen',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
