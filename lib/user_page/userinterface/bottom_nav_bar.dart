import 'package:assemblex/user_page/aboutus.dart';
import 'package:assemblex/user_page/pc_build.dart';
import 'package:flutter/material.dart';
import 'package:assemblex/user_page/userfrontpage.dart';
import 'package:assemblex/user_page/user_profile.dart';

class BottomNavBar extends StatefulWidget {
final int selectedindex;

  const BottomNavBar({
    super.key,
    this.selectedindex =0
    });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
   int _selectedindex=0; 


@override
  void initState() {

    super.initState();
    _selectedindex = widget.selectedindex;
  }
  void _onTapIcon(int index) {
    setState(() {
      _selectedindex = index;
    });

    Widget nextpage;
    switch(index){
      case 0:
      nextpage =  User_frontpage();
      break;
      case 1:
      nextpage =  PcBuild();
      break;
      case 2:
      nextpage =  AboutUS();
      break;
      case 3: 
      nextpage = const UserProfile();
      break;
      default:
      nextpage = const User_frontpage();
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder:(context)=>nextpage));
  }

   Widget _buildNavItem(IconData icon, int index) {
    final bool isSelected = _selectedindex == index;

    return  GestureDetector(
            onTap: () => _onTapIcon(index),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Theme.of(context).colorScheme.secondary : Colors.transparent,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[700],
                size: 24,
              ),
            )
    );
       
  }

  @override
  Widget build(BuildContext context) {
    return  Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 50),
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home, 0),
                    _buildNavItem(Icons.build, 1),
                    _buildNavItem(Icons.person_4_sharp, 2),
                    _buildNavItem(Icons.person, 3),
                  ],
                ),
              ),
            ),
          );
  }
}