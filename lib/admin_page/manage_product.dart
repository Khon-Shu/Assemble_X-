import 'dart:io';

import 'package:assemblex/admin_page/admininterface/admin_appbar.dart';
import 'package:assemblex/admin_page/admininterface/admin_bottom_navbar.dart';
import 'package:assemblex/admin_page/product_editor.dart';
import 'package:flutter/material.dart';

// Import all your service files
import 'package:assemblex/services/cpu_service.dart';
import 'package:assemblex/services/gpu_service.dart';
import 'package:assemblex/services/psu_service.dart';
import 'package:assemblex/services/ram_service.dart';
import 'package:assemblex/services/storage_service.dart';
import 'package:assemblex/services/motherboard_service.dart';
import 'package:assemblex/services/case_service.dart';
import 'package:assemblex/services/cooling_service.dart';

class ManageProduct extends StatefulWidget {
  const ManageProduct({super.key});

  @override
  State<ManageProduct> createState() => _ManageProductState();
}

class _ManageProductState extends State<ManageProduct> {
  bool _isLoading = false;
  final List<Map<String, dynamic>> _allProducts = [];
  final Map<String, List<Map<String, dynamic>>> _categorizedProducts = {};
  String _selectedCategory = 'GPU'; // Default category

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }

  Future<void> _loadAllProducts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load products from all services
      final List<Future> futures = [
        _loadCPUs(),
        _loadGPUs(),
        _loadPSUs(),
        _loadRAMs(),
        _loadStorages(),
        _loadMotherboards(),
        _loadCases(),
        _loadCoolings(),
      ];

      await Future.wait(futures);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
void _deleteProduct(int id , String category){
 showDialog(
  context: context,
  builder: (context) => AlertDialog(
  title: Text('Confirm Delete'),
  content: Text('Are You Sure You Want To Delete the $category?'),
  actions:  [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
  
          ElevatedButton(
            style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.red)),
            onPressed: ()async {
             Navigator.pop(context);
             
              setState(() {
                _isLoading = true;
              });
              try{
            switch(category){
             
              case 'GPU':
              await GPUService.deleteGPU(id);
              break;

              case 'CPU':
              await CPUService.deleteCPU(id);
              break;

              case 'Cooling':
              await CoolingService.deleteCooling(id);
              break;

              case 'Motherboard':
              await MotherboardService.deleteMotherboard(id);
              break;

              case 'PSU':
              await PSUService.deletePSU(id);
              break;

              case 'RAM':
              await RAMService.deleteRAM(id);
              break;

              case 'Storage':
              await StorageService.deleteStorage(id);
              break;

              case 'Case':
             await  CaseService.deleteCase(id);
               break;
              
              default:
              Text('No category selected');
              break;
            }
            await _loadAllProducts();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$category Sucessfully deleted')));
            
             } 
             catch(e){
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$category Failed to delete $e')));
             }
             finally{
              setState(() {
                _isLoading =false;
              });
             }
          }, child: Text('Yes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),)),

          ElevatedButton(onPressed: (){
            Navigator.pop(context);
          }, child: Text('No', style: TextStyle(fontWeight: FontWeight.bold),))
        ],
      )
    
  );


   
}  Future<void> _loadCPUs() async {
    try {
      final cpus = await CPUService.getAllCPUs();
      _categorizedProducts['CPU'] = cpus.map((cpu) => cpu.toMap()).toList();
      _allProducts.addAll(_categorizedProducts['CPU']!);
    } catch (e) {
      print('Error loading CPUs: $e');
    }
  }

  Future<void> _loadGPUs() async {
    try {
      final gpus = await GPUService.getAllGPUs();
      _categorizedProducts['GPU'] = gpus.map((gpu) => gpu.toMap()).toList();
      _allProducts.addAll(_categorizedProducts['GPU']!);
    } catch (e) {
      print('Error loading GPUs: $e');
    }
  }

  Future<void> _loadPSUs() async {
    try {
      final psus = await PSUService.getAllPSUs();
      _categorizedProducts['PSU'] = psus.map((psu) => psu.toMap()).toList();
      _allProducts.addAll(_categorizedProducts['PSU']!);
    } catch (e) {
      print('Error loading PSUs: $e');
    }
  }

  Future<void> _loadRAMs() async {
    try {
      final rams = await RAMService.getAllRAMs();
      _categorizedProducts['RAM'] = rams.map((ram) => ram.toMap()).toList();
      _allProducts.addAll(_categorizedProducts['RAM']!);
    } catch (e) {
      print('Error loading RAMs: $e');
    }
  }

  Future<void> _loadStorages() async {
    try {
      final storages = await StorageService.getAllStorages();
      _categorizedProducts['Storage'] = storages.map((storage) => storage.toMap()).toList();
      _allProducts.addAll(_categorizedProducts['Storage']!);
    } catch (e) {
      print('Error loading Storages: $e');
    }
  }

  Future<void> _loadMotherboards() async {
    try {
      final motherboards = await MotherboardService.getAllMotherboards();
      _categorizedProducts['Motherboard'] = motherboards.map((mb) => mb.toMap()).toList();
      _allProducts.addAll(_categorizedProducts['Motherboard']!);
    } catch (e) {
      print('Error loading Motherboards: $e');
    }
  }

  Future<void> _loadCases() async {
    try {
      final cases = await CaseService.getAllCases();
      _categorizedProducts['Case'] = cases.map((caseComp) => caseComp.toMap()).toList();
      _allProducts.addAll(_categorizedProducts['Case']!);
    } catch (e) {
      print('Error loading Cases: $e');
    }
  }

  Future<void> _loadCoolings() async {
    try {
      final coolings = await CoolingService.getAllCoolings();
      _categorizedProducts['Cooling'] = coolings.map((cooling) => cooling.toMap()).toList();
      _allProducts.addAll(_categorizedProducts['Cooling']!);
    } catch (e) {
      print('Error loading Coolings: $e');
    }
  }

  Widget _buildImageWidget(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Image.asset(
        'assets/images/default_cpu.png',
        width: 100,
        height: 120,
        fit: BoxFit.cover,
      );
    }

    if (imageUrl.startsWith('/data/')) {
      
      return Image.file(
        File(imageUrl),
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultImage(),
      );
    } else {
   
      return Image.asset(
        imageUrl,
        width: 120,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultImage(),
      );
    }
  }

  Widget _buildDefaultImage() {
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey[300],
      child: const Icon(Icons.computer, size: 40, color: Colors.grey),
    );
  }

  
  void _showProductDetails(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['model_name'] ?? 'Product Details', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
        content: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: _buildImageWidget(product['imageURL'])),
              const SizedBox(height: 16),
              _buildScrollableNameRow('Name', product['model_name']),
              _buildDetailRow('Price', 'Rs.${product['price']}'),
              _buildDetailRow('Brand', product['brand']),
              _buildDetailRow('ID', product['id'].toString()),
              
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold),),
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.red)
            ),
            onPressed: (){
                 Navigator.pop(context);
                _deleteProduct(product['id'], _selectedCategory);           
          }, 
          child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, ),)),
        ElevatedButton(
  onPressed: () {
   showDialog(context: context, builder: (context) => EditProductPage(productId: product['id']
   , category: _selectedCategory));
  },
  child: const Text('Edit', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 16 ,fontWeight: FontWeight.bold, color: Colors.green)),
          Text(value ?? 'N/A', style: TextStyle(fontWeight: FontWeight.bold),),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentProducts = _categorizedProducts[_selectedCategory] ?? [];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: CustomAppBar(leading: true),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                color: Colors.white,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Manage Products',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
                      ),
                    ),
                    const SizedBox(height: 20),

                 
                    _buildCategorySelector(),

                    const SizedBox(height: 20),

                 
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : currentProducts.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No products found',
                                    style: TextStyle(fontSize: 18, color: Colors.grey),
                                  ),
                                )
                              : GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 0.8,
                                  ),
                                  itemCount: currentProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = currentProducts[index];
                                    return GestureDetector(
                                      onTap: () => _showProductDetails(product),
                                      child: Card(
                                        elevation: 3,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Center(
                                                child: _buildImageWidget(product['imageURL']),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                product['model_name'] ?? 'No Name',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Center(
                                                child: Text(
                                                  'Rs.${product['price']}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                   
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
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
            child: const AdminBottomNavBar(selectedindex: 0)),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      'CPU', 'GPU', 'RAM', 'Motherboard', 
      'PSU', 'Storage', 'Case', 'Cooling'
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(category),
              selected: _selectedCategory == category,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
          );
        },
      ),
    );
  }
}

Widget _title(String title) {
  return Title(
    color: Colors.green,
    child: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
    ),
  );
}
Widget _buildScrollableNameRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.green
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );
}
