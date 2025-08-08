import 'package:firebase_auth/firebase_auth.dart';


class AuthService{

  final _auth = FirebaseAuth.instance;

 

  Future<User?> createUserWithEmailAndPassword(String email,String password) async{
    try{
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return cred.user;
    }catch(e){
      print("Registration error: $e");
      rethrow; // Re-throw to allow UI to handle the error
    }
  }

  Future<User?> loginUserWithEmailAndPassword(String email,String password) async{
    try{
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return cred.user;
    }catch(e){
      print("Login error: $e");
      rethrow; // Re-throw to allow UI to handle the error
    }
  }

  Future<void> signout() async{
    try{
      await _auth.signOut();
    }catch(e){
      print("Sign out error: $e");
      rethrow; // Re-throw to allow UI to handle the error
    }
  }
  
}