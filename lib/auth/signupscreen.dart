import 'package:flutter/material.dart';
import 'package:carhive/auth/auth_service.dart';

class Signupscreen extends StatefulWidget {
  const Signupscreen({super.key});

  @override
  State<Signupscreen> createState() => _SignupscreenState();
}

class _SignupscreenState extends State<Signupscreen> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  @override
  void dispose(){
    super.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text("Signup"),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: "Name",
            ),
          ),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: "Email",
            ),
          ),
          TextField(  
            controller: _passwordController,
            decoration: InputDecoration(
              hintText: "Password",
            ),
          ),
          ElevatedButton(
            onPressed: _signup,
            child: Text("Signup"),
          )
        ],
      ),
    );
  }

  goToHome(BuildContext context){
    Navigator.pushNamed(context, '/home');
  }
  _signup() async{
    final user = await _authService.createUserWithEmailAndPassword(_emailController.text, _passwordController.text);
    if(user != null){
      print("User created successfully");
      goToHome(context);
    }
  }
}