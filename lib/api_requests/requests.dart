import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


final _baseURL = 'https://recycler-api.herokuapp.com';
final _loginEndpoint = '/users/login/';

Future<String> fetchToken(String userName, String password, BuildContext context) async {
  final _loginURL = _baseURL + _loginEndpoint;
  
  final http.Response response = await http.post(
    _loginURL,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'username': userName,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
  // If the server did return a 200 OK response,
  // then parse the JSON.
    var responseJson = jsonDecode(response.body);
    return responseJson['token'];
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    return null;
  }
}

