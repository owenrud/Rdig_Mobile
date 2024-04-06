import 'package:flutter/material.dart';
import 'package:main/guest.dart';
import 'package:http/http.dart' as http;
import 'package:main/register.dart';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:main/global_variable.dart';

void main() async {
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.deepPurple,
      ),
      home: const MyHomePage(title: ''),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
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
            stops: [
              0.1,
              0.9
            ], // Gradient from https://learnui.design/tools/gradient-generator.html
            tileMode: TileMode.mirror,
          ),
        ),
        constraints: BoxConstraints.expand(),
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Halo!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Selamat datang di aplikasi registrasi digital',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Input Email
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email),
                    labelText: 'Email',
                    filled: true,
                    fillColor: Colors.deepPurple[200],
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Input Kata Sandi
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock),
                    labelText: 'Kata Sandi',
                    filled: true,
                    fillColor: Colors.deepPurple[200],
                    labelStyle: const TextStyle(color: Colors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _gradientButton(
                      text: 'MASUK',
                      startColor: Colors.purple[300]!,
                      endColor: Colors.purple[900]!,
                      onPressed: () {
                        loginUser(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.white,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        "atau",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10), // Adjust the height as needed

                // Google sign-in button
                ElevatedButton.icon(
                  onPressed: () => _handleGoogleSignIn(context),
                  icon: const Icon(Icons.g_mobiledata_rounded),
                  label: const Text(
                    "Masuk dengan Google",
                    style: TextStyle(fontSize: 20),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Belum Punya Akun ?",
                      style: TextStyle(color: Colors.white),
                    ),
                    _gradientText(
                      text: 'Daftar Sekarang',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RegisterPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                // Adjust the height as needed
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleSignInAccount =
          await _googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;

        final String googleIdToken = googleSignInAuthentication.idToken ?? '';

        // Check if the user is already registered in your database
        Map<String, dynamic>? userData =
            await getUserDataByGoogleId(googleIdToken);

        if (userData != null && userData['is_registered'] == true) {
          int userId = userData['user']['ID_User'];

          // If the user is registered, navigate to the GuestPage with the userId
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GuestPage(userId: userId.toString()),
            ),
          );
        } else {
          // If the user is not registered, navigate to the registration page
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RegisterPage(),
            ),
          );
        }
      } else {
        print('Google Sign-In canceled');
      }
    } on PlatformException catch (platformException) {
      // Handle specific platform exceptions
      if (platformException.code == 'sign_in_failed') {
        // Handle sign-in failure
        print('Error during Google Sign-In: ${platformException.message}');
      } else {
        // Handle other platform exceptions
        print('Error during Google Sign-In: $platformException');
      }
    } catch (error) {
      // Handle generic errors
      print('Error during Google Sign-In: $error');
    }
  }

  Future<Map<String, dynamic>?> getUserDataByGoogleId(
      String googleIdToken) async {
    try {
      final Uri apiUrl = Uri.parse('http://$ipAddress:8000/api/user/GID');
      final response = await http.post(
        apiUrl,
        body: {'googleId': googleIdToken},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        // Handle API error
        print('Error fetching user data by Google ID: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      // Handle generic errors
      print('Error fetching user data by Google ID: $error');
      return null;
    }
  }

  Future<void> loginUser(BuildContext context) async {
    String email = emailController.text;
    String password = passwordController.text;

    final url = Uri.parse('http://$ipAddress:8000/api/user/login');

    final response = await http.post(
      url,
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      // Login berhasil
      final responseData = json.decode(response.body);
      int userId = responseData['user']['ID_User'];

      print('Login Successful: $responseData');

      // Lanjutkan ke halaman berikutnya, misalnya GuestPage
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GuestPage(userId: userId.toString()),
        ),
      );
    } else {
      // Login gagal, mungkin tampilkan pesan kesalahan
      final errorMessage = response.body;
      print('Login Failed: $errorMessage');
    }
    emailController.clear();
    passwordController.clear();
  }

  Widget _gradientText({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 50, horizontal: 15),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.purpleAccent[700],
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// Metode untuk membuat tombol dengan efek gradien
Widget _gradientButton({
  required String text,
  required Color startColor,
  required Color endColor,
  required VoidCallback onPressed,
}) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [startColor, endColor],
      ),
      borderRadius: BorderRadius.circular(25),
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ),
      ),
    ),
  );
}
