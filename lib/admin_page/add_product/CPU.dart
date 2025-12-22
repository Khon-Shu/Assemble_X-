import 'dart:io';
import 'package:assemblex/admin_page/admininterface/admin_appbar.dart';
import 'package:assemblex/admin_page/admininterface/admin_bottom_navbar.dart';
import 'package:assemblex/services/cpu_service.dart'; // Import the CPU service
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class pageCPU extends StatefulWidget {
  const pageCPU({super.key});

  @override
  State<pageCPU> createState() => _pageCPUState();
}

class _pageCPUState extends State<pageCPU> {
  String? _selectedBrand;
  bool? _hasIntegratedGraphics;
  File? _cpuImage;
  bool _isSaving = false; // Added loading state

  // TextEditingControllers for all fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _socketController = TextEditingController();
  final TextEditingController _coresController = TextEditingController();
  final TextEditingController _threadsController = TextEditingController();
  final TextEditingController _baseClockController = TextEditingController();
  final TextEditingController _boostClockController = TextEditingController();
  final TextEditingController _tdpController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _cpuImage = File(pickedImage.path);
      });
    }
  }

  // Function to save CPU data to database
  Future<void> _saveCPU() async {
    // Validate required fields
    if (_nameController.text.isEmpty ||
        _socketController.text.isEmpty ||
        _coresController.text.isEmpty ||
        _threadsController.text.isEmpty ||
        _baseClockController.text.isEmpty ||
        _boostClockController.text.isEmpty ||
        _tdpController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _selectedBrand == null ||
        _hasIntegratedGraphics == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
       String imagePath;
      
      if (_cpuImage != null)  {
        // Generate unique filename for each new case
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'case_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imagePath = (await _cpuImage!.copy('${appDir.path}/$fileName')).path;
      } else {
        // Use default image if no image selected
        imagePath = 'assets/images/caseimages/default_cpu.png';
      }
      
      // Convert boolean to integer (true = 1, false = 0)
      int integratedGraphicsInt = _hasIntegratedGraphics! ? 1 : 0;
      
      // Create CPU object from form data
      CPU newCPU = CPU(
        modelName: _nameController.text,
        brand: _selectedBrand!,
        socket: _socketController.text,
        cores: int.parse(_coresController.text),
        threads: int.parse(_threadsController.text),
        baseClock: double.parse(_baseClockController.text),
        boostClock: double.parse(_boostClockController.text),
        tdp: int.parse(_tdpController.text),
        integratedGraphics: integratedGraphicsInt,
        price: int.parse(_priceController.text),
        imageURL: imagePath,
      );

      // Save to database
      int newId = await CPUService.insertCPU(newCPU);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CPU saved successfully! ID: $newId')),
      );

      // Clear the form
      _clearForm();

    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving CPU: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Function to clear the form
  void _clearForm() {
    _nameController.clear();
    _socketController.clear();
    _coresController.clear();
    _threadsController.clear();
    _baseClockController.clear();
    _boostClockController.clear();
    _tdpController.clear();
    _priceController.clear();
    setState(() {
      _selectedBrand = null;
      _hasIntegratedGraphics = null;
      _cpuImage = null;
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
              height: double.infinity,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Add Detail\'s of the CPU',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
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
                          child: _cpuImage != null
                              ? Image.file(_cpuImage!, fit: BoxFit.cover)
                              : const Icon(
                                  Icons.add_a_photo,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: "CPU Name",
                          hintStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          prefixIcon: const Icon(Icons.memory),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          prefixIcon: const Icon(Icons.branding_watermark),
                          hintText: 'Select Brand',
                          hintStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        initialValue: _selectedBrand,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                        ),
                        items: ['Intel', 'AMD'].map((brand) {
                          return DropdownMenuItem(
                            value: brand,
                            child: Text(
                              brand,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBrand = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<bool>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          prefixIcon: const Icon(Icons.graphic_eq),
                          hintText: 'Integrated Graphics',
                          hintStyle: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        initialValue: _hasIntegratedGraphics,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: true,
                            child: Text(
                              'Yes',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Text(
                              'No',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _hasIntegratedGraphics = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        controller: _socketController,
                        decoration: InputDecoration(
                          hintText: "Socket",
                          hintStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          prefixIcon: const Icon(Icons.dns),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        controller: _coresController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: "Cores",
                          hintStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          prefixIcon: const Icon(Icons.blur_circular),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        controller: _threadsController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: "Threads",
                          hintStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          prefixIcon: const Icon(Icons.sync_alt),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        controller: _baseClockController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: InputDecoration(
                          hintText: "Base Clock (GHz)",
                          hintStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          prefixIcon: const Icon(Icons.speed),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        controller: _boostClockController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: InputDecoration(
                          hintText: "Boost Clock (GHz)",
                          hintStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          prefixIcon: const Icon(Icons.flash_on),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        controller: _tdpController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: "TDP (watts)",
                          hintStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          prefixIcon: const Icon(Icons.bolt),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: "Price",
                          hintStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          prefixIcon: const Icon(Icons.attach_money_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.green),
                          minimumSize: WidgetStatePropertyAll(Size(200, 50)),
                        ),
                        onPressed: _isSaving ? null : _saveCPU, // Disable when saving
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Save CPU",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                       const SizedBox(height: 10),
                   
                      
                    ],
                  ),
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