import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/apresentacao.dart';
import '../providers/apresentacao_provider.dart';

class SelecionarProximaDialog extends StatefulWidget {
  final ApresentacaoProvider provider; // Adicione esta linha

  SelecionarProximaDialog({required this.provider}); // Adicione esta linha

  @override
  _SelecionarProximaDialogState createState() =>
      _SelecionarProximaDialogState();
}

class _SelecionarProximaDialogState extends State<SelecionarProximaDialog> {
  String _busca = '';
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    // Use o provider passado como parâmetro em vez de Consumer
    final provider = widget.provider;
    
    // Combinar próximas e apresentadas para seleção
    final todas = [
      ...provider.proximas,
      ...provider.apresentadas,
    ];

    // Filtrar por busca
    final filtradas = todas.where((a) {
      final busca = _busca.toLowerCase();
      return a.nome.toLowerCase().contains(busca) ||
          a.grupo.toLowerCase().contains(busca) ||
          (a.nomeMusica?.toLowerCase().contains(busca) ?? false);
    }).toList();

    return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selecionar Próxima Apresentação'),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar apresentação...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _busca = value;
                  });
                },
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: filtradas.isEmpty
                ? Center(
              child: Text(
                _busca.isEmpty
                    ? 'Nenhuma apresentação disponível'
                    : 'Nenhum resultado encontrado',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: filtradas.length,
              itemBuilder: (context, index) {
                final apresentacao = filtradas[index];
                final isSelected = _selectedId == apresentacao.id;

                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  color: isSelected
                      ? Colors.blue[50]
                      : Colors.white,
                  elevation: isSelected ? 4 : 1,
                  child: ListTile(
                    onTap: () {
                      setState(() {
                        _selectedId = apresentacao.id;
                      });
                    },
                    leading: CircleAvatar(
                      backgroundColor: _getTipoColor(apresentacao.tipo),
                      child: Icon(
                        _getTipoIcon(apresentacao.tipo),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      apresentacao.nome,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Grupo: ${apresentacao.grupo}'),
                        if (apresentacao.nomeMusica != null)
                          Text('Música: ${apresentacao.nomeMusica}'),
                        SizedBox(height: 4),
                        _buildStatusBadge(apresentacao.status),
                      ],
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: Colors.blue)
                        : null,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _selectedId == null
                  ? null
                  : () {
                provider.selecionarProxima(_selectedId!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Apresentação movida para o topo da fila'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Text('Confirmar'),
            ),
          ],
        );
  }

  Color _getTipoColor(TipoApresentacao tipo) {
    switch (tipo) {
      case TipoApresentacao.danca:
        return Colors.blue;
      case TipoApresentacao.karaoke:
        return Colors.purple;
      case TipoApresentacao.canto:
        return Colors.orange;
      case TipoApresentacao.outros:
        return Colors.green;
    }
  }

  IconData _getTipoIcon(TipoApresentacao tipo) {
    switch (tipo) {
      case TipoApresentacao.danca:
        return Icons.theater_comedy;
      case TipoApresentacao.karaoke:
        return Icons.mic;
      case TipoApresentacao.canto:
        return Icons.music_note;
      case TipoApresentacao.outros:
        return Icons.star;
    }
  }

  Widget _buildStatusBadge(StatusApresentacao status) {
    Color color;
    String label;

    switch (status) {
      case StatusApresentacao.proxima:
        color = Colors.blue;
        label = 'Próxima';
        break;
      case StatusApresentacao.atual:
        color = Colors.red;
        label = 'Atual';
        break;
      case StatusApresentacao.apresentada:
        color = Colors.green;
        label = 'Apresentada';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}