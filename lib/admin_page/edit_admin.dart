import 'package:assemblex/admin_page/admininterface/admin_appbar.dart';
import 'package:assemblex/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqlite_api.dart';

class EditAdmin extends StatefulWidget {
  const EditAdmin({super.key});

  @override
  State<EditAdmin> createState() => _EditAdminState();
}

class _EditAdminState extends State<EditAdmin> {
  Map<String,dynamic>? adminData;

    @override
    void initState(){
      super.initState();
  loadAdminDetails();
    }
      Future<void> loadAdminDetails() async{
        final data = await DatabaseService.instance.getAdminById(1);
        setState(() {
          adminData = data;
          });
        }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(leading: true),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Padding(
        padding: const EdgeInsets.only(top :10.0),
        child: Container(
          height: double.infinity,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
          
            borderRadius: BorderRadius.only(topRight: Radius.circular(25), topLeft: Radius.circular(25))
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                  Center(
                    child: Text("Edit Admin",
                    style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  height: 500,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                    
                      color: Colors.black
                    ),
                  borderRadius:BorderRadius.circular(30)
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Center(
                          child: Text("Admin Details",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Colors.black
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              adminDetails("First Name:", adminData!['firstname']),
                              const SizedBox( height: 10),
                              adminDetails("Last Name:",adminData!['lastname']),
                               const SizedBox( height: 10),
                              adminDetails("Email:",adminData!['email']),
                               const SizedBox( height: 10),
                              adminDetails("User Type:", adminData!['type']),
                               const SizedBox( height: 10),
                          

                            ],
                          ) 
                        )
                      ],
                    ),
                  ),
                ),
              )
              ],
            ),
          )
          ),
      )
    );
  }
}

Widget adminDetails( String title, String context){
  return Row(
                        children: [
                          Text(title, 
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold
                          ),
                          ),
                        const SizedBox(width: 20),
                        Text(context, 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20
                        ),
                        )
                        ],
                      );

}