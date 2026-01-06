import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceDetailPage extends StatefulWidget {
  final BluetoothDevice device;
  const DeviceDetailPage({super.key, required this.device});

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  List<BluetoothService> services = [];

  @override
  void initState() {
    super.initState();
    discoverServices();
  }

  Future<void> discoverServices() async {
    final discoveredServices = await widget.device.discoverServices();
    setState(() {
      services = discoveredServices;
    });
  }

  Widget buildCharacteristicTile(BluetoothCharacteristic c) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          title: Text(
            'Characteristic',
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'UUID: ${c.uuid}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                'Properties: ${_propertiesText(c)}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          trailing: Wrap(
            spacing: 4,
            children: [
              if (c.properties.read)
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.lightBlue),
                  tooltip: "讀取",
                  onPressed: () async {
                    final value = await c.read();
                    _showSnackBar('讀取值: $value');
                  },
                ),
              if (c.properties.write)
                IconButton(
                  icon: const Icon(Icons.upload, color: Colors.orangeAccent),
                  tooltip: "寫入",
                  onPressed: () async {
                    await c.write([0x01], withoutResponse: false);
                    _showSnackBar('已寫入 0x01');
                  },
                ),
              if (c.properties.notify)
                IconButton(
                  icon:
                      const Icon(Icons.notifications, color: Colors.greenAccent),
                  tooltip: "訂閱通知",
                  onPressed: () async {
                    await c.setNotifyValue(true);
                    c.value.listen((value) {
                      _showSnackBar('通知值: $value');
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildServiceTile(BluetoothService s) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        collapsedBackgroundColor: const Color(0xFF121212),
        backgroundColor: const Color(0xFF121212),
        iconColor: Colors.white,
        collapsedIconColor: Colors.grey,
        title: Text(
          'Service UUID',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          s.uuid.toString(),
          style: const TextStyle(color: Colors.grey),
        ),
        children: s.characteristics.map(buildCharacteristicTile).toList(),
      ),
    );
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF2A2A2A),
        content: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  String _propertiesText(BluetoothCharacteristic c) {
    final props = <String>[];
    if (c.properties.read) props.add('READ');
    if (c.properties.write) props.add('WRITE');
    if (c.properties.notify) props.add('NOTIFY');
    if (c.properties.indicate) props.add('INDICATE');
    return props.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final deviceName =
        widget.device.name.isEmpty ? 'Unknown Device' : widget.device.name;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          deviceName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.link_off, color: Colors.redAccent),
            tooltip: "斷開連線",
            onPressed: () async {
              await widget.device.disconnect();
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: services.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : ListView(
              children: services.map(buildServiceTile).toList(),
            ),
    );
  }
}
