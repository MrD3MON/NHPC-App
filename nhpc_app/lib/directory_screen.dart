import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:accordion/accordion.dart';
import 'package:accordion/controllers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';

class DirectoryScreen extends StatefulWidget {
  @override
  _DirectoryScreenState createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  String? selectedValue;
  List<String> dropdownOptions = [];
  List<Map<String, dynamic>> hospitalData = []; // List to store hospital data
  bool _isLoading = false; // Loading state variable for dropdown options
  bool _isFetchingHospitalData = false; // Loading state variable for hospital data

  static const headerStyle = TextStyle(
      color: Color(0xffffffff), fontSize: 18, fontWeight: FontWeight.bold);
  static const contentStyleHeader = TextStyle(
      color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w900);
  static const contentStyle = TextStyle(
      color: Colors.black, fontSize: 14, fontWeight: FontWeight.normal);

  @override
  void initState() {
    super.initState();
    fetchDropdownOptions();
  }

  // Function to handle PDF download
  Future<void> downloadPdf(String fileName) async {
    final url = 'http://192.168.0.102:3000/download-pdf?fileName=$fileName';
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> fetchDropdownOptions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse('http://192.168.0.102:3000/dropdown-options'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<String> options = List<String>.from(data);
        options.sort();
        setState(() {
          dropdownOptions = options;
        });
      } else {
        print('Failed to fetch dropdown options');
      }
    } catch (error) {
      print('Error fetching dropdown options: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchHospitalData(String locName) async {
    setState(() {
      _isFetchingHospitalData = true;
    });
    try {
      final response = await http.get(Uri.parse('http://192.168.0.102:3000/hospital-data?locName=$locName'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          hospitalData = List<Map<String, dynamic>>.from(data);
        });
      } else {
        print('Failed to fetch hospital data');
      }
    } catch (error) {
      print('Error fetching hospital data: $error');
    } finally {
      setState(() {
        _isFetchingHospitalData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: AppBar(
          backgroundColor: Color.fromARGB(255, 2, 43, 96),
          title: Padding(
            padding: EdgeInsets.only(top: 35.0),
            child: const Text(
              'Empanelled Hospitals',
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
          ),
          centerTitle: true,
          leading: Padding(
            padding: EdgeInsets.only(top: 27.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70,),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Center(
            child: _isLoading
                ? CircularProgressIndicator(color: Color.fromARGB(255, 2, 43, 96))
                : Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.blueGrey[100],
              ),
              child: DropdownButton2<String>(
                items: dropdownOptions.map((String item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                )).toList(),
                onChanged: (String? newValue) {
                  print('New value: $newValue');
                  setState(() {
                    if (newValue != null) {
                      selectedValue = newValue;
                      fetchHospitalData(newValue);
                    }
                  });
                },
                hint: Text(selectedValue ?? 'Select State', style: TextStyle(color: Colors.black)),
                underline: Container(),
                dropdownStyleData: DropdownStyleData(
                  maxHeight: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.blueGrey[50],
                  ),
                  scrollbarTheme: ScrollbarThemeData(
                    radius: Radius.circular(10),
                    thickness: MaterialStateProperty.all(8),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: _isFetchingHospitalData
                ? Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 2, 43, 96)))
                : (selectedValue == null || selectedValue == 'Select State')
                ? Container()
                : hospitalData.isEmpty
                ? Center(child: Text('No Data Available', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))
                : ListView(
              children: hospitalData.map((hospital) => Padding(
                padding: const EdgeInsets.only(top: 0, bottom: 0), // Adjust this value to control the gap
                child: Accordion(
                  headerBorderColor: Colors.blueGrey,
                  headerBorderColorOpened: Colors.transparent,
                  headerBackgroundColorOpened: Color(0xff0a5e4d),
                  headerBackgroundColor: Color(0xff3b4977),
                  contentBackgroundColor: Colors.white,
                  contentBorderColor: Color(0xff0a5e4d),
                  contentBorderWidth: 6,
                  contentHorizontalPadding: 20,
                  scaleWhenAnimating: true,
                  openAndCloseAnimation: true,
                  headerPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  sectionOpeningHapticFeedback: SectionHapticFeedback.heavy,
                  sectionClosingHapticFeedback: SectionHapticFeedback.heavy,
                  paddingBetweenClosedSections: 0,
                  disableScrolling:true,
                  children: [
                    AccordionSection(
                      isOpen: false,
                      leftIcon: const Icon(Icons.account_balance, color: Colors.white),
                      header: Text(hospital['Hosp_name'], style: headerStyle),
                      content: Container(
                        constraints: BoxConstraints(
                          maxHeight: 300,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              buildCustomRow('Name:', hospital['Hosp_name'] ?? ''),
                              buildCustomRow('Address:', hospital['hosp_add'] ?? ''),
                              buildCustomRow('Validity:', '${hospital['valid_from'] ?? ''} to ${hospital['VALID_UPTO'] ?? ''}'),
                              buildCustomRow('Reg Valid Upto:', hospital['RegValidUptoDt'] ?? ''),
                              buildCustomRow('Remarks:', hospital['Rem'] ?? ''),
                              buildCustomRow('Approval Order:', hospital['Approval_Order'] ?? ''),
                              buildCustomRow('Tariff:', hospital['Tariff'] ?? ''),
                              buildCustomRow('Facilitation:', hospital['Facilitation'] ?? ''),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCustomRow(String title, String content) {
    final bool isSpecialRow = title == 'Approval Order:' || title == 'Tariff:' || title == 'Facilitation:';
    final TextStyle customContentStyle = isSpecialRow
        ? _DirectoryScreenState.contentStyle.copyWith(color: Colors.blue) // Change the color as needed
        : _DirectoryScreenState.contentStyle;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              title,
              style: _DirectoryScreenState.contentStyleHeader,
            ),
          ),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                if (title == 'Approval Order:') {
                  downloadPdf(content);
                }
                else if (title == 'Tariff:') {
                  downloadPdf(content);
                }
                else if (title == 'Facilitation:') {
                  downloadPdf(content);
                }
              },
              child: Text(
                content,
                style: customContentStyle,
                softWrap: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: DirectoryScreen(),
  ));
}
