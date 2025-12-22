import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserAppBar extends StatelessWidget implements PreferredSizeWidget {
  const UserAppBar({
    super.key,
    bool? leading,
  
    });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    bool leading = false;
 
    return AppBar(
      automaticallyImplyLeading: leading, // optional, keeps back button
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
      
    );
  }
}
