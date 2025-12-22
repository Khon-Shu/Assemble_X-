import 'dart:io';
import 'package:assemblex/admin_page/admininterface/admin_appbar.dart';
import 'package:assemblex/admin_page/admininterface/admin_bottom_navbar.dart';
import 'package:assemblex/services/case_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // ADD THIS IMPORT

class pageCase extends StatefulWidget {
  const pageCase({super.key});

  @override
  State<pageCase> createState() => _pageCaseState();
}

class _pageCaseState extends State<pageCase> {
  String? _selectedBrand;
  String? _selectedFormFactor;
  File? _caseImage;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _maxGPUlengthController = TextEditingController();
  final TextEditingController _wattageController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _caseImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _saveCase() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _maxGPUlengthController.text.isEmpty ||
        _wattageController.text.isEmpty ||
        _selectedBrand == null ||
        _selectedFormFactor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all the required fields')),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });

    try {
      String imagePath;
      
      if (_caseImage != null) {
        // Generate unique filename for each new case
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'case_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imagePath = (await _caseImage!.copy('${appDir.path}/$fileName')).path;
      } else {
        // Use default image if no image selected
        imagePath = 'assets/images/caseimages/default_case.png';
      }

      // Map tower type to supported motherboard form factors for compatibility checks
      String mappedFormFactor;
      switch (_selectedFormFactor) {
        case 'Full-Tower':
          mappedFormFactor = 'E-ATX, ATX, Micro ATX, Mini ITX';
          break;
        case 'Mid-Tower':
          mappedFormFactor = 'ATX, Micro ATX, Mini ITX';
          break;
        case 'Mini-Tower':
          mappedFormFactor = 'Micro ATX, Mini ITX';
          break;
        default:
          mappedFormFactor = _selectedFormFactor!;
      }

      Case newCase = Case(
        modelName: _nameController.text,
        brand: _selectedBrand!,
        formFactor: mappedFormFactor,
        maxGpuLength: int.parse(_maxGPUlengthController.text),
        estimatedPower: int.parse(_wattageController.text),
        price: int.parse(_priceController.text),
        imageURL: imagePath, // Use the proper image path
      );
      
      int newId = await CaseService.insertCase(newCase);

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Case has been successfully saved with the id: $newId $imagePath')));

      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to Save the Case: $e')));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    _maxGPUlengthController.clear();
    _wattageController.clear();
    setState(() {
      _selectedBrand = null;
      _caseImage = null;
      _selectedFormFactor = null;
    });
  }
    


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: CustomAppBar(leading: true),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                child: Column(
                  children: [
                    const Text(
                      "Add Detail's of the Case",
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: _caseImage != null
                            ? Image.file(_caseImage!, fit: BoxFit.cover)
                            : const Icon(Icons.add_a_photo,
                                size: 50, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: "Case Name",
                        hintStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.devices),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.branding_watermark),
                        hintText: "Select Brand",
                      ),
                      initialValue: _selectedBrand,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat'),
                      items: [
                        "NZXT",
                        "Corsair",
                        "Cooler Master",
                        "Lian Li",
                        "Fractal Design",
                        "Phanteks",
                        "Asus"
                      ].map((brand) {
                        return DropdownMenuItem(
                            value: brand,
                            child: Text(brand,
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 16)));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBrand = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.view_module),
                        hintText: "Primary Form Factor",
                      ),
                      initialValue: _selectedFormFactor,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat'),
                      items: ["Full-Tower", "Mid-Tower", "Mini-Tower"].map((form) {
                        return DropdownMenuItem(
                            value: form,
                            child: Text(form,
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 16)));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFormFactor = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _maxGPUlengthController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: "Max GPU Length (mm)",
                        hintStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.straighten),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _wattageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: "Estimated Power Draw (W)",
                        hintStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.power), // Changed icon to power
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: "Price",
                        hintStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: const ButtonStyle(
                          backgroundColor:
                              WidgetStatePropertyAll(Colors.green)),
                      onPressed: _isSaving ? null : _saveCase,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Save Case",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white),
                            ),
                    ),
                     const SizedBox(height: 10),
                    
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: AdminBottomNavBar(selectedindex: 1),
          ),
        ],
      ),
    );
  }
}