// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';

void main() {
  runApp(const LatLngTrackerApp());
}

class LatLngTrackerApp extends StatefulWidget {
  const LatLngTrackerApp({super.key});

  @override
  State<LatLngTrackerApp> createState() => _LatLngTrackerAppState();
}

class _LatLngTrackerAppState extends State<LatLngTrackerApp> {
  Timer? _timer;
  final List<Map<String, dynamic>> _locationData = [];
  late File _locationFile;

  @override
  void initState() {
    super.initState();
    _initLocationFile();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Location Tracker'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _toggleTracking,
                child:
                    Text(_timer == null ? 'Start Tracking' : 'Stop Tracking'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------- FUNCTIONS --------------------------------------------

  Future<void> _initLocationFile() async {
    await DownloadsPath.downloadsDirectory();
    String? downloadsDirectoryPath =
        (await DownloadsPath.downloadsDirectory())?.path;
    final now = DateTime.now();
    final fileName = 'location_data_${now.year}${now.month}${now.day}.json';
    _locationFile = File('$downloadsDirectoryPath/$fileName');

    if (!_locationFile.existsSync()) {
      _locationFile.createSync();
      _locationFile.writeAsStringSync('[]');
    }
  }

  Future<void> _toggleTracking() async {
    if (_timer == null) {
      bool hasPermission = await _checkLocationPermission();
      if (hasPermission) {
        // Start tracking
        _timer = Timer.periodic(const Duration(seconds: 2), (_) {
          _trackLocation();
        });
        Timer(const Duration(seconds: 30), () {
          _toggleTracking();
          setState(() {});
        });
      } else {
        // Handle location permission denied
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location Permission'),
            content:
                const Text('Please grant permission to access your location.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      // Stop tracking
      setState(() {
        _timer?.cancel();
        _timer = null;
      });
    }
  }

  Future<bool> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      final permissionStatus = await Geolocator.requestPermission();
      return permissionStatus == LocationPermission.always ||
          permissionStatus == LocationPermission.whileInUse;
    } else {
      return true;
    }
  }

  Future<void> _trackLocation() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    final location = {
      'timestamp': DateTime.now().toIso8601String(),
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
    print(location);
    setState(() {
      _locationData.add(location);
    });
    _saveLocationData();
  }

  Future<void> _saveLocationData() async {
    final jsonData = json.encode(_locationData);
    final meow = await _locationFile.writeAsString(jsonData);
    print(meow.path);
  }
}
