import 'package:flutter/material.dart';
import 'home.dart'; // Import màn hình home

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String _password = "1234"; // Ví dụ mật khẩu cần nhập

  void _validatePassword() {
    if (_passwordController.text == _password) {
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text("Correct password!")));
      // Điều hướng tới màn hình Home khi mật khẩu đúng
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incorrect password!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  const Text("Intro Screen"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome to the app!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const Text(
              "Please enter the password to continue",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration:  const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _validatePassword,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.blueAccent,
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
