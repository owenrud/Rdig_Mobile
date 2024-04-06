import 'package:flutter/material.dart';
import 'package:main/event.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:main/event_user.dart';
import 'package:main/main.dart';
import 'package:main/global_variable.dart';

class GuestPage extends StatefulWidget {
  final String userId;

  const GuestPage({Key? key, required this.userId}) : super(key: key);

  @override
  _GuestPageState createState() => _GuestPageState();
}

class _GuestPageState extends State<GuestPage> {
  late Future<Map<String, dynamic>> profileData;
  // Future<List<Map<String, dynamic>>> eventList =
  //     Future.value([]); // Use an initial value
  late Future<List<Map<String, dynamic>>> eventList;

  @override
  void initState() {
    super.initState();
    // Fetch profile data when the widget is created
    profileData = fetchProfileData(widget.userId);
    eventList = fetchEventList(widget.userId);
  }

  Future<List<Map<String, dynamic>>> fetchEventList(String userId) async {
    try {
      // Fetch ID_event using the first API
      print('Fetching event list for user ID: $userId');

      final response1 = await http.post(
        Uri.parse('http://$ipAddress:8000/api/peserta/show/user'),
        body: {'ID_user': userId},
      );

      if (response1.statusCode == 200) {
        final pesertaData = json.decode(response1.body);

        if (pesertaData['is_success'] == true &&
            pesertaData.containsKey('data')) {
          final List<int> eventIdList = pesertaData['data']
              .map<int>((peserta) => peserta['ID_event'] as int)
              .toList();

          print('Event ID List: $eventIdList');

          // Fetch event details using the second API
          final List<Future<List<Map<String, dynamic>>>> eventDetailsFutures =
              eventIdList.map((eventId) => fetchEventDetails(eventId)).toList();

// Wait for all futures to complete
          final List<List<Map<String, dynamic>>> eventDetails =
              await Future.wait(
            eventDetailsFutures,
          );

// Flatten the list of lists
          final List<Map<String, dynamic>> flattenedEventDetails =
              eventDetails.expand((element) => element).toList();

          print('Event Details: $flattenedEventDetails');

          return flattenedEventDetails;
        } else {
          throw Exception('Invalid event list response format');
        }
      } else {
        throw Exception(
            'Failed to fetch event list. Error code: ${response1.statusCode}');
      }
    } catch (error) {
      throw Exception('Error during event list fetching: $error');
    }
  }

  Future<List<Map<String, dynamic>>> fetchEventDetails(int eventId) async {
    try {
      // Fetch event details using the third API
      final response2 = await http.post(
        Uri.parse('http://$ipAddress:8000/api/event/show'),
        body: {'ID_event': eventId.toString()},
      );

      if (response2.statusCode == 200) {
        final eventData = json.decode(response2.body);
        print(
            'Event Details Response for ID $eventId: $eventData'); // Print the API response

        return List<Map<String, dynamic>>.from(eventData['data']);
      } else {
        throw Exception(
            'Failed to fetch event details. Error code: ${response2.statusCode}');
      }
    } catch (error) {
      throw Exception('Error during event details fetching: $error');
    }
  }

  Widget buildEventCard(Map<String, dynamic> eventData) {
    print('Building Event Card for: $eventData'); // Print event data
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GestureDetector(
        onTap: () async {
          int idEvent = eventData['ID_event'];
          Map<String, dynamic> resolvedProfileData = await profileData;
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => UserEventPage(
              idEvent: idEvent,
              profileData: resolvedProfileData,
            ),
          ));
        },
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  height: 80,
                  child: Center(
                    child: Text(
                      eventData['nama_event'] ?? 'No Event Name',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              ListTile(
                title: Text(eventData['nama_event'] ?? 'No Event Name'),
                subtitle: Text(eventData['desc_event'] ?? 'No Description'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void fetchDataAndNavigate() async {
    try {
      // Fetch profile data
      Map<String, dynamic> profileData = await fetchProfileData(widget.userId);

      // Navigate to EventPage with the resolved profileData
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EventPage(profileData: profileData)),
      );
    } catch (error) {
      // Handle errors
      print('Error fetching and navigating: $error');
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Logout"),
          content: Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                // Perform logout logic here
                // For example, you can navigate to the login screen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MyHomePage(
                            title: '',
                          )), // Replace YourLoginPage with your actual login page
                  (Route<dynamic> route) =>
                      false, // Remove all routes from the stack
                ); // Close the dialog
              },
              child: Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 120,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          height: 150.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade300, Colors.deepPurple.shade400],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              stops: [0.1, 0.9],
            ),
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: profileData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text("Error: ${snapshot.error}"),
                );
              } else {
                final profileData = snapshot.data as Map<String, dynamic>?;

                if (profileData != null) {
                  final userFullName = profileData['nama_lengkap'] as String;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: 16),
                      Text(
                        'Hello \n${userFullName} !',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Padding(
                        padding: EdgeInsets.only(right: 16.0),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: 20.0),
                              child: IconButton(
                                icon: Icon(
                                  Icons.notifications,
                                  color: Colors.white,
                                  size: 35,
                                ),
                                onPressed: () {
                                  // Add notification logic here
                                },
                              ),
                            ),
                            CircleAvatar(
                              radius: 25,
                              child: InkWell(
                                onTap: () {
                                  _showLogoutDialog(
                                      context); // Show the logout dialog when CircleAvatar is tapped
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Text('Profile data is null');
                }
              }
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 20,
            ),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              child: ElevatedButton(
                onPressed: () {
                  fetchDataAndNavigate();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Colors.black,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Cari Event...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Eventmu",
                  style: TextStyle(
                    color: Colors.deepPurple[900],
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: eventList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                } else {
                  final List<Map<String, dynamic>> eventData =
                      snapshot.data ?? [];

                  if (eventData.isNotEmpty) {
                    return ListView.builder(
                      shrinkWrap: true, // Add this line
                      physics: NeverScrollableScrollPhysics(), // Add this line
                      itemCount: eventData.length,
                      itemBuilder: (context, index) {
                        final event = eventData[index];
                        return buildEventCard(event);
                      },
                    );
                  } else {
                    return Text('No events available');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>> fetchProfileData(String userId) async {
  final url = Uri.parse('http://$ipAddress:8000/api/profile/show');
  try {
    final response = await http.post(
      url,
      body: {'id': userId},
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('API Response: $responseData');
      return responseData['data'];
    } else {
      final errorMessage = response.body;
      throw Exception('Failed to fetch profile data: $errorMessage');
    }
  } catch (error) {
    throw Exception('Error during profile data fetching: $error');
  }
}
