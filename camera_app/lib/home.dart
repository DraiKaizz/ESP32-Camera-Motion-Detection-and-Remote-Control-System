import 'package:flutter/material.dart';
import 'package:network_discovery/network_discovery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'allcamra.dart';
import 'camera_sreen.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, String> cameraIPs = {}; // Lưu trữ camera và khu vực
  bool isScanning = false;
  int foundDevices = 0;
  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _loadCameraData(); // Đọc dữ liệu khi ứng dụng khởi động
  }

  // Hàm đọc cameraIPs từ SharedPreferences
  Future<void> _loadCameraData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cameraList = prefs.getStringList('cameraData');

    if (cameraList != null) {
      Map<String, String> loadedData = {};
      for (String entry in cameraList) {
        List<String> parts = entry.split(',');
        if (parts.length == 2) {
          loadedData[parts[0]] = parts[1];
        }
      }
      setState(() {
        cameraIPs = loadedData;
      });
    }
  }

  // Hàm lưu cameraIPs vào SharedPreferences
  Future<void> saveCameraData(Map<String, String> cameraData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cameraList = [];

    cameraData.forEach((areaName, ip) {
      cameraList.add('$areaName,$ip');
    });
    await prefs.setStringList('cameraData', cameraList);
  }

  // Hàm quét toàn bộ các subnet
  Future<void> scanAllSubnets() async {
    setState(() {
      isScanning = true;
      foundDevices = 0;
      cameraIPs = {}; // Reset dữ liệu mỗi khi bắt đầu quét
    });

    const port = 80;
    final detectedIPs = <String, String>{};

    try {
      for (int i = 0; i <= 255; i++) {
        final subnet = '192.168.$i';
        final stream = NetworkDiscovery.discover(subnet, port);

        _scanSubscription = stream.listen((addr) {
          if (_scanSubscription?.isPaused ?? false) {
            return;
          }
          foundDevices++;

          String areaName = 'Khu vực ${detectedIPs.length + 1}';
          detectedIPs[areaName] = addr.ip;

          setState(() {
            cameraIPs = Map.from(detectedIPs);
          });

          // Lưu dữ liệu camera vào SharedPreferences
          saveCameraData(cameraIPs);
        });

        await Future.delayed(Duration(milliseconds: 500));
        if (_scanSubscription?.isPaused ?? false) {
          break;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quét xong. Tìm thấy $foundDevices thiết bị.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi quét: $e')),
      );
    } finally {
      setState(() {
        isScanning = false;
      });
    }
  }

  // Hàm dừng quét
  void cancelScan() {
    if (_scanSubscription?.isPaused == false) {
      _scanSubscription?.pause();
      setState(() {
        isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã dừng quét.')),
      );
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
        actions: [
          if (isScanning)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: cancelScan, // Dừng quét khi nhấn nút "X"
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 120),
            const Text(
              "Các khu vực trong ngôi nhà",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllCamerasScreen(cameraIPs: cameraIPs),
                  ),
                );
              },
              child: const Text("Xem tất cả camera", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isScanning ? null : scanAllSubnets,
              child: isScanning
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Quét toàn bộ mạng", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            if (foundDevices > 0)
              Text("Tìm thấy $foundDevices thiết bị.", style: const TextStyle(fontSize: 16, color: Colors.green)),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                ),
                itemCount: cameraIPs.length,
                itemBuilder: (context, index) {
                  String areaName = cameraIPs.keys.elementAt(index);
                  return GestureDetector(
                    onTap: () {
                      String cameraIP = cameraIPs[areaName] ?? "";
                      if (cameraIP.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Không có IP cho khu vực này")),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CameraScreen(areaName: areaName, cameraIP: cameraIP),
                        ),
                      );
                    },
                    child: Card(
                      color: Colors.blue[100],
                      child: Center(
                        child: Text(
                          areaName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
