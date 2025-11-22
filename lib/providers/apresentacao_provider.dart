import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/apresentacao.dart';
import '../services/network_service.dart';

class ApresentacaoProvider extends ChangeNotifier {
  final List<Apresentacao> _apresentacoes = [];
  Evento? _evento;

  // Rede
  NetworkServer? _server;
  NetworkClient? _client;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  bool _isServer = true;

  // Getters
  List<Apresentacao> get proximas => _apresentacoes
      .where((a) => a.status == StatusApresentacao.proxima)
      .toList()
    ..sort((a, b) => a.ordem.compareTo(b.ordem));

  Apresentacao? get atual => _apresentacoes
      .where((a) => a.status == StatusApresentacao.atual)
      .cast<Apresentacao?>()
      .firstOrNull;

  List<Apresentacao> get apresentadas => _apresentacoes
      .where((a) => a.status == StatusApresentacao.apresentada)
      .toList()
    ..sort((a, b) => b.ordem.compareTo(a.ordem));

  Evento? get evento => _evento;
  ConnectionStatus get connectionStatus => _connectionStatus;
  bool get isServer => _isServer;

  // ============= INICIALIZAÇÃO =============

  Future<void> initialize({required bool asServer}) async {
    _isServer = asServer;
    await _loadFromStorage();

    if (_isServer) {
      await _startServer();
    } else {
      await _startClient();
    }
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    // Carregar evento
    final eventoJson = prefs.getString('evento');
    if (eventoJson != null) {
      _evento = Evento.fromJson(jsonDecode(eventoJson));
    } else {
      _evento = Evento(
        id: Uuid().v4(),
        nome: 'Novo Evento',
        dataCriacao: DateTime.now(),
      );
      await _saveEvento();
    }

    // Carregar apresentações
    final apresentacoesJson = prefs.getString('apresentacoes');
    if (apresentacoesJson != null) {
      final List<dynamic> lista = jsonDecode(apresentacoesJson);
      _apresentacoes.clear();
      _apresentacoes.addAll(lista.map((e) => Apresentacao.fromJson(e)));
    }

    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'apresentacoes',
      jsonEncode(_apresentacoes.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _saveEvento() async {
    if (_evento == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('evento', jsonEncode(_evento!.toJson()));
  }

  // ============= REDE - SERVIDOR =============

  Future<void> _startServer() async {
    _server = NetworkServer();
    await _server!.start(_evento?.nome ?? 'Evento');

    // Escutar mensagens de clientes (se necessário)
    _server!.messageStream.listen((message) {
      // Processar mensagens dos clientes
    });
  }

  void _broadcastUpdate(String type, Map<String, dynamic> data) {
    if (_server != null) {
      _server!.broadcast(NetworkMessage(type: type, data: data));
    }
  }

  // ============= REDE - CLIENTE =============

  Future<void> _startClient() async {
    _client = NetworkClient();

    // Escutar mudanças de status
    _client!.statusStream.listen((status) {
      _connectionStatus = status;
      notifyListeners();
    });

    // Escutar mensagens do servidor
    _client!.messageStream.listen((message) {
      _handleServerMessage(message);
    });

    await _client!.startDiscovery();
  }

  void _handleServerMessage(NetworkMessage message) {
    switch (message.type) {
      case 'STATE_UPDATE':
        _updateFromServer(message.data);
        break;
      case 'APRESENTACAO_ADDED':
        _addFromServer(message.data);
        break;
      case 'APRESENTACAO_UPDATED':
        _updateApresentacaoFromServer(message.data);
        break;
      case 'APRESENTACAO_DELETED':
        _deleteFromServer(message.data['id']);
        break;
      case 'CHAMAR_PROXIMA':
        _chamarProximaFromServer();
        break;
      case 'RETORNAR_ATUAL':
        _retornarAtualFromServer();
        break;
    }
  }

  void _updateFromServer(Map<String, dynamic> data) {
    _apresentacoes.clear();
    final List<dynamic> lista = data['apresentacoes'];
    _apresentacoes.addAll(lista.map((e) => Apresentacao.fromJson(e)));

    if (data['evento'] != null) {
      _evento = Evento.fromJson(data['evento']);
    }

    notifyListeners();
  }

  // ============= OPERAÇÕES =============

  Future<void> updateEventoNome(String nome) async {
    if (_evento != null) {
      _evento!.nome = nome;
      await _saveEvento();

      if (_isServer) {
        _broadcastUpdate('EVENT_UPDATED', _evento!.toJson());
      }

      notifyListeners();
    }
  }

  Future<void> adicionarApresentacao(Apresentacao apresentacao) async {
    // Definir ordem
    apresentacao.ordem = proximas.length;

    _apresentacoes.add(apresentacao);
    await _saveToStorage();

    if (_isServer) {
      _broadcastUpdate('APRESENTACAO_ADDED', apresentacao.toJson());
    }

    notifyListeners();
  }

  Future<void> editarApresentacao(String id, Apresentacao atualizada) async {
    final index = _apresentacoes.indexWhere((a) => a.id == id);
    if (index != -1) {
      _apresentacoes[index] = atualizada;
      await _saveToStorage();

      if (_isServer) {
        _broadcastUpdate('APRESENTACAO_UPDATED', atualizada.toJson());
      }

      notifyListeners();
    }
  }

  Future<void> deletarApresentacao(String id) async {
    _apresentacoes.removeWhere((a) => a.id == id);
    await _saveToStorage();

    if (_isServer) {
      _broadcastUpdate('APRESENTACAO_DELETED', {'id': id});
    }

    notifyListeners();
  }

  Future<void> chamarProxima() async {
    // Mover atual para apresentadas
    if (atual != null) {
      atual!.status = StatusApresentacao.apresentada;
    }

    // Pegar próxima
    if (proximas.isNotEmpty) {
      final proxima = proximas.first;
      proxima.status = StatusApresentacao.atual;
    }

    await _saveToStorage();

    if (_isServer) {
      _broadcastUpdate('CHAMAR_PROXIMA', {});
    }

    notifyListeners();
  }

  Future<void> retornarAtual() async {
    if (atual != null) {
      atual!.status = StatusApresentacao.proxima;
      atual!.ordem = proximas.length;
    }

    await _saveToStorage();

    if (_isServer) {
      _broadcastUpdate('RETORNAR_ATUAL', {});
    }

    notifyListeners();
  }

  Future<void> selecionarProxima(String id) async {
    final apresentacao = _apresentacoes.firstWhere((a) => a.id == id);

    if (apresentacao.status == StatusApresentacao.proxima) {
      // Reordenar - colocar no topo
      apresentacao.ordem = -1;
      _reordenarProximas();
    } else if (apresentacao.status == StatusApresentacao.apresentada) {
      // Mover de volta para próximas no topo
      apresentacao.status = StatusApresentacao.proxima;
      apresentacao.ordem = -1;
      _reordenarProximas();
    }

    await _saveToStorage();

    if (_isServer) {
      _broadcastUpdate('APRESENTACAO_UPDATED', apresentacao.toJson());
    }

    notifyListeners();
  }

  void _reordenarProximas() {
    final lista = proximas;
    for (int i = 0; i < lista.length; i++) {
      lista[i].ordem = i;
    }
  }

  Future<void> reordenarProximas(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;

    final lista = proximas;
    final item = lista.removeAt(oldIndex);
    lista.insert(newIndex, item);

    // Atualizar ordens
    for (int i = 0; i < lista.length; i++) {
      lista[i].ordem = i;
    }

    await _saveToStorage();

    if (_isServer) {
      _broadcastUpdate('STATE_UPDATE', {
        'apresentacoes': _apresentacoes.map((e) => e.toJson()).toList(),
      });
    }

    notifyListeners();
  }

  // Métodos para atualizar a partir do servidor (cliente)
  void _addFromServer(Map<String, dynamic> data) {
    final apresentacao = Apresentacao.fromJson(data);
    _apresentacoes.add(apresentacao);
    notifyListeners();
  }

  void _updateApresentacaoFromServer(Map<String, dynamic> data) {
    final apresentacao = Apresentacao.fromJson(data);
    final index = _apresentacoes.indexWhere((a) => a.id == apresentacao.id);
    if (index != -1) {
      _apresentacoes[index] = apresentacao;
      notifyListeners();
    }
  }

  void _deleteFromServer(String id) {
    _apresentacoes.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  void _chamarProximaFromServer() {
    if (atual != null) {
      atual!.status = StatusApresentacao.apresentada;
    }
    if (proximas.isNotEmpty) {
      proximas.first.status = StatusApresentacao.atual;
    }
    notifyListeners();
  }

  void _retornarAtualFromServer() {
    if (atual != null) {
      atual!.status = StatusApresentacao.proxima;
      atual!.ordem = proximas.length;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _server?.stop();
    _client?.stop();
    super.dispose();
  }
}