import 'package:assemblex/services/database_service.dart';
import 'package:assemblex/user_page/user_profile.dart';
import 'package:assemblex/user_page/userinterface/appbar.dart';
import 'package:flutter/material.dart';
import 'package:assemblex/user_page/userinterface/bottom_nav_bar.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
   final _formKey = GlobalKey<FormState>();
   final TextEditingController _firstname =  TextEditingController();
    final TextEditingController _lastname =  TextEditingController();
    final TextEditingController _password=  TextEditingController();
    final TextEditingController _email =  TextEditingController();

   
File? _profileImage;

   Future<void> _pickimage() async{
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if(pickedFile != null){
      setState(() {
        _profileImage = File(pickedFile.path);

      });
    }
   }

   Future<void> _registerUser() async{
              final firstname =_firstname.text.trim();
              final lastname =_lastname.text.trim();
              final email =_email.text.trim();
              final password =_password.text.trim();
              
        if (firstname.isEmpty ||
        lastname.isEmpty ||
        email.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final db = DatabaseService.instance;
    // Check if email already exists before attempting insert
    final existing = await db.getUserByEmail(email);
    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email already registered')),
      );
      return;
    }
    try{
      await db.insertUser(
        firstname: firstname, 
        lastname: lastname, 
        email: email, 
        password: password,
        imageURL: _profileImage?.path ?? '',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration sucessfull'))
        );
         Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const UserProfile()),
         );
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );

    }
          }
  @override
  Widget build(BuildContext context) {
   
    return Scaffold(
        resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: UserAppBar(),
      body:Stack(
        children: [
          Padding(
          padding: const EdgeInsets.only(top:10.0),
          child: Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft:Radius.circular(30), topRight: Radius.circular(30))
            ),
            child: 
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Text("Register To Assemble_X ", 
                      style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold
                      )),
                     const SizedBox(height: 20),
                     Container(
                        
                        width: 350,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                         
                          borderRadius: BorderRadius.circular(30)
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                            children: [
                              SizedBox(
                                height: 100,
                                width: 240,
                                child: Image.asset('assets/images/logo.png')),
                              
                              GestureDetector(
                                  onTap: _pickimage,
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage: _profileImage != null
                                        ? FileImage(_profileImage!)
                                        : null,
                                    child: _profileImage == null
                                        ? const Icon(Icons.camera_alt,
                                            size: 30, color: Colors.black54)
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 20),
                              TextFormField(
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold
                                ),
                                controller: _firstname,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(50)
                                  ),
                                  prefixIcon: const Icon(Icons.person),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16
                                  ),
                                  hintText: 'Enter your First Name ',
                                  hintStyle: TextStyle(
                                   fontSize: 16,
                                   fontWeight: FontWeight.bold
                                  )
                              ),
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty) return 'First name is required';
                                  if (v.length < 2) return 'First name must be at least 2 characters';
                                  return null;
                                },
                            ),
                            const SizedBox( height: 20),
                            TextFormField(
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold
                                ),
                              controller: _lastname,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50)
                                ),
                                prefixIcon: const Icon(Icons.person),
                                contentPadding: const EdgeInsets.symmetric(
                              
                                  horizontal: 16
                                ),
                                hintText: 'Enter your Last Name ',
                                hintStyle: TextStyle(
                                 fontSize: 16,
                                 fontWeight: FontWeight.bold
                                )
                              ),
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty) return 'Last name is required';
                                  if (v.length < 2) return 'Last name must be at least 2 characters';
                                  return null;
                                },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold
                                ),
                              controller: _email,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50)
                                ),
                                prefixIcon: const Icon(Icons.email),
                                contentPadding: const EdgeInsets.symmetric(
                              
                                  horizontal: 16
                                ),
                                hintText: 'Enter your Email ',
                                hintStyle: TextStyle(
                                 fontSize: 16,
                                 fontWeight: FontWeight.bold
                                )
                              ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty) return 'Email is required';
                                  final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.[A-Za-z]{2,}$');
                                  if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
                                  return null;
                                },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold
                                ),
                              controller: _password,
                              obscureText: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50)
                                ),
                                prefixIcon: const Icon(Icons.lock),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16
                                ),
                                hintText: 'Enter your password',
                                hintStyle: TextStyle(
                                 fontSize: 16,
                                 fontWeight: FontWeight.bold
                                )
                              ),
                                validator: (value) {
                                  final v = value?.trim() ?? '';
                                  if (v.isEmpty) return 'Password is required';
                                  if (v.length < 6) return 'Password must be at least 6 characters';
                                  return null;
                                },
                            ),
                            const SizedBox(height: 20),
                            Text('Already Have an Account? ', 
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold
                            )),
                           
                           TextButton(onPressed: (){
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context){
                                  return UserProfile();
                                })
                              );
                           }, child: Text("Log In",
                           style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold
                           ),
                           )),
                           
                           Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            child: TextButton(onPressed: () async{
                               if(_formKey.currentState!.validate()){
                                 await _registerUser();
                               }
                            }, child: 
                            Text('Register',
                            style: TextStyle(color: Colors.white,
                             fontSize: 16,
                              fontWeight: FontWeight.bold ),
                            ),
                       
                            )
                           ),
                          
                            ],
                          ),
                          ),
                        ),
                     ),
                    ],
                  ),
                ),
              ),
              
              
            ),
            BottomNavBar(
                selectedindex: 3,
              )
        ])
          
    
        
      );
    
  }
}