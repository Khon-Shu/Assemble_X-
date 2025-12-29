import 'package:assemblex/admin_page/admininterface/admin_appbar.dart';
import 'package:flutter/material.dart';

class EditAdmin extends StatelessWidget {
  const EditAdmin({super.key});

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
              Container(
                height: 500,
                width: double.infinity,
                decoration: BoxDecoration(
                
                  border: Border.all(
                  
                    color: Colors.black
                  ),
                borderRadius:BorderRadius.circular(30)
                ),
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
                      child: Row(
                        children: [
                          Text("User Name")
                        ],
                      ),
                    )
                  ],
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