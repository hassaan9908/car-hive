import 'package:carhive/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:carhive/auth/signupscreen.dart';
import 'package:carhive/pages/homepage.dart';
class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  final _auth = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose(){
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          children: [
              Text(
                'Login',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                ),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Name'
                  ),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: 'Password'
                  ),
                ),
                ElevatedButton(
                  onPressed: _login,
                   child: Text('Login')
                ),
                Row(
                  children: [
                    Text('Dont have account!'),
                    TextButton(onPressed: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Signupscreen()));
                    },
                    child: Text(
                      'SignUp',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      ))
                  ],
                )
          ],
        )
      ),
      
    );
  }

  goToHome(BuildContext context){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Homepage()));
  }

  _login() async{
    final user = await _auth.loginUserWithEmailAndPassword(_emailController.text, _passwordController.text);

    if (user != null){
      print("User logged In");
      goToHome(context);
    }
  }
}