import 'package:assemblex/user_page/about%20us%20page/aboutapp.dart';
import 'package:assemblex/user_page/about%20us%20page/location.dart';
import 'package:assemblex/user_page/userinterface/appbar.dart';
import 'package:assemblex/user_page/userinterface/bottom_nav_bar.dart';
import 'package:flutter/material.dart';

class AboutUS extends StatelessWidget {
  const AboutUS({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: UserAppBar(),

      body: Stack(
        children: [
         
          Container(
            height: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
          ),

          // ✅ MAIN CONTENT
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                

                  // ✅ TITLE
                  Center(
                    child: Text(
                      'About Us',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // ✅ TAB BAR (NO LINE UNDER IT)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TabBar(
                      indicatorColor:
                          Theme.of(context).colorScheme.secondary,
                      indicatorWeight: 4,
                      labelColor: Theme.of(context).colorScheme.secondary,
                      unselectedLabelColor: Colors.grey,
                      dividerColor: Colors.transparent, // ✅ REMOVES DEFAULT TAB LINE
                      tabs: const [
                        Tab(text: "Assemble X"),
                        Tab(text: "Location"),
                      ],
                    ),
                  ),

                   SizedBox(height: 8), // tighter gap
                  Container(
                    height: 670,
                  width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration:  BoxDecoration(
                      color: Colors.white,
                     borderRadius: BorderRadius.circular(25)
                    ),
                    child: const TabBarView(
                      children: [
                        Aboutapp(),
                        LocationPage(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ BOTTOM NAV
          BottomNavBar(selectedindex: 2),
        ],
      ),
    );
  }
}
