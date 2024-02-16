import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:main/detail_event.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';

class EventPage extends StatefulWidget {
  final Map<String, dynamic> profileData;
  const EventPage({required this.profileData, Key? key}) : super(key: key);

  @override
  _EventPageState createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  Timer? _debounce;
  List<Map<String, dynamic>> events = [];
  List<String> selectedCategories = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Cancel the debounce timer on widget disposal
    super.dispose();
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
    );
  }

  Future<void> _searchEvents(String searchTerm) async {
    const int maxRetries = 20;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // Make API request to search endpoint using POST
        final response = await http.post(
          Uri.parse('http://192.168.0.103:8000/api/event/search'),
          body: {'search': searchTerm},
        );

        //print('Search Response Status Code: ${response.statusCode}');
        // print('Search Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data['is_success'] == true && data.containsKey('data')) {
            setState(() {
              events = List<Map<String, dynamic>>.from(data['data']);
            });
          } else {
            throw Exception('Invalid search response format');
          }
          return; // Successful response, exit the retry loop
        } else {
          throw Exception('Failed to fetch search results');
        }
      } catch (e) {
        //print('Error during search: $e');
        retryCount++;
        // print("Attempts:${retryCount}");
        // print('Retrying in 5 Seconds...');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Searching Error Because, Too Many Requests to Server,Now Retrying ${retryCount} of ${maxRetries}',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.deepPurple,
          ),
        );
        await Future.delayed(const Duration(seconds: 5));
      }
    }

    // Max retries reached, throw an exception
    throw Exception('Failed to fetch search results after multiple attempts');
  }

  Future<void> _fetchEvents() async {
    final response = await http
        .get(Uri.parse('http://192.168.0.103:8000/api/event/mobile/test'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      //print('Response Body: ${response.body}');

      if (data['is_success'] == true) {
        final List<dynamic> eventData = data['data'];
        setState(() {
          events = eventData.cast<Map<String, dynamic>>().toList();
          //print('Fetched events: $events'); // Add this line for debugging
        });
      }
    }
  }

  Future<List<String>> _fetchCategoryNames() async {
    final response = await http
        .get(Uri.parse('http://192.168.0.103:8000/api/event/kategori/all'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<String> categoryNames =
          data.map((category) => category['nama_kategori'].toString()).toList();
      return categoryNames;
    } else {
      throw Exception('Failed to fetch category names');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
          height: 150.0,
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
                  Text(
                    "List Event",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(child: _buildSearchBar()),
                  SizedBox(width: 8),
                  _buildFilterButton(context),
                ],
              ),
            ),
            Expanded(
              child: _buildEventList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search events',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (value) {
          // Handle search text changes with a debounce
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(seconds: 3), () {
            print('Search: $value');
            _searchEvents(value); // Call the search function after the delay
          });
        },
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        List<String> allCategoryNames = await _fetchCategoryNames();
        _showFilterDialog(context, allCategoryNames);
      },
      child: CircleAvatar(
        backgroundColor: Colors.purple[700],
        child: Icon(
          Icons.filter_list,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, List<String> allCategoryNames) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter Categories'),
          content: SingleChildScrollView(
            child: Column(
              children: allCategoryNames.map((category) {
                return CheckboxListTile(
                  title: Text(category),
                  value: selectedCategories.contains(category),
                  onChanged: (value) {
                    setState(() {
                      if (value != null) {
                        if (value) {
                          selectedCategories.add(category);
                        } else {
                          selectedCategories.remove(category);
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                primary: Colors.deepPurple,
              ),
              child: Text('Apply', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEventList() {
    // Check if there is an active search
    bool isSearching = searchController.text.trim().isNotEmpty;

    if (isSearching) {
      // Display search results
      if (events.isEmpty) {
        return Center(child: Text("No matching events"));
      } else {
        return Expanded(
          child: ListView.builder(
            physics: AlwaysScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> event = events[index];
              return _buildEventCard(event);
            },
          ),
        );
      }
    } else {
      // Display the initial event list
      return FutureBuilder<void>(
        future: _fetchEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            return Expanded(
              child: ListView.builder(
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> event = events[index];
                  return _buildEventCard(event);
                },
              ),
            );
          }
        },
      );
    }
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () {
          int idEvent = event['id'];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailEventPage(
                idEvent: idEvent,
                profileData: widget.profileData,
              ),
            ),
          );
        },
        child: Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
              bottom: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                height: 80,
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
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
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        event['kategori'] ?? '',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${event['provinsi'] ?? 'Unknown'}",
                            style: TextStyle(
                              color: Colors.purple[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text("${event['nama_event'] ?? 'Unknown'}"),
                          Text("${event['deskripsi'] ?? 'Unknown'}"),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Start Event:"),
                        Text(
                          "${_formatDate(event['start']) ?? 'Unknown Date'}",
                          textAlign: TextAlign.end,
                        ),
                      ],
                    ),
                  ],
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
              ),
            ],
          ),
        ),
      ),
    );
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
