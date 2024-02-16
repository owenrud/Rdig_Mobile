import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:qr_flutter/qr_flutter.dart';

class QrCodePage extends StatelessWidget {
  final String qrData;
  final Map<String, dynamic> profileData;

  const QrCodePage({Key? key, required this.qrData, required this.profileData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello ${profileData['nama_lengkap']}",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: 10,
            ),
          ],
        ),
        toolbarHeight: 120,
        flexibleSpace: Container(
          padding: EdgeInsets.fromLTRB(8.0, 30.0, 16.0, 0.0),
          height: 120.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade300, Colors.deepPurple.shade400],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              stops: [0.1, 0.9],
            ),
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 10,
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.purple,
                          ),
                          SizedBox(height: 20),
                          Text(
                            "${profileData['nama_lengkap']}",
                            style: TextStyle(fontSize: 24),
                          ),
                          Text(
                            "${profileData['no_telp']}",
                            style: TextStyle(fontSize: 20),
                          ),
                          SizedBox(
                            height: 50,
                          ),
                          Text(
                            "Peserta Event QR Code",
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Expanded(
                            child: QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 250.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
