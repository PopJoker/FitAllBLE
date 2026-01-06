import 'package:flutter/material.dart';
import '../Models/scan_filter_settings.dart';

class ScanFilterPage extends StatefulWidget {
  final ScanFilterSettings settings;

  const ScanFilterPage({super.key, required this.settings});

  @override
  State<ScanFilterPage> createState() => _ScanFilterPageState();
}

class _ScanFilterPageState extends State<ScanFilterPage> {
  late ScanFilterSettings tempSettings;

  @override
  void initState() {
    super.initState();
    tempSettings = widget.settings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "搜尋設定",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSwitch(
            title: "隱藏 Unknown Device",
            value: tempSettings.hideUnknown,
            onChanged: (v) => setState(() => tempSettings.update(hideUnknown: v)),
          ),
          _buildSwitch(
            title: "只顯示有名稱的設備",
            value: tempSettings.onlyNamed,
            onChanged: (v) => setState(() => tempSettings.update(onlyNamed: v)),
          ),
          _buildSwitch(
            title: "Auto Rescan（工程模式）",
            value: tempSettings.autoRescan,
            onChanged: (v) => setState(() => tempSettings.update(autoRescan: v)),
          ),
          const SizedBox(height: 24),
          Text(
            "最小訊號強度 (${tempSettings.minRssi} dBm)",
            style: const TextStyle(color: Colors.white70),
          ),
          Slider(
            min: -100,
            max: -30,
            divisions: 14,
            value: tempSettings.minRssi.toDouble(),
            label: "${tempSettings.minRssi}",
            onChanged: (v) => setState(() => tempSettings.update(minRssi: v.toInt())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.check),
        label: const Text("套用"),
        onPressed: () {
          Navigator.pop(context, tempSettings);
        },
      ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      color: const Color(0xFF111111),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        value: value,
        activeColor: Colors.white,
        onChanged: onChanged,
      ),
    );
  }
}
