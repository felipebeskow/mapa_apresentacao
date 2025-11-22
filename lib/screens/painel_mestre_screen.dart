import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../providers/apresentacao_provider.dart';
import '../models/apresentacao.dart';
import '../services/network_service.dart';

class PainelMestreScreen extends StatefulWidget {
  @override
  _PainelMestreScreenState createState() => _PainelMestreScreenState();
}

class _PainelMestreScreenState extends State<PainelMestreScreen> {
  Timer? _clockTimer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          _buildConnectionStatus(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<ApresentacaoProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.event, color: Colors.white, size: 32),
                  SizedBox(width: 16),
                  Text(
                    provider.evento?.nome ?? 'Aguardando conexão...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    _currentTime,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer<ApresentacaoProvider>(
      builder: (context, provider, _) {
        final status = provider.connectionStatus;
        Color color;
        String text;
        IconData icon;

        switch (status) {
          case ConnectionStatus.connected:
            color = Colors.green;
            text = 'Conectado ao servidor';
            icon = Icons.check_circle;
            break;
          case ConnectionStatus.connecting:
            color = Colors.orange;
            text = 'Conectando...';
            icon = Icons.sync;
            break;
          case ConnectionStatus.searching:
            color = Colors.orange;
            text = 'Procurando servidor...';
            icon = Icons.search;
            break;
          case ConnectionStatus.disconnected:
            color = Colors.red;
            text = 'Desconectado';
            icon = Icons.error;
            break;
        }

        return Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          color: color.withOpacity(0.1),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (status == ConnectionStatus.searching ||
                  status == ConnectionStatus.connecting)
                Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Consumer<ApresentacaoProvider>(
      builder: (context, provider, _) {
        if (provider.connectionStatus != ConnectionStatus.connected) {
          return _buildWaitingScreen();
        }

        return Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildAtualSection(provider),
            ),
            Container(
              width: 1,
              color: Colors.grey[300],
            ),
            Expanded(
              flex: 2,
              child: _buildProximasSection(provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWaitingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_find,
            size: 120,
            color: Colors.grey[400],
          ),
          SizedBox(height: 24),
          Text(
            'Procurando servidor na rede...',
            style: TextStyle(
              fontSize: 24,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Certifique-se de que o painel principal está aberto\ne conectado à mesma rede',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 32),
          CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildAtualSection(ApresentacaoProvider provider) {
    final atual = provider.atual;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              '🎭 Apresentando Agora',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: atual == null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    size: 80,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aguardando próxima apresentação...',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white.withOpacity(0.9),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
                : Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            atual.nome,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 32),
                          _buildInfoRow(
                            Icons.group,
                            atual.grupo,
                            large: true,
                          ),
                          if (atual.nomeMusica != null) ...[
                            SizedBox(height: 20),
                            _buildInfoRow(
                              Icons.music_note,
                              atual.nomeMusica!,
                              large: true,
                            ),
                          ],
                          SizedBox(height: 24),
                          _buildTipoBadge(atual.tipo),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProximasSection(ApresentacaoProvider provider) {
    final proximas = provider.proximas;

    return Container(
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.queue_music, color: Color(0xFF667eea), size: 28),
                SizedBox(width: 12),
                Text(
                  'Próximas Apresentações',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: proximas.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma apresentação\nagendada',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: proximas.length > 5 ? 5 : proximas.length,
              itemBuilder: (context, index) {
                final apresentacao = proximas[index];
                return _buildProximaCard(apresentacao, index + 1);
              },
            ),
          ),
          if (proximas.length > 5)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.more_horiz, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    '+ ${proximas.length - 5} apresentações',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProximaCard(Apresentacao apresentacao, int numero) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFF667eea),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$numero',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apresentacao.nome,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 6),
                  _buildInfoRow(Icons.group, apresentacao.grupo),
                  if (apresentacao.nomeMusica != null) ...[
                    SizedBox(height: 4),
                    _buildInfoRow(Icons.music_note, apresentacao.nomeMusica!),
                  ],
                  SizedBox(height: 8),
                  _buildTipoBadge(apresentacao.tipo, small: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool large = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: large ? 24 : 16,
          color: large ? Colors.white : Color(0xFF667eea),
        ),
        SizedBox(width: large ? 12 : 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: large ? 24 : 14,
              color: large ? Colors.white : Colors.black87,
              fontWeight: large ? FontWeight.w500 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTipoBadge(TipoApresentacao tipo, {bool small = false}) {
    Color color;
    switch (tipo) {
      case TipoApresentacao.danca:
        color = Colors.blue;
        break;
      case TipoApresentacao.karaoke:
        color = Colors.purple;
        break;
      case TipoApresentacao.canto:
        color = Colors.orange;
        break;
      case TipoApresentacao.outros:
        color = Colors.green;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 10 : 16,
        vertical: small ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: small ? color.withOpacity(0.1) : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tipo.label,
        style: TextStyle(
          color: small ? color : Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: small ? 12 : 18,
        ),
      ),
    );
  }
}