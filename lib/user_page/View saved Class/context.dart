import 'package:flutter/material.dart';

class PageContext extends StatelessWidget {
  final String name;
  final Widget imageWidget;
  final String price;
  final VoidCallback? onTap;
  
  const PageContext({
    required this.name,
    required this.imageWidget,
    required this.price,
    this.onTap,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Size adapts to parent (Grid/List). No fixed width/height.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [ 
                Positioned.fill(
                  child: imageWidget,
                ),
                // Soft bottom gradient for text legibility
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6)
                      ],
                      stops: const [0.45, 1.0],
                    )
                  )
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Name with enhanced text visibility
                      Text(
                        name,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.8),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      
                      // Price with enhanced visibility
                      
                          
                          // Optional action button with better visibility
                        
                        
                      
                    ], 
                  ),
                ),
              ]
            )
          ),
        ),
      ),
    );
  }
}