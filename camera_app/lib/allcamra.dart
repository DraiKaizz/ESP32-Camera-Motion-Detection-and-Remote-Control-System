import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'dart:math'; // Để sử dụng pi nếu cần

class AllCamerasScreen extends StatelessWidget {
  final Map<String, String> cameraIPs;

  AllCamerasScreen({required this.cameraIPs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Cameras"),
        backgroundColor: Colors.blueAccent,
      ),
      body: PageView.builder(
        itemCount: cameraIPs.length,
        itemBuilder: (context, index) {
          String areaName = cameraIPs.keys.elementAt(index);
          String cameraIP = cameraIPs[areaName] ?? "";

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Card(
              elevation: 8.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Column(
                children: [
                  // Tên khu vực (camera)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15.0),
                        topRight: Radius.circular(15.0),
                      ),
                    ),
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      areaName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Hiển thị video stream từ camera
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationX(0), // Xoay video feed
                          child: Mjpeg(
                            isLive: true,
                            stream: 'http://$cameraIP/stream',
                            fit: BoxFit.contain, // Giữ nguyên tỷ lệ video
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Thông tin thêm hoặc nút điều khiển (nếu cần)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Camera: $areaName')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                      ),
                      child: const Text(
                        "Camera Information",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
