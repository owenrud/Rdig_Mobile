import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:main/otpScreen.dart';
import 'dart:convert';
import 'package:main/global_variable.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

Future<List<String>>? _provincesFuture;
Future<List<String>>? _districtsFuture;

// This will give you the local IPv4 address

class _RegisterPageState extends State<RegisterPage> {
  @override
  void initState() {
    super.initState();
    _provincesFuture = _fetchProvinces();
  }

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();

  List<String> genders = ['Male', 'Female', 'Other'];
  String selectedGender = 'Male';
  List<String> provinces = [];
  String selectedProvince = '';
  Map<String, int> provinceIdMap = {};
  Map<String, int> districtIdMap = {};

  List<String> districts = [];
  String selectedDistrict = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: <Color>[
              Color(0xFF9575CD),
              Color(0XFFBA68C8),
            ],
            stops: [0.1, 0.9],
            tileMode: TileMode.mirror,
          ),
        ),
        constraints: BoxConstraints.expand(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Register',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField("Email", _emailController, Icons.email),
                _buildTextField("Password", _passwordController, Icons.lock,
                    isPassword: true),
                _buildDropdownField("Gender", selectedGender, genders,
                    _handleGenderChange, Icons.person),
                _buildTextField("Full Name", _fullNameController, Icons.person),
                _buildTextField(
                    "Phone Number", _phoneNumberController, Icons.phone),
                _buildTextField("Address", _addressController, Icons.home),
                _buildProvincesDropdown(),
                _buildDropdownField("District", selectedDistrict, districts,
                    _handleDistrictChange, Icons.location_on),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Register',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
  }

  Future<List<String>> _fetchProvinces() async {
    try {
      final response = await http
          //.get(Uri.parse("http://192.168.0.105:8000/api/provinsi/all"));
          .get(Uri.parse("http://$ipAddress:8000/api/provinsi/all"));

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        // print("API Response: ${response.body}");

        if (responseData['is_success'] == true) {
          List<dynamic> provincesData = responseData['data'];

          Set<String> uniqueProvinceNames = provincesData
              .where((item) =>
                  (item['nama'] as String?)?.isNotEmpty == true &&
                  (item['ID_provinsi'] as int?) != null)
              .map<String>((item) {
            int id = item['ID_provinsi'];
            provinceIdMap[item['nama']] = id;

            return item['nama'] as String;
          }).toSet();

          List<String> provinceNames = uniqueProvinceNames.toList();

          if (selectedProvince.isEmpty && provinceNames.isNotEmpty) {
            setState(() {
              selectedProvince = provinceNames[0];
            });
          }

          setState(() {
            provinces = provinceNames;
            selectedProvince = provinceNames.isNotEmpty ? provinceNames[0] : '';
          });
          return provinceNames;
        } else {
          print("API response indicates failure");
          throw Exception("API response indicates failure");
        }
      } else {
        print("Failed to load provinces");
        throw Exception("Failed to load provinces");
      }
    } catch (error) {
      print("Error during province fetching: $error");
      throw Exception("Error during province fetching: $error");
    }
  }

  Future<List<String>> _fetchDistricts(int idProvinsi) async {
    try {
      final response = await http.post(
        Uri.parse("http://$ipAddress:8000/api/kabupaten/show"),
        body: {'id_provinsi': idProvinsi.toString()},
      );

      print("response district: ${response.body}");
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['is_success'] == true) {
          List<dynamic> districtsData = responseData['data'];

          // Map district names to their IDs
          districtsData.forEach((district) {
            int id = district['id'];
            String name = district['nama'];
            districtIdMap[name] = id;
          });

          Set<String> uniqueDistrictNames = districtsData
              .where((item) => (item['nama'] as String?)?.isNotEmpty == true)
              .map<String>((item) => item['nama'] as String)
              .toSet();

          List<String> districtNames = uniqueDistrictNames.toList();

          if (selectedDistrict.isEmpty && districtNames.isNotEmpty) {
            setState(() {
              selectedDistrict = districtNames[0];
            });
          }

          setState(() {
            districts = districtNames;
          });
          return districtNames;
        } else {
          print("API response indicates failure");
          throw Exception("API response indicates failure");
        }
      } else {
        print("Failed to load districts");
        throw Exception("Failed to load districts");
      }
    } catch (error) {
      print("Error during district fetching: $error");
      throw Exception("Error during district fetching: $error");
    }
  }

  Widget _buildProvincesDropdown() {
    return FutureBuilder<List<String>>(
      future: _provincesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Text("No provinces available");
        } else {
          return _buildDropdownField(
            "Province",
            selectedProvince,
            snapshot.data!,
            _handleProvinceChange,
            Icons.location_city,
          );
        }
      },
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          prefixIcon: Icon(icon, color: Colors.white),
          filled: true,
          fillColor: Colors.deepPurpleAccent[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String selectedValue,
      List<String> items, void Function(String?) onChanged, IconData icon) {
    // print("Items before dropdown creation: $items");
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          prefixIcon: Icon(icon, color: Colors.white),
          filled: true,
          fillColor: Colors.deepPurpleAccent[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue,
            onChanged: onChanged,
            items: items.map<DropdownMenuItem<String>>((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _handleGenderChange(String? value) {
    setState(() {
      selectedGender = value ?? "";
    });
  }

  void _handleProvinceChange(String? value) async {
    print("Selected Province: $value");
    if (value != null) {
      int idProvinsi = provinceIdMap[value] ?? 0;
      print("ID Provinsi:${idProvinsi}");
      // Check if idProvinsi is 0, which means it's not found in the map
      if (idProvinsi != 0) {
        // Call _fetchDistricts and update _districtsFuture
        try {
          List<String> districts = await _fetchDistricts(idProvinsi);

          // Update the districts list and reset selectedDistrict
          setState(() {
            _districtsFuture = Future.value(districts);
            selectedProvince = value;
            selectedDistrict = districts.isNotEmpty ? districts[0] : '';
            _provinceController.text = idProvinsi.toString();
            // Add this line to update the controller
          });
        } catch (error) {
          print("Error during district fetching: $error");
          // Handle the error as needed
        }
      } else {
        // Handle the case where the province is not found
        print("Province ID not found for $value");
      }
    }
  }

  void _handleDistrictChange(String? value) async {
    print("Selected District: $value"); // Log the selected district name

    if (value != null) {
      // Find the district ID based on its name in the fetched data
      int? districtId = districtIdMap[value];

      if (districtId != null) {
        // If the district ID is found, set it to the controller
        _districtController.text = districtId.toString();
        setState(() {
          selectedDistrict = value;
        });
        print(
            "District ID: $districtId"); // Log the ID of the selected district
      } else {
        // Handle the case where the district ID is not found
        print("District ID not found for $value");
      }
    }
  }

  void _registerUser() async {
    // Validate the form before making the API call
    if (_validateForm()) {
      try {
        // Make the registration API call
        final response = await http.post(
          Uri.parse('http://$ipAddress:8000/api/register-account'),
          body: {
            'email': _emailController.text,
            'password': _passwordController.text,
            'role': 'user', // Set the role as needed
            'verify_email': '0', // You may adjust this as needed
            'full_name': _fullNameController.text,
            'no_telp': _phoneNumberController.text,
            'alamat': _addressController.text,
            'provinsi': _provinceController.text,
            'kabupaten': _districtController.text,
            'profile_picture': '', // Set the profile picture URL or leave empty
          },
        );

        if (response.statusCode == 201) {
          // Registration successful
          // You can handle the success response here
          print('Registration successful');
          //print(response.body);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => OTPScreen(
                      email: _emailController.text,
                    )),
          );
        } else {
          // Registration failed
          // You can handle the failure response here
          print('Registration failed');
          print(response.body);
        }
      } catch (error) {
        // Handle any errors that occurred during the API call
        print('Error during registration: $error');
      }
    }
  }

// Function to validate the form before making the API call
  bool _validateForm() {
    // Implement your form validation logic here
    // For example, check if required fields are not empty
    /* print('Email: ${_emailController.text}');
    print('Password: ${_passwordController.text}');
    print('Full Name: ${_fullNameController.text}');
    print('Phone Number: ${_phoneNumberController.text}');
    print('Address: ${_addressController.text}');*/
    print('Province: ${_provinceController.text}');
    print('District: ${_districtController.text}');
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        _phoneNumberController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _provinceController.text.isEmpty ||
        _districtController.text.isEmpty) {
      // Show an error message or handle the validation failure
      print('Form validation failed');
      return false;
    }

    // The rest of your validation logic can go here...

    // If all validations pass, return true
    return true;
  }
}

void main() {
  runApp(MaterialApp(
    home: RegisterPage(),
  ));
}
