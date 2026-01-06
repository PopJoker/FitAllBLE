import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'DeviceDetailPage.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Models/scan_filter_settings.dart';
import '../Models/scanned_device.dart';
import 'ScanFilterPage.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  List<BluetoothDevice> devicesList = [];
  List<ScannedDevice> allDevices = [];
  List<ScannedDevice> filteredDevices = [];
  Map<String, bool> connectingDevices = {};
  TextEditingController searchController = TextEditingController();
  Map<String, bool> connectedDevices = {};

  @override
  void initState() {
    super.initState();
    requestPermissions().then((_) => startScan());
  }

  void connectToDevice(BluetoothDevice device) async {
    final id = device.id.id;
    
    if (connectingDevices[id] == true) return; // 已經在連線中就跳過

    setState(() => connectingDevices[id] = true);

    try {
      await device.connect();
      setState(() {
        connectedDevices[id] = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已連接: ${device.name.isEmpty ? "Unknown" : device.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('連接失敗: ${device.name.isEmpty ? "Unknown" : device.name}')),
      );
    } finally {
      setState(() => connectingDevices[id] = false);
    }
  }

  Future<void> requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }
  ScanFilterSettings filterSettings = ScanFilterSettings();

  bool isScanning = false;

  void startScan() async {
    if (isScanning) return;

    setState(() => isScanning = true);

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen((results) {
      bool changed = false;

      for (final r in results) {
        final index = allDevices.indexWhere(
          (d) => d.device.id == r.device.id,
        );

        if (index == -1) {
          allDevices.add(
            ScannedDevice(device: r.device, rssi: r.rssi),
          );
          connectedDevices[r.device.id.id] = false;
          changed = true;
        } else {
          allDevices[index].rssi = r.rssi;
          changed = true;
        }
      }

      if (changed) {
        filterDevices(searchController.text);
      }
    });

    Future.delayed(const Duration(seconds: 5), () {
      setState(() => isScanning = false);
      if (filterSettings.autoRescan) {
        startScan();
      }
    });
  }


  void filterDevices(String keyword) {
    setState(() {
      filteredDevices = allDevices.where((item) {
        final device = item.device;
        final name = device.name.trim();

        if (item.rssi < filterSettings.minRssi) return false;

        if (filterSettings.hideUnknown &&
            (name.isEmpty || name == "Unknown Device")) {
          return false;
        }

        if (filterSettings.onlyNamed && name.isEmpty) {
          return false;
        }

        if (keyword.isNotEmpty &&
            !name.toLowerCase().contains(keyword.toLowerCase())) {
          return false;
        }

        return true;
      }).toList();
    });
  }


  void disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      setState(() {
        connectedDevices[device.id.id] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已斷開: ${device.name.isEmpty ? "Unknown" : device.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('斷開失敗: ${device.name.isEmpty ? "Unknown" : device.name}')),
      );
    }
  }

  Widget buildDeviceCard(ScannedDevice item) {
    final device = item.device;
    bool isConnected = connectedDevices[device.id.id] ?? false;
    bool isConnecting = connectingDevices[device.id.id] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左側藍牙 icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isConnected ? Colors.white : Colors.grey.shade700,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.bluetooth,
              color: isConnected ? Colors.white : Colors.grey.shade500,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          // 中間資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name.isEmpty ? "Unknown Device" : device.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "RSSI: ${item.rssi} dBm",
                  style: TextStyle(
                    color: item.rssi > -60
                        ? Colors.green
                        : item.rssi > -80
                            ? Colors.orange
                            : Colors.red,
                    fontSize: 12,
                  ),
                ),
                Text(
                  device.id.id,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // 右側按鈕
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: isConnected || isConnecting ? Colors.black : Colors.white,
              backgroundColor: isConnected || isConnecting ? Colors.white : Colors.transparent,
              side: BorderSide(color: Colors.white.withOpacity(0.25)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
           onPressed: isConnecting
              ? null // 連線中鎖住
              : () {
                  if (isConnected) {
                    // 已連線 → 打開 Detail 頁面
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeviceDetailPage(device: device),
                      ),
                    );
                  } else {
                    // 未連線 → 執行連線
                    connectToDevice(device);
                  }
                },

            child: Text(
              isConnected
                  ? "DETAIL"
                  : isConnecting
                      ? "..."
                      : "CONNECT",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              "Fit All BLE",
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(width: 8),
            if (isScanning)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
          ],
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          // 搜尋 / 過濾設定
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            tooltip: "搜尋設定",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScanFilterPage(settings: filterSettings),
                ),
              );

              if (result != null && result is ScanFilterSettings) {
                setState(() {
                  filterSettings = result;
                });
                filterDevices(searchController.text);
              }
            },
          ),

          // 重新掃描
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "重新掃描",
            onPressed: () {
            setState(() {
              allDevices.clear();
              connectedDevices.clear();
            });
            startScan();
          },
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜尋列
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: searchController,
              onChanged: filterDevices,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search device name",
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: Colors.grey.shade500),
                        onPressed: () {
                          searchController.clear();
                          filterDevices('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF111111),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 裝置列表
          Expanded(
            child: filteredDevices.isEmpty
                ? const Center(
                    child: Text(
                      "No device found",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredDevices.length,
                    itemBuilder: (context, index) {
                      return buildDeviceCard(filteredDevices[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            devicesList.clear();
            connectedDevices.clear();
          });
          startScan();
        },
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: const Icon(Icons.search),
        tooltip: "掃描設備",
      ),
    );
  }
}
