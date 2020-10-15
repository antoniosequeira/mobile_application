import 'dart:core';
import 'package:flutter/material.dart';
import 'package:recycler_mobile/api_requests/requests.dart';
import 'package:recycler_mobile/screens/menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatelessWidget {
  
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  String token;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Sign In', ),
        ),
        body: Padding(
            padding: EdgeInsets.all(10),
            child: ListView(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'User Name',
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextField(
                    obscureText: true,
                    controller: passwordController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                    ),
                  ),
                ),
                Container(
                  height: 50,
                    margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: RaisedButton(
                      textColor: Colors.white,
                      color: Colors.blue,
                      child: Text('Login'),
                      onPressed: () async {
                        var token = await fetchToken(nameController.text, passwordController.text, context);
                        if (token.isNotEmpty) {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString('token', token);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => Menu()),);
                        }
                      }
                    )),
              ],
            )));
  }
}