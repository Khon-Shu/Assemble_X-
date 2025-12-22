import 'package:assemblex/services/case_service.dart';
import 'package:assemblex/services/cooling_service.dart';
import 'package:assemblex/services/cpu_service.dart';
import 'package:assemblex/services/gpu_service.dart';
import 'package:assemblex/services/motherboard_service.dart';
import 'package:assemblex/services/psu_service.dart';
import 'package:assemblex/services/ram_service.dart';
import 'package:assemblex/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class EditProductPage extends StatefulWidget {
  final int productId;
  final String category;
  const EditProductPage({
    required this.productId,
    required this.category,
    super.key});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final Map<String, TextEditingController> _controllers = {};
  late String _category;
  dynamic _product;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    _category = widget.category.toLowerCase();
    _initializeForm();
    super.initState();
  }
  
  void _initializeForm() async {
    try {
      _product = await _fetchProduct();
      if (_product != null) {
        _setupControllers();
      }
    } catch (e) {
      print('Error initializing form: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<dynamic> _fetchProduct() async {
    switch (_category) {
      case 'cpu':
        return await CPUService.getCPUById(widget.productId);
      case 'gpu':
        return await GPUService.getGPUById(widget.productId);
      case 'motherboard':
        return await MotherboardService.getMotherboardById(widget.productId);
      case 'psu':
        return await PSUService.getPSUById(widget.productId);
      case 'cooling':
        return await CoolingService.getCoolingById(widget.productId);
      case 'ram':
        return await RAMService.getRAMById(widget.productId);
      case 'case':
        return await CaseService.getCaseById(widget.productId);
      case 'storage':
        return await StorageService.getStorageById(widget.productId);
      default:
        return null;
    }
  }

  void _setupControllers() {
    // Common fields for all products - initialize with empty text
    _controllers['modelName'] = TextEditingController();
    _controllers['brand'] = TextEditingController();
    _controllers['price'] = TextEditingController();

    // Category-specific fields
    switch (_category) {
      case 'gpu':
        _controllers['vram'] = TextEditingController();
        _controllers['coreClock'] = TextEditingController();
        _controllers['boostClock'] = TextEditingController();
        _controllers['tdp'] = TextEditingController();
        _controllers['length'] = TextEditingController();
        break;
      
      case 'cpu':
        _controllers['socket'] = TextEditingController();
        _controllers['cores'] = TextEditingController();
        _controllers['threads'] = TextEditingController();
        _controllers['baseClock'] = TextEditingController();
        _controllers['boostClock'] = TextEditingController();
        _controllers['tdp'] = TextEditingController();
        _controllers['integratedGraphics'] = TextEditingController();
        break;
      
      case 'ram':
        _controllers['memoryType'] = TextEditingController();
        _controllers['capacity'] = TextEditingController();
        _controllers['speed'] = TextEditingController();
        _controllers['modules'] = TextEditingController();
        break;
      
      case 'motherboard':
        _controllers['socket'] = TextEditingController();
        _controllers['chipset'] = TextEditingController();
        _controllers['formFactor'] = TextEditingController();
        _controllers['memoryType'] = TextEditingController();
        _controllers['memorySlots'] = TextEditingController();
        _controllers['maxMemory'] = TextEditingController();
        break;
      
      case 'storage':
        _controllers['interface'] = TextEditingController();
        _controllers['capacity'] = TextEditingController();
        break;
      
      case 'psu':
        _controllers['wattage'] = TextEditingController();
        _controllers['formFactor'] = TextEditingController();
        _controllers['efficiencyRating'] = TextEditingController();
        break;
      
      case 'case':
        _controllers['formFactor'] = TextEditingController();
        _controllers['maxGpuLength'] = TextEditingController();
        _controllers['estimatedPower'] = TextEditingController();
        break;
      
      case 'cooling':
        _controllers['type'] = TextEditingController();
        _controllers['supportedSockets'] = TextEditingController();
        break;
    }
  }

  Widget _buildTextField(String key, String label, {bool isRequired = false}) {
    String currentValue = _getCurrentValue(key);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: TextFormField(
        controller: _controllers[key],
        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
        decoration: InputDecoration(
          labelText: '$label${isRequired ? ' *' : ''}',
          labelStyle: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
          hintText: 'Current: $currentValue',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildNumberField(String key, String label, {bool isRequired = false}) {
    String currentValue = _getCurrentValue(key);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
        decoration: InputDecoration(
          labelText: '$label${isRequired ? ' *' : ''}',
          labelStyle: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
          hintText: 'Current: $currentValue',
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  String _getCurrentValue(String key) {
    if (_product == null) return '';
    
    switch (key) {
      case 'modelName':
        return _product.modelName ?? '';
      case 'brand':
        return _product.brand ?? '';
      case 'price':
        return _product.price?.toString() ?? '';
      case 'vram':
        return _product.vram?.toString() ?? '';
      case 'coreClock':
        return _product.coreClock?.toString() ?? '';
      case 'boostClock':
        return _product.boostClock?.toString() ?? '';
      case 'tdp':
        return _product.tdp?.toString() ?? '';
      case 'length':
        return _product.length?.toString() ?? '';
      case 'socket':
        return _product.socket ?? '';
      case 'cores':
        return _product.cores?.toString() ?? '';
      case 'threads':
        return _product.threads?.toString() ?? '';
      case 'baseClock':
        return _product.baseClock?.toString() ?? '';
      case 'integratedGraphics':
        return _product.integratedGraphics?.toString() ?? '';
      case 'memoryType':
        return _product.memoryType ?? '';
      case 'capacity':
        return _product.capacity?.toString() ?? '';
      case 'speed':
        return _product.speed?.toString() ?? '';
      case 'modules':
        return _product.modules?.toString() ?? '';
      case 'chipset':
        return _product.chipset ?? '';
      case 'formFactor':
        return _product.formFactor ?? '';
      case 'memorySlots':
        return _product.memorySlots?.toString() ?? '';
      case 'maxMemory':
        return _product.maxMemory?.toString() ?? '';
      case 'interface':
        return _product.interface ?? '';
      case 'wattage':
        return _product.wattage?.toString() ?? '';
      case 'efficiencyRating':
        return _product.efficiencyRating ?? '';
      case 'maxGpuLength':
        return _product.maxGpuLength?.toString() ?? '';
      case 'estimatedPower':
        return _product.estimatedPower?.toString() ?? '';
      case 'type':
        return _product.type ?? '';
      case 'supportedSockets':
        return _product.supportedSockets ?? '';
      default:
        return '';
    }
  }

  Widget _buildProductImage() {
    return FutureBuilder<String?>(
      future: _getImagePath(),
      builder: (context, snapshot) {
        String? imagePath = snapshot.data;
        
        return Container(
          width: double.infinity,
          height: 180,
          margin: EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: imagePath != null && File(imagePath).existsSync()
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                  ),
                )
              : _buildImagePlaceholder(),
        );
      },
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library, size: 50, color: Colors.grey[400]),
          SizedBox(height: 8),
          Text(
            'No Image Available',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<String?> _getImagePath() async {
    try {
      // Check if imageURL contains a local file path
      if (_product.imageURL != null && _product.imageURL.isNotEmpty) {
        // If it's already a full path, use it directly
        if (_product.imageURL.contains('/')) {
          final file = File(_product.imageURL);
          if (await file.exists()) {
            return _product.imageURL;
          }
        }
        
        // If it's just a filename, construct the full path
        final appDir = await getApplicationDocumentsDirectory();
        final fullPath = '${appDir.path}/${_product.imageURL}';
        final file = File(fullPath);
        
        if (await file.exists()) {
          return fullPath;
        }
      }
      return null;
    } catch (e) {
      print('Error getting image path: $e');
      return null;
    }
  }

  Widget _buildForm() {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.all(20),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with title
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Edit ${_category.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 16),
              
              // Product Image
              _buildProductImage(),
              
              // Current Product Info
              Container(
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Current Product Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      ' Model: ${_product.modelName}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 6),
                    Text(
                      ' Brand: ${_product.brand}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 6),
                    Text(
                      ' Price: Rs${_product.price}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 8),
                   
                  ],
                ),
              ),
              
              // Edit Form
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Product Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildTextField('modelName', 'Model Name', isRequired: true),
                    SizedBox(height: 12),
                    _buildTextField('brand', 'Brand', isRequired: true),
                    SizedBox(height: 12),
                    _buildNumberField('price', 'Price (\$)', isRequired: true),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Category-specific specifications
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '${_category.toUpperCase()} Specifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ..._buildCategorySpecificFields(),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Action Buttons
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveChange,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                        ),
                        child: _isSaving 
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategorySpecificFields() {
    List<Widget> fields = [];
    
    switch (_category) {
      case 'gpu':
        fields.addAll([
          _buildNumberField('vram', 'VRAM (GB)'),
          SizedBox(height: 12),
          _buildNumberField('coreClock', 'Core Clock (MHz)'),
          SizedBox(height: 12),
          _buildNumberField('boostClock', 'Boost Clock (MHz)'),
          SizedBox(height: 12),
          _buildNumberField('tdp', 'TDP (W)'),
          SizedBox(height: 12),
          _buildNumberField('length', 'Length (mm)'),
        ]);
        break;
      
      case 'cpu':
        fields.addAll([
          _buildTextField('socket', 'Socket'),
          SizedBox(height: 12),
          _buildNumberField('cores', 'Cores'),
          SizedBox(height: 12),
          _buildNumberField('threads', 'Threads'),
          SizedBox(height: 12),
          _buildNumberField('baseClock', 'Base Clock (GHz)'),
          SizedBox(height: 12),
          _buildNumberField('boostClock', 'Boost Clock (GHz)'),
          SizedBox(height: 12),
          _buildNumberField('tdp', 'TDP (W)'),
          SizedBox(height: 12),
          _buildNumberField('integratedGraphics', 'Integrated Graphics (1=Yes, 0=No)'),
        ]);
        break;
      
      case 'ram':
        fields.addAll([
          _buildTextField('memoryType', 'Memory Type'),
          SizedBox(height: 12),
          _buildNumberField('capacity', 'Capacity (GB)'),
          SizedBox(height: 12),
          _buildNumberField('speed', 'Speed (MHz)'),
          SizedBox(height: 12),
          _buildNumberField('modules', 'Modules'),
        ]);
        break;
      
      case 'motherboard':
        fields.addAll([
          _buildTextField('socket', 'Socket'),
          SizedBox(height: 12),
          _buildTextField('chipset', 'Chipset'),
          SizedBox(height: 12),
          _buildTextField('formFactor', 'Form Factor'),
          SizedBox(height: 12),
          _buildTextField('memoryType', 'Memory Type'),
          SizedBox(height: 12),
          _buildNumberField('memorySlots', 'Memory Slots'),
          SizedBox(height: 12),
          _buildNumberField('maxMemory', 'Max Memory (GB)'),
        ]);
        break;
      
      case 'storage':
        fields.addAll([
          _buildTextField('interface', 'Interface'),
          SizedBox(height: 12),
          _buildNumberField('capacity', 'Capacity (GB)'),
        ]);
        break;
      
      case 'psu':
        fields.addAll([
          _buildNumberField('wattage', 'Wattage (W)'),
          SizedBox(height: 12),
          _buildTextField('formFactor', 'Form Factor'),
          SizedBox(height: 12),
          _buildTextField('efficiencyRating', 'Efficiency Rating'),
        ]);
        break;
      
      case 'case':
        fields.addAll([
          _buildTextField('formFactor', 'Form Factor'),
          SizedBox(height: 12),
          _buildNumberField('maxGpuLength', 'Max GPU Length (mm)'),
          SizedBox(height: 12),
          _buildNumberField('estimatedPower', 'Estimated Power (W)'),
        ]);
        break;
      
      case 'cooling':
        fields.addAll([
          _buildTextField('type', 'Type'),
          SizedBox(height: 12),
          _buildTextField('supportedSockets', 'Supported Sockets'),
        ]);
        break;
      
      default:
        fields.addAll([
          Text('Edit form for $_category coming soon...', 
               style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
        ]);
    }
    
    return fields;
  }

  Future<void> _saveChange() async {
    // Use values from text fields if provided, otherwise use current values
    String modelName = _controllers['modelName']!.text.isNotEmpty 
        ? _controllers['modelName']!.text 
        : _product.modelName;
    
    String brand = _controllers['brand']!.text.isNotEmpty 
        ? _controllers['brand']!.text 
        : _product.brand;
    
    int price = _controllers['price']!.text.isNotEmpty 
        ? int.tryParse(_controllers['price']!.text) ?? _product.price
        : _product.price;

    if (modelName.isEmpty || brand.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Model Name and Brand are required!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      dynamic updatedProduct = _createUpdatedProduct();
      bool success = await _updateProductInDatabase(updatedProduct);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $_category updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          )
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update $_category'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        )
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  dynamic _createUpdatedProduct() {
    // Helper function to get value from controller or use current value
    dynamic getValue(String key, dynamic currentValue) {
      if (_controllers[key]!.text.isNotEmpty) {
        if (currentValue is int) {
          return int.tryParse(_controllers[key]!.text) ?? currentValue;
        } else if (currentValue is double) {
          return double.tryParse(_controllers[key]!.text) ?? currentValue;
        } else {
          return _controllers[key]!.text;
        }
      }
      return currentValue;
    }

    switch (_category) {
      case 'gpu':
        return GPU(
          id: widget.productId,
          modelName: getValue('modelName', _product.modelName),
          brand: getValue('brand', _product.brand),
          vram: getValue('vram', _product.vram),
          coreClock: getValue('coreClock', _product.coreClock),
          boostClock: getValue('boostClock', _product.boostClock),
          tdp: getValue('tdp', _product.tdp),
          length: getValue('length', _product.length),
          price: getValue('price', _product.price),
          imageURL: _product.imageURL, // Keep existing image
        );
      
      case 'cpu':
        return CPU(
          id: widget.productId,
          modelName: getValue('modelName', _product.modelName),
          brand: getValue('brand', _product.brand),
          socket: getValue('socket', _product.socket),
          cores: getValue('cores', _product.cores),
          threads: getValue('threads', _product.threads),
          baseClock: getValue('baseClock', _product.baseClock),
          boostClock: getValue('boostClock', _product.boostClock),
          tdp: getValue('tdp', _product.tdp),
          integratedGraphics: getValue('integratedGraphics', _product.integratedGraphics),
          price: getValue('price', _product.price),
          imageURL: _product.imageURL,
        );
      
      // Add other categories similarly...
      default:
        return null;
    }
  }

  Future<bool> _updateProductInDatabase(dynamic updatedProduct) async {
    if (updatedProduct == null) return false;

    switch (_category) {
      case 'cpu':
        return (await CPUService.updateCPU(updatedProduct)) > 0;
      case 'gpu':
        return (await GPUService.updateGPU(updatedProduct)) > 0;
      case 'cooling':
        return (await CoolingService.updateCooling(updatedProduct)) > 0;
      case 'ram':
        return (await RAMService.updateRAM(updatedProduct)) > 0;
      case 'motherboard':
        return (await MotherboardService.updateMotherboard(updatedProduct)) > 0;
      case 'case':
        return (await CaseService.updateCase(updatedProduct)) > 0;
      case 'psu':
        return (await PSUService.updatePSU(updatedProduct)) > 0;
      case 'storage':
        return (await StorageService.updateStorage(updatedProduct)) > 0;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Dialog(
            child: Container(
              padding: EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Loading product data...', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          )
        : _product == null
            ? AlertDialog(
                title: Text('Product Not Found', style: TextStyle(color: Colors.red)),
                content: Text('The requested product could not be found.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              )
            : _buildForm();
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }
}