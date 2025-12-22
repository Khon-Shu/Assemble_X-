import 'dart:io';
import 'package:assemblex/admin_page/admininterface/admin_appbar.dart';
import 'package:assemblex/admin_page/admininterface/admin_bottom_navbar.dart';
import 'package:assemblex/services/gpu_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';


class pageGPU extends StatefulWidget {
  const pageGPU({super.key});

  @override
  State<pageGPU> createState() => _pageGPUState();
}

class _pageGPUState extends State<pageGPU> {
  String? _selectedBrand;
  File? _gpuImage;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _vramController = TextEditingController();
  final TextEditingController _coreClockController = TextEditingController();
  final TextEditingController _boostClockController = TextEditingController();
  final TextEditingController _tdpController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _length = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _gpuImage = File(pickedImage.path);
      });
    }
  }
 void _clearForm() {
    _nameController.clear();
    _boostClockController.clear();
    _vramController.clear();
    _coreClockController.clear();
    _tdpController.clear();
    _priceController.clear();
    _length.clear();
    setState(() {
      _selectedBrand =null;
      _gpuImage =null;
    });
  }
  Future<void>  _saveGPU() async{
    if(_nameController.text.isEmpty ||
      _vramController.text.isEmpty ||
      _coreClockController.text.isEmpty ||
      _boostClockController.text.isEmpty ||
      _tdpController.text.isEmpty ||
      _priceController.text.isEmpty ||
      _length.text.isEmpty ||
      _selectedBrand == null||
      _gpuImage == null    
    ){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all the field')));
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try{
       String imagePath;
      
      if (_gpuImage != null)  {
        // Generate unique filename for each new case
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'case_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imagePath = (await _gpuImage!.copy('${appDir.path}/$fileName')).path;
      } else {
        // Use default image if no image selected
        imagePath = 'assets/images/caseimages/default_cpu.png';
      }
        GPU gpu =GPU(modelName: _nameController.text, 
        brand: _selectedBrand!, 
        vram: int.parse(_vramController.text),
         coreClock: double.parse(_coreClockController.text),
          boostClock: double.parse(_boostClockController.text),
           tdp: int.parse(_tdpController.text), 
           length: int.parse(_length.text), 
           price: int.parse(_priceController.text),
            imageURL: imagePath);
      int newId  = await GPUService.insertGPU(gpu);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Your GPU has been saved succesfully under id $newId')));
      _clearForm();

    }catch(e){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error Svaing your GPU $e')));
    }
    finally{
      setState(() {
        _isSaving = false;
      });
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
                      "Add Detail's of the GPU",
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
                        child: _gpuImage != null
                            ? Image.file(_gpuImage!, fit: BoxFit.cover)
                            : const Icon(Icons.add_a_photo,
                                size: 50, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: "GPU Name",
                        hintStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.graphic_eq),
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
                      items: ["NVIDIA", "AMD"].map((brand) {
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
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _vramController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: "VRAM (GB)",
                        hintStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.sd_storage),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _coreClockController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                      ],
                      decoration: InputDecoration(
                        hintText: "Core Clock (MHz)",
                          hintStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
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
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                      ],
                      decoration: InputDecoration(
                        hintText: "Boost Clock (MHz)",
                        hintStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.flash_on),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _tdpController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: "TDP (watts)",
                        hintStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.bolt),
                      ),
                    ),
                    const SizedBox(height: 10),
                     TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _length,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: "Length",
                        hintStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.bolt),
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
                      onPressed: _isSaving ? null : _saveGPU, // Disable when saving
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                     
                        "Save GPU",
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
