import 'dart:io';
import 'package:assemblex/admin_page/admininterface/admin_appbar.dart';
import 'package:assemblex/admin_page/admininterface/admin_bottom_navbar.dart';
import 'package:assemblex/services/storage_service.dart'; // Import Storage service
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class pageStorage extends StatefulWidget {
  const pageStorage({super.key});

  @override
  State<pageStorage> createState() => _pageStorageState();
}

class _pageStorageState extends State<pageStorage> {
  String? _selectedInterface;
  File? _storageImage;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  Future<void> pickImage() async {
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _storageImage = File(pickedImage.path);
      });
    }
  }

  // Function to save Storage to database
  Future<void> _saveStorage() async {
    if (_selectedInterface == null || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
        String imagePath;
      
      if (_storageImage != null)  {
        // Generate unique filename for each new case
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'case_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imagePath = (await _storageImage!.copy('${appDir.path}/$fileName')).path;
      } else {
        // Use default image if no image selected
        imagePath = 'assets/images/caseimages/default_cpu.png';
      }
      // Create Storage object
      final storage = Storage(
        modelName: _nameController.text,
        interface: _selectedInterface!,
        capacity: int.parse(_capacityController.text),
        price: int.parse(_priceController.text),
        imageURL: imagePath, // Store image path or empty string
      );

      // Insert into database
      final id = await StorageService.insertStorage(storage);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage saved successfully! ID: $id')),
      );

      // Clear form after successful save
      _clearForm();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving Storage: $e')),
      );
    }
  }

  // Function to clear the form
  void _clearForm() {
    _nameController.clear();
    _capacityController.clear();
    _priceController.clear();
    setState(() {
      _selectedInterface = null;
      _storageImage = null;
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
                    topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                child: Column(
                  children: [
                    const Text(
                      "Add Detail's of the Storage",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                        child: _storageImage != null
                            ? Image.file(_storageImage!, fit: BoxFit.cover)
                            : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: "Storage Name ",
                        hintStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.sd_storage),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.category),
                        hintText: "Select Interface",
                        hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      initialValue: _selectedInterface,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat'
                          ),
                      items: ["SATA III", "NVMe PCIe 3.0", "NVMe PCIe 4.0", "NVMe PCIe 5.0"].map((type) {
                        return DropdownMenuItem(
                            value: type,
                            child: Text(type, style: const TextStyle(color: Colors.black, fontSize: 16)));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedInterface = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: "Capacity (GB)",
                        hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.storage),
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
                        hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: const ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.green)),
                      onPressed: _saveStorage, // Changed to call _saveStorage function
                      child: const Text(
                        "Save Storage",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
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