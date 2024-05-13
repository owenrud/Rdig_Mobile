import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:main/global_variable.dart';

class DetailEventPage extends StatefulWidget {
  final int idEvent;
  final Map<String, dynamic> profileData;

  const DetailEventPage(
      {Key? key, required this.idEvent, required this.profileData})
      : super(key: key);

  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<DetailEventPage> {
  //late Future<Map<String, dynamic>> _eventDetails = Future.value({});
  late Future<Map<String, dynamic>> _event = Future.value({});
  late Future<Map<String, dynamic>> _userProfile = Future.value({});
  final _mapController = MapController(
      initPosition: GeoPoint(latitude: -7.77016, longitude: 110.379));
// San Francisco coordinates
  int UserID = 0;
  @override
  void initState() {
    super.initState();
    UserID = widget.profileData['ID_User'];
    _event = _fetchEvent();
    //_eventDetails = _fetchEventDetails();
    _userProfile = _fetchUserProfile();
    print(widget.profileData);
  }

  Future<Map<String, dynamic>> _fetchEvent() async {
    try {
      final response = await http.post(
        Uri.parse("http://$ipAddress:8000/api/event/show"),
        body: {'ID_event': widget.idEvent.toString()},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['is_success'] == true) {
          final event = responseData['data'][0];

          // Format start and end dates
          final startDate =
              DateFormat("dd MMMM yyyy").format(DateTime.parse(event['start']));
          final endDate =
              DateFormat("dd MMMM yyyy").format(DateTime.parse(event['end']));

          event['start'] = startDate;
          event['end'] = endDate;

          return event;
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

  void _updateMapPosition(double latitude, double longitude) {
    final updatedPosition = GeoPoint(latitude: latitude, longitude: longitude);
    _mapController.goToLocation(updatedPosition);
  }

  // Future<Map<String, dynamic>> _fetchEventDetails() async {
  //   try {
  //     final eventId = (await _event)['ID_event'].toString();
  //     final response = await http.post(
  //       Uri.parse("http://$ipAddress:8000/api/event/detail/show"),
  //       body: {'ID_event': eventId},
  //     );

  //     if (response.statusCode == 200) {
  //       final responseData = json.decode(response.body);

  //       if (responseData['is_success'] == true) {
  //         return responseData['data'];
  //       } else {
  //         throw Exception("API response indicates failure");
  //       }
  //     } else {
  //       throw Exception("Failed to load event details");
  //     }
  //   } catch (error) {
  //     throw Exception("Error during event details fetching: $error");
  //   }
  // }

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
          final userData = responseData['data'] as Map<String, dynamic>;
          return userData;
        } else {
          throw Exception("API response indicates failure");
        }
      } else {
        throw Exception("Failed to load user profile");
      }
    } catch (error) {
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
                  Row(children: [
                    Padding(padding: EdgeInsets.symmetric(horizontal: 10)),
                    FutureBuilder<Map<String, dynamic>>(
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
                          );
                        }
                      },
                    ),
                  ]),
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
                                ? (event['nama']?.toString() ?? "Loading...")
                                : "Loading...",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          );
                        }
                      },
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
                                  builder: (context, snapshotEventDetails) {
                                    if (snapshotEventDetails.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text("Loading...");
                                    } else if (snapshotEventDetails.hasError) {
                                      print(
                                          "Error: ${snapshotEventDetails.error}");
                                      return Text(
                                          "Error: ${snapshotEventDetails.error}");
                                    } else {
                                      final eventDetails = snapshotEventDetails
                                          .data as Map<String, dynamic>?;

                                      final alamat = eventDetails != null
                                          ? eventDetails['alamat'] as String?
                                          : null;
                                      final lokasi = eventDetails != null
                                          ? eventDetails['lokasi'] as String?
                                          : null;
                                      return Text(
                                        alamat != null
                                            ? "$alamat($lokasi)"
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
                                  registerParticipant();
                                },
                                style: ElevatedButton.styleFrom(
                                  side: BorderSide(color: Colors.deepPurple),
                                  elevation: 8,
                                ),
                                child: Text(
                                  "Register",
                                  style: TextStyle(
                                    color: Colors.purple[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
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

  Future<void> registerParticipant() async {
    try {
      // Extract the required data from profileData
      //print(widget.profileData);
      int idEvent = widget.idEvent ?? 0; // Default to 0 if null
      int idUser = widget.profileData['ID_User'] ?? 0; // Default to 0 if null

      String participantName = widget.profileData['nama_lengkap'];

      String participantEmail = widget.profileData['email'];
      print('ID Event: $idEvent');
      print('ID User: $idUser');
      print('Participant Name: $participantName');
      print('Participant Email: $participantEmail');
      // Make the API call
      final response = await http.post(
        Uri.parse('http://$ipAddress:8000/api/peserta/save'),
        body: {
          'ID_event': idEvent.toString(),
          'ID_User': idUser.toString(),
          'nama': participantName,
          'email': participantEmail,
          'gender': 'L', // Adjust according to your data
          'type': 'normal', // Adjust according to your data
          'status_absen': '0', // Adjust according to your data
        },
      );

      // Handle the response
      if (response.statusCode == 200) {
        // Registration successful, handle the success case here
        print('Registration successful');
        Navigator.pop(context);
        Navigator.pop(context);
      } else {
        // Registration failed, handle the error
        print('Registration failed. Error code: ${response.statusCode}');
        print('Error message: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Registrasi gagal, karena peserta sudah terdaftar atau kesalahan server(500)'),
            backgroundColor:
                Colors.red, // You can customize the background color
          ),
        );
      }
    } catch (error) {
      print('Error: $error');
      // Handle errors during the process
    }
  }
}
