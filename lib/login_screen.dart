import 'package:allergy_app/home_screen.dart';
import 'package:allergy_app/quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _keepMeLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  Future<void> _checkIfLoggedIn() async {
    final user = _auth.currentUser;
    if (user != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        UserCredential userCredential =
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if ((userCredential.additionalUserInfo?.isNewUser ?? false) &&
            mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const QuizScreen()),
            );
          });
          return;
        }
      }

      if (_isLogin && _auth.currentUser != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1D1E33),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          user == null ? '' : 'Welcome, ${user.email ?? 'User'}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: user != null
            ? [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
          )
        ]
            : null,
      ),
      body: user != null
          ? Center(
        child: Text(
          'Logged in as ${user.email ?? 'User'}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      )
          : SingleChildScrollView(
        padding:
        const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'FOODGUARD',
              style: TextStyle(
                color: Color(0xFF00E676),
                fontSize: 30,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 50),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'example@gmail.com',
                labelStyle: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontFamily: 'Nunito'),
                prefixIcon: const Icon(Icons.email, color: Colors.white),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                  const BorderSide(color: Color(0xFF00E676)),
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: '••••••••',
                labelStyle:
                TextStyle(color: Colors.white.withOpacity(0.7)),
                prefixIcon:
                const Icon(Icons.lock, color: Colors.white),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                  const BorderSide(color: Color(0xFF00E676)),
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Checkbox(
                  value: _keepMeLoggedIn,
                  onChanged: (bool? newValue) {
                    setState(() {
                      _keepMeLoggedIn = newValue!;
                    });
                  },
                  activeColor: const Color(0xFF00E676),
                  checkColor: Colors.black,
                  side: BorderSide(color: Colors.white.withOpacity(0.7)),
                ),
                Text(
                  'Keep me logged in',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontFamily: 'Nunito'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signInWithEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.black),
                )
                    : Text(
                  _isLogin ? 'LOGIN' : 'SIGN UP',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                  _errorMessage = null;
                });
              },
              child: Text(
                _isLogin
                    ? 'Don\'t have an account? Sign up here'
                    : 'Already have an account? Sign In',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontFamily: 'Nunito',
                  decorationColor: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
