import 'package:assemblex/user_page/tabbar/build.dart';
import 'package:assemblex/user_page/save_build.dart';
import 'package:assemblex/user_page/userinterface/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class PcBuild extends StatefulWidget {
  const PcBuild({super.key});

  @override
  State<PcBuild> createState() => _PcBuildState();
}

class _PcBuildState extends State<PcBuild> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // number of tabs
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        appBar: AppBar(
      automaticallyImplyLeading: false, // optional, keeps back button
      backgroundColor: Theme.of(context).colorScheme.primary,
      elevation: 0,
      title: Row(
        children: [
          Image.asset('assets/images/logomain.png', height: 50),
          const SizedBox(width: 10),
          Text(
            'Assemble_X',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 253, 253, 253),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: 60,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.secondary,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications, color: Colors.white),
            ),
          ),
        )
          ],
          bottom: TabBar(
  indicatorColor: Colors.white, // underline color
  indicatorWeight: 4.0, // underline thickness
  labelColor: Colors.white,
  unselectedLabelColor: Colors.white70,

  dividerColor: Colors.transparent, // ✅ REMOVES BOTTOM LINE COMPLETELY

  tabs: const [
    Tab(icon: Icon(Icons.computer), text: "Build PC"),
    Tab(icon: Icon(Icons.settings), text: "View Saved PC"),
  ],
),

        ),
       body: Stack(
  children: [
    Container(
      height: 180, // ✅ Controls where the curve ends
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
    ),

    // ✅ WHITE CONTENT AREA WITH CURVE ON TOP
    Column(
      children: [
        const SizedBox(height: 12), // small spacing from tabbar

        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: const TabBarView(
              children: [
                buildPC(),
                ViewSaveBuild(),
              ],
            ),
          ),
        ),
      ],
    ),

    // ✅ BOTTOM NAV
    BottomNavBar(selectedindex: 1),
  ],
),

      ),
    );
  }
}
