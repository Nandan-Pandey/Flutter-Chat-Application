import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:push_chat_app/widgets/user_image_picker.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var _enteredEmail = '';
  var _enteredPass = '';
  var _enteredUsername = '';
  final _formKey = GlobalKey<FormState>();
  var _isLogin = true;
  var _isAuthenticating = false;

  File? _selectedImage;

  // void _isSubmit() async {
  //   final _isValid = _formKey.currentState!.validate();
  //   if (!_isValid) {
  //     return;
  //   }
  //   if (!_isValid || !_isLogin || _selectedImage == null) {
  //     return;
  //   }
  //   _formKey.currentState!.save();

  //   if (_isLogin) {
  //     //log users in
  //     try {
  //       final userCredentials = await _firebase.signInWithEmailAndPassword(
  //           email: _enteredEmail, password: _enteredPass);
  //       print(userCredentials);
  //     } on FirebaseAuthException catch (error) {
  //       ScaffoldMessenger.of(context).clearSnackBars();
  //       ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text(error.message ?? 'Login failed')));
  //     }
  //   } else {
  //     try {
  //       final userCredentials = await _firebase.createUserWithEmailAndPassword(
  //           email: _enteredEmail, password: _enteredPass);
  //       print(userCredentials);

  //       final storageRef = FirebaseStorage.instance
  //           .ref()
  //           .child('user_images')
  //           .child('${userCredentials.user!.uid}.jpg');

  //       await storageRef.putFile(_selectedImage!);
  //       final imageUrl = storageRef.getDownloadURL();
  //       print(imageUrl);

  //     } on FirebaseAuthException catch (error) {
  //       if (error == 'email-already-in-use') {}

  //       ScaffoldMessenger.of(context).clearSnackBars();
  //       ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(content: Text(error.message ?? 'Authentication failed')));
  //     }
  //   }
  // }

  void _isSubmit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid || !_isLogin && _selectedImage == null) {
      return;
    }
    _formKey.currentState!.save();
    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_isLogin) {
        final UserCredential = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPass);
        print(UserCredential);
      } else {
        final userCredential = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPass);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('Users_Images')
            .child('${userCredential.user!.uid}.jpg');
        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();
        print(imageUrl);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': _enteredUsername,
          'email': _enteredEmail,
          'image_url': imageUrl
        });
        // await Firebase.instance
        //     .collection('users')
        //     .doc(userCredential.user!.uid)
        //     .set({
        //   'username': _enteredUsername,
        //   'email': _enteredEmail,
        //   'image_url': imageUrl
        // });
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        //..
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Authentication Failed')));
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                    top: 30, bottom: 20, left: 20, right: 20),
                width: 200,
                child: Image.asset(
                  'assets/images/chat.png',
                ),
              ),
              Card(
                margin: EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_isLogin)
                              UserImagePicker(
                                onPickImage: (pickedImage) {
                                  _selectedImage = pickedImage;
                                },
                              ),
                            TextFormField(
                                decoration: const InputDecoration(
                                    labelText: 'Email Address'),
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                textCapitalization: TextCapitalization.none,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty ||
                                      !value.contains('@')) {
                                    return 'Please enter a valid address';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _enteredEmail = value!;
                                }),
                            TextFormField(
                                decoration: const InputDecoration(
                                    labelText: 'Password'),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().length < 6) {
                                    return 'Password must be atleast 6 character long';
                                  }
                                },
                                onSaved: (value) {
                                  _enteredPass = value!;
                                }),
                            // USERNAME
                            if(!_isLogin)
                            TextFormField(
                                decoration:
                                    const InputDecoration(labelText: 'Name'),
                                enableSuggestions: false,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().length < 4 ||
                                      value.isEmpty) {
                                    return 'Plz enter atleast 4 characters';
                                  }
                                },
                                onSaved: (value) {
                                  _enteredUsername = value!;
                                }),
                            const SizedBox(
                              height: 12,
                            ),
                            if (_isAuthenticating) CircularProgressIndicator(),
                            if (!_isAuthenticating)
                              ElevatedButton(
                                  onPressed: _isSubmit,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer),
                                  child: Text(_isLogin ? 'Login' : 'Signup')),
                            if (!_isAuthenticating)
                              TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLogin = !_isLogin;
                                    });
                                  },
                                  child: Text(_isLogin
                                      ? 'Create an account'
                                      : 'Already have an account'))
                          ],
                        )),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
