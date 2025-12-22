import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPage extends StatelessWidget {
  const LocationPage({super.key});

  @override
  Widget build(BuildContext context) {
final LatLng location = LatLng(27.7049, 85.3070); 

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 5),
            const Text(
              "Our Location",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

           const SizedBox(height: 12.5),
              Divider(thickness: 1.5,color: Colors.black,),
                const SizedBox(height: 12.5),


            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: location,  
                    initialZoom: 15,          
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: 'com.example.assemblex',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: location,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                  child: Container(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text("Contact Us",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20
                          ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "We are available at:"
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(Icons.call),
                            SizedBox(width: 10),
                            Text("Phone:"),
                            const SizedBox(width:10),
                            Text('9863252012', style: TextStyle(
                              fontWeight: FontWeight.bold
                            ),)
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined),
                            SizedBox(width: 10),
                            Text("Location:"),
                            const SizedBox(width:10),
                            Text('Jho Chen,\nKathmandu', style: TextStyle(
                              fontWeight: FontWeight.bold
                            ),)
                          ],
                        ),
                         const SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(Icons.email),
                            SizedBox(width: 10),
                            Text("Email:"),
                            const SizedBox(width:10),
                            Text('assemblex@gmail.com', style: TextStyle(
                              fontWeight: FontWeight.bold
                            ),)
                          ],
                        )
                      ],
                    ),
                  ),
            )
          ],
        ),
      ),
    );
  }
}
