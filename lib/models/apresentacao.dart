enum TipoApresentacao {
  danca,
  karaoke,
  canto,
  outros;

  String get label {
    switch (this) {
      case TipoApresentacao.danca:
        return 'Dança';
      case TipoApresentacao.karaoke:
        return 'Karaokê';
      case TipoApresentacao.canto:
        return 'Canto';
      case TipoApresentacao.outros:
        return 'Outros';
    }
  }
}

enum StatusApresentacao {
  proxima,
  atual,
  apresentada;
}

class Apresentacao {
  final String id;
  final String nome;
  final String grupo;
  final TipoApresentacao tipo;
  final String? nomeMusica;
  final String? caminhoAudio;
  StatusApresentacao status;
  int ordem;

  Apresentacao({
    required this.id,
    required this.nome,
    required this.grupo,
    required this.tipo,
    this.nomeMusica,
    this.caminhoAudio,
    this.status = StatusApresentacao.proxima,
    this.ordem = 0,
  });

  // Conversão para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'grupo': grupo,
      'tipo': tipo.name,
      'nomeMusica': nomeMusica,
      'caminhoAudio': caminhoAudio,
      'status': status.name,
      'ordem': ordem,
    };
  }

  // Criar a partir de JSON
  factory Apresentacao.fromJson(Map<String, dynamic> json) {
    return Apresentacao(
      id: json['id'] as String,
      nome: json['nome'] as String,
      grupo: json['grupo'] as String,
      tipo: TipoApresentacao.values.firstWhere(
            (e) => e.name == json['tipo'],
        orElse: () => TipoApresentacao.outros,
      ),
      nomeMusica: json['nomeMusica'] as String?,
      caminhoAudio: json['caminhoAudio'] as String?,
      status: StatusApresentacao.values.firstWhere(
            (e) => e.name == json['status'],
        orElse: () => StatusApresentacao.proxima,
      ),
      ordem: json['ordem'] as int? ?? 0,
    );
  }

  // Copiar com alterações
  Apresentacao copyWith({
    String? nome,
    String? grupo,
    TipoApresentacao? tipo,
    String? nomeMusica,
    String? caminhoAudio,
    StatusApresentacao? status,
    int? ordem,
  }) {
    return Apresentacao(
      id: id,
      nome: nome ?? this.nome,
      grupo: grupo ?? this.grupo,
      tipo: tipo ?? this.tipo,
      nomeMusica: nomeMusica ?? this.nomeMusica,
      caminhoAudio: caminhoAudio ?? this.caminhoAudio,
      status: status ?? this.status,
      ordem: ordem ?? this.ordem,
    );
  }
}

class Evento {
  final String id;
  String nome;
  final DateTime dataCriacao;

  Evento({
    required this.id,
    required this.nome,
    required this.dataCriacao,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'dataCriacao': dataCriacao.toIso8601String(),
    };
  }

  factory Evento.fromJson(Map<String, dynamic> json) {
    return Evento(
      id: json['id'] as String,
      nome: json['nome'] as String,
      dataCriacao: DateTime.parse(json['dataCriacao'] as String),
    );
  }
}