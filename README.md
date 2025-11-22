# Sistema de Gerenciamento de Apresentações Culturais

Sistema desenvolvido em Flutter para gerenciar apresentações culturais em eventos, com sincronização automática entre dispositivos via rede local (LAN).

## 🚀 Recursos

✅ **Painel Principal** (Servidor)
- Cadastro completo de apresentações
- Controle de fila (próximas/atual/apresentadas)
- Reprodução de áudio integrada
- Reordenação por arrastar e soltar
- Servidor automático (WebSocket + UDP Broadcast)

✅ **Painel do Mestre de Cerimônias** (Cliente)
- Visualização simplificada e ampliada
- Conexão automática ao servidor
- Atualização em tempo real
- Status de conexão visual

✅ **Sincronização Automática**
- Autodescoberta via UDP Broadcast
- Conexão WebSocket estável
- Suporte para múltiplos clientes
- Reconexão automática

## 📋 Pré-requisitos

- **Flutter SDK** 3.0 ou superior
- **Dart** 3.0 ou superior
- **Windows 10+** (para desktop) ou **Android 8+/iOS 12+** (para tablets)
- Rede LAN local (Wi-Fi ou cabo)

## 🔧 Instalação

### 1. Instalar Flutter

Siga as instruções oficiais: https://docs.flutter.dev/get-started/install

### 2. Clonar/Baixar o Projeto

```bash
# Se estiver usando Git
git clone <url-do-repositorio>
cd apresentacoes_culturais

# Ou extrair o ZIP do projeto
```

### 3. Instalar Dependências

```bash
flutter pub get
```

### 4. Verificar Configuração

```bash
flutter doctor
```

## ▶️ Como Executar

### Windows (Desktop)

```bash
# Habilitar suporte desktop se ainda não fez
flutter config --enable-windows-desktop

# Executar
flutter run -d windows
```

### Android (Tablet)

```bash
# Conectar tablet via USB ou usar emulador
flutter devices

# Executar
flutter run -d <device-id>
```

### iOS (Tablet)

```bash
# Requer macOS e Xcode instalado
flutter run -d <device-id>
```

## 📱 Como Usar

### Configuração Inicial

1. **Notebook/Desktop Principal:**
   - Execute o aplicativo
   - Selecione **"Painel Principal"**
   - Configure o nome do evento
   - O servidor será iniciado automaticamente

2. **Tablet (Mestre de Cerimônias):**
   - Execute o aplicativo no mesmo Wi-Fi
   - Selecione **"Mestre de Cerimônias"**
   - O app conectará automaticamente ao servidor
   - Aguarde o indicador "🟢 Conectado"

### Operações Principais

#### Adicionar Apresentação
1. Clique em **"Nova Apresentação"**
2. Preencha: Nome, Grupo, Tipo, Música
3. (Opcional) Selecione arquivo de áudio
4. Clique em **"Adicionar"**

#### Chamar Próxima Apresentação
1. Clique em **"Chamar Próxima"**
2. Confirme a ação
3. A apresentação atual vai para "Apresentadas"
4. A próxima da fila se torna "Atual"

#### Selecionar Apresentação Específica
1. Clique em **"Selecionar Próxima"**
2. Busque ou selecione na lista
3. Confirme
4. A apresentação vai para o topo da fila

#### Retornar Apresentação
1. Clique em **"Retornar Atração"**
2. Confirme
3. A apresentação atual volta para a fila

#### Reordenar Fila
- Arraste e solte apresentações na coluna "Próximas Atrações"

## 🔌 Configuração de Rede

### Portas Utilizadas
- **UDP 9999** - Descoberta de servidor (broadcast)
- **TCP 8080** - WebSocket (sincronização)

### Requisitos de Rede
- Todos os dispositivos na **mesma rede local**
- Firewall permitindo conexões nas portas acima
- Wi-Fi ou cabo Ethernet funcionando

### Solução de Problemas de Conexão

**"Procurando servidor..."**
- Verifique se o Painel Principal está aberto
- Confirme que ambos estão na mesma rede
- Verifique firewall (Windows Defender, etc.)
- Tente reiniciar ambos os apps

**Conexão instável**
- Aproxime dispositivos do roteador
- Reduza interferências Wi-Fi
- Use cabo Ethernet se possível

## 📁 Estrutura do Projeto

```
apresentacoes_culturais/
├── lib/
│   ├── main.dart                          # Ponto de entrada
│   ├── models/
│   │   └── apresentacao.dart              # Modelos de dados
│   ├── providers/
│   │   └── apresentacao_provider.dart     # Gerenciamento de estado
│   ├── services/
│   │   └── network_service.dart           # UDP + WebSocket
│   └── screens/
│       ├── painel_principal_screen.dart   # Tela principal (servidor)
│       ├── painel_mestre_screen.dart      # Tela mestre (cliente)
│       ├── adicionar_apresentacao_dialog.dart
│       └── selecionar_proxima_dialog.dart
├── pubspec.yaml                           # Dependências
└── README.md
```

## 🛠️ Compilar para Produção

### Windows

```bash
flutter build windows --release
```

Executável em: `build/windows/runner/Release/apresentacoes_culturais.exe`

### Android (APK)

```bash
flutter build apk --release
```

APK em: `build/app/outputs/flutter-apk/app-release.apk`

### Android (App Bundle)

```bash
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

## 📦 Dependências Principais

- **provider** - Gerenciamento de estado
- **web_socket_channel** - Comunicação WebSocket
- **shared_preferences** - Armazenamento local
- **just_audio** - Reprodução de áudio
- **file_picker** - Seleção de arquivos
- **intl** - Formatação de data/hora

## ⚠️ Limitações Conhecidas

- Player de áudio ainda não implementado (placeholder visual presente)
- Funciona apenas em rede local (sem internet)
- Máximo recomendado: 5 clientes simultâneos

## 🔮 Próximas Melhorias

- [ ] Implementar player de áudio completo com controles
- [ ] Adicionar edição de apresentações existentes
- [ ] Exportar/importar evento completo (JSON)
- [ ] Tema escuro
- [ ] Histórico de eventos anteriores
- [ ] Estatísticas de apresentações

## 📄 Licença

Projeto desenvolvido para fins educacionais (Projeto de Extensão).

## 👨‍💻 Suporte

Para dúvidas ou problemas:
1. Verifique a documentação de requisitos
2. Consulte a seção de "Solução de Problemas"
3. Entre em contato com o desenvolvedor

---

**Versão:** 1.0.0  
**Última atualização:** Novembro 2024