// lib/admin_page/builds_list_page.dart
import 'package:assemblex/admin_page/admininterface/admin_bottom_navbar.dart';
import 'package:assemblex/user_page/userinterface/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:assemblex/admin_page/admininterface/admin_appbar.dart';
import 'package:assemblex/services/database_service.dart';
import 'package:assemblex/admin_page/build_details_page.dart';

class BuildsListPage extends StatefulWidget {
  const BuildsListPage({Key? key}) : super(key: key);

  @override
  _BuildsListPageState createState() => _BuildsListPageState();
}

class _BuildsListPageState extends State<BuildsListPage> {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Map<String, dynamic>> _builds = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBuilds();
  }

  Future<void> _loadBuilds() async {
    try {
      final db = await _databaseService.database;
      
      // First, check if the tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND (name='user_build_table' OR name='userinfo')"
      );
      
      if (tables.length < 2) {
        throw Exception('Required tables do not exist');
      }

      final List<Map<String, dynamic>> builds = await db.rawQuery('''
        SELECT 
          b.*, 
          u.firstname as firstname,
          u.lastname as lastname
        FROM user_build_table b
        LEFT JOIN userinfo u 
          ON b.user_id = u.id
        ORDER BY b.id DESC
      ''');
      
      if (mounted) {
        setState(() {
          _builds = builds;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      print('Error loading builds: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading builds: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: CustomAppBar(leading: true),
     body: Padding(
  padding: const EdgeInsets.only(top: 16.0),
  child: Stack(
    children: [

      // ✅ FORCE CONTENT TO FILL FULL SCREEN
      Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadBuilds,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _builds.isEmpty
                      ? const Center(
                          child: Text(
                            'No builds found',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _builds.length,
                          itemBuilder: (context, index) {
                            final build = _builds[index];
                            final userName =
                                '${build['firstname'] ?? 'Unknown'} ${build['lastname'] ?? ''}';
                            final buildName =
                                build['build_name']?.toString() ?? 'Unnamed Build';

                            final totalPrice = build['total_price'] != null
                                ? '${(build['total_price'] as num).toStringAsFixed(2)}'
                                : 'N/A';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BuildDetailsPage(
                                          buildId: build['id']),
                                    ),
                                  );
                                },
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Colors.purple.shade100,
                                    child: const Icon(Icons.computer,
                                        color: Colors.purple),
                                  ),
                                  title: Text(buildName),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('User: $userName'),
                                      Text('Total Price: Rs. $totalPrice'),
                                    ],
                                  ),
                                  trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),

      //  NAVBAR PERMANENTLY FIXED AT BOTTOM
      const Positioned(
        bottom: 30,
        left: 0,
        right: 0,
        child: AdminBottomNavBar(selectedindex: 0),
      ),
    ],
  ),
),

    );
  }
}