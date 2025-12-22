import 'package:assemblex/user_page/tabbar/algorithm/compatibility.dart';
import 'package:assemblex/user_page/tabbar/buildpc_page/loading_animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

// Import your services
import 'package:assemblex/services/cpu_service.dart';
import 'package:assemblex/services/gpu_service.dart';
import 'package:assemblex/services/psu_service.dart';
import 'package:assemblex/services/ram_service.dart';
import 'package:assemblex/services/storage_service.dart';
import 'package:assemblex/services/motherboard_service.dart';
import 'package:assemblex/services/case_service.dart';
import 'package:assemblex/services/cooling_service.dart';
// Import recommendation service
import 'package:assemblex/services/recommendation_service.dart';
import 'package:assemblex/services/save_build.dart';
import 'package:assemblex/services/database_service.dart';

class buildPC extends StatefulWidget {
  const buildPC({super.key});

  @override
  State<buildPC> createState() => _buildPCState();
}

class _buildPCState extends State<buildPC> {
  final TextEditingController _buildname = TextEditingController();
  int _totalprice = 0;
  bool _isLoading = true;
  String _voltage = '0W';
  String _compatibility = "Not Checked";
  bool _buildbool = false;
  List<CPU> _cpus = [];
  int? _selectedCpuIndex;

  List<GPU> _gpus = [];
  int? _selectedGpuIndex;

  List<PSU> _psus = [];
  int? _selectedPsuIndex;

  List<RAM> _rams = [];
  int? _selectedRamIndex;

  List<Storage> _storages = [];
  int? _selectedStorageIndex;

  List<Motherboard> _motherboards = [];
  int? _selectedMotherboardIndex;

  List<Case> _cases = [];
  int? _selectedCaseIndex;

  List<Cooling> _coolings = [];
  int? _selectedCoolingIndex;

  // Add PCBuild object
  PCBuild _currentBuild = PCBuild();

  // Recommendation system variables - Separate for database and dataset
  List<Recommendation> _cpuRecommendations = [];
  List<Recommendation> _gpuRecommendations = [];
  List<Recommendation> _ramRecommendations = [];
  List<Recommendation> _motherboardRecommendations = [];
  List<Recommendation> _psuRecommendation = [];
  List<Recommendation> _caseRecommendation = [];
  List<Recommendation> _coolingRecommendation = [];
  List<Recommendation> _storageRecommendation = [];
  
  // Separate dataset recommendations (reference only)
  List<Recommendation> _cpuDatasetRecommendations = [];
  List<Recommendation> _gpuDatasetRecommendations = [];
  List<Recommendation> _ramDatasetRecommendations = [];
  List<Recommendation> _motherboardDatasetRecommendations = [];
  List<Recommendation> _psuDatasetRecommendation = [];
  List<Recommendation> _caseDatasetRecommendation = [];
  List<Recommendation> _coolingDatasetRecommendation = [];
  List<Recommendation> _storageDatasetRecommendation = [];
  
  bool _recommendationsLoading = false;
  bool _recommendationServerAvailable = false;

  T? _itemAt<T>(List<T> items, int? index) {
    if (index == null) return null;
    if (index < 0 || index >= items.length) return null;
    return items[index];
  }

  @override
  void initState() {
    super.initState();
    _loadAllComponents();
    _checkRecommendationServer();
  }

  Future<void> _checkRecommendationServer() async {
    print('🔍 Checking recommendation server...');
    
    // Test connection first
    await RecommendationService.testConnection();
    
    try {
      _recommendationServerAvailable = await RecommendationService.isServerHealthy();
      print('Recommendation server available: $_recommendationServerAvailable');
      
      // Test if recommendation endpoints actually work
      if (_recommendationServerAvailable) {
        await RecommendationService.debugRecommendations();
      }
      
    } catch (e) {
      print('Recommendation server check failed: $e');
      _recommendationServerAvailable = false;
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadAllComponents() async {
    try {
      final cpus = await CPUService.getAllCPUs();
      final gpus = await GPUService.getAllGPUs();
      final psus = await PSUService.getAllPSUs();
      final rams = await RAMService.getAllRAMs();
      final storages = await StorageService.getAllStorages();
      final motherboards = await MotherboardService.getAllMotherboards();
      final cases = await CaseService.getAllCases();
      final coolings = await CoolingService.getAllCoolings();

      setState(() {
        _cpus = cpus;
        _gpus = gpus;
        _psus = psus;
        _rams = rams;
        _storages = storages;
        _motherboards = motherboards;
        _cases = cases;
        _coolings = coolings;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading components: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update the build and check compatibility
  void _updateBuildAndCheckCompatibility() {
    setState(() {
      _currentBuild = PCBuild(
        cpu: _itemAt(_cpus, _selectedCpuIndex),
        motherboard: _itemAt(_motherboards, _selectedMotherboardIndex),
        ram: _itemAt(_rams, _selectedRamIndex),
        gpu: _itemAt(_gpus, _selectedGpuIndex),
        storage: _itemAt(_storages, _selectedStorageIndex),
        psu: _itemAt(_psus, _selectedPsuIndex),
        c: _itemAt(_cases, _selectedCaseIndex),
        cooling: _itemAt(_coolings, _selectedCoolingIndex),
      );

      // Calculate total voltage
      final finalvoltage = "${CompatibilityChecker.calculateTotalPowerConsumption(_currentBuild)}W";
      _voltage = finalvoltage;

      // Check compatibility
      final result = CompatibilityChecker.checkCompatibility(_currentBuild);
      _compatibility = result.isCompatible ? "Compatible " : "Issues ";
    
      // If there are errors, show the count
      if (!result.isCompatible) {
        _compatibility = "${result.errors.length} Issues ";
      }
    });

    // Load recommendations when build changes
    _loadRecommendations();
  }
  // Method to load recommendations based on current build
  Future<void> _loadRecommendations() async {
    if (!_recommendationServerAvailable || !mounted) return;
    
    setState(() {
      _recommendationsLoading = true;
    });

    try {
      // Create current build map with non-null IDs
      final Map<String, int> currentBuild = {};
      
      final selectedCpu = _itemAt(_cpus, _selectedCpuIndex);
      if (selectedCpu != null && selectedCpu.id != null) {
        currentBuild['cpu'] = selectedCpu.id!;
      }
      final selectedMobo = _itemAt(_motherboards, _selectedMotherboardIndex);
      if (selectedMobo != null && selectedMobo.id != null) {
        currentBuild['motherboard'] = selectedMobo.id!;
      }
      final selectedGpu = _itemAt(_gpus, _selectedGpuIndex);
      if (selectedGpu != null && selectedGpu.id != null) {
        currentBuild['gpu'] = selectedGpu.id!;
      }
      final selectedRam = _itemAt(_rams, _selectedRamIndex);
      if (selectedRam != null && selectedRam.id != null) {
        currentBuild['ram'] = selectedRam.id!;
      }
      final selectedCase = _itemAt(_cases, _selectedCaseIndex);
      if (selectedCase != null && selectedCase.id != null) {
        currentBuild['case'] = selectedCase.id!;
      }
      final selectedPsu = _itemAt(_psus, _selectedPsuIndex);
      if (selectedPsu != null && selectedPsu.id != null) {
        currentBuild['psu'] = selectedPsu.id!;
      }
      final selectedStorage = _itemAt(_storages, _selectedStorageIndex);
      if (selectedStorage != null && selectedStorage.id != null) {
        currentBuild['storage'] = selectedStorage.id!;
      }
      final selectedCooling = _itemAt(_coolings, _selectedCoolingIndex);
      if (selectedCooling != null && selectedCooling.id != null) {
        currentBuild['cooling'] = selectedCooling.id!;
      }

      print(' Loading recommendations for build: $currentBuild');

      // Load separate database and dataset recommendations
      // CPU recommendations
      if (_selectedMotherboardIndex != null && _selectedCpuIndex == null) {
        final cpuRecs = await RecommendationService.getCompatibleRecommendationsSeparate(
          currentBuild: currentBuild,
          targetCategory: 'cpu',
          nRecommendations: 5,
        );
        _cpuRecommendations = cpuRecs['database'] ?? [];
        _cpuDatasetRecommendations = cpuRecs['dataset'] ?? [];
        print(' Loaded ${_cpuRecommendations.length} CPU DB + ${_cpuDatasetRecommendations.length} dataset recommendations');
      } else {
        _cpuRecommendations = [];
        _cpuDatasetRecommendations = [];
      }

      // GPU recommendations
      if (_selectedGpuIndex == null) {
        final gpuRecs = await RecommendationService.getCompatibleRecommendationsSeparate(
          currentBuild: currentBuild,
          targetCategory: 'gpu',
          nRecommendations: 5,
        );
        _gpuRecommendations = gpuRecs['database'] ?? [];
        _gpuDatasetRecommendations = gpuRecs['dataset'] ?? [];
        print(' Loaded ${_gpuRecommendations.length} GPU DB + ${_gpuDatasetRecommendations.length} dataset recommendations');
      } else {
        _gpuRecommendations = [];
        _gpuDatasetRecommendations = [];
      }

      // RAM recommendations
      if (_selectedMotherboardIndex != null && _selectedRamIndex == null) {
        final ramRecs = await RecommendationService.getCompatibleRecommendationsSeparate(
          currentBuild: currentBuild,
          targetCategory: 'ram',
          nRecommendations: 5,
        );
        _ramRecommendations = ramRecs['database'] ?? [];
        _ramDatasetRecommendations = ramRecs['dataset'] ?? [];
        print(' Loaded ${_ramRecommendations.length} RAM DB + ${_ramDatasetRecommendations.length} dataset recommendations');
      } else {
        _ramRecommendations = [];
        _ramDatasetRecommendations = [];
      }

      // PSU recommendations
      if ((_selectedCpuIndex != null || _selectedGpuIndex != null) && _selectedPsuIndex == null) {
        final psuRecs = await RecommendationService.getCompatibleRecommendationsSeparate(
          currentBuild: currentBuild,
          targetCategory: 'psu',
          nRecommendations: 5,
        );
        _psuRecommendation = psuRecs['database'] ?? [];
        _psuDatasetRecommendation = psuRecs['dataset'] ?? [];
        print('✅ Loaded ${_psuRecommendation.length} PSU DB + ${_psuDatasetRecommendation.length} dataset recommendations');
      } else {
        _psuRecommendation = [];
        _psuDatasetRecommendation = [];
      }

      // Case recommendations
      if ((_selectedMotherboardIndex != null || _selectedGpuIndex != null) && _selectedCaseIndex == null) {
        final caseRecs = await RecommendationService.getCompatibleRecommendationsSeparate(
          currentBuild: currentBuild,
          targetCategory: 'case',
          nRecommendations: 5,
        );
        _caseRecommendation = caseRecs['database'] ?? [];
        _caseDatasetRecommendation = caseRecs['dataset'] ?? [];
        print('✅ Loaded ${_caseRecommendation.length} Case DB + ${_caseDatasetRecommendation.length} dataset recommendations');
      } else {
        _caseRecommendation = [];
        _caseDatasetRecommendation = [];
      }

      // Motherboard recommendations
      if (_selectedCpuIndex != null && _selectedMotherboardIndex == null) {
        final moboRecs = await RecommendationService.getCompatibleRecommendationsSeparate(
          currentBuild: currentBuild,
          targetCategory: 'motherboard',
          nRecommendations: 5,
        );
        _motherboardRecommendations = moboRecs['database'] ?? [];
        _motherboardDatasetRecommendations = moboRecs['dataset'] ?? [];
        print('✅ Loaded ${_motherboardRecommendations.length} Motherboard DB + ${_motherboardDatasetRecommendations.length} dataset recommendations');
      } else {
        _motherboardRecommendations = [];
        _motherboardDatasetRecommendations = [];
      }

      // STORAGE recommendations
      if (_selectedStorageIndex == null) {
        final storageRecs = await RecommendationService.getCompatibleRecommendationsSeparate(
          currentBuild: currentBuild,
          targetCategory: 'storage',
          nRecommendations: 5,
        );
        _storageRecommendation = storageRecs['database'] ?? [];
        _storageDatasetRecommendation = storageRecs['dataset'] ?? [];
        print(' Loaded ${_storageRecommendation.length} Storage DB + ${_storageDatasetRecommendation.length} dataset recommendations');
      } else {
        _storageRecommendation = [];
        _storageDatasetRecommendation = [];
      }

      // COOLING recommendations
      if (_selectedCpuIndex != null && _selectedCoolingIndex == null) {
        final coolingRecs = await RecommendationService.getCompatibleRecommendationsSeparate(
          currentBuild: currentBuild,
          targetCategory: 'cooling',
          nRecommendations: 5,
        );
        _coolingRecommendation = coolingRecs['database'] ?? [];
        _coolingDatasetRecommendation = coolingRecs['dataset'] ?? [];
        print('✅ Loaded ${_coolingRecommendation.length} Cooling DB + ${_coolingDatasetRecommendation.length} dataset recommendations');
      } else {
        _coolingRecommendation = [];
        _coolingDatasetRecommendation = [];
      }

    } catch (e) {
      print('Error loading recommendations: $e');
      // Clear recommendations on error
      _cpuRecommendations = [];
      _gpuRecommendations = [];
      _ramRecommendations = [];
      _motherboardRecommendations = [];
      _caseRecommendation = [];
      _psuRecommendation = [];
      _storageRecommendation = [];
      _coolingRecommendation = [];
      // Clear dataset recommendations
      _cpuDatasetRecommendations = [];
      _gpuDatasetRecommendations = [];
      _ramDatasetRecommendations = [];
      _motherboardDatasetRecommendations = [];
      _caseDatasetRecommendation = [];
      _psuDatasetRecommendation = [];
      _storageDatasetRecommendation = [];
      _coolingDatasetRecommendation = [];
    } finally {
      if (mounted) {
        setState(() {
          _recommendationsLoading = false;
        });
      }
    }
  }


  // Helper method to find component by ID
// Helper method to find component by ID with better error handling
int? _findComponentIndexById(List<dynamic> components, int id, String category) {
  print(' Looking for $category ID $id in ${components.length} components');
  
  for (int i = 0; i < components.length; i++) {
    if (components[i].id == id) {
      print(' Found $category ID $id at index $i: ${components[i].modelName}');
      return i;
    }
  }
  
  print(' $category ID $id not found in local database');
  return null;
}

  Widget _buildImageWidget(String? imageUrl, {double size = 40}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.asset('assets/images/default_cpu.png', width: size, height: size, fit: BoxFit.cover);
    }

    if (imageUrl.startsWith('/data/')) {
      return Image.file(
        File(imageUrl),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset('assets/images/default_cpu.png', width: size, height: size),
      );
    } else {
      return Image.asset(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset('assets/images/default_cpu.png', width: size, height: size),
      );
    }
  }

  Widget _componentItem(dynamic item) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Row(
          children: [
            _buildImageWidget(item.imageURL, size: 50),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.modelName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text('Rs.${item.price}', style: const TextStyle(fontSize: 14, color: Colors.green)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget to display recommendation items - UPDATED VERSION
  Widget _recommendationItem(Recommendation recommendation, String targetCategory, Function onSelect) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 3,
      color: recommendation.inDatabase ? Colors.blue[50] : Colors.orange[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: recommendation.inDatabase ? Colors.blue[200]! : Colors.orange[200]!,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: recommendation.inDatabase ? Colors.blue[100] : Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(targetCategory),
            color: recommendation.inDatabase ? Colors.blue[700] : Colors.orange[700],
            size: 20,
          ),
        ),
        title: Text(
          recommendation.modelName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: recommendation.inDatabase ? Colors.blue[800] : Colors.orange[800],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rs.${recommendation.price}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: recommendation.inDatabase ? Colors.green[700] : Colors.orange[700],
              ),
            ),
            Text(
              recommendation.availabilityStatus,
              style: TextStyle(
                fontSize: 9,
                color: recommendation.inDatabase ? Colors.green[600] : Colors.orange[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            if (recommendation.reason.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  recommendation.reason,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (recommendation.compatibilityNotes.isNotEmpty)
              Text(
                recommendation.compatibilityNotes.first,
                style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: recommendation.inDatabase
    ? Tooltip(
        message: 'Add to build ',
        child: IconButton(
          icon: Icon(Icons.add_circle, size: 20, color: Colors.green),
          onPressed: () {
            print(' Add button pressed for: ${recommendation.modelName}');
            onSelect();
          },
        ),
      )
    : Tooltip(
        message: 'Reference only',
        child: Icon(Icons.visibility, size: 20, color: Colors.orange),
      ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cpu':
        return Icons.memory;
      case 'gpu':
        return Icons.graphic_eq;
      case 'ram':
        return Icons.sd_storage;
      case 'motherboard':
        return Icons.developer_board;
      case 'psu':
        return Icons.power;
      case 'storage':
        return Icons.storage;
      case 'case':
        return Icons.desktop_windows;
      case 'cooling':
        return Icons.ac_unit;
      default:
        return Icons.computer;
    }
  }

  

  Future<void> _saveBuild()async{
    _updateBuildAndCheckCompatibility();
    if(_selectedCaseIndex == null ||
      _selectedCoolingIndex == null ||
      _selectedCpuIndex == null ||
      _selectedGpuIndex == null ||
      _selectedRamIndex == null ||
      _selectedMotherboardIndex == null ||
      _selectedPsuIndex == null ||
      _selectedStorageIndex == null
    ){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please input all the field required to Save the PC'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    final compatibilityCheck = CompatibilityChecker.checkCompatibility(_currentBuild);
    if(!compatibilityCheck.isCompatible){
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Compatibility Issue',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20
            ),
          ),
          content: Text('Your Build Has Compatibility issue. Are You Sure You Wanna Save?',
          style: TextStyle(
            fontWeight: FontWeight.bold
          ),
          
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.red)
              ),
             child: Text('Cancel',
             style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white
             ),
             )),
            TextButton(onPressed: () {
              Navigator.pop(context); // close compatibility dialog first
              _savebuildname();
            },
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.green)
            ),
             child: Text('Yes',
             style:TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold
             ),
             ))
          ],
        )
      );
    } else {
      _savebuildname();
    }
  }
  Future<void> _savebuildname() async{
    _buildbool = _buildname.text.trim().isNotEmpty;
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
          icon: Icon(Icons.save),
            title: Text(
              'Your Build Name:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            content: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _buildname,
                onChanged: (val) {
                  setStateDialog(() {
                    _buildbool = val.trim().isNotEmpty;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Name Of Your Build',
                  hintStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  contentPadding: EdgeInsets.all(10.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            buttonPadding: EdgeInsets.all(16.0),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.red),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              TextButton(
                onPressed: _buildbool ? saveToDatabase : null,
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.green),
                ),
                child: Text(
                  'Save The Build',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  

  Future<void> saveToDatabase() async {
    try {
      // Get current user from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getInt('loggedInUserId');
      
      if (savedUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to save builds'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context); // Close the dialog
        return;
      }
      
      final userId = savedUserId;
      
      // Initialize SaveBuild database
      final db = await DatabaseService.instance.database;
      SaveBuild.setDatabase(db);
      
      // Parse voltage (remove 'W' suffix if present)
      final voltageStr = _voltage.replaceAll('W', '').trim();
      final totalWattage = double.parse(voltageStr);
      
      // Get case image URL (use case image as build image)
      final caseImageUrl = _currentBuild.c?.imageURL ?? '';
      
      if (caseImageUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Case image not found. Please select a case.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (_buildname.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a build name'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_currentBuild.cpu == null ||
          _currentBuild.motherboard == null ||
          _currentBuild.ram == null ||
          _currentBuild.psu == null ||
          _currentBuild.c == null ||
          _currentBuild.gpu == null ||
          _currentBuild.storage == null ||
          _currentBuild.cooling == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('One or more components are missing. Please complete your build.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_currentBuild.cpu!.id == null ||
          _currentBuild.motherboard!.id == null ||
          _currentBuild.ram!.id == null ||
          _currentBuild.psu!.id == null ||
          _currentBuild.c!.id == null ||
          _currentBuild.gpu!.id == null ||
          _currentBuild.storage!.id == null ||
          _currentBuild.cooling!.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Component IDs are invalid. Please re-select components.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Save the build
      final saveBuild = SaveBuild();
      final buildId = await saveBuild.saveUserBuild(
        userId: userId,
        buildName: _buildname.text.trim(),
        totalWattage: totalWattage,
        totalPrice: _totalprice.toDouble(),
        cpuId: _currentBuild.cpu!.id!.toInt(),
        motherboardId: _currentBuild.motherboard!.id!.toInt(),
        ramId: _currentBuild.ram!.id!.toInt(),
        psuId: _currentBuild.psu!.id!.toInt(),
        caseId: _currentBuild.c!.id!.toInt(),
        gpuId: _currentBuild.gpu!.id!.toInt(),
        storageId: _currentBuild.storage!.id!.toInt(),
        coolerId: _currentBuild.cooling!.id!.toInt(),
        imagePath: caseImageUrl, // Use case image as build image
      );
      
      if (buildId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Build "${_buildname.text.trim()}" saved successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context); // Close the build name dialog only
        _buildname.clear(); // Clear the build name field
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save build. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error saving build: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving build: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  } 

  void _showPicker<T>(
    BuildContext context,
    List<T> items,
    int? selectedIndex,
    void Function(int?) onSelected,
    Widget Function(T) itemBuilder,
    String title,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => SizedBox(
        width: double.infinity,
        height: 300,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8.0),
              color: CupertinoColors.systemBackground,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    CupertinoButton(child: const Text('Done'), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 70,
                backgroundColor: Colors.white,
                scrollController: FixedExtentScrollController(initialItem: selectedIndex != null ? selectedIndex + 1 : 0),
                onSelectedItemChanged: (int value) {
                  onSelected(value == 0 ? null : value - 1);
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        const Center(child: Text('+ Select product', style: TextStyle(fontSize: 16, color: Colors.grey))),
                      ],
                    ),
                  ),
                  ...items.map(itemBuilder),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showDatasetComponentDetails(Recommendation recommendation) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Reference Component'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(recommendation.modelName, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Price: Rs.${recommendation.price}'),
          SizedBox(height: 8),
          Text('This component is from our extended dataset but not currently available in store.', 
               style: TextStyle(color: Colors.orange)),
          SizedBox(height: 8),
          if (recommendation.compatibilityNotes.isNotEmpty) ...[
            Text('Compatibility Notes:'),
            ...recommendation.compatibilityNotes.map((note) => 
              Text('• $note', style: TextStyle(fontSize: 12))
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}

  Widget _buildCardWithRecommendations<T>(
    String label,
    IconData icon,
    List<T> items,
    int? selectedIndex,
    void Function(int?) onSelected,
    List<Recommendation> databaseRecommendations,
    List<Recommendation> datasetRecommendations,
  ) {
    return Column(
      children: [
        _buildCard(label, icon, items, selectedIndex, onSelected),
        
        // Show recommendations if available and no component selected
        if (_recommendationServerAvailable && 
            selectedIndex == null && 
            !_recommendationsLoading) ...[
          // Database Recommendations (Available in store - can be added)
          if (databaseRecommendations.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shopping_cart, size: 18, color: Colors.green[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Available ${label}s (Add to Build):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...databaseRecommendations.map((rec) => _recommendationItem(rec, label.toLowerCase(), () {
                    // Database items can be added
                    final foundIndex = _findComponentIndexById(items, rec.id, label.toLowerCase());
                    if (foundIndex != null) {
                      print('✅ Adding recommended ${label.toLowerCase()}: ${rec.modelName}');
                      onSelected(foundIndex);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${rec.modelName} added to your build!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      print(' Database component ${rec.id} not found in local list - ID mismatch?');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Component not found in local database. Please refresh and try again.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  })),
                ],
              ),
            ),
          ],
          
          // Dataset Recommendations (Reference only - cannot be added)
          if (datasetRecommendations.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.orange[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Reference ${label}s:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...datasetRecommendations.map((rec) => _recommendationItem(rec, label.toLowerCase(), () {
                    // Dataset items cannot be added - show details
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${rec.modelName} is not available in store - for reference only'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    _showDatasetComponentDetails(rec);
                  })),
                ],
              ),
            ),
          ],
        ],

        // Show loading indicator for recommendations
        if (_recommendationServerAvailable && 
            selectedIndex == null && 
            _recommendationsLoading) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading recommendations...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCard<T>(
    String label,
    IconData icon,
    List<T> items,
    int? selectedIndex,
    void Function(int?) onSelected,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: _isLoading || items.isEmpty
            ? const Text('Loading...')
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _showPicker<T>(
                  context,
                  items,
                  selectedIndex,
                  (i) {
                    setState(() => onSelected(i));
                    _updateBuildAndCheckCompatibility(); // Update compatibility after selection
                  },
                  _componentItem,
                  'Select $label',
                ),
                child: selectedIndex == null
                    ? const Text('+ Select product', style: TextStyle(color: Colors.grey))
                    : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                          children: [
                            _buildImageWidget((items[selectedIndex] as dynamic).imageURL, size: 30),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                (items[selectedIndex] as dynamic).modelName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ),
              ),
        trailing: selectedIndex == null || items.isEmpty
            ? const Text('-')
            : Text('Rs.${(items[selectedIndex] as dynamic).price}', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTotalPrice() {
    final total =
        (_itemAt(_cpus, _selectedCpuIndex)?.price ?? 0) +
        (_itemAt(_gpus, _selectedGpuIndex)?.price ?? 0) +
        (_itemAt(_psus, _selectedPsuIndex)?.price ?? 0) +
        (_itemAt(_rams, _selectedRamIndex)?.price ?? 0) +
        (_itemAt(_storages, _selectedStorageIndex)?.price ?? 0) +
        (_itemAt(_motherboards, _selectedMotherboardIndex)?.price ?? 0) +
        (_itemAt(_cases, _selectedCaseIndex)?.price ?? 0) +
        (_itemAt(_coolings, _selectedCoolingIndex)?.price ?? 0);
    
    _totalprice = total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Total Price: Rs.$total',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showDetailedCompatibility() {
    final result = CompatibilityChecker.checkCompatibility(_currentBuild);
    final voltage = CompatibilityChecker.calculateTotalPowerConsumption(_currentBuild);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Compatibility Check', style: TextStyle(
          color: result.isCompatible ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 28
        )),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Score: ${result.score}%', style: TextStyle(
                color: _getScoreColor(result.score),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              )),
              Text('Build Completion: ${result.completionPercentage.toStringAsFixed(1)}%', style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
              Text('Total Power: $voltage',style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Critical Issues:', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ...result.errors.map((error) => Text('• $error', style: const TextStyle(color: Colors.red))),
              ],
              
              if (result.warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Suggestions:', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ...result.warnings.map((warning) => Text('• $warning', style: const TextStyle(color: Colors.orange))),
              ],

              // Show recommendation status
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _recommendationServerAvailable ? Icons.auto_awesome : Icons.warning,
                      color: _recommendationServerAvailable ? Colors.amber : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _recommendationServerAvailable 
                            ? 'Smart recommendations are active'
                            : 'Recommendation server unavailable',
                        style: TextStyle(
                          color: _recommendationServerAvailable ? Colors.blue[800] : Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (result.isCompatible && result.completionPercentage == 100) 
                const Text(' Build is fully compatible!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [        
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              children: [
                
                _buildCardWithRecommendations(
                  'CPU', 
                  Icons.memory, 
                  _cpus, 
                  _selectedCpuIndex, 
                  (i) => setState(() => _selectedCpuIndex = i),
                  _cpuRecommendations,
                  _cpuDatasetRecommendations,
                ),
                
                _buildCardWithRecommendations(
                  'Motherboard', 
                  Icons.developer_board, 
                  _motherboards, 
                  _selectedMotherboardIndex, 
                  (i) => setState(() => _selectedMotherboardIndex = i),
                  _motherboardRecommendations,
                  _motherboardDatasetRecommendations,
                ),
                
                _buildCardWithRecommendations(
                  'GPU', 
                  Icons.graphic_eq, 
                  _gpus, 
                  _selectedGpuIndex, 
                  (i) => setState(() => _selectedGpuIndex = i),
                  _gpuRecommendations,
                  _gpuDatasetRecommendations,
                ),
                
                _buildCardWithRecommendations(
                  'RAM', 
                  Icons.sd_storage, 
                  _rams, 
                  _selectedRamIndex, 
                  (i) => setState(() => _selectedRamIndex = i),
                  _ramRecommendations,
                  _ramDatasetRecommendations,
                ),
                
                _buildCardWithRecommendations(
                  'PSU', 
                  Icons.power, 
                  _psus, 
                  _selectedPsuIndex, 
                  (i) => setState(() => _selectedPsuIndex = i),
                  _psuRecommendation,
                  _psuDatasetRecommendation,
                ),
                _buildCardWithRecommendations(
                  'Case', 
                  Icons.desktop_windows, 
                  _cases, 
                  _selectedCaseIndex, 
                  (i) => setState(() => _selectedCaseIndex = i),
                  _caseRecommendation,
                  _caseDatasetRecommendation,
                ),
                _buildCardWithRecommendations(
                  'Storage', 
                  Icons.storage, 
                  _storages, 
                  _selectedStorageIndex, 
                  (i) => setState(() => _selectedStorageIndex = i),
                  _storageRecommendation,
                  _storageDatasetRecommendation,
                ),
                _buildCardWithRecommendations(
                  'Cooling', 
                  Icons.ac_unit, 
                  _coolings, 
                  _selectedCoolingIndex, 
                  (i) => setState(() => _selectedCoolingIndex = i),
                  _coolingRecommendation,
                  _coolingDatasetRecommendation,
                ),    
                
                _buildTotalPrice(),
                
                const SizedBox(height: 10),
                SizedBox(
                  height: 210,
                  child: GridView.count(
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    crossAxisCount: 2,
                    children: [
                      Card(
                        elevation: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RadialProgressAnimation(progress: _getCompatibilityProgress(), color: _getCompatibilityColor()),
                            const SizedBox(height: 10),
                            Text(
                              'Compatibility', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _compatibility,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.blue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Card(
                        elevation: 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.power, color:Colors.blue, size: 40),
                            const SizedBox(height: 10),
                            Text(
                              'Wattage', 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _voltage,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.blue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _showDetailedCompatibility,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Check Detailed Compatibility',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height:20),
                
                ElevatedButton(
                  onPressed:  _saveBuild,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Save The Build',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 100),
                
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for compatibility display
  double _getCompatibilityProgress() {
    final result = CompatibilityChecker.checkCompatibility(_currentBuild);
    return result.score / 100.0; // Convert percentage to 0.0-1.0 range
  }

  int _getCompatibilityPercentage() {
    final result = CompatibilityChecker.checkCompatibility(_currentBuild);
    return result.score;
  }

  Color _getCompatibilityColor() {
    final score = _getCompatibilityPercentage();
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
