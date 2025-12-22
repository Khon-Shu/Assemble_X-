import 'package:flutter/material.dart';
import 'dart:async';

import 'package:assemblex/user_page/userfrontpage.dart';
import 'package:google_fonts/google_fonts.dart';

class AssembleX_home extends StatefulWidget {
  const AssembleX_home({super.key});

  @override
  State<AssembleX_home> createState() => _AssembleX_homeState();
}

class _AssembleX_homeState extends State<AssembleX_home> with TickerProviderStateMixin{

  final List<String> images =[
    "assets/images/home1.jpg",
    "assets/images/home4.png",
    "assets/images/home1.png",
  ];

 Timer? _timer;
 int currentindex = 0;
 late AnimationController _titleanimation;
late AnimationController _subtitleanimation;
late AnimationController _bottomnav;
late AnimationController _HomePagecontroller;
late Animation<double> _animation;
late AnimationController _travelcontroller;
late Animation<double> _scaleanimation;
bool _showarrow = true;
 @override
  void initState() {
    
    _timer = Timer.periodic(const Duration(milliseconds: 3500), (Timer t){
        setState(() {
          currentindex++;
          if( currentindex >= images.length){
            currentindex = 0;
          }
        });

    });
    _travelcontroller =AnimationController(
            vsync: this,
            duration: Duration(milliseconds: 500)
            );

  _scaleanimation =Tween<double>(begin: 1, end: 50).animate(_travelcontroller);
    _HomePagecontroller = AnimationController(
        vsync: this,
        duration:  Duration(milliseconds: 1500)
        );

    _animation = Tween<double>(begin: 0, end: 1).animate(_HomePagecontroller);
    _titleanimation= AnimationController(
          vsync: this , 
          duration: const Duration(milliseconds: 2000));

    _subtitleanimation =AnimationController(
      vsync: this,
      duration:  Duration(milliseconds: 2000)
      );

    _bottomnav = AnimationController(vsync: this, duration: Duration(milliseconds: 2000));
        _HomePagecontroller.forward();
      _titleanimation.forward();
  
      

      Future.delayed(const Duration(milliseconds: 1500),(){
        _subtitleanimation.forward();
      });
      Future.delayed(const Duration(milliseconds: 1500),(){
          _bottomnav.forward();

      });
      _scaleanimation.addListener((){
          if(_scaleanimation.isCompleted){
            Navigator.of(context).push(
              PageRouteBuilder(pageBuilder: (context, animation, secondaryAnimation){
                return User_frontpage();
              },
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                  );
              },
            )
            ).then((_){
              setState(() {
                _showarrow = true;
              });
              _travelcontroller.reset();
            });
          }
      });

      
    super.initState();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _bottomnav.dispose();
    _subtitleanimation.dispose();
    _titleanimation.dispose();
    _travelcontroller.dispose();
    _HomePagecontroller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _animation,
        child: Stack(
          children:[   
              Container(
                decoration: BoxDecoration(
                image: DecorationImage(
                image: AssetImage(images[currentindex]),
                fit: BoxFit.cover,
                alignment: Alignment(0.2, 0)
                
                )
              )         
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.0,-0.5),
                end:  Alignment(0.0,1.0),
                
                colors: [
                  Colors.transparent,
                  Colors.black
                ])
                )
            ),   
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Spacer(),
                  AnimatedBuilder(
                    animation: _titleanimation,
                    builder: (context, child){
                      return Opacity(
                        opacity: _titleanimation.value,
                        child: Transform.translate(offset: Offset(0, 30 * (1 - _titleanimation.value)),
                        child: child,
                        ),
                      );
                    },
                    child: Text('From Parts to Performance', 
                    style:GoogleFonts.poppins(
                      fontSize: 34,
                    fontWeight: FontWeight.w500,
                    color: const Color.fromARGB(255, 255, 255, 255),
                    ),

                        ),
                  ),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation:  _subtitleanimation,
                      builder: (context, child)  {
                        return Opacity(
                          opacity: _subtitleanimation.value,
                          child: Transform.translate(
                            offset: Offset(0, 30*(1 - _subtitleanimation.value)),
                            child: child,
                            ),
                          );
                      },
                      child: Text('Build, match, and optimize your PC with ease and confidence.',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.normal,
                          color: Colors.white
                        ),
                      ),
                    ),
      
      
       ],
              ),
              
            ) 
          ]
        ),
        
      ),
      bottomNavigationBar:  FadeTransition(
        opacity: _animation,
        child: BottomAppBar(
          color: Colors.black,
           child: Row(
             children: [
               Spacer(),
               AnimatedBuilder(
                 animation: _bottomnav,
                 builder: (context, child) {
                   return Transform.translate(
                     offset:Offset(0, 100 *(1 - _bottomnav.value)),
                     child: Opacity(
                       opacity: _bottomnav.value,
                       child: child,
                       ),
                   );
                 },
                 child: Row(
                   children: [
                    Text("Get Started", 
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                      )),
                    SizedBox(width:20),
                     GestureDetector(
                      onTap: (){
                        setState(() {
                          _showarrow = false;
                        });
                       _travelcontroller.forward();
                      },
                       child: ScaleTransition(
                         scale: _scaleanimation,
                         child: Container(
                          width: 60,
                          height: 60,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle
                              ),
                              child: _showarrow? Icon(Icons.chevron_right, color: Colors.white,):null,
                         )
                       ),
                     ),
                   ],
                 ),
               )
             ],
           ),
         ),
      ),
      );
  }
}