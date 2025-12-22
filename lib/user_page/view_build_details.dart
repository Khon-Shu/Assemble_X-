import 'package:assemblex/user_page/userinterface/appbar.dart';
import 'package:assemblex/user_page/userinterface/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:assemblex/services/save_build.dart';
import 'package:assemblex/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewBuildDetails extends StatefulWidget {
  final int buildId;
  const ViewBuildDetails({super.key, required this.buildId});

  @override
  State<ViewBuildDetails> createState() => _ViewBuildDetailsState();
}

class _ViewBuildDetailsState extends State<ViewBuildDetails> {
  Map<String, dynamic>? _details;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      // Ensure user is logged in and owns the build
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('loggedInUserId');
      if (userId == null) {
        setState(() {
          _error = 'Please log in to view build details.';
          _loading = false;
        });
        return;
      }

      final db = await DatabaseService.instance.database;
      SaveBuild.setDatabase(db);
      final saver = SaveBuild();

      // Verify the build belongs to this user
      final userBuilds = await saver.getUserBuilds(userId);
      final ownsThisBuild = userBuilds.any((b) => (b['id'] as int?) == widget.buildId);
      if (!ownsThisBuild) {
        setState(() {
          _error = 'Build not found for this user.';
          _loading = false;
        });
        return;
      }

      // Load detailed info
      final row = await saver.getUserBuildByIdWithDetails(widget.buildId);
      setState(() {
        _details = row;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load build details';
        _loading = false;
      });
    }
  }

  Widget _item(String title, String? value) {
    final v = value ?? '-';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(v, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: UserAppBar(leading: true,),
      body: 
      Stack(
        children:[ 
          Padding(
          padding: const EdgeInsets.only(top: 25.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white
            ),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_error != null)
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : (_details == null)
                        ? const Center(child: Text('Not found'))
                        : Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ListView(
                              children: [
                                Text(
                                  _details!['build_name']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text('Total Wattage: ${_details!['total_wattage'] ?? '-'}W'),
                                Text('Total Price: Rs.${_details!['total_price'] ?? '-'}'),
                                const Divider(height: 24),
                                _item('CPU', _details!['cpu_name']?.toString()),
                                _item('GPU', _details!['gpu_name']?.toString()),
                                _item('Motherboard', _details!['motherboard_name']?.toString()),
                                _item('RAM', _details!['ram_name']?.toString()),
                                _item('Storage', _details!['storage_name']?.toString()),
                                _item('PSU', _details!['psu_name']?.toString()),
                                _item('Case', _details!['case_name']?.toString()),
                                _item('Cooling', _details!['cooler_name']?.toString()),
                              ],
                            ),
                          ),
          ),
        ),
        BottomNavBar(selectedindex: 1,)
        ]
      ),
    );
  }
}
