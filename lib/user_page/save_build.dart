import 'package:assemblex/user_page/View%20saved%20Class/SavedBuildContext.dart';
import 'package:assemblex/user_page/userinterface/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:assemblex/services/database_service.dart';
import 'package:assemblex/services/save_build.dart';
import 'package:assemblex/user_page/view_build_details.dart';

class ViewSaveBuild extends StatefulWidget {
  const ViewSaveBuild({super.key});

  @override
  State<ViewSaveBuild> createState() => _ViewSaveBuildState();
}

class _ViewSaveBuildState extends State<ViewSaveBuild> {
  List<Map<String, dynamic>> _builds = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBuilds();
  }

  Future<void> _loadBuilds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('loggedInUserId');

      // Migration: fallback from legacy email key
      if (userId == null) {
        final legacyEmail = prefs.getString('loggedInUser');
        if (legacyEmail != null) {
          final dbService = DatabaseService.instance;
          final user = await dbService.getUserByEmail(legacyEmail);
          if (user != null) {
            userId = user['id'] as int;
            await prefs.setInt('loggedInUserId', userId);
            await prefs.remove('loggedInUser');
          }
        }
      }

      if (userId == null) {
        setState(() {
          _error = 'Please log in to view saved builds.';
          _loading = false;
        });
        return;
      }
      
      final dbService = DatabaseService.instance;
      final db = await dbService.database;
      SaveBuild.setDatabase(db);
      final saver = SaveBuild();
      final builds = await saver.getUserBuilds(userId);

      setState(() {
        _builds = builds;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load saved builds';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Your Saved Build', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : (_error != null)
                            ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                            : (_builds.isEmpty)
                                ? const Center(child: Text('No saved builds'))
                                : ListView.builder(
                                    itemCount: _builds.length,
                                    itemBuilder: (context, index) {
                                      final row = _builds[index];
                                      final name = (row['build_name'] ?? '').toString();
                                      final price = (row['total_price'] ?? 0).toString();
                                      final image = (row['imageURL'] ?? '').toString();
                                      final buildId = row['id'] as int?;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: ViewSavedBuildContext(
                                          build_name: name,
                                          price: price,
                                          imageUrl: image,
                                          onView: (buildId == null)
                                              ? null
                                              : () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => ViewBuildDetails(buildId: buildId),
                                                    ),
                                                  );
                                                },
                                        ),
                                      );
                                    },
                                  ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}