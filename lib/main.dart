import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/authorizedbuyersmarketplace/v1.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:googleapis/fitness/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

final _googleSignIn = GoogleSignIn(
  scopes: [
    FitnessApi.fitnessActivityReadScope,
    FitnessApi.fitnessBloodPressureReadScope,
    FitnessApi.fitnessSleepReadScope,
    'email',
    'https://www.googleapis.com/auth/plus.me',
    'https://www.googleapis.com/auth/fitness.body.read',
    'https://www.googleapis.com/auth/contacts.readonly',
    'https://www.googleapis.com/auth/fitness.activity.read',
    'https://www.googleapis.com/auth/fitness.blood_glucose.read',
    'https://www.googleapis.com/auth/fitness.blood_pressure.read',
    'https://www.googleapis.com/auth/fitness.body.read',
    'https://www.googleapis.com/auth/fitness.body_temperature.read',
    'https://www.googleapis.com/auth/fitness.heart_rate.read',
    'https://www.googleapis.com/auth/fitness.nutrition.read',
    'https://www.googleapis.com/auth/fitness.oxygen_saturation.read',
  ],
);
late bool _isAuth;
Future<void> main() async {

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'My App',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePage();
}

class _MyHomePage extends State<MyHomePage> {
  static const channelRequest = MethodChannel('flutter.fit.requests');
  bool _isAuth = false;
  String text = 'No data';
  @override
  void initState() {
    super.initState();
    checkUserLoggedIn();
  }

  void checkUserLoggedIn() async {
    bool isSignedIn = await _googleSignIn.isSignedIn();
    setState(() {
      _isAuth = isSignedIn;
    });
  }
  var steps = 'no data';
  var weightTxt = '0';
  var heightTxt = '0';

  Future<String> _getHealthData() async {
    if (_isAuth) {
      var status = await Permission.activityRecognition.request();
      if (status.isGranted) {
        try{
          final String result = await channelRequest.invokeMethod('getHealthData');
          print('success');
          return result;
        }on PlatformException catch (e){
          return 'Error: $e';
        }
      }else{
        return 'No permissions';
      }
    }else{
      return 'U must be logged in!';
    }
  }

  Future<String> _getStepsDay() async {
    if (_isAuth) {
      var status = await Permission.activityRecognition.request();
      if (status.isGranted) {
        try{
          final String result = await channelRequest.invokeMethod('getStepsDay');
          print('success');
          return result;
        }on PlatformException catch (e){
          return 'Error: $e';
        }
      }else{
        return 'No permissions';
      }
    }else{
      return 'U must be logged in!';
    }
  }

  Future<String> _getHeight() async {
    if (_isAuth) {
      var status = await Permission.activityRecognition.request();
      if (status.isGranted) {
        try{
          final String result = await channelRequest.invokeMethod('getHeight');
          print('success');
          return result;
        }on PlatformException catch (e){
          return 'Error: $e';
        }
      }else{
        return 'No permissions';
      }
    }else{
      return 'U must be logged in!';
    }
  }

  DateTime now = DateTime.now();
  DateTime oneWeekAgo = DateTime.now().subtract(Duration(days: 7));


  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: _googleSignIn.currentUser != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(_googleSignIn.currentUser != null
                      ? _googleSignIn.currentUser!.email
                      : 'null'),
                  ElevatedButton(
                    onPressed: () async {
                      String res = await _getHealthData();
                      setState(() {
                        text =
                            'Шаги за неделю: $res (${DateFormat('dd.MM').format(oneWeekAgo)} - ${DateFormat('dd.MM').format(now)})';
                      });
                      
                      print(res);
                    },
                    child: const Text('Get week steps'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      String res = await _getStepsDay();
                      setState(() {
                        text = 'Шаги за день: $res';
                      });
                      print(res);
                    },
                    child: const Text('Get day steps'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      String res = await _getHeight();
                      setState(() {
                        text = 'Рост: $res м.';
                      });
                      print(res);
                    },
                    child: const Text('Get height'),
                  ),
                  Text(text),


                  ElevatedButton(
                      child: const Text('SignOut'),
                      onPressed: () {
                          _googleSignIn.signOut();

                        checkUserLoggedIn();
                      }),
                ],
              )
            : ElevatedButton(
                child: const Text('SignIn'),
                onPressed: () async {
                  _googleSignIn.signIn();
                  checkUserLoggedIn();
                },
              ),
      ),
    );
  }
}
