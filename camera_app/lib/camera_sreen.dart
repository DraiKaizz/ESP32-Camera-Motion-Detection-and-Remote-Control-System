import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:http/http.dart' as http;

class CameraScreen extends StatefulWidget {
  final String areaName;
  final String cameraIP;

  CameraScreen({required this.areaName, required this.cameraIP});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool isRunning = true;
  bool isFullScreen = false;
  bool isFlashOn = false; // Trạng thái của đèn 1
  bool isFlash2On = false; // Trạng thái của đèn 2
  bool isFlash3On = false; // Trạng thái của đèn 2
  int currentAngle = 90; // Góc hiện tại của servo (bắt đầu ở 90°)
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchLightStatus(); // Lấy trạng thái từ server khi khởi tạo màn hình
  }

  Future<void> fetchLightStatus() async {
    try {
      final url1 = Uri.parse('http://${widget.cameraIP}/status-light');
      final url2 = Uri.parse('http://${widget.cameraIP}/status-light2');

      final response1 = await http.get(url1);
      final response2 = await http.get(url2);

      if (response1.statusCode == 200 && response2.statusCode == 200) {
        setState(() {
          isFlashOn = response1.body.trim() == '1'; // Assuming server returns '1' for ON
          isFlash2On = response2.body.trim() == '1'; // Assuming server returns '1' for ON
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching light status: $e')),
      );
    }
  }

  Future<void> toggleFlash() async {
    try {
      setState(() {
        isRunning = false;
      });

      final url = Uri.parse('http://${widget.cameraIP}/toggle-light');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          isFlashOn = !isFlashOn;
          isRunning = true;
        });
      } else {
        throw Exception('Failed to toggle flash');
      }
    } catch (e) {
      setState(() {
        isRunning = true;
      });
    }
  }

  Future<void> toggleFlash2() async {
    try {
      setState(() {
        isRunning = false;
      });

      // Bật cả đèn 2 và đèn 3
      final url1 = Uri.parse('http://${widget.cameraIP}/toggle-light2');
      final url2 = Uri.parse('http://${widget.cameraIP}/toggle-light3');

      final response1 = await http.get(url1);
      final response2 = await http.get(url2);

      if (response1.statusCode == 200 && response2.statusCode == 200) {
        setState(() {
          isFlash2On = !isFlash2On;
          // Cập nhật trạng thái của đèn 3 tương tự đèn 2
          isFlash3On = !isFlash3On;
          isRunning = true;
        });
      } else {
        throw Exception('Failed to toggle flash 2 and flash 3');
      }
    } catch (e) {
      setState(() {
        isRunning = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  Future<void> controlServo(int angle) async {
    try {
      setState(() {
        isRunning = false;
      });

      final url = Uri.parse('http://${widget.cameraIP}/servo');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'text/plain'},
        body: angle.toString(),
      );

      if (response.statusCode == 200) {
        setState(() {
          currentAngle = angle;
          isRunning = true;
        });
      } else {
        throw Exception('Failed to control servo');
      }
    } catch (e) {
      setState(() {
        isRunning = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.areaName),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
            onPressed: () {
              setState(() {
                isFullScreen = !isFullScreen;
              });
            },
          ),
        ],
      ),
      body: isFullScreen
          ? Center(
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationX(3.14159), // Lật ngược theo trục X
          child: Mjpeg(
            isLive: isRunning,
            stream: 'http://${widget.cameraIP}/stream',
            fit: BoxFit.cover,
          ),
        ),
      )
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[100]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: <Widget>[
            SizedBox(height: 20),
            // Nút bật/tắt đèn 1
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFlashOn ? Colors.red : Colors.green,
                  padding: EdgeInsets.symmetric(
                      horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: toggleFlash,
                child: Text(
                  isFlashOn ? 'Tắt Đèn 1' : 'Bật Đèn 1',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            ),
            // Nút bật/tắt đèn 2
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  isFlash2On ? Colors.red : Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: toggleFlash2,
                child: Text(
                  isFlash2On ? 'Tắt Đèn 2 và 3' : 'Bật Đèn 2 và 3', // Cập nhật văn bản nút
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            ),
            // Video stream
            Container(
              height: 350,
              width: 500,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationX(3.14159), // Lật ngược theo trục X
                    child: Mjpeg(
                      isLive: isRunning,
                      stream: 'http://${widget.cameraIP}/stream',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            // Nút điều chỉnh servo
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_left, size: 50),
                  onPressed: () {
                    if (currentAngle > 0) {
                      controlServo(currentAngle - 10);
                    }
                  },
                ),
                SizedBox(width: 30),
                IconButton(
                  icon: Icon(Icons.arrow_right, size: 50),
                  onPressed: () {
                    if (currentAngle < 180) {
                      controlServo(currentAngle + 10);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.settings_remote),
        onPressed: () {
          controlServo(90);
        },
      ),
    );
  }
}
