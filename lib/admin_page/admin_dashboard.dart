import 'package:assemblex/admin_page/admininterface/admin_appbar.dart';
import 'package:assemblex/admin_page/admininterface/admin_bottom_navbar.dart';
import 'package:assemblex/admin_page/manage_product.dart';
import 'package:assemblex/admin_page/overview.dart';
import 'package:assemblex/admin_page/users_list_page.dart';
import 'package:assemblex/admin_page/builds_list_page.dart';
import 'package:assemblex/services/database_service.dart';
import 'package:assemblex/widgets/animated_counter.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sqflite/sqflite.dart';

class adminDashboard extends StatefulWidget {
  const adminDashboard({super.key});

  @override
  State<adminDashboard> createState() => _adminDashboardState();
}

class _adminDashboardState extends State<adminDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _totalusers =0;
  int _totalbuilds = 0;
  final DatabaseService _databaseService = DatabaseService.instance; 

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      print('Loading user count...');
      final users = await _databaseService.getTotalUsers();
      print('User count loaded: $users');
      
      print('Loading build count...');
      final builds = await _databaseService.getTotalBuilds();
      print('Build count loaded: $builds');
      
      if (mounted) {
        print('Updating UI with counts - Users: $users, Builds: $builds');
        setState(() {
          _totalusers = users;
          _totalbuilds = builds;
        });
      } else {
        print('Widget not mounted, skipping UI update');
      }
    } catch (e, stackTrace) {
      print('Error in _loadCounts: $e');
      print('Stack trace: $stackTrace');
    } finally {
      print('Finished loading counts');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: CustomAppBar(leading: false),
      body: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20, left: 8, right: 8, bottom: 8),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Row(
                            children: [
                              Text(
                                'Hey There !! \nAdmin',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[900],
                                  letterSpacing: 0.5,
                                ),
                              
                              ),
                              const SizedBox(width: 20),
                              LottieBuilder.asset(
                                'assets/lottie/admin.json',
                                height: 150,
                                width: 180,
                                fit: BoxFit.fill,
                              )
                            ],
                          ),
                        ),
                        
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: GridView.count(   
                              padding: EdgeInsets.fromLTRB(8, 8, 8, 100), 
                              crossAxisCount: 2,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              children: [
                                _buildAndUserWidget(context, "Total Builds\nAssembled", _totalbuilds.toString(), "26.5%"),
                                _buildAndUserWidget(context, "Total Users", _totalusers.toString(), "12.5%"),
                                _buildTile(context, Icons.computer, "Manage Parts", ManageProduct(), 0, Colors.purple.shade400, const Color.fromARGB(255, 249, 213, 255)),
                                _buildTile(context, Icons.build, "Manage Builds", BuildsListPage(), 1, Colors.blue, const Color.fromARGB(255, 211, 233, 251)),
                                _buildTile(context, Icons.people, "Users", UsersListPage(), 2,Colors.purple.shade400, const Color.fromARGB(255, 249, 213, 255)),
                                _buildTile(context, Icons.settings, "Edit Admin ", EditAdmin(), 3,Colors.blue, const Color.fromARGB(255, 211, 233, 251)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 30,
                child: AdminBottomNavBar(selectedindex: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildTile(BuildContext context, IconData icon, String label, Widget page, int index, Color iconColor, Color backgroundColor){
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: Duration(milliseconds: 400 + (index * 150)),
    curve: Curves.easeOut,
    builder: (context, value, child) {
      return Opacity(
        opacity: value,
        child: Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (){
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => page,
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    )
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow:[BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                    ],
                    borderRadius: BorderRadius.circular(20),
                    
                    
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 48,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                          letterSpacing: 0.3,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildAndUserWidget(BuildContext context, String title, String total, String number) {
  final bool isUserCount = title.toLowerCase().contains('user');
  final icon = isUserCount ? Icons.people_alt_rounded : Icons.computer_rounded;
  final color = isUserCount 
      ? Colors.blue.shade400 
      : Colors.purple.shade400;

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: Colors.grey.shade200,
        width: 1.5,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Title Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Animated Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: AnimatedCounter(
                  value: int.tryParse(total) ?? 0,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.1,
                  ),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                ),
              ),
              // Trend indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      number,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: 0.7,
              minHeight: 3,
              backgroundColor: Colors.grey.shade200,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}