import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/apresentacao.dart';
import '../providers/apresentacao_provider.dart';

class AdicionarApresentacaoDialog extends StatefulWidget {
  final Apresentacao? apresentacao; // Para edição
  final ApresentacaoProvider provider; // Adicione esta linha

  AdicionarApresentacaoDialog({
    this.apresentacao,
    required this.provider, // Adicione esta linha
  });

  @override
  _AdicionarApresentacaoDialogState createState() =>
      _AdicionarApresentacaoDialogState();
}

class _AdicionarApresentacaoDialogState
    extends State<AdicionarApresentacaoDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _grupoController;
  late TextEditingController _musicaController;

  TipoApresentacao _tipoSelecionado = TipoApresentacao.danca;
  String? _caminhoAudio;

  @override
  void initState() {
    super.initState();

    _nomeController = TextEditingController(
      text: widget.apresentacao?.nome ?? '',
    );
    _grupoController = TextEditingController(
      text: widget.apresentacao?.grupo ?? '',
    );
    _musicaController = TextEditingController(
      text: widget.apresentacao?.nomeMusica ?? '',
    );

    if (widget.apresentacao != null) {
      _tipoSelecionado = widget.apresentacao!.tipo;
      _caminhoAudio = widget.apresentacao!.caminhoAudio;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _grupoController.dispose();
    _musicaController.dispose();
    super.dispose();
  }

  Future<void> _selecionarAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _caminhoAudio = result.files.single.path!;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar arquivo: $e')),
      );
    }
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      // Use o provider passado como parâmetro
      final provider = widget.provider;

      if (widget.apresentacao == null) {
        // Adicionar nova
        final novaApresentacao = Apresentacao(
          id: Uuid().v4(),
          nome: _nomeController.text,
          grupo: _grupoController.text,
          tipo: _tipoSelecionado,
          nomeMusica: _musicaController.text.isEmpty
        ? null
            : _musicaController.text,
          caminhoAudio: _caminhoAudio,
        );

        provider.adicionarApresentacao(novaApresentacao);
      } else {
        // Editar existente
        final atualizada = widget.apresentacao!.copyWith(
          nome: _nomeController.text,
          grupo: _grupoController.text,
          tipo: _tipoSelecionado,
          nomeMusica: _musicaController.text.isEmpty
        ? null
            : _musicaController.text,
          caminhoAudio: _caminhoAudio,
        );

        provider.editarApresentacao(widget.apresentacao!.id, atualizada);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.apresentacao != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Apresentação' : 'Nova Apresentação'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome da Apresentação *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _grupoController,
                decoration: InputDecoration(
                  labelText: 'Grupo/Artista *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obrigatório';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<TipoApresentacao>(
                value: _tipoSelecionado,
                decoration: InputDecoration(
                  labelText: 'Tipo de Apresentação',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: TipoApresentacao.values.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _tipoSelecionado = value;
                    });
                  }
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _musicaController,
                decoration: InputDecoration(
                  labelText: 'Nome da Música',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.music_note),
                  hintText: 'Opcional',
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Arquivo de Áudio (Opcional)',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _selecionarAudio,
                icon: Icon(Icons.audiotrack),
                label: Text(_caminhoAudio == null
                    ? 'Selecionar Áudio'
                    : 'Áudio Selecionado'),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
              if (_caminhoAudio != null) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _caminhoAudio!.split('/').last,
                          style: TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _caminhoAudio = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _salvar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
          ),
          child: Text(isEditing ? 'Salvar' : 'Adicionar'),
        ),
      ],
    );
  }
}