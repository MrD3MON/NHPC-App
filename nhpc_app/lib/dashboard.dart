import 'package:flutter/material.dart';
import 'Circular.dart';
import 'directory_screen.dart';
import 'login_page.dart';

class DashboardScreen extends StatefulWidget {
  final String name;
  final String designation;

  const DashboardScreen({
    Key? key,
    required this.name,
    required this.designation,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String savedToken = 'mockToken';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
    child: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              decoration: BoxDecoration(
                //border: Border.all(color: Colors.white, width: 1),
                borderRadius: BorderRadius.all(Radius.circular(5)),
                color: Colors.white,
              ),
              child: Image.asset('assets/nhpclogo.png', // Mock logo URL
                height: 33,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                width: 1,
                height: 40,
                color: Color.fromARGB(255, 132, 177, 241),
              ),
            ),
            Text(
              'Dashboard',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Color.fromARGB(255, 2, 43, 96),
      ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Welcome 🙏,',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      //color: Color.fromARGB(255, 235, 110, 1),
                      color: Color(0xffa0330c),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showLogoutDialog(context),
                    icon: Icon(Icons.logout, color: Color.fromARGB(255, 2, 43, 96),),
                  ),
                ],
              ),
              EmployeeCard(
                token: savedToken,
                employeeDetail: {
                  'name': widget.name,
                  'designation': widget.designation,
                  'photoUrl': 'assets/profile.png',
                },
              ),
              SizedBox(height: 20),
              Text(
                'Please choose an option to proceed',
                style: TextStyle(fontWeight: FontWeight.w800, color: Colors.grey.shade400),
              ),
              SizedBox(height: 5),
              Divider(height: 2, thickness: 2, color: Colors.grey.shade400,),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DirectoryScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        padding: const EdgeInsets.all(15.0),
                        backgroundColor: Colors.white,
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.contact_emergency,
                            size: 40,
                            color: Color(0xff3b4977),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Directory',
                            style: TextStyle(fontSize: 19, color: Color(0xff3b4977),),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CircularScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                        padding: const EdgeInsets.all(15.0),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fact_check,
                            size: 40,
                            color: Color(0xff3b4977),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Circulars',
                            style: TextStyle(fontSize: 19, color: Color(0xff3b4977),),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              const Expanded(
                child: Align(
                  alignment: FractionalOffset.bottomCenter,
                  child: Text('v1.0.0'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout', style: TextStyle(fontWeight: FontWeight.w600)),
          content: Text('Are you sure you want to log out?', style: TextStyle(fontWeight: FontWeight.w500)),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800,color: Color(0xff3b4977))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Successfully Logged Out.')),
                );
              },
              child: Text('Logout', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xff3b4977))),
            ),
          ],
        );
      },
    );
  }
}

class EmployeeCard extends StatelessWidget {
  final String token;
  final Map<String, dynamic> employeeDetail;

  const EmployeeCard({
    Key? key,
    required this.token,
    required this.employeeDetail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 50,
                width: 50,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.asset(
                    employeeDetail['photoUrl'],
                    fit: BoxFit.contain,
                    height: 40,
                  ),
                ),
              ),
              SizedBox(width: 5),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employeeDetail['name'].toString().toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      employeeDetail['designation'].toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 80, 79, 79),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}
