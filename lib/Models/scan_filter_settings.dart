import 'package:flutter/foundation.dart';

class ScanFilterSettings extends ChangeNotifier {
  bool hideUnknown;
  bool onlyNamed;
  int minRssi;
  bool autoRescan;

  ScanFilterSettings({
    this.hideUnknown = true,
    this.onlyNamed = false,
    this.minRssi = -100,
    this.autoRescan = false,
  });

  void update({
    bool? hideUnknown,
    bool? onlyNamed,
    int? minRssi,
    bool? autoRescan,
  }) {
    this.hideUnknown = hideUnknown ?? this.hideUnknown;
    this.onlyNamed = onlyNamed ?? this.onlyNamed;
    this.minRssi = minRssi ?? this.minRssi;
    this.autoRescan = autoRescan ?? this.autoRescan;
    notifyListeners();
  }
}
