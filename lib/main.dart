import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/authorizedbuyersmarketplace/v1.dart';
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
  Future<void> _getHealthData() async {
    if (_isAuth) {
      var status = await Permission.activityRecognition.request();
      if (status.isGranted) {
        try {
          var t = await channelRequest.invokeMethod('getHealthData');
          final authClient = await _googleSignIn.authenticatedClient();
          print('client: $authClient');
          FitnessApi api = FitnessApi(authClient!);
          final dataSources = await api.users.dataSources.list('me');
          print('dataSources: ${dataSources.dataSource}');
          for (var dataSource in dataSources.dataSource!) {
            print('Data Source ID: ${dataSource.dataStreamId}');
            print('Data Source Type: ${dataSource.type}');
            // Выводим другую информацию об источнике данных по желанию
          }

          final now = DateTime.now();
          final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0, 0);
          final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

          // final startTime = startOfDay.microsecondsSinceEpoch * 1000;
          // final endTime = endOfDay.microsecondsSinceEpoch * 1000;
          // final datasetId = '$startTime-$endTime';

          // final startTime = now.subtract(Duration(hours: 24)).microsecondsSinceEpoch * 1000;
          // final endTime = now.microsecondsSinceEpoch * 1000;
          // final datasetId = '$startTime-$endTime';

          final DateTime startDate = DateTime(2010);
          final DateTime endDate = DateTime.now();

          final int startTime = startDate.microsecondsSinceEpoch * 1000;
          final int endTime = endDate.microsecondsSinceEpoch * 1000;

          // Убедитесь, что startTime меньше endTime
          if (startTime >= endTime) {
            print('Ошибка: Неверный временной диапазон.');
            return;
          }

          final datasetId = '$startTime-$endTime';

          final data = await api.users.dataSources.datasets.get(
              'me',
              'derived:com.google.step_count.delta:com.google.android.gms:estimated_steps',
              datasetId);
          final weight = await api.users.dataSources.datasets.get(
              'me',
              'raw:com.google.weight:com.google.android.apps.fitness:user_input',
              datasetId
          );
          print('weight: ${weight.point}');
          if (weight.point != null && weight.point!.isNotEmpty) {
            // Получение значения веса из первой точки данных
            double? weightValue = weight.point![0].value![0].fpVal;

            // Преобразование веса в строку и округление до одной десятичной цифры
            String weightString = weightValue!.toStringAsFixed(1);

            // Обновление значения переменной weightTxt
            setState(() {
              weightTxt = weightString;
            });
          }

          final height = await api.users.dataSources.datasets.get(
              'me',
              'raw:com.google.height:com.google.android.apps.fitness:user_input',
              datasetId);
          print('height: ${height.point}');
          if (height.point != null && height.point!.isNotEmpty) {
            // Получение значения роста из первой точки данных
            double? heightValue = height.point![0].value![0].fpVal;

            // Преобразование роста в строку и округление до одной десятичной цифры
            String heightString = heightValue!.toStringAsFixed(2);

            // Обновление значения переменной heightTxt
            setState(() {
              heightTxt = heightString;
            });
          }

          print('data: ${data.point}');

          int totalSteps = 0;

          // Перебираем каждый объект DataPoint и извлекаем количество шагов из него
          for (var dataPoint in data.point!) {
            // Каждый dataPoint имеет поле "value", которое содержит значение шагов

            final int steps = dataPoint.value![0].intVal!;
            // Добавляем количество шагов из текущего dataPoint к общему количеству шагов
            totalSteps += steps;
          }

          // Выводим общее количество шагов
          print('Total steps: $totalSteps');
          setState(() {
            steps = totalSteps.toString();
          });

          print('debug: $t');
          if (t == null) {
            setState(() {
              text = 'null';
            });
          } else if (t != null) {
            print('успех!');
            setState(() {
              text = t;
            });
          } else {
            setState(() {
              text = 'error';
            });
          }
        } catch (e) {
          print('Ошибка при вызове "getHealthData": $e');
          setState(() {
            text = 'error';
          });
        }
      } else {
        print('permission error');
        setState(() {
          text = 'error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: _isAuth
            ? Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(_googleSignIn.currentUser != null
                      ? _googleSignIn.currentUser!.email
                      : 'null'),
                  ElevatedButton(
                    onPressed: _getHealthData,
                    child: const Text('Get health data'),
                  ),
                  Text(text),
                  Text('Steps: $steps'),
                  Text('Вес: $weightTxt кг.'),
                  Text('Рост: $heightTxt м.'),
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
