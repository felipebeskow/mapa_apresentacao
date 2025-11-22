// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/io.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';


enum ConnectionStatus {
  disconnected,
  searching,
  connecting,
  connected,
}

class NetworkMessage {
  final String type;
  final Map<String, dynamic> data;

  NetworkMessage({required this.type, required this.data});

  Map<String, dynamic> toJson() => {'type': type, 'data': data};

  factory NetworkMessage.fromJson(Map<String, dynamic> json) {
    return NetworkMessage(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }
}

// ============= SERVIDOR (Painel Principal) =============
class NetworkServer {
  static const int UDP_PORT = 9999;
  static const int WEBSOCKET_PORT = 8080;
  static const String BROADCAST_ADDRESS = '255.255.255.255';

  RawDatagramSocket? _udpSocket;
  HttpServer? _webSocketServer;
  Timer? _broadcastTimer;

  final List<IOWebSocketChannel> _clients = [];
  final StreamController<NetworkMessage> _messageController =
  StreamController<NetworkMessage>.broadcast();

  Stream<NetworkMessage> get messageStream => _messageController.stream;

  String? _serverIp;
  String _eventName = 'Evento Cultural';

  Future<void> start(String eventName) async {
    _eventName = eventName;

    // Obter IP local
    _serverIp = await _getLocalIp();

    // Iniciar servidor WebSocket
    await _startWebSocketServer();

    // Iniciar broadcast UDP
    await _startUdpBroadcast();

    print('✅ Servidor iniciado em $_serverIp:$WEBSOCKET_PORT');
  }

  Future<String> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith('192.168')) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Erro ao obter IP: $e');
    }
    return '127.0.0.1';
  }

  Future<void> _startWebSocketServer() async {
    _webSocketServer = await HttpServer.bind(InternetAddress.anyIPv4, WEBSOCKET_PORT);

    _webSocketServer!.listen((HttpRequest request) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        WebSocketTransformer.upgrade(request).then((WebSocket ws) {
          final channel = IOWebSocketChannel(ws);
          _clients.add(channel);

          print('🟢 Cliente conectado. Total: ${_clients.length}');

          // Escutar mensagens do cliente
          channel.stream.listen(
                (message) {
              final msg = NetworkMessage.fromJson(jsonDecode(message));
              _messageController.add(msg);
            },
            onDone: () {
              _clients.remove(channel);
              print('🔴 Cliente desconectado. Total: ${_clients.length}');
            },
            onError: (error) {
              _clients.remove(channel);
              print('❌ Erro na conexão: $error');
            },
          );
        });
      }
    });
  }

  Future<void> _startUdpBroadcast() async {
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _udpSocket!.broadcastEnabled = true;

    // Enviar broadcast a cada 3 segundos
    _broadcastTimer = Timer.periodic(Duration(seconds: 3), (_) {
      _sendBroadcast();
    });

    _sendBroadcast(); // Enviar imediatamente
  }

  void _sendBroadcast() {
    if (_udpSocket == null || _serverIp == null) return;

    final message = jsonEncode({
      'type': 'SERVER_ANNOUNCEMENT',
      'ip': _serverIp,
      'port': WEBSOCKET_PORT,
      'eventName': _eventName,
    });

    _udpSocket!.send(
      utf8.encode(message),
      InternetAddress(BROADCAST_ADDRESS),
      UDP_PORT,
    );
  }

  // Enviar mensagem para todos os clientes
  void broadcast(NetworkMessage message) {
    final json = jsonEncode(message.toJson());
    for (var client in _clients) {
      try {
        client.sink.add(json);
      } catch (e) {
        print('Erro ao enviar para cliente: $e');
      }
    }
  }

  void stop() {
    _broadcastTimer?.cancel();
    _udpSocket?.close();

    for (var client in _clients) {
      client.sink.close();
    }
    _clients.clear();

    _webSocketServer?.close();
    _messageController.close();

    print('🛑 Servidor parado');
  }
}

// ============= CLIENTE (Painel Mestre de Cerimônias) =============
class NetworkClient {
  static const int UDP_PORT = 9999;
  static const Duration TIMEOUT = Duration(seconds: 10);

  RawDatagramSocket? _udpSocket;
  IOWebSocketChannel? _webSocketChannel;
  Timer? _timeoutTimer;

  final StreamController<ConnectionStatus> _statusController =
  StreamController<ConnectionStatus>.broadcast();
  final StreamController<NetworkMessage> _messageController =
  StreamController<NetworkMessage>.broadcast();

  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  Stream<NetworkMessage> get messageStream => _messageController.stream;

  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _serverIp;
  int? _serverPort;

  Future<void> startDiscovery() async {
    _updateStatus(ConnectionStatus.searching);

    // Escutar broadcasts UDP
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, UDP_PORT);

    _udpSocket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _udpSocket!.receive();
        if (datagram != null) {
          _handleBroadcast(datagram);
        }
      }
    });

    // Timeout para considerar servidor offline
    _resetTimeout();
  }

  void _handleBroadcast(Datagram datagram) {
    try {
      final message = jsonDecode(utf8.decode(datagram.data));

      if (message['type'] == 'SERVER_ANNOUNCEMENT') {
        _serverIp = message['ip'];
        _serverPort = message['port'];

        _resetTimeout();

        // Conectar ao WebSocket se ainda não conectado
        if (_status != ConnectionStatus.connected) {
          _connectWebSocket();
        }
      }
    } catch (e) {
      print('Erro ao processar broadcast: $e');
    }
  }

  Future<void> _connectWebSocket() async {
    if (_serverIp == null || _serverPort == null) return;

    try {
      _updateStatus(ConnectionStatus.connecting);

      final uri = Uri.parse('ws://$_serverIp:$_serverPort');
      _webSocketChannel = IOWebSocketChannel.connect(uri);

      await _webSocketChannel!.ready;
      _updateStatus(ConnectionStatus.connected);

      print('✅ Conectado ao servidor $_serverIp:$_serverPort');

      // Escutar mensagens
      _webSocketChannel!.stream.listen(
            (message) {
          final msg = NetworkMessage.fromJson(jsonDecode(message));
          _messageController.add(msg);
        },
        onDone: () {
          print('🔴 Conexão WebSocket fechada');
          _reconnect();
        },
        onError: (error) {
          print('❌ Erro WebSocket: $error');
          _reconnect();
        },
      );
    } catch (e) {
      print('Erro ao conectar WebSocket: $e');
      _reconnect();
    }
  }

  void _resetTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(TIMEOUT, () {
      if (_status == ConnectionStatus.connected) {
        print('⏱️ Timeout - servidor offline');
        _reconnect();
      }
    });
  }

  void _reconnect() {
    _webSocketChannel?.sink.close();
    _webSocketChannel = null;
    _updateStatus(ConnectionStatus.searching);
  }

  void _updateStatus(ConnectionStatus status) {
    _status = status;
    _statusController.add(status);
  }

  void stop() {
    _timeoutTimer?.cancel();
    _udpSocket?.close();
    _webSocketChannel?.sink.close();
    _statusController.close();
    _messageController.close();

    print('🛑 Cliente parado');
  }
}