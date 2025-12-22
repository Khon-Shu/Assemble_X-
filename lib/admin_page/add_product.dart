import 'package:assemblex/admin_page/add_product/CPU.dart';
import 'package:assemblex/admin_page/add_product/GPU.dart';
import 'package:assemblex/admin_page/add_product/PSU.dart';
import 'package:assemblex/admin_page/add_product/RAM.dart';
import 'package:assemblex/admin_page/add_product/case.dart';
import 'package:assemblex/admin_page/add_product/cooling.dart';
import 'package:assemblex/admin_page/add_product/motherboard.dart';
import 'package:assemblex/admin_page/add_product/storage.dart';
import 'package:assemblex/admin_page/admininterface/admin_appbar.dart';
import 'package:assemblex/admin_page/admininterface/admin_bottom_navbar.dart';
import 'package:flutter/material.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define tiles
    final List<Widget> tiles = [
      _addProductItems(context, Icons.memory, "CPU", pageCPU(), 0, Colors.purple.shade400, const Color.fromARGB(255, 249, 213, 255)),
      _addProductItems(context, Icons.sports_esports, "GPU", pageGPU(), 1, Colors.amber,
          const Color.fromARGB(255, 255, 246, 148)),
      _addProductItems(context, Icons.developer_board, "Motherboard", pageMotherboard(), 2,
         Colors.purple.shade400, const Color.fromARGB(255, 249, 213, 255)),
      _addProductItems(context, Icons.storage, "RAM", pageRAM(), 3, Colors.amber,
          const Color.fromARGB(255, 255, 246, 148)),
      _addProductItems(context, Icons.power, "Power Supply", pagePSU(), 4,Colors.purple.shade400, const Color.fromARGB(255, 249, 213, 255)),
      _addProductItems(context, Icons.save, "Storage", pageStorage(), 5, Colors.amber,
          const Color.fromARGB(255, 255, 246, 148)),
      _addProductItems(context, Icons.desktop_windows, "Case", pageCase(), 6,Colors.purple.shade400, const Color.fromARGB(255, 249, 213, 255)),
      _addProductItems(context, Icons.ac_unit, "Cooling", pageCooling(), 7, Colors.amber,
          const Color.fromARGB(255, 255, 246, 148)),
          
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: CustomAppBar(leading: false),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Add Product',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[900],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Divider(thickness: 2, color: Colors.black),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16,16,16,60),
                          child: ListView.builder(
                            itemCount: (tiles.length / 2).ceil(),
                            itemBuilder: (context, rowIndex) {
                              final firstIndex = rowIndex * 2;
                              final secondIndex = firstIndex + 1;

                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: tiles[firstIndex]),
                                      // Vertical Divider
                                      if (secondIndex < tiles.length)
                                        Container(
                                          width: 2,
                                          height: 120, // adjust height as needed
                                          color: Colors.black,
                                          margin: const EdgeInsets.symmetric(horizontal: 8),
                                        ),
                                      if (secondIndex < tiles.length)
                                        Expanded(child: tiles[secondIndex])
                                      else
                                        const Expanded(child: SizedBox()),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Horizontal Divider
                                  const Divider(thickness: 2, color: Colors.black),
                                  const SizedBox(height: 16),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: AdminBottomNavBar(selectedindex: 1),
          ),
        ],
      ),
    );
  }
}

Widget _addProductItems(BuildContext context, IconData icon, String label, Widget page,
    int index, Color iconColors, Color opactityColor) {
  return TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.0, end: 1.0),
    duration: Duration(milliseconds: 400 + (index * 100)),
    curve: Curves.easeOut,
    builder: (context, value, child) {
      return Opacity(
        opacity: value,
        child: Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => page,
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: opactityColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 48,
                          color: iconColors,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey[900],
                          letterSpacing: 0.3,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
