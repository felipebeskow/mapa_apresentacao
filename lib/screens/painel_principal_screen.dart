import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../providers/apresentacao_provider.dart';
import '../models/apresentacao.dart';
import 'adicionar_apresentacao_dialog.dart';
import 'selecionar_proxima_dialog.dart';

class PainelPrincipalScreen extends StatefulWidget {
  @override
  _PainelPrincipalScreenState createState() => _PainelPrincipalScreenState();
}

class _PainelPrincipalScreenState extends State<PainelPrincipalScreen> {
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
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildProximasColumn()),
                Expanded(child: _buildAtualColumn()),
                Expanded(child: _buildApresentadasColumn()),
              ],
            ),
          ),
          _buildActionButtons(),
          _buildAddButton(),
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
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _editEventName(context, provider),
                  child: Row(
                    children: [
                      Icon(Icons.event, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          provider.evento?.nome ?? 'Novo Evento',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.edit, color: Colors.white70, size: 20),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 20),
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    _currentTime,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1,
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

  Widget _buildProximasColumn() {
    return Consumer<ApresentacaoProvider>(
      builder: (context, provider, _) {
        final proximas = provider.proximas;

        return Container(
          color: Colors.grey[100],
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildColumnTitle('📋 Próximas Atrações', Colors.blue),
              SizedBox(height: 16),
              Expanded(
                child: proximas.isEmpty
                    ? _buildEmptyState('Nenhuma atração agendada')
                    : ReorderableListView.builder(
                  itemCount: proximas.length,
                  onReorder: (oldIndex, newIndex) {
                    provider.reordenarProximas(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final apresentacao = proximas[index];
                    return _buildApresentacaoCard(
                      key: ValueKey(apresentacao.id),
                      apresentacao: apresentacao,
                      provider: provider,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAtualColumn() {
    return Consumer<ApresentacaoProvider>(
      builder: (context, provider, _) {
        final atual = provider.atual;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
            ),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildColumnTitle('🎭 Atração a se Apresentar', Colors.white),
              SizedBox(height: 16),
              Expanded(
                child: atual == null
                    ? _buildEmptyState('Nenhuma atração em apresentação',
                    textColor: Colors.white70)
                    : _buildAtualCard(atual),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildApresentadasColumn() {
    return Consumer<ApresentacaoProvider>(
      builder: (context, provider, _) {
        final apresentadas = provider.apresentadas;

        return Container(
          color: Colors.grey[200],
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildColumnTitle('✅ Atrações Apresentadas', Colors.green),
              SizedBox(height: 16),
              Expanded(
                child: apresentadas.isEmpty
                    ? _buildEmptyState('Nenhuma atração apresentada ainda')
                    : ListView.builder(
                  itemCount: apresentadas.length,
                  itemBuilder: (context, index) {
                    final apresentacao = apresentadas[index];
                    return _buildApresentacaoCard(
                      key: ValueKey(apresentacao.id),
                      apresentacao: apresentacao,
                      provider: provider,
                      isApresentada: true,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColumnTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _buildEmptyState(String text, {Color? textColor}) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor ?? Colors.grey[600],
          fontSize: 16,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildApresentacaoCard({
    required Key key,
    required Apresentacao apresentacao,
    required ApresentacaoProvider provider,
    bool isApresentada = false,
  }) {
    return Card(
      key: key,
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showApresentacaoOptions(context, apresentacao, provider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      apresentacao.nome,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _buildTipoBadge(apresentacao.tipo),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.group, size: 16, color: Color(0xFF667eea)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      apresentacao.grupo,
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ],
              ),
              if (apresentacao.nomeMusica != null) ...[
                SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.music_note, size: 16, color: Color(0xFF667eea)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        apresentacao.nomeMusica!,
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ],
              if (apresentacao.caminhoAudio != null) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.audiotrack, size: 14, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      'Áudio disponível',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAtualCard(Apresentacao apresentacao) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            apresentacao.nome,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          _buildAtualInfo(Icons.group, apresentacao.grupo),
          if (apresentacao.nomeMusica != null) ...[
            SizedBox(height: 12),
            _buildAtualInfo(Icons.music_note, apresentacao.nomeMusica!),
          ],
          SizedBox(height: 16),
          _buildTipoBadge(apresentacao.tipo, large: true),
          if (apresentacao.caminhoAudio != null) ...[
            SizedBox(height: 24),
            _buildAudioPlayer(),
          ],
        ],
      ),
    );
  }

  Widget _buildAtualInfo(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(width: 12),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipoBadge(TipoApresentacao tipo, {bool large = false}) {
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
        horizontal: large ? 16 : 10,
        vertical: large ? 10 : 6,
      ),
      decoration: BoxDecoration(
        color: large ? Colors.white.withOpacity(0.3) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        tipo.label,
        style: TextStyle(
          color: large ? Colors.white : color,
          fontWeight: FontWeight.w600,
          fontSize: large ? 16 : 12,
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    // Placeholder para player de áudio
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.play_circle_filled, size: 48),
                color: Colors.white,
                onPressed: () {
                  // TODO: Implementar reprodução
                },
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.35,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            '1:24 / 4:00',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Consumer<ApresentacaoProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: provider.proximas.isEmpty
                      ? null
                      : () => _confirmarChamarProxima(context, provider),
                  icon: Icon(Icons.skip_next),
                  label: Text('Chamar Próxima'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final provider = Provider.of<ApresentacaoProvider>(context, listen: false);
                    _showSelecionarProximaDialog(context, provider);
                  },
                  icon: Icon(Icons.list),
                  label: Text('Selecionar Próxima'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: provider.atual == null
                      ? null
                      : () => _confirmarRetornarAtual(context, provider),
                  icon: Icon(Icons.undo),
                  label: Text('Retornar Atração'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddButton() {
    return Container(
      padding: EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () {
          final provider = Provider.of<ApresentacaoProvider>(context, listen: false);
          _showAdicionarDialog(context, provider);
        },
        icon: Icon(Icons.add_circle),
        label: Text('Nova Apresentação'),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  // Diálogos e ações

  void _editEventName(BuildContext context, ApresentacaoProvider provider) {
    final controller = TextEditingController(text: provider.evento?.nome);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Nome do Evento'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nome do Evento',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.updateEventoNome(controller.text);
                Navigator.pop(context);
              }
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showAdicionarDialog(BuildContext context, ApresentacaoProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AdicionarApresentacaoDialog(provider: provider),
    );
  }

  void _showSelecionarProximaDialog(BuildContext context, ApresentacaoProvider provider) {
    showDialog(
      context: context,
      builder: (context) => SelecionarProximaDialog(provider: provider),
    );
  }

  void _confirmarChamarProxima(
      BuildContext context, ApresentacaoProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar'),
        content: Text('Deseja chamar a próxima apresentação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.chamarProxima();
              Navigator.pop(context);
            },
            child: Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _confirmarRetornarAtual(
      BuildContext context, ApresentacaoProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar'),
        content: Text('Deseja retornar a apresentação atual para a fila?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.retornarAtual();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showApresentacaoOptions(BuildContext context,
      Apresentacao apresentacao, ApresentacaoProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(apresentacao.nome),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Grupo: ${apresentacao.grupo}'),
            if (apresentacao.nomeMusica != null)
              Text('Música: ${apresentacao.nomeMusica}'),
            SizedBox(height: 8),
            Text('Tipo: ${apresentacao.tipo.label}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Abrir diálogo de edição
            },
            child: Text('Editar'),
          ),
          TextButton(
            onPressed: () {
              provider.deletarApresentacao(apresentacao.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Deletar'),
          ),
        ],
      ),
    );
  }
}