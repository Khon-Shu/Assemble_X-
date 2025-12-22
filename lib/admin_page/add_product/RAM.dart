import 'dart:io';
import 'package:assemblex/admin_page/admininterface/admin_appbar.dart';
import 'package:assemblex/admin_page/admininterface/admin_bottom_navbar.dart';
import 'package:assemblex/services/ram_service.dart'; // Import RAM service
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class pageRAM extends StatefulWidget {
  const pageRAM({super.key});

  @override
  State<pageRAM> createState() => _pageRAMState();
}

class _pageRAMState extends State<pageRAM> {
  String? _selectedType;
  File? _ramImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _speedController = TextEditingController();
  final TextEditingController _modulesController = TextEditingController(); // Added for modules
  final TextEditingController _priceController = TextEditingController();

  Future<void> pickImage() async {
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _ramImage = File(pickedImage.path);
      });
    }
  }

  // Function to save RAM to database
  Future<void> _saveRAM() async {
    if (_selectedType == null || _nameController.text.isEmpty) {
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
      
      if (_ramImage != null)  {
        // Generate unique filename for each new case
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'case_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imagePath = (await _ramImage!.copy('${appDir.path}/$fileName')).path;
      } else {
        // Use default image if no image selected
        imagePath = 'assets/images/caseimages/default_cpu.png';
      }
      // Create RAM object
      final ram = RAM(
        modelName: _nameController.text,
        memoryType: _selectedType!,
        capacity: int.parse(_capacityController.text),
        speed: int.parse(_speedController.text),
        modules: int.parse(_modulesController.text), // Get modules from controller
        price: int.parse(_priceController.text),
        imageURL: imagePath // Store image path or empty string
      );

      // Insert into database
      final id = await RAMService.insertRAM(ram);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('RAM saved successfully! ID: $id')),
      );

      // Clear form after successful save
      _clearForm();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving RAM: $e')),
      );
    }
    finally{
      setState(() {
        _isSaving = false;
      });
    }
  }

  // Function to clear the form
  void _clearForm() {
    _nameController.clear();
    _capacityController.clear();
    _speedController.clear();
    _modulesController.clear();
    _priceController.clear();
    setState(() {
      _selectedType = null;
      _ramImage = null;
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
                      "Add Detail's of the RAM",
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
                        child: _ramImage != null
                            ? Image.file(_ramImage!, fit: BoxFit.cover)
                            : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: "RAM Name ",
                        hintStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.memory),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.sd_storage),
                        hintText: "Select RAM Type",
                        hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      initialValue: _selectedType,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: "Montserrat",
                          fontWeight: FontWeight.bold),
                      items: ["DDR4", "DDR5"].map((type) { // Removed DDR3
                        return DropdownMenuItem(
                            value: type,
                            child: Text(type, style: const TextStyle(color: Colors.black, fontSize: 16)));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
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
                        hintText: "Total Capacity (GB)",
                        hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.storage),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _speedController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: "Speed (MHz)",
                        hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.speed),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField( 
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),// Added modules field
                      controller: _modulesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: "Number of Modules (e.g., 2)",
                        hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.view_array),
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
                      onPressed: _isSaving? null: _saveRAM, // Changed to call _saveRAM function
                       child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                        "Save RAM",
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