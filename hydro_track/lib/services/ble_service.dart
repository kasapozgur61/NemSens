import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// ESP32'den gelen 11-byte paketin parse edilmis hali.
class SensorData {
  final int timestamp;
  final double g;
  final double scl;
  final double phasic;
  final bool scrFlag;

  const SensorData({
    required this.timestamp,
    required this.g,
    required this.scl,
    required this.phasic,
    required this.scrFlag,
  });
}

/// BLE baglantiyi ve NemSens-GSR sensor verisini yoneten singleton servis.
class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  static const String serviceUuid        = 'a1b2c3d4-0001-4a5b-9c8d-1e2f3a4b5c6d';
  static const String characteristicUuid = 'a1b2c3d4-0002-4a5b-9c8d-1e2f3a4b5c6d';
  static const String deviceName         = 'NemSens-GSR';

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _dataCharacteristic;
  StreamSubscription? _notifySubscription;
  StreamSubscription? _connectionSubscription;

  final _dataController       = StreamController<SensorData>.broadcast();
  final _connectedController  = StreamController<bool>.broadcast();

  Stream<SensorData> get dataStream       => _dataController.stream;
  Stream<bool>       get connectionStream => _connectedController.stream;
  bool               get isConnected      => _connectedDevice != null;
  String?            get connectedDeviceName => _connectedDevice?.platformName;

  Stream<List<ScanResult>> startScan({int timeout = 5}) {
    FlutterBluePlus.startScan(
      timeout: Duration(seconds: timeout),
    );
    return FlutterBluePlus.scanResults;
  }

  Future<void> stopScan() async => FlutterBluePlus.stopScan();

  Future<String?> connect(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnect();
        }
      });

      final services = await device.discoverServices();
      for (final service in services) {
        if (service.serviceUuid.toString().toLowerCase() == serviceUuid) {
          for (final char in service.characteristics) {
            if (char.characteristicUuid.toString().toLowerCase() == characteristicUuid) {
              _dataCharacteristic = char;
              await char.setNotifyValue(true);
              _notifySubscription = char.onValueReceived.listen(_onDataReceived);
              _connectedController.add(true);
              return null;
            }
          }
        }
      }
      await device.disconnect();
      _connectedDevice = null;
      return 'NemSens servisi bulunamadi. Dogru cihaz mi?';
    } catch (e) {
      _connectedDevice = null;
      return 'Baglanti hatasi: $e';
    }
  }

  Future<void> disconnect() async {
    await _notifySubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _dataCharacteristic = null;
    _connectedController.add(false);
  }

  void _onDataReceived(List<int> raw) {
    if (raw.length < 11) return;
    final bytes = Uint8List.fromList(raw);
    final bd    = ByteData.sublistView(bytes);

    final t       = bd.getUint32(0, Endian.little);
    final gi      = bd.getUint16(4, Endian.little);
    final si      = bd.getUint16(6, Endian.little);
    final pi      = bd.getInt16(8, Endian.little);
    final scrFlag = bytes[10] == 1;

    final data = SensorData(
      timestamp: t,
      g:         gi / 1000.0,
      scl:       si / 1000.0,
      phasic:    pi / 10000.0,
      scrFlag:   scrFlag,
    );

    if (!_dataController.isClosed) _dataController.add(data);
  }

  void _handleDisconnect() {
    _notifySubscription?.cancel();
    _connectionSubscription?.cancel();
    _connectedDevice = null;
    _dataCharacteristic = null;
    _connectedController.add(false);
  }
}
