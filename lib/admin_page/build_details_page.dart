import 'dart:io';
import 'package:assemblex/admin_page/admininterface/admin_bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:assemblex/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:assemblex/user_page/userinterface/bottom_nav_bar.dart';

class BuildDetailsPage extends StatefulWidget {
  final int buildId;

  const BuildDetailsPage({Key? key, required this.buildId}) : super(key: key);

  @override
  _BuildDetailsPageState createState() => _BuildDetailsPageState();
}

class _BuildDetailsPageState extends State<BuildDetailsPage> {
  final DatabaseService _databaseService = DatabaseService.instance;
  Map<String, dynamic>? _build;
  final Map<String, Map<String, dynamic>> _components = {};
  bool _isLoading = true;
  String? _errorMessage;
  int _totalTDP = 0;

  @override
  void initState() {
    super.initState();
    _loadBuildDetails();
  }

  Future<void> _loadBuildDetails() async {
    try {
      final db = await _databaseService.database;

      final builds = await db.query(
        'user_build_table',
        where: 'id = ?',
        whereArgs: [widget.buildId],
      );

      if (builds.isEmpty) {
        throw Exception('Build not found');
      }

      _build = builds.first;
      _components.clear();

      // Helper function to fetch component details
      Future<void> fetchComponent(String table, String idKey) async {
        if (_build?[idKey] != null) {
          final result = await db.query(
            table,
            where: 'id = ?',
            whereArgs: [_build![idKey]],
          );
          if (result.isNotEmpty) {
            _components[table] = result.first;
          }
        }
      }

      await Future.wait([
        fetchComponent('CPUtable', 'cpu_id'),
        fetchComponent('GPUtable', 'gpu_id'),
        fetchComponent('motherboardtable', 'motherboard_id'),
        fetchComponent('RAMtable', 'ram_id'),
        fetchComponent('storagetable', 'storage_id'),
        fetchComponent('PSUtable', 'psu_id'),
        fetchComponent('casetable', 'case_id'),
        fetchComponent('coolingtable', 'cooler_id'),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading build details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading build details';
        });
      }
    }
  }

  Widget _buildComponentList() {
    final List<Widget> widgets = [];
    int totalPrice = 0;
    _totalTDP = 0; // Reset TDP counter
    final formatter = NumberFormat('#,##0');

    _components.forEach((key, component) {
      // Calculate total price
      if (component['price'] != null) {
        if (component['price'] is int || component['price'] is double) {
          totalPrice += (component['price'] as num).toInt();
        } else {
          try {
            totalPrice += int.tryParse(component['price'].toString()) ?? 0;
          } catch (e) {
            print('Error parsing price: $e');
          }
        }
      }

      // Calculate estimated power consumption
      if (component['tdp'] != null) {
        if (component['tdp'] is int || component['tdp'] is double) {
          _totalTDP += (component['tdp'] as num).toInt();
        } else {
          try {
            _totalTDP += int.tryParse(component['tdp'].toString()) ?? 0;
          } catch (e) {
            print('Error parsing TDP: $e');
          }
        }
      }
    });

    // Build Summary Card
    widgets.add(
      Card(
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Theme.of(context).primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.computer,
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'BUILD SUMMARY',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ],
              ),
              const Divider(height: 30, thickness: 1),

              // Build Info Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Build #${_build?['id'] ?? 'N/A'}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (_build?['build_name'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            _build!['build_name'],
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Cost',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rs. ${formatter.format(totalPrice)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              children: [
                _buildStatCard(
                  context,
                  icon: Icons.electrical_services,
                  title: 'Estimated Power',
                  value: '${_totalTDP}W',
                  color: Colors.orange,
                ),
                if (_build?['total_wattage'] != null)
                  _buildStatCard(
                    context,
                    icon: Icons.battery_charging_full,
                    title: 'PSU Capacity',
                    value: '${_build!['total_wattage']}W',
                    color: Colors.green,
                  ),
              ],
            ),
              
          ],
        ),
      ),
    ),
  );
  

    // Add compatibility check section
    widgets.add(
      Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green[700],
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Compatibility Check',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCompatibilityCheck(context),
            ],
          ),
        ),
      ),
    );

    // Define component order
    const componentOrder = [
      'CPUtable',
      'GPUtable',
      'motherboardtable',
      'RAMtable',
      'storagetable',
      'PSUtable',
      'coolingtable',
      'casetable', // Case will be handled separately
    ];

    // Sort components
    final sortedComponents = _components.entries.toList()
      ..sort((a, b) {
        final aIndex = componentOrder.indexOf(a.key);
        final bIndex = componentOrder.indexOf(b.key);
        return aIndex.compareTo(bIndex);
      });

    // Add components
    for (var entry in sortedComponents) {
      final component = entry.value;
      if (component.isEmpty) continue;

      // Format component name for display
      String componentName = entry.key.replaceAll('table', '');
      if (componentName == 'case') {
        componentName = 'Case';
      } else if (componentName.isNotEmpty) {
        componentName = componentName[0].toUpperCase() + componentName.substring(1);
      }

      final imagePath = component['imageURL']?.toString() ?? '';
      final price = component['price'] != null ? 'Rs. ${component['price']}' : 'Price not available';

      widgets.add(
        _buildComponentCard(
          componentName: componentName,
          component: component,
          imagePath: imagePath,
          price: price,
        ),
      );
    }

    return Column(children: widgets);
  }

  Widget _buildComponentCard({
    required String componentName,
    required Map<String, dynamic> component,
    required String imagePath,
    required String price,
  }) {
    final type = componentName.toLowerCase();
    final isCase = type == 'case';
    final isCpu = type == 'cputable';
    final isGpu = type == 'gputable';
    final isMotherboard = type == 'motherboard';
    final isRam = type == 'ram';
    final isStorage = type == 'storage';
    final isPsu = type == 'psu';
    final isCooler = type == 'cooling';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        leading: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 60, maxHeight: 60),
          child: _buildComponentImage(imagePath),
        ),
        title: Text(
          component['model_name']?.toString() ?? 'Unknown Model',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            _getComponentTypeName(type),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 100),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: 
                  Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              price,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:  Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildComponentDetails(type, component),
            ),
          ),
        ],
      ),
    );
  }

  String _getComponentTypeName(String type) {
    switch (type.toLowerCase()) {
      case 'cputable':
        return 'Processor';
      case 'gputable':
        return 'Graphics Card';
      case 'motherboardtable':
        return 'Motherboard';
      case 'ramtable':
        return 'Memory (RAM)';
      case 'storagetable':
        return 'Storage';
      case 'psutable':
        return 'Power Supply';
      case 'casetable':
        return 'Case';
      case 'coolingtable':
        return 'CPU Cooler';
      default:
        return type;
    }
  }

  Widget _buildComponentImage(String imagePath) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: imagePath.isNotEmpty
          ? FutureBuilder<File>(
              future: Future<File>.value(File(imagePath)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                    ),
                  );
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return _buildPlaceholderIcon();
                } else {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      snapshot.data!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderIcon();
                      },
                    ),
                  );
                }
              },
            )
          : _buildPlaceholderIcon(),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(Icons.computer, size: 28, color: Colors.grey),
    );
  }

  List<Widget> _buildComponentDetails(String type, Map<String, dynamic> component) {
    final List<Widget> details = [];
    final formatter = NumberFormat('#,##0');

    // Add brand if available
    if (component['brand'] != null) {
      details.add(_buildDetailRow('Brand', component['brand']));
    }

    switch (type.toLowerCase()) {
      case 'cputable':
        if (component['cores'] != null)
          details.add(_buildDetailRow('Cores', component['cores'].toString()));
        if (component['threads'] != null)
          details.add(_buildDetailRow('Threads', component['threads'].toString()));
        if (component['baseclock'] != null)
          details.add(_buildDetailRow('Base Clock', '${component['baseclock']} GHz'));
        if (component['boostclock'] != null)
          details.add(_buildDetailRow('Boost Clock', '${component['boostclock']} GHz'));
        if (component['socket'] != null)
          details.add(_buildDetailRow('Socket', component['socket']));
        if (component['tdp'] != null)
          details.add(_buildDetailRow('TDP', '${component['tdp']}W'));
        if (component['integratedgraphics'] == 1)
          details.add(_buildDetailRow('Graphics', 'Integrated Graphics'));
        break;

      case 'gputable':
        if (component['vram'] != null)
          details.add(_buildDetailRow('VRAM', '${component['vram']} GB GDDR6'));
        if (component['core_clock'] != null)
          details.add(_buildDetailRow('Core Clock', '${component['core_clock']} MHz'));
        if (component['boostclock'] != null)
          details.add(_buildDetailRow('Boost Clock', '${component['boostclock']} MHz'));
        if (component['tdp'] != null)
          details.add(_buildDetailRow('TDP', '${component['tdp']}W'));
        if (component['length_mm'] != null)
          details.add(_buildDetailRow('Length', '${component['length_mm']} mm'));
        break;

      case 'motherboardtable':
        if (component['socket'] != null)
          details.add(_buildDetailRow('Socket', component['socket']));
        if (component['chipset'] != null)
          details.add(_buildDetailRow('Chipset', component['chipset']));
        if (component['form_factor'] != null)
          details.add(_buildDetailRow('Form Factor', component['form_factor']));
        if (component['memory_type'] != null)
          details.add(_buildDetailRow('Memory Type', component['memory_type']));
        if (component['memory_slots'] != null)
          details.add(_buildDetailRow('Memory Slots', component['memory_slots'].toString()));
        if (component['max_memory'] != null)
          details.add(_buildDetailRow('Max Memory', '${component['max_memory']} GB'));
        break;

      case 'ramtable':
        if (component['capacity'] != null)
          details.add(_buildDetailRow('Capacity', '${component['capacity']} GB'));
        if (component['speed'] != null)
          details.add(_buildDetailRow('Speed', '${component['speed']} MHz'));
        if (component['memory_type'] != null)
          details.add(_buildDetailRow('Type', component['memory_type']));
        if (component['modules'] != null)
          details.add(_buildDetailRow('Modules', '${component['modules']} x ${(component['capacity'] as int? ?? 0) ~/ (component['modules'] as int? ?? 1)}GB'));
        break;

      case 'storagetable':
        if (component['capacity'] != null)
          details.add(_buildDetailRow('Capacity', '${(component['capacity'] as int) >= 1000 ? '${(component['capacity'] as int) ~/ 1000}TB' : '${component['capacity']}GB'}'));
        if (component['type'] != null)
          details.add(_buildDetailRow('Type', component['type']));
        if (component['interface'] != null)
          details.add(_buildDetailRow('Interface', component['interface']));
        break;

      case 'psutable':
        if (component['wattage'] != null)
          details.add(_buildDetailRow('Wattage', '${component['wattage']}W'));
        if (component['efficiency_rating'] != null)
          details.add(_buildDetailRow('Efficiency', component['efficiency_rating']));
        if (component['form_factor'] != null)
          details.add(_buildDetailRow('Form Factor', component['form_factor']));
        break;

      case 'casetable':
        if (component['form_factor'] != null)
          details.add(_buildDetailRow('Form Factor', component['form_factor']));
        if (component['max_gpu_length'] != null)
          details.add(_buildDetailRow('Max GPU Length', '${component['max_gpu_length']} mm'));
        break;

      case 'coolingtable':
        if (component['type'] != null)
          details.add(_buildDetailRow('Type', component['type']));
        if (component['supported_sockets'] != null)
          details.add(_buildDetailRow('Compatible Sockets', component['supported_sockets']));
        break;

      case 'case':
        if (component['form_factor'] != null)
          details.add(_buildDetailRow('Form Factor', component['form_factor']));
        break;
    }

    return details;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityCheck(BuildContext context) {
    final List<Map<String, dynamic>> checks = [];

    // Get components
    final cpu = _components['CPUtable'];
    final gpu = _components['GPUtable'];
    final motherboard = _components['motherboardtable'];
    final ram = _components['RAMtable'];
    final psu = _components['PSUtable'];
    final pcCase = _components['casetable'];

    // Check CPU-Motherboard compatibility
    if (cpu != null && motherboard != null) {
      final cpuSocket = cpu['socket']?.toString().toLowerCase();
      final mbSocket = motherboard['socket']?.toString().toLowerCase();

      checks.add({
        'title': 'CPU-Motherboard Socket',
        'isOk': cpuSocket == mbSocket,
        'message': cpuSocket == mbSocket
            ? 'Compatible (${cpuSocket?.toUpperCase()})'
            : 'Incompatible: CPU (${cpuSocket?.toUpperCase()}) ≠ Motherboard (${mbSocket?.toUpperCase()})',
      });
    }

    // Check RAM-Motherboard compatibility
    if (ram != null && motherboard != null) {
      final ramType = ram['memory_type']?.toString().toLowerCase();
      final mbRamType = motherboard['memory_type']?.toString().toLowerCase();

      checks.add({
        'title': 'RAM-Motherboard',
        'isOk': ramType == mbRamType,
        'message': ramType == mbRamType
            ? 'Compatible (${ramType?.toUpperCase()})'
            : 'Incompatible: RAM (${ramType?.toUpperCase()}) ≠ Motherboard (${mbRamType?.toUpperCase()})',
      });
    }

    // Check PSU wattage
    if (psu != null) {
      final psuWattage = (psu['wattage'] as int?) ?? 0;
      final estimatedWattage = (_totalTDP * 1.5).round(); // Add 50% headroom

      checks.add({
        'title': 'Power Supply',
        'isOk': psuWattage >= estimatedWattage,
        'message': psuWattage >= estimatedWattage
            ? 'Adequate (${psuWattage}W ≥ ${estimatedWattage}W estimated)'
            : 'Insufficient: ${psuWattage}W < ${estimatedWattage}W estimated',
      });
    }

    // Check GPU fit in case
    if (gpu != null && pcCase != null) {
      final gpuLength = (gpu['length_mm'] as int?) ?? 0;
      final maxGpuLength = (pcCase['max_gpu_length'] as int?) ?? 0;

      checks.add({
        'title': 'GPU Fit in Case',
        'isOk': gpuLength <= maxGpuLength,
        'message': gpuLength <= maxGpuLength
            ? 'Fits (${gpuLength}mm ≤ ${maxGpuLength}mm max)'
            : 'Too long: ${gpuLength}mm > ${maxGpuLength}mm max',
      });
    }

    if (checks.isEmpty) {
      return const Text('Compatibility check not available');
    }

    return Column(
      children: checks.map((check) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  check['isOk'] ? Icons.check_circle : Icons.error,
                  color: check['isOk'] ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        check['title'],
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        check['message'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _build?['build_name']?.toString() ?? 'Build Details',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        elevation: 0,
        actions: [
          if (_build?['user_id'] != null)
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                // TODO: Navigate to user profile
              },
              tooltip: 'View User Profile',
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon')),
              );
            },
            tooltip: 'Share Build',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Stack(
          children:[ _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadBuildDetails,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16.0,16,16,100),
                      child: _buildComponentList(),
                    ),
                    const Positioned(
        bottom: 30,
        left: 0,
        right: 0,
        child: AdminBottomNavBar(selectedindex: 0),
      ),
                    ]
        ),
      ),
  
    );
  }
}