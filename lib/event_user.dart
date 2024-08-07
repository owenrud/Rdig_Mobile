import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:main/qr_code.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:main/global_variable.dart';

class UserEventPage extends StatefulWidget {
  final int idEvent;

  final Map<String, dynamic> profileData;

  const UserEventPage(
      {Key? key, required this.idEvent, required this.profileData})
      : super(key: key);

  @override
  _UserEventPageState createState() => _UserEventPageState();
}

class _UserEventPageState extends State<UserEventPage> {
  late Future<Map<String, dynamic>> _event = Future.value({});
  Future<Map<String, dynamic>>? _userProfile;

  String qrData = "";
  int StatusAbsen = 0;
  final _mapController = MapController(
      initPosition: GeoPoint(
          latitude: -6.175398530482024,
          longitude: 106.82715682783265)); // San Francisco coordinates
  int UserID = 0;
  int EventID = 0;
  @override
  void initState() {
    super.initState();
    UserID = widget.profileData['ID_User'];
    EventID = widget.idEvent;
    _event = _fetchEvent();
    _userProfile = _fetchUserProfile();
    _loadUserData();
    print("Test ID Event:${widget.idEvent}");
    print("User ID:$UserID");
    print("ISI EVENT :$_event");
  }

  Future<Map<String, dynamic>> fetchUserData(
      String userId, String EventId) async {
    final Uri apiUrl =
        Uri.parse('http://$ipAddress:8000/api/peserta/show/guest');

    try {
      final http.Response response = await http.post(
        apiUrl,
        body: {'ID_user': userId, 'ID_event': EventId},
      );
      print("Test Fetch User:${response.body}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['is_success'] == true) {
          final Map<String, dynamic> userData = responseData['data'];

          if (userData.isNotEmpty && userData is Map<String, dynamic>) {
            // Return the user data directly
            return userData;
          } else {
            throw Exception('No valid user data found in the response');
          }
        } else {
          throw Exception(
              'Failed to fetch user data: ${responseData['message']}');
        }
      } else {
        throw Exception(
            'Failed to fetch user data. Error code: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error during user data fetching: $error');
    }
  }

  void _updateMapPosition(double latitude, double longitude) {
    final updatedPosition = GeoPoint(latitude: latitude, longitude: longitude);
    _mapController.goToLocation(updatedPosition);
  }

  Future<void> _loadUserData() async {
    try {
      if (UserID != null) {
        Map<String, dynamic> userData =
            await fetchUserData(UserID.toString(), EventID.toString());
        print(userData);
        String jsonString = json.encode(userData);
        int status = userData['status_absen'];
        print("status absen dari Load User Data: $status");

        setState(() {
          qrData = jsonString;
          StatusAbsen = status;
        });
      } else {
        print('Error loading user data: UserID is null');
      }
    } catch (error) {
      print('Error loading user data: $error');
    }
  }

  Future<Map<String, dynamic>> _fetchEvent() async {
    try {
      final response = await http.post(
        Uri.parse("http://$ipAddress:8000/api/event/show"),
        body: {'ID_event': widget.idEvent.toString()},
      );
      print("EVENT: ${response.body}");
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['is_success'] == true) {
          return responseData['data'][0];
        } else {
          throw Exception("API response indicates failure");
        }
      } else {
        throw Exception("Failed to load events");
      }
    } catch (error) {
      throw Exception("Error during event fetching: $error");
    }
  }

  Future<Map<String, dynamic>> _fetchUserProfile() async {
    try {
      final EO_ID = (await _event)['ID_EO'].toString();

      final response = await http.post(
        Uri.parse("http://$ipAddress:8000/api/profile/show"),
        body: {'id': EO_ID}, // Replace with the actual user ID
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['is_success'] == true) {
          if (responseData['data'] is Map<String, dynamic>) {
            return responseData['data'];
          } else {
            throw Exception("Data is not in the expected format");
          }
        } else {
          throw Exception("API response indicates failure");
        }
      } else {
        throw Exception("Failed to load user profile");
      }
    } catch (error) {
      print("Error User: $error");
      throw Exception("Error during user profile fetching: $error");
    }
  }

  Widget buildUserProfile() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userProfile,
      builder: (context, snapshotUserProfile) {
        if (snapshotUserProfile.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshotUserProfile.hasError) {
          return Text("Error: ${snapshotUserProfile.error}");
        } else {
          final userProfile = snapshotUserProfile.data;
          final userName = userProfile?['nama_lengkap'] ?? "Loading...";

          return Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.purple,
                backgroundImage: NetworkImage(userProfile?['foto'] ?? ""),
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                userName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 250,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          padding: EdgeInsets.fromLTRB(8.0, 30.0, 16.0, 0.0),
          height: 250.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade300, Colors.deepPurple.shade400],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              stops: [0.1, 0.9],
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(
                    width: 90,
                  ),
                  Text(
                    "Detail Event",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 5),
              Column(
                children: [
                  Row(
                    children: [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 10)),
                      buildUserProfile(),
                    ],
                  ),
                  SizedBox(height: 15),
                  Row(
                    children: [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 10)),
                      Expanded(
                        child: FutureBuilder<Map<String, dynamic>>(
                          future: _event,
                          builder: (context, snapshotEvent) {
                            if (snapshotEvent.connectionState ==
                                ConnectionState.waiting) {
                              return Text("Loading...");
                            } else if (snapshotEvent.hasError) {
                              return Text("Error: ${snapshotEvent.error}");
                            } else {
                              final event = snapshotEvent.data;

                              return Text(
                                event != null
                                    ? (event['nama_event']?.toString() ??
                                        "Loading...")
                                    : "Loading...",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      Padding(padding: EdgeInsets.symmetric(horizontal: 10)),
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today, // Icon kalender
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8), // Jarak antara ikon dan teks
                          FutureBuilder<Map<String, dynamic>>(
                            future: _event,
                            builder: (context, snapshotEvent) {
                              if (snapshotEvent.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (snapshotEvent.hasError) {
                                return Text("Error: ${snapshotEvent.error}");
                              } else {
                                final event = snapshotEvent.data;
                                final startDate = event != null
                                    ? event['start']
                                    : "Loading...";
                                final endDate =
                                    event != null ? event['end'] : "Loading...";

                                return Text(
                                  "$startDate to $endDate",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
              SizedBox(
                height: 15,
              ),
              Row(
                children: [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10)),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.purple.shade900,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 16),
                    child: Text(
                      "Seminar",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _event,
                      builder: (context, snapshotEvent) {
                        if (snapshotEvent.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshotEvent.hasError) {
                          return Text("Error: ${snapshotEvent.error}");
                        } else {
                          final event = snapshotEvent.data;
                          final backgroundColor =
                              event != null && event['public'] == 1
                                  ? Colors.amberAccent[700]
                                  : Colors.green[900];

                          return Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 1, horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              color: backgroundColor,
                            ),
                            child: Text(
                              event != null && event['public'] == 1
                                  ? "Public"
                                  : "Private",
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(4),
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(4),
            child: Card(
              elevation: 20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Expanded(
                    child: Column(
                      children: [
                        Padding(padding: EdgeInsets.all(8)),
                        Row(
                          children: [
                            Text(
                              "Detail Acara",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: FutureBuilder<Map<String, dynamic>>(
                                future: _event,
                                builder: (context, snapshotEvent) {
                                  if (snapshotEvent.connectionState ==
                                      ConnectionState.waiting) {
                                    return Text("Loading...");
                                  } else if (snapshotEvent.hasError) {
                                    return Text(
                                        "Error: ${snapshotEvent.error}");
                                  } else {
                                    final event = snapshotEvent.data;
                                    final description = event != null
                                        ? event['desc_event'] ?? ""
                                        : "Loading...";

                                    return Text(
                                      description,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          children: [
                            Column(
                              children: [
                                Text("Lokasi",
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500)),
                                FutureBuilder<Map<String, dynamic>>(
                                  future: _event,
                                  builder: (context, snapshotEvent) {
                                    if (snapshotEvent.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text("Loading...");
                                    } else if (snapshotEvent.hasError) {
                                      print("Error: ${snapshotEvent.error}");
                                      return Text(
                                          "Error: ${snapshotEvent.error}");
                                    } else {
                                      final event = snapshotEvent.data
                                          as Map<String, dynamic>?;

                                      final alamat = event != null
                                          ? event['alamat'] as String?
                                          : null;

                                      return Text(
                                        alamat != null
                                            ? alamat
                                            : "Alamat not available",
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Container(
                          width: 350,
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.purple,
                          ),
                          child: OSMFlutter(
                            controller: _mapController,
                            mapIsLoading: const Center(
                              child: CircularProgressIndicator(),
                            ),
                            onMapIsReady: (ready) async {
                              if (ready) {
                                await _fetchEvent().then((event) {
                                  if (event != null) {
                                    final latitude = event['latitude']
                                        .toDouble(); // Assuming the latitude is in 'latitude' field of the event data
                                    final longitude = event['longitude']
                                        .toDouble(); // Assuming the longitude is in 'longitude' field of the event data

                                    _updateMapPosition(latitude, longitude);
                                  }
                                });
                              }
                            },
                            osmOption: OSMOption(
                              zoomOption: const ZoomOption(
                                initZoom: 24.0,
                                minZoomLevel: 3.7,
                                maxZoomLevel: 17.0,
                              ),

                              // roadConfiguration:
                              //     const RoadOption(roadColor: Colors.blueGrey),
                              markerOption: MarkerOption(
                                  defaultMarker: const MarkerIcon(
                                icon: Icon(
                                  Icons.location_pin,
                                  size: 32,
                                ),
                              )),
                              userLocationMarker: UserLocationMaker(
                                personMarker: const MarkerIcon(
                                  icon: Icon(
                                    Icons.location_pin,
                                    size: 100,
                                  ),
                                ),
                                directionArrowMarker: const MarkerIcon(
                                  icon: Icon(
                                    Icons.location_pin,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => QrCodePage(
                                        qrData: qrData,
                                        profileData: widget.profileData,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  side: BorderSide(color: Colors.deepPurple),
                                  elevation: 8,
                                ),
                                child: Text(
                                  "Show QR Code",
                                  style: TextStyle(
                                    color: Colors.purple[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            FutureBuilder<Map<String, dynamic>>(
                              future: _event,
                              builder: (context, snapshotEvent) {
                                if (snapshotEvent.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                } else if (snapshotEvent.hasError) {
                                  return Text("Error: ${snapshotEvent.error}");
                                } else {
                                  final event = snapshotEvent.data;

                                  // Store the status in a variable for easier access
                                  final eventStatus =
                                      event != null ? event['status'] : null;

                                  // Conditionally show the "Sertifikat" button based on eventStatus
                                  final showSertifikatButton =
                                      eventStatus == 0 && StatusAbsen != 0;
                                  print(
                                      "Test Kondisi Sertifikat button: $showSertifikatButton");
                                  print("EVENT STATUS: $eventStatus");
                                  print("Status ABSEN : $StatusAbsen");

                                  return Column(
                                    children: [
                                      // Container for the "Sertifikat" button
                                      if (showSertifikatButton)
                                        ElevatedButton(
                                          onPressed: () {
                                            _DownloadCertificate();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            side: BorderSide(
                                                color: Colors.deepPurple),
                                            elevation: 8,
                                          ),
                                          child: Text(
                                            "Sertifikat",
                                            style: TextStyle(
                                              color: Colors.purple[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
            ),
          ),
        ),
      ),
    );
  }

  void _DownloadCertificate() async {
    try {
      // Make the POST request to download the PDF
      var response = await http.post(
        Uri.parse('http://$ipAddress:8000/api/test/postpdf/export'),
        body: jsonEncode({'ID_user': UserID, 'ID_event': widget.idEvent}),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      // Check if the request was successful (status code 200)
      if (response.statusCode == 200) {
        // Get the directory where the PDF file will be saved
        final Directory? downloadsDir = await getDownloadsDirectory();

        if (downloadsDir != null) {
          String filePath = '${downloadsDir.path}/certificate.pdf';

          // Write the response body (PDF content) to the file
          File file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          print("File saved to: $filePath");

          // Open the locally saved PDF file
          // You can implement the logic to open the PDF file here
        } else {
          print("Error: Downloads directory is null");
        }
      } else {
        // Handle the case where the request was not successful
        print(
            'Failed to download certificate. Status code: ${response.statusCode}');
      }
    } catch (error) {
      // Handle any errors that occur during the request
      print("Error downloading certificate: $error");
    }
  }

  String _formatDate(String? dateString) {
    if (dateString != null) {
      final DateTime dateTime = DateTime.parse(dateString);
      final DateFormat formatter = DateFormat('dd-MMM-yy');
      return formatter.format(dateTime);
    }
    return '';
  }
}
