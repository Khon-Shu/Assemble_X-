import 'dart:io';
import 'package:assemblex/services/save_build.dart';
import 'package:assemblex/user_page/userinterface/appbar.dart';
import 'package:flutter/material.dart';
import 'package:assemblex/user_page/View%20saved%20Class/context.dart';
import 'package:assemblex/user_page/userinterface/bottom_nav_bar.dart';
import 'dart:async';
import 'package:assemblex/services/cpu_service.dart';
import 'package:assemblex/services/gpu_service.dart';
import 'package:assemblex/services/motherboard_service.dart';
import 'package:assemblex/services/ram_service.dart';
import 'package:assemblex/services/storage_service.dart';
import 'package:assemblex/services/psu_service.dart';
import 'package:assemblex/services/case_service.dart';
import 'package:assemblex/services/cooling_service.dart';
import 'package:lottie/lottie.dart';

class User_frontpage extends StatefulWidget{
  const User_frontpage({super.key});

  @override
  State<User_frontpage> createState() => _frontpageState();
}

class _frontpageState extends State<User_frontpage>  with TickerProviderStateMixin{
  int _currentindex =0;
  Timer? _imageTimer;
  late PageController _imagePageController;
  String? selectedfilter;
  String? _isSelected ;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final PageController _pageController = PageController();
  final List<Map<String,dynamic>> _allProducts = [];
  bool _loadingAll = false;
  final List<String> _images =[
   'assets/images/animationimg.png',
   'assets/images/animationimg2.png',
   'assets/images/amimationimg3.png'
  ];
  final List<String> _listtile =[
    'Case',
    'Cooling',
    'CPU',
    'GPU',
    'MotherBoard',
    'PSU',
    'RAM',
    'Storage'
  ];
  Timer? _timer;

  List<Map<String,dynamic>> _products =[];
  bool _isloading = false;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  
  @override
void initState() {
  super.initState();
  
  // Initialize animations FIRST
  _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500), // Longer duration to see it better
  );

  _slideController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  
  _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
    CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
  );
  _imagePageController= PageController();
  _startImageSlider();
  
  _slideAnimation = Tween<Offset>(
    begin: const Offset(0.0, 0.3), // More noticeable offset
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

  // Start animations after a short delay to ensure widget is built
  Future.delayed(const Duration(milliseconds: 100), () {
    if (mounted) {
      _fadeController.forward();
      _slideController.forward();
    }
  });
}
  void _startImageSlider() {
  _imageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
    if (_imagePageController.hasClients && mounted) {
      int nextPage = _currentindex + 1;
      if (nextPage >= _images.length) {
        nextPage = 0;
      }
      
      _imagePageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  });
}
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    _timer?.cancel();
    
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchProduct(String category)async{
    setState(() {
      _isloading = true;
    });
    try{
        switch(category){
         
          case 'CPU':
          final cpus = await CPUService.getAllCPUs();
          _products = cpus.map((cpu) => cpu.toMap()).toList();
          case 'GPU':
          final gpus = await GPUService.getAllGPUs();
          _products = gpus.map((gpu) => gpu.toMap()).toList();
          break;
           case 'Cooling':
          final coolers = await CoolingService.getAllCoolings();
          _products = coolers.map((cooler) => cooler.toMap()).toList();
          break;
           case 'Case':
          final cases = await CaseService.getAllCases();
          _products = cases.map((casess) => casess.toMap()).toList();
          break;
           case 'MotherBoard': 
          final motherboards = await MotherboardService.getAllMotherboards();
          _products = motherboards.map((motherboard) => motherboard.toMap()).toList();
          break;
           case 'PSU':
          final psus = await PSUService.getAllPSUs();
          _products = psus.map((psu) => psu.toMap()).toList();
          break;
           case 'RAM':
          final rams = await RAMService.getAllRAMs();
          _products = rams.map((ram) => ram.toMap()).toList();
          break;
           case 'Storage':
          final storages = await StorageService.getAllStorages();
          _products = storages.map((storage) => storage.toMap()).toList();
          break;
          default:
          _products = [];
        }
    }catch(e){
        print('Error fetchind $category :$e');
        _products = [];
    }

    setState(() {
      _isloading = false;
    });
  }

  List<Map<String,dynamic>> _filteredProducts(){
    final List<Map<String,dynamic>> source = (_isSelected != null && _isSelected != 'Popular')
        ? _products
        : (_allProducts.isNotEmpty ? _allProducts : _products);
    if(_searchQuery.isEmpty){
      return source;
    }
    final q = _searchQuery.toLowerCase();
    return source.where((p){
      final name = (p['model_name'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).toList();
  }

  void _showProductDialog(Map<String, dynamic> product) {
  final List<MapEntry<String, dynamic>> productDetails = product.entries
      .where((entry) =>
          entry.key != 'id' &&
          entry.key != 'imageURL' &&
          entry.key != 'createdAt' &&
          entry.key != 'updatedAt' &&
          entry.value != null)
      .toList();

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 10,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _getImageWidget(product['imageURL']),
                ),

                const SizedBox(height: 20),

                // Title & Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['model_name'] ?? 'Product',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rs. ${product['price']?.toStringAsFixed(2) ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: Colors.grey[300], thickness: 1),

                const SizedBox(height: 10),
                // Product Details Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Specifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Specs List
                ...productDetails.map((entry) {
                  if (entry.value == null || entry.value.toString().isEmpty || entry.key == 'model_name' || entry.key == 'price') {
                    return const SizedBox.shrink();
                  }

                  String formattedKey = entry.key
                      .replaceAll('_', ' ')
                      .split(' ')
                      .map((s) => s[0].toUpperCase() + s.substring(1))
                      .join(' ');

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            '$formattedKey:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: TextStyle(
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 20),
                Divider(color: Colors.grey[300], thickness: 1),
                
                // Action Buttons (optional)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'CLOSE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                   
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}


  Future<void> _loadAllProductsIfNeeded() async {
    if(_allProducts.isNotEmpty || _loadingAll) return;
    setState(() { _loadingAll = true; });
    try{
      final cpus = await CPUService.getAllCPUs();
      final gpus = await GPUService.getAllGPUs();
      final coolers = await CoolingService.getAllCoolings();
      final cases = await CaseService.getAllCases();
      final motherboards = await MotherboardService.getAllMotherboards();
      final psus = await PSUService.getAllPSUs();
      final rams = await RAMService.getAllRAMs();
      final storages = await StorageService.getAllStorages();
      _allProducts
        ..addAll(cpus.map((e)=>e.toMap()))
        ..addAll(gpus.map((e)=>e.toMap()))
        ..addAll(coolers.map((e)=>e.toMap()))
        ..addAll(cases.map((e)=>e.toMap()))
        ..addAll(motherboards.map((e)=>e.toMap()))
        ..addAll(psus.map((e)=>e.toMap()))
        ..addAll(rams.map((e)=>e.toMap()))
        ..addAll(storages.map((e)=>e.toMap()));
    } catch (_) {
      // ignore errors for now
    } finally {
      if(mounted){
        setState(() { _loadingAll = false; });
      }
    }
  }

  Widget _getImageWidget(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return Image.asset('assets/images/default_product.png', fit: BoxFit.cover);
    }
    
    // If it's a file path (starts with /data/), use FileImage
    if (imagePath.startsWith('/data/')) {
      return Image.file(File(imagePath), fit: BoxFit.cover);
    }
    
    // Otherwise, assume it's an asset image
    return Image.asset(imagePath, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar:const UserAppBar(),
      body: Stack(
        children: [
          // Soft header background
          Container(
            height: 145,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(45),
                bottomRight: Radius.circular(45),
              ),
            ),
          ),
          // Body content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SearchBar(
                      hintText: "Search the products",
                      hintStyle: WidgetStateProperty.all(
                        TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        )
                      ),
                      leading: Icon(Icons.search, color: Colors.black),
                      controller: _searchController,
                      onChanged: (value){
                        setState(() {
                          _searchQuery = value.trim();
                        });
                        if(_isSelected == null || _isSelected == 'Popular'){
                          _loadAllProductsIfNeeded();
                        }
                      },
                      trailing: _searchQuery.isNotEmpty
                        ? [
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: (){
                                _searchController.clear();
                                setState(() { _searchQuery = ''; });
                              },
                            )
                          ]
                        : null,
                      elevation: WidgetStateProperty.all(4),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        )
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SlideTransition(
                  position: _slideAnimation,
                  child: SizedBox(
                    height: 55,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _listtile.length,
                      itemBuilder: (contex, index){
                        final finalfilter = _listtile[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 50)),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
                                  child: GestureDetector(
                                    onTap: (){
                                      setState(() {
                                        _isSelected = finalfilter;
                                      });
                                      _fetchProduct(finalfilter);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: finalfilter == _isSelected 
                                            ? Theme.of(context).colorScheme.secondary
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: finalfilter == _isSelected
                                            ? [
                                                BoxShadow(
                                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.35),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                )
                                              ]
                                            : [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.08),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                )
                                              ],
                                      ),
                                      child: Text(
                                        _listtile[index],
                                        style:  TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          letterSpacing: 0.3,
                                          color: finalfilter == _isSelected 
                                            ? Colors.white
                                            : Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
  opacity: _fadeAnimation,
  child: Container(
    width: double.infinity,
    height: 220,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 5),
        )
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          // Animated PageView instead of static Image.asset
          PageView.builder(
            controller: _imagePageController,
            itemCount: _images.length,
            onPageChanged: (index) {
              setState(() {
                _currentindex = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.asset(
                _images[index],
                fit: BoxFit.cover,
                width: double.infinity,
              );
            },
          ),
          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              height: 90,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.5),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: _isSelected != null && _isSelected != 'Popular'
                        ? (_isloading
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                                    ),
                                    const SizedBox(height: 16),
                                   LottieBuilder.asset(
                                    'assets/lottie/loading.json',
                                    width: 150,
                                    height: 200,
                                    fit: BoxFit.fill,
                                   )
                                  ],
                                ),
                              )
                            : (_products.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.inbox_outlined,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No products found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(8,4,8,100),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: 0.72,
                                    ),
                                    itemCount: _filteredProducts().length,
                                    itemBuilder: (context, index) {
                                      final product = _filteredProducts()[index];
                                      return TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration: Duration(milliseconds: 300 + (index * 60)),
                                        curve: Curves.easeOut,
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: Transform.translate(
                                              offset: Offset(0, 20 * (1 - value)),
                                              child: PageContext(
                                                name: product['model_name'] ?? 'No Name',
                                                imageWidget: _getImageWidget(product['imageURL']),
                                                price: product['price'].toString(),
                                                onTap: (){ _showProductDialog(product); },
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  )))
                        : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const SizedBox(height: 50),
                               Lottie.asset(
                                'assets/lottie/frontpage.json',
                                height: 150,
                                width: 200,
                                fit: BoxFit.fill
                                                           ),
                            
                            
                              const SizedBox(height: 20),
                             
                          
                              Text(
                                'Select a category to browse products',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
          // Search suggestions overlay
          if (_searchQuery.isNotEmpty && _filteredProducts().isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              top: 80,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0,4),
                      )
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredProducts().length,
                    itemBuilder: (context, index){
                      final p = _filteredProducts()[index];
                      return ListTile(
                        leading: SizedBox(
                          height: 36, 
                          width: 36, 
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6), 
                            child: _getImageWidget(p['imageURL'])
                          )
                        ),
                        title: Text(
                          p['model_name'] ?? 'No Name', 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis
                        ),
                        subtitle: Text('Rs. ${p['price']}'),
                        onTap: (){
                          FocusScope.of(context).unfocus();
                          _showProductDialog(p);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            BottomNavBar(selectedindex: 0)
        ],
      ),
      
    );
  }
}