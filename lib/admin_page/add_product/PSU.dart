import 'dart:io';
import 'package:assemblex/admin_page/admininterface/admin_appbar.dart';
import 'package:assemblex/admin_page/admininterface/admin_bottom_navbar.dart';
import 'package:assemblex/services/psu_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class pagePSU extends StatefulWidget {
  const pagePSU({super.key});

  @override
  State<pagePSU> createState() => _pagePSUState();
}

class _pagePSUState extends State<pagePSU> {
  String? _selectedBrand;
  String? _selectedCertification;
    String? _selectedFormFactor; 
  File? _psuImage;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _wattageController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _psuImage = File(pickedImage.path);
      });
    }
  }
  void _clearForm(){
    _nameController.clear();
    _wattageController.clear();
    _priceController.clear();
    setState(() {
      _selectedBrand =null;
      _selectedCertification = null;
      _psuImage =null;
      _selectedFormFactor =null;
    });
  }
  Future<void> _savePSU()async{
    if(_nameController.text.isEmpty ||
    _wattageController.text.isEmpty ||
    _priceController.text.isEmpty ||
    _selectedBrand == null ||
    _psuImage == null||
    _selectedCertification == null ||
    _selectedFormFactor == null){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter all the field')));
    }
    else{
       setState(() {
      _isSaving = true;
    });
      try{
         String imagePath;
      
      if (_psuImage != null)  {
        // Generate unique filename for each new case
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'case_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imagePath = (await _psuImage!.copy('${appDir.path}/$fileName')).path;
      } else {
        // Use default image if no image selected
        imagePath = 'assets/images/caseimages/default_cpu.png';
      }
      PSU psu = PSU(
        modelName: _nameController.text, 
        brand: _selectedBrand!,
         wattage:int.parse(_wattageController.text) ,
          formFactor: _selectedFormFactor!, 
          efficiencyRating: _selectedCertification!,
           price: int.parse(_priceController.text), 
           imageURL: imagePath);

        int newid =await PSUService.insertPSU(psu);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PSU has been sucessfully saved under id: $newid')));
        _clearForm();
      }
      catch(e){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error Saving PSU error: $e')));
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
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                child: Column(
                  children: [
                    const Text(
                      "Add Detail's of the PSU",
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
                        child: _psuImage != null
                            ? Image.file(_psuImage!, fit: BoxFit.cover)
                            : const Icon(Icons.add_a_photo,
                                size: 50, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: "PSU Name",
                        hintStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.electrical_services),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.branding_watermark),
                        hintText: "Select Brand",
                        hintStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      initialValue: _selectedBrand,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold),
                      items: ["Corsair", "EVGA", "Seasonic", "Cooler Master", "ASUS"]
                          .map((brand) {
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.aspect_ratio),
                hintText: "Form Factor",
                hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              initialValue: _selectedFormFactor,
              style: const TextStyle(color: Colors.black, fontSize: 18, fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
              items: ["ATX", "SFX", "SFX-L"].map((formFactor) { // Common PSU form factors
                return DropdownMenuItem(
                  value: formFactor,
                  child: Text(formFactor, style: const TextStyle(color: Colors.black, fontSize: 16)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFormFactor = value;
                });
              },
            ),
            const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.verified),
                        hintText: "Select Certification",
                        hintStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      initialValue: _selectedCertification,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold),
                      items: ["80+ Bronze", "80+ Silver", "80+ Gold", "80+ Platinum"]
                          .map((cert) {
                        return DropdownMenuItem(
                            value: cert,
                            child: Text(cert,
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 16)));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCertification = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _wattageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: "Wattage (W)",
                        hintStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.power),
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
                      onPressed: _isSaving ? null : _savePSU, // Disable when saving
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                        "Save PSU",
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
