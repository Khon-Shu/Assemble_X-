import 'dart:io';
import 'package:assemblex/admin_page/admininterface/admin_bottom_navbar.dart';
import 'package:assemblex/services/database_service.dart';
import 'package:assemblex/user_page/register_page.dart';
import 'package:assemblex/user_page/forgot_password_page.dart';
import 'package:assemblex/user_page/userinterface/appbar.dart';
import 'package:flutter/material.dart';
import 'package:assemblex/user_page/userinterface/bottom_nav_bar.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> with SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService.instance;
  Map<String, dynamic>? _loggedInUser;
  bool _isAdmin = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
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
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    
    _animationController.forward();
    _loadUser();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    int? savedUserId = prefs.getInt('loggedInUserId');
    final isAdmin = prefs.getBool('isAdmin') ?? false;

    // Migration: if older email-based key exists, resolve to id and save
    if (savedUserId == null) {
      final legacyEmail = prefs.getString('loggedInUser');
      if (legacyEmail != null && !isAdmin) {
        final legacyUser = await _databaseService.getUserByEmail(legacyEmail);
        if (legacyUser != null) {
          savedUserId = legacyUser['id'] as int;
          await prefs.setInt('loggedInUserId', savedUserId);
          await prefs.remove('loggedInUser');
        }
      }
    }

    if (savedUserId != null) {
      if (isAdmin) {
        final admin = await _databaseService.getAdminById(savedUserId);
        if (admin != null) {
          setState(() {
            _loggedInUser = admin;
            _isAdmin = true;
          });
        }
      } else {
        final user = await _databaseService.getUserById(savedUserId);
        if (user != null) {
          setState(() {
            _loggedInUser = user;
            _isAdmin = false;
          });
        }
      }
    }
  }

  Future<void> _saveLogin(int userId, bool isAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('loggedInUserId', userId);
    await prefs.setBool('isAdmin', isAdmin);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUserId');
    await prefs.remove('isAdmin');
    setState(() {
      _loggedInUser = null;
      _isAdmin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: UserAppBar(),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Container(
              height: double.infinity,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30), 
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height:20),
                          Text(
                            "Welcome To Assemble_x",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _loggedInUser == null 
                                ? "Let's Log You In" 
                                : _isAdmin 
                                    ? "Welcome Admin" 
                                    : "Your Profile",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            height: _loggedInUser == null ?
                             520 : 
                             _isAdmin ?520:590,
                            width: 350,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _loggedInUser == null
                                  ? buildLoginForm()
                                  : _isAdmin 
                                      ? buildAdminDetails()
                                      : buildUserDetails(),
                            ),
                          ),
                          
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (!_isAdmin) const BottomNavBar(selectedindex: 3)
          else Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: AdminBottomNavBar(selectedindex: 3),
          ),
        ],
      ),
    );
  }

  /// LOGIN FORM
  Widget buildLoginForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 100,
            width: 240,
            child: Image.asset('assets/images/logo.png'),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
            
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(50)),
              prefixIcon: const Icon(Icons.email),
              hintText: 'Enter your email',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(50)),
              prefixIcon: const Icon(Icons.lock),
              hintText: 'Enter your password',
              hintStyle: TextStyle(
                color: Colors.black
              )
            ),
          ),
          const SizedBox(height: 10),
           Container(
            alignment: Alignment(0.8,1),
            width: double.infinity,
            decoration: BoxDecoration(

            ),
            child:
             
               TextButton(
                onPressed: (){
                  Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                );
                },
                child: Text('Forgot Password',style: 
              TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary
              )
              )
              ,)),
        
          const SizedBox(height: 20),
          const Text("Don't Have an Account?", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterPage()),
              );
            },
            child: const Text("Register", style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(height: 10),
         
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: loginUser,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Log In',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// USER DETAILS
  Widget buildUserDetails() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value,
                  child: _loggedInUser!['imageURL'] != null && _loggedInUser!['imageURL'] != ''
                      ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: FileImage(File(_loggedInUser!['imageURL'])),
                          ),
                        )
                      : Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                          ),
                          child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildInfoCard('First Name', _loggedInUser!['firstname']),
          const SizedBox(height: 12),
          _buildInfoCard('Last Name', _loggedInUser!['lastname']),
          const SizedBox(height: 12),
          _buildInfoCard('Email', _loggedInUser!['email']),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openManageAccountDialog,
                  icon: const Icon(Icons.manage_accounts),
                  label: const Text(
                    'Manage Account',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.red[400]!, Colors.red[600]!],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _logout,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Log Out',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Lottie animation inside the box for user details
          Lottie.asset(
            'assets/lottie/working.json',
            height: 150,
            width: 150,
            repeat: true,
            animate: true,
          ),
        ],
      ),
    );
  }

  void _openManageAccountDialog() {
    if (_loggedInUser == null || _isAdmin) return; // Only for normal users here
    final fnameCtrl = TextEditingController(text: _loggedInUser!['firstname'] ?? '');
    final lnameCtrl = TextEditingController(text: _loggedInUser!['lastname'] ?? '');
    final emailCtrl = TextEditingController(text: _loggedInUser!['email'] ?? '');
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Manage Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fnameCtrl,
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                TextField(
                  controller: lnameCtrl,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New Password (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Confirm delete
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c2) => AlertDialog(
                    title: const Text('Delete Account?'),
                    content: const Text('This will permanently delete your account and saved builds.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(c2).pop(false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.of(c2).pop(true),
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm != true) return;
                try {
                  final id = _loggedInUser!['id'] as int;
                  await _databaseService.deleteUser(id);
                  if (mounted) {
                    Navigator.of(ctx).pop();
                    await _logout();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account deleted successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete account: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () async {
                final firstname = fnameCtrl.text.trim();
                final lastname = lnameCtrl.text.trim();
                final email = emailCtrl.text.trim();
                final newPassword = passwordCtrl.text.trim();
                if (firstname.isEmpty || lastname.isEmpty || email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('First name, last name and email are required')),
                  );
                  return;
                }
                try {
                  final id = _loggedInUser!['id'] as int;
                  await _databaseService.updateUser(
                    id: id,
                    firstname: firstname,
                    lastname: lastname,
                    email: email,
                    password: newPassword.isEmpty ? null : newPassword,
                  );
                  // Refresh user from DB using id
                  final refreshed = await _databaseService.getUserById(id);
                  if (mounted) {
                    setState(() {
                      _loggedInUser = refreshed;
                    });
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account updated')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Update failed: $e')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  /// ADMIN DETAILS
  Widget buildAdminDetails() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.admin_panel_settings, size: 80, color: Colors.blue),
          const SizedBox(height: 20),
          Text('Admin: ${_loggedInUser!['firstname']} ${_loggedInUser!['lastname']}', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text('Email: ${_loggedInUser!['email']}', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text('Type: ${_loggedInUser!['type']}', 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
          const SizedBox(height: 20),
          
          
          // Lottie animation inside the box for admin details
          Lottie.asset(
            'assets/lottie/working.json',
            height: 200,
            width: 200,
            repeat: true,
            animate: true,
          ),
          ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 62, vertical: 14),
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// LOGIN FUNCTION
  void loginUser() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    final admin = await _databaseService.loginAdmin(email, password);
    if (admin != null) {
      final adminId = admin['id'] as int;
      await _saveLogin(adminId, true);
      setState(() {
        _loggedInUser = admin;
        _isAdmin = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin Login Successful!')),
      );
      return;
    }

    final user = await _databaseService.loginuser(email, password);
    if (user != null) {
      final userId = user['id'] as int;
      await _saveLogin(userId, false);
      setState(() {
        _loggedInUser = user;
        _isAdmin = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log In Successful')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Failed. Please try again')),
      );
    }
  }
  
  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}