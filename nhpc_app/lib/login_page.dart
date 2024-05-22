import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dashboard.dart'; // Import the dashboard

void main() {
  runApp(LoginPage());
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: LoginScreen(),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isSignup = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();
  }

  void _showSignupSuccessMessage(BuildContext context) {
    final snackBar = SnackBar(
      content: Text('Sign up successful. Please Login to continue'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isSignup = false;
        _nameController.clear();
        _designationController.clear();
        _usernameController.clear();
        _passwordController.clear();
      });
    });
  }

  bool _validateSignupFields() {
    return _nameController.text.isNotEmpty &&
        _designationController.text.isNotEmpty &&
        _usernameController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  Future<void> _signup() async {
    final checkUsernameResponse = await http.post(
      Uri.parse('http://192.168.0.102:3000/check-username'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': _usernameController.text}),
    );

    if (checkUsernameResponse.statusCode == 200) {
      final signupData = {
        'name': _nameController.text,
        'designation': _designationController.text,
        'username': _usernameController.text,
        'password': _passwordController.text,
      };

      final response = await http.post(
        Uri.parse('http://192.168.0.102:3000/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(signupData),
      );

      if (response.statusCode == 200) {
        _showSignupSuccessMessage(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign up failed. Please try again.'),
          ),
        );
      }
    } else if (checkUsernameResponse.statusCode == 409) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Username already exists. Please choose a different username.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred. Please try again.'),
        ),
      );
    }
  }

  Future<void> _login() async {
    final loginData = {
      'username': _usernameController.text,
      'password': _passwordController.text,
    };

    final response = await http.post(
      Uri.parse('http://192.168.0.102:3000/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(loginData),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final name = responseData['name'];
      final designation = responseData['designation'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            name: name,
            designation: designation,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed. Please check your username and password.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          //backgroundColor: Colors.blueGrey.shade500,
          //backgroundColor: Color(0xff416171),
          backgroundColor: Color(0xff58777d),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 60),
                    ScaleTransition(
                      scale: _animation,
                      child: Image.asset('assets/logo.png', width: 160),
                    ),
                    SizedBox(height: 30),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (_isSignup)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50.0),
                                    color: Colors.blueGrey.shade100,
                                  ),
                                  child: TextField(
                                    controller: _nameController,
                                    textAlignVertical: TextAlignVertical.center,
                                    decoration: InputDecoration(
                                      labelText: 'Name',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                    ),
                                  ),
                                ),
                              if (_isSignup) SizedBox(height: 20),
                              if (_isSignup)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(50.0),
                                    color: Colors.blueGrey.shade100,
                                  ),
                                  child: TextField(
                                    controller: _designationController,
                                    textAlignVertical: TextAlignVertical.center,
                                    decoration: InputDecoration(
                                      labelText: 'Designation',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                    ),
                                  ),
                                ),
                              if (_isSignup) SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50.0),
                                  color: Colors.blueGrey.shade100,
                                ),
                                child: TextField(
                                  controller: _usernameController,
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50.0),
                                  color: Colors.blueGrey.shade100,
                                ),
                                child: TextField(
                                  controller: _passwordController,
                                  textAlignVertical: TextAlignVertical.center,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                    prefixIcon: Icon(Icons.lock),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () async {
                                  if (_isSignup) {
                                    if (_validateSignupFields()) {
                                      await _signup();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Please fill all the fields'),
                                        ),
                                      );
                                    }
                                  } else {
                                    await _login();
                                  }
                                },
                                child: Text(
                                  _isSignup ? 'Signup' : 'Login',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade400,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isSignup = !_isSignup;
                                  });
                                },
                                child: Text(
                                  _isSignup
                                      ? 'Already have an account? Login'
                                      : 'Don\'t have an account? Signup',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
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
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _designationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
