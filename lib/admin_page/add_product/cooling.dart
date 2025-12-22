import 'dart:io';
import 'package:assemblex/admin_page/admininterface/admin_appbar.dart';
import 'package:assemblex/admin_page/admininterface/admin_bottom_navbar.dart';
import 'package:assemblex/services/cooling_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class pageCooling extends StatefulWidget {
  const pageCooling({super.key});

  @override
  State<pageCooling> createState() => _pageCoolingState();
}

class _pageCoolingState extends State<pageCooling> {
  String? _selectedType;
  File? _coolerImage;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _supportedSocketsController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _coolerImage = File(pickedImage.path);
      });
    }
  }
  
Future<void> _saveCooling() async{
  if(_nameController.text.isEmpty ||
  _supportedSocketsController.text.isEmpty ||
  _priceController.text.isEmpty ||
  _selectedType == null||
  _coolerImage == null )
  {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PLease fill all the field')));
  }
  setState(() {
    _isSaving = true;
  });
  void clearform(){
   _nameController.clear();
   _priceController.clear();
   _supportedSocketsController.clear();
   setState(() {
     _coolerImage =null;
     _selectedType =null;

   });
}
  try{
    String imagePath;
      
      if (_coolerImage != null)  {
        // Generate unique filename for each new case
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'case_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imagePath = (await _coolerImage!.copy('${appDir.path}/$fileName')).path;
      } else {
        // Use default image if no image selected
        imagePath = 'assets/images/caseimages/default_case.png';
      }

    Cooling newcooler = Cooling(
      modelName: _nameController.text,
       type: _selectedType!, 
       supportedSockets: _supportedSocketsController.text,
        price: int.parse(_priceController.text), 
        imageURL: imagePath);
        int newid = await CoolingService.insertCooling(newcooler);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cooler has been saved on id $newid')));
        clearform();
  
}
  catch(e){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error occured: $e')));
    
  }finally{
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
                      "Add Detail's of the Cooling",
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
                        child: _coolerImage != null
                            ? Image.file(_coolerImage!, fit: BoxFit.cover)
                            : const Icon(Icons.add_a_photo,
                                size: 50, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      style:TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: "Cooling Name",
                        hintStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.ac_unit),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.type_specimen),
                        hintText: "Select Type",
                      ),
                      initialValue: _selectedType,
                       style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat'
                          ),
                      items: ["Air Cooler", "Liquid Cooler"].map((type) {
                        return DropdownMenuItem(
                            value: type, child: Text(type,style: const TextStyle(color: Colors.black, fontSize: 16)));
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
              controller: _supportedSocketsController,
              decoration: InputDecoration(
                hintText: "Supported Sockets (comma-separated, e.g., AM5, LGA1700)",
                hintStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.fit_screen),
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
                      onPressed:  _isSaving ? null : _saveCooling,
                      child:  _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        "Save Cooling",
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
