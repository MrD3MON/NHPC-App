import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'dart:convert';

class CircularScreen extends StatefulWidget {
  @override
  _CircularScreenState createState() => _CircularScreenState();
}

class _CircularScreenState extends State<CircularScreen> with TickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> circularData;
  late Future<List<Map<String, dynamic>>> notificationData;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    circularData = fetchCircularData();
    notificationData = fetchNotificationData();

    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: false);

    _animation = Tween<double>(begin: 1, end: -1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchCircularData() async {
    final response = await http.get(Uri.parse('http://192.168.0.102:3000/api/circulars'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load circular data');
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotificationData() async {
    final response = await http.get(Uri.parse('http://192.168.0.102:3000/api/circulars'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map<Map<String, dynamic>>((item) {
        int index = data.indexOf(item) + 1;
        return {
          'Notification': item['Notification'] ?? '',
          'Circular_Id': item['Circular_Id'].toString(),
          'Index': index.toString(),
        };
      }).toList();
    } else {
      throw Exception('Failed to load notification data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: AppBar(
          //backgroundColor: Colors.blue.shade800,
          backgroundColor: Color.fromARGB(255, 2, 43, 96),
          title: Padding(
            padding: EdgeInsets.only(top: 35.0),
            child: const Text(
              'Latest Circulars',
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
      body: FutureBuilder(
        future: Future.wait([circularData, notificationData]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 2, 43, 96),));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<Map<String, dynamic>> circularData = snapshot.data![0];
            List<Map<String, dynamic>> notificationData = snapshot.data![1];

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Container(
                    height: 25,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.blue.withOpacity(0.2),
                          Colors.blue.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_animation.value * MediaQuery.of(context).size.width, 0),
                            child: Row(
                              children: notificationData.map((item) {
                                return GestureDetector(
                                  onTap: () {
                                    handleNotificationTap(context, item['Circular_Id'].toString());
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                                    child: Text(
                                      item['Notification'],
                                      style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: circularData.length,
                    itemBuilder: (context, index) {
                      final String title = circularData[index]['Circular_Title'] ?? 'Unknown Title';
                      final String subtitle = circularData[index]['Circular_Date'] ?? 'Unknown Date';
                      final String circularId = circularData[index]['Circular_Id'].toString();
                      final double viewerHeight = MediaQuery.of(context).size.height * 0.6;

                      return ListTile(
                        leading: Icon(Icons.label, size: 22, color: Colors.blueGrey.shade700),
                        title: Text(title),
                        subtitle: Text(subtitle),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SecondPage(
                                title: title,
                                circularId: circularId,
                                viewerHeight: viewerHeight,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  void handleNotificationTap(BuildContext context, String circularId) {
    final url = 'http://192.168.0.102:3000/api/circulars/notification-file/$circularId';
    _pdfdownloadbutton(url);
  }

  Future<void> _pdfdownloadbutton(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }
}

class SecondPage extends StatelessWidget {
  final String title;
  final String circularId;
  final double viewerHeight;

  SecondPage({
    Key? key,
    required this.title,
    required this.circularId,
    required this.viewerHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print(circularId);
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: AppBar(
          backgroundColor: Color.fromARGB(255, 2, 43, 96),
          title: Padding(
            padding: EdgeInsets.only(top: 35.0),
            child: Text(
              title,
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white70),
            ),
          ),
          leading: Padding(
            padding: EdgeInsets.only(top: 25.0),
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
        children: [ SizedBox(height: 0, width: 0),
          Padding(
            padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.75),
            child: ElevatedButton.icon(
              onPressed: () {
                _pdfdownloadbutton(
                    'http://192.168.0.102:3000/api/circulars/pdf/$circularId');
              },
              label: const Text('PDF', style: TextStyle(
                fontSize: 13,
                color: Colors.black,
                fontWeight: FontWeight.w900,
              )),
              icon: const Icon(
                  Icons.download_rounded, color: Colors.black, size: 21),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.fromLTRB(3, 3, 5, 3),
                minimumSize: Size(10, 6),
                backgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  //side: BorderSide(color: Colors.black, width: 1.5),
                ),
              ),
            ),
          ),
          Container(
              height: viewerHeight,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black, // Color of the border
                  width: 2, // Width of the border
                ),
                borderRadius: BorderRadius.circular(130.0),
              ),
              child: SfPdfViewer.network(
                  'http://192.168.0.102:3000/api/circulars/pdf/$circularId')
          ),
          SizedBox(height: 10, width: 10),
          FutureBuilder<bool>(
            future: checkAttachmentAvailability(circularId, 0),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox.shrink();
              } else {
                if (snapshot.hasData && snapshot.data!) {
                  // Show the row with text "Attachments"
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.03),
                        child: Text(
                          'Attachments',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(
                                offset: Offset(0.0, 0.0), // Set the shadow offset
                                blurRadius: 10.0, // Set the blur radius
                                color: Colors.grey.withOpacity(0.7), // Set the shadow color
                              ),
                            ],
                            //fontFamily: 'PoetsenOne-Regular',
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return SizedBox.shrink();
                }
              }
            },
          ),
          SizedBox(height: 4, width: 0),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: 10),
              FutureBuilder<bool>(
                future: checkAttachmentAvailability(circularId, 0),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox.shrink();
                  } else {
                    if (snapshot.hasData && snapshot.data!) {
                      return ElevatedButton.icon(
                        onPressed: () {
                          _pdfdownloadbutton(
                              'http://192.168.0.102:3000/api/circulars/attachments/$circularId/0');
                        },
                        label: FutureBuilder<String?>(
                          future: getAttachmentFileName(
                            'http://192.168.0.102:3000/api/circulars/attachments/$circularId/0',
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                snapshot.data!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  //color: Colors.blue.shade900,
                                  color: Color.fromARGB(255, 2, 43, 96),
                                ),
                              );
                            } else if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text(
                                '',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              );
                            } else {
                              return const Text(
                                '',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              );
                            }
                          },
                        ),
                        icon:  Icon(
                            Icons.download_rounded, color: Color.fromARGB(255, 2, 43, 96) , size: 21),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          //padding: const EdgeInsets.fromLTRB(5, 1, 5, 1),
                          //minimumSize: Size(10, 6),
                          backgroundColor: Colors.grey.shade200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7.0),
                            //side: BorderSide(color: Colors.black, width: 1.3),
                          ),
                        ),
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  }
                },
              ),
              SizedBox(width: 10),
              FutureBuilder<bool>(
                future: checkAttachmentAvailability(circularId, 1),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox.shrink();
                  } else {
                    if (snapshot.hasData && snapshot.data!) {
                      return ElevatedButton.icon(
                        onPressed: () {
                          _pdfdownloadbutton(
                              'http://192.168.0.102:3000/api/circulars/attachments/$circularId/1');
                        },
                        label: FutureBuilder<String?>(
                          future: getAttachmentFileName(
                            'http://192.168.0.102:3000/api/circulars/attachments/$circularId/1',
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                snapshot.data!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  //color: Colors.blue.shade900,
                                  color: Color.fromARGB(255, 2, 43, 96),
                                ),
                              );
                            } else if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text(
                                '',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              );
                            } else {
                              return const Text(
                                '',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              );
                            }
                          },
                        ),
                        icon: Icon(Icons.download_rounded, color: Color.fromARGB(255, 2, 43, 96) , size: 21),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          //minimumSize: Size(10, 6),
                          backgroundColor: Colors.grey.shade200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7.0),
                            //side: BorderSide(color: Colors.black, width: 1.3),
                          ),
                        ),
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  }
                },
              ),
              SizedBox(width: 10),
              FutureBuilder<bool>(
                future: checkAttachmentAvailability(circularId, 1),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox.shrink();
                  } else {
                    if (snapshot.hasData && snapshot.data!) {
                      return ElevatedButton.icon(
                        onPressed: () {
                          _pdfdownloadbutton(
                              'http://192.168.0.102:3000/api/circulars/attachments/$circularId/2');
                        },
                        label: FutureBuilder<String?>(
                          future: getAttachmentFileName(
                            'http://192.168.0.102:3000/api/circulars/attachments/$circularId/2',
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                snapshot.data!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  //color: Colors.blue.shade900,
                                  color: Color.fromARGB(255, 2, 43, 96),
                                ),
                              );
                            } else if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text(
                                '',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              );
                            } else {
                              return const Text(
                                '',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              );
                            }
                          },
                        ),
                        icon: Icon(Icons.download_rounded, color: Color.fromARGB(255, 2, 43, 96) , size: 21),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          //minimumSize: Size(10, 6),
                          backgroundColor: Colors.grey.shade200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7.0),
                            //side: BorderSide(color: Colors.black, width: 1.3),
                          ),
                        ),
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  }
                },
              ),
            ],
          ),
        ], // Removed the semicolon here
      ),
    );
  }

  Future<String?> getAttachmentFileName(String url) async {
    final response = await http.head(Uri.parse(url));
    final String? contentDisposition = response.headers['content-disposition'];
    if (contentDisposition != null) {
      final List<String> dispositionParams = contentDisposition.split(';');
      for (String param in dispositionParams) {
        if (param.trim().startsWith('filename')) {
          String filename = param.split('=')[1].trim();
          // Remove double inverted commas if present
          filename = filename.replaceAll('"', '');
          return filename;
        }
      }
    }
    return null;
  }

  Future<bool> checkAttachmentAvailability(String circularId, int index) async {
    final response = await http.get(
        Uri.parse(
            'http://192.168.0.102:3000/api/circulars/attachments/$circularId/$index'));
    return response.statusCode == 200;
  }

  Future<void> _pdfdownloadbutton(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }
}