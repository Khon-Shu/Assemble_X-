import 'dart:io';
import 'package:assemblex/admin_page/admininterface/admin_appbar.dart';
import 'package:assemblex/admin_page/admininterface/admin_bottom_navbar.dart';
import 'package:assemblex/services/motherboard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class pageMotherboard extends StatefulWidget {
  const pageMotherboard({super.key});

  @override
  State<pageMotherboard> createState() => _pageMotherboardState();
}

class _pageMotherboardState extends State<pageMotherboard> {
  String? _selectedBrand;
  String? _selectedFormFactor;
  File? _motherboardImage;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _socketController = TextEditingController();
  final TextEditingController _chipsetController = TextEditingController();
  final TextEditingController _memorySlotsController = TextEditingController();
  final TextEditingController _maxMemoryController = TextEditingController();
  
  final TextEditingController _memorytypeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _motherboardImage = File(pickedImage.path);
      });
    }
  }
  void _clearForm(){
    _nameController.clear();
        _socketController.clear();
        _chipsetController.clear();
        _memorySlotsController.clear();
        _maxMemoryController.clear();
        _memorytypeController.clear();
        _priceController.clear();
        setState(() {
           _selectedBrand = null;
        _selectedFormFactor = null ;
        _motherboardImage = null;
        });
       
  }
  Future<void> _saveMotherboard()async{
    if(_nameController.text.isEmpty ||
        _socketController.text.isEmpty ||
        _chipsetController.text.isEmpty ||
        _memorySlotsController.text.isEmpty ||
        _maxMemoryController.text.isEmpty ||
        _memorytypeController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _selectedBrand == null||
        _selectedFormFactor == null ||
        _motherboardImage ==  null
    ){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all the field')));
      return;
    }
     setState(() {
      _isSaving = true;
    });{
    try{
      String imagePath;
      
      if (_motherboardImage != null)  {
        // Generate unique filename for each new case
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'case_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imagePath = (await _motherboardImage!.copy('${appDir.path}/$fileName')).path;
      } else {
        // Use default image if no image selected
        imagePath = 'assets/images/caseimages/default_cpu.png';
      }
      Motherboard motherboard = Motherboard
      (modelName: _nameController.text,
       brand: _selectedBrand!,
        socket: _socketController.text,
         chipset: _chipsetController.text, 
         formFactor: _selectedFormFactor!,
          memoryType: _memorytypeController.text, 
          memorySlots: int.parse(_memorySlotsController.text),
           maxMemory: int.parse(_maxMemoryController.text),
            price: int.parse(_priceController.text),
            imageURL: imagePath);
        int newId = await MotherboardService.insertMotherboard(motherboard);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Motherboard sucessfully saved under id : $newId')));
      _clearForm();
    }
    catch(e){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error occured saving the Motherboard $e')));
    }
    finally{
      setState(() {
        _isSaving = false;
      });
    }
  }
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
                    topRight: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                child: Column(
                  children: [
                    const Text(
                      "Add Detail's of the Motherboard",
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
                        child: _motherboardImage != null
                            ? Image.file(_motherboardImage!, fit: BoxFit.cover)
                            : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: "Motherboard Name",
                        hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.developer_board),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.branding_watermark),
                        hintText: "Select Brand",
                        hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black,fontFamily: 'Montserrat'),
                      ),
                      initialValue: _selectedBrand,
                      style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                      items: ["ASUS", "Gigabyte", "MSI", "ASRock"].map((brand) {
                        return DropdownMenuItem(
                            value: brand,
                            child: Text(brand, style: const TextStyle(color: Colors.black, fontSize: 16)));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBrand = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _socketController,
                      decoration: InputDecoration(
                        hintText: "CPU Socket",
                        hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.memory),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _chipsetController,
                      decoration: InputDecoration(
                        hintText: "Chipset",
                        hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.settings),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.aspect_ratio),
                        hintText: "Select Form Factor",
                        hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black, fontFamily: "Montserrat"),
                      ),
                      initialValue: _selectedFormFactor,
                      style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                      items: ["ATX", "Micro-ATX", "Mini-ITX"].map((type) {
                        return DropdownMenuItem(
                            value: type,
                            child: Text(type, style: const TextStyle(color: Colors.black, fontSize: 16)));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFormFactor = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                     TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // ADDED TextField for Memory Type
              controller: _memorytypeController,
              decoration: InputDecoration(
                hintText: "Memory Type ",
                hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.memory),
              ),
            ),
            const SizedBox(height: 10),
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _memorySlotsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: "Memory Slots",
                        hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.view_array),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _maxMemoryController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: "Max Memory (GB)",
                        hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.sd_storage),
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
                      onPressed: _isSaving ? null : _saveMotherboard, // Disable when saving
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                        "Save Motherboard",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
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
