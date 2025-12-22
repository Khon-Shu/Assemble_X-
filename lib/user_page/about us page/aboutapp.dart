import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Aboutapp extends StatelessWidget {
  const Aboutapp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(   
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 70,
                      ),
                      const SizedBox(height: 10),
                     
                      const SizedBox(height: 4),
                      const Text(
                        "Smart PC Builder App",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.5),
              Divider(thickness: 1.5,color: Colors.black,),
                const SizedBox(height: 12.5),
         
      

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:  [
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.blueAccent),
                          SizedBox(width: 8),
                          Text(
                            "Developer",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                       Center(
                         child: LottieBuilder.asset(
                                     'assets/lottie/contact.json',
                                     height: 150,
                                     width: 200,
                                   fit: BoxFit.fill,
                                   ),
                       ),
          const SizedBox(height: 10),
                      Center(
                        child: Text(
                          "Amit Muni Bajracharya\nBCA 6th Semester",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 17),
                        ),
                      ),
                    ],
                  ),
                ),

               const SizedBox(height: 12.5),
              Divider(thickness: 1.5,color: Colors.black,),
                const SizedBox(height: 12.5),


              
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blueAccent),
                          SizedBox(width: 8),
                          Text(
                            "About The App",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
Center(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(
      "Assemble X is a smart PC builder app designed to make PC building simple and stress-free. "
      "Check real-time component compatibility, get intelligent product recommendations, "
      "and confidently build gaming rigs, workstations, or budget-friendly PCs.",
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        height: 1.6,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
),


                    ],
                    
                  ),
                ),
           

 const SizedBox(height: 40),
               
              ],
            ),
          ),
        ),
      ),
    );
  }
}
