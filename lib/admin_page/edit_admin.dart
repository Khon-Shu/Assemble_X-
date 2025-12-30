import 'package:assemblex/admin_page/admininterface/admin_appbar.dart';
import 'package:assemblex/services/database_service.dart';
import 'package:flutter/material.dart';

class EditAdmin extends StatefulWidget {
  const EditAdmin({super.key});

  @override
  State<EditAdmin> createState() => _EditAdminState();
}

class _EditAdminState extends State<EditAdmin> {
  Map<String, dynamic>? adminData;

  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    loadAdminDetails();
  }

  Future<void> loadAdminDetails() async {
    final data = await DatabaseService.instance.getAdminById(1);

    firstNameController =
        TextEditingController(text: data!['firstname']);
    lastNameController =
        TextEditingController(text: data!['lastname']);
    emailController =
        TextEditingController(text: data!['email']);
    passwordController = TextEditingController();

    setState(() {
      adminData = data;
    });
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (adminData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(leading: true),
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "Edit Admin",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),

                /// Admin details box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Admin Details",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      adminDetails("First Name:", adminData!['firstname']),
                      adminDetails("Last Name:", adminData!['lastname']),
                      adminDetails("Email:", adminData!['email']),
                      adminDetails("User Type:", adminData!['type']),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => adminAlertDialog(
                              parentContext: context,
                              firstNameController: firstNameController,
                              lastNameController: lastNameController,
                              emailController: emailController,
                              passwordController: passwordController,
                              onSaved: loadAdminDetails,
                            ),
                          );
                        },
                        child: const Text(
                          "Edit Admin Profile",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
Widget adminDetails(String title, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ],
    ),
  );
}
Widget adminAlertDialog({
  required BuildContext parentContext,
  required TextEditingController firstNameController,
  required TextEditingController lastNameController,
  required TextEditingController emailController,
  required TextEditingController passwordController,
  required VoidCallback onSaved,
}) {
  return AlertDialog(
    title: const Text("Edit Admin Information"),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: firstNameController,
            decoration: const InputDecoration(labelText: "First Name"),
          ),
          TextField(
            controller: lastNameController,
            decoration: const InputDecoration(labelText: "Last Name"),
          ),
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: "Email"),
          ),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "New Password (optional)",
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(parentContext),
        child: const Text("Cancel"),
      ),
      ElevatedButton(
        onPressed: () async {
          try {
            await DatabaseService.instance.updateAdmin(
              id: 1,
              firstname: firstNameController.text,
              lastname: lastNameController.text,
              email: emailController.text,
              password: passwordController.text.isEmpty
                  ? null
                  : passwordController.text,
            );

            passwordController.clear();
            Navigator.pop(parentContext);
            onSaved();

            ScaffoldMessenger.of(parentContext).showSnackBar(
              const SnackBar(
                content: Text("Successfully updated admin info"),
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              const SnackBar(
                content: Text("Error saving data"),
              ),
            );
          }
        },
        child: const Text("Save"),
      ),
    ],
  );
}
