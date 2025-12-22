import 'package:assemblex/admin_page/admininterface/admin_appbar.dart';
import 'package:flutter/material.dart';

class EditAdmin extends StatelessWidget {
  const EditAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(leading: true),
    );
  }
}