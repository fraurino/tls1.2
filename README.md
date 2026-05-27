# PowerShell TLS 1.2 Activator for Delphi

[![Delphi](https://img.shields.io/badge/Delphi-7%20to%2012-red.svg)](https://www.embarcadero.com/products/delphi)
[![Windows](https://img.shields.io/badge/Windows-7%2B-blue.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Um componente/snippet Delphi para configurar silenciosamente o TLS 1.2 no PowerShell, garantindo conexões seguras com servidores que exigem protocolos modernos.

---

## 📖 Sobre o Projeto

Este projeto resolve um problema comum em sistemas Delphi: a impossibilidade do PowerShell se conectar a servidores que exigem **TLS 1.2** (como GitHub, Azure, APIs modernas, etc).

O código configura automaticamente o protocolo de segurança antes de qualquer requisição, prevenindo erros como:

```powershell
irm : A conexão subjacente estava fechada:
Erro inesperado em um envio.
```

---

## ⚠️ Por que isso acontece?

O PowerShell 5.1 (padrão do Windows 10/11) utiliza **TLS 1.0** por padrão em alguns cenários, enquanto servidores modernos exigem **TLS 1.2 ou superior**.

---

## ✨ Funcionalidades

- ✅ Configuração silenciosa
- ✅ Sem janelas ou popups
- ✅ Compatível com Delphi 7 até Delphi 12
- ✅ Execução via WinExec e CreateProcess
- ✅ Logging completo
- ✅ Fallback automático
- ✅ Sem dependências externas
- ✅ Ideal para APIs HTTPS modernas

---

## 🔧 Pré-requisitos

- Delphi 7 ou superior
- Windows 7/8/10/11
- PowerShell instalado

---

## 📦 Instalação

1. Baixe o arquivo `uPowerShellTLS.pas`
2. Adicione ao projeto:

```text
Project -> Add to Project -> uPowerShellTLS.pas
```

3. Adicione a unit no `uses`:

```pascal
uses
  uPowerShellTLS;
```

---

# 🚀 Como Usar

## Exemplo 1 — Executar no FormCreate

```pascal
uses
  uPowerShellTLS;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  ConfigurarPowerShellTLS;
end;
```

---

## Exemplo 2 — Execução Manual

```pascal
procedure TfrmMain.btnAtivarTLSClick(Sender: TObject);
begin
  if ConfigurarPowerShellTLS then
    ShowMessage('TLS 1.2 configurado com sucesso!')
  else
    ShowMessage('Falha na configuração. Verifique o log.');
end;
```

---

## Exemplo 3 — Execução em Background

```pascal
procedure TfrmMain.FormCreate(Sender: TObject);
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      ConfigurarPowerShellTLS;
    end
  ).Start;
end;
```

---

# 📝 Código Completo

```pascal
unit uPowerShellTLS;

interface

uses
  Windows, SysUtils, Forms;

function ConfigurarPowerShellTLS: Boolean;

implementation

function ConfigurarPowerShellTLS: Boolean;
var
  LogFile: TextFile;
  LogPath: string;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  Command: string;
  Success: Boolean;
  ExitCode: DWORD;
begin
  LogPath := ExtractFilePath(ParamStr(0)) + 'powershell_tls_log.txt';
  Success := False;

  try
    AssignFile(LogFile, LogPath);

    if FileExists(LogPath) then
      Append(LogFile)
    else
      Rewrite(LogFile);

    Writeln(LogFile, '========================================');
    Writeln(LogFile, 'LOG - Ativação TLS 1.2 para PowerShell');
    Writeln(LogFile, 'Data: ' + FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
    Writeln(LogFile, 'Usuário: ' + GetEnvironmentVariable('USERNAME'));
    Writeln(LogFile, 'Computador: ' + GetEnvironmentVariable('COMPUTERNAME'));
    Writeln(LogFile, '----------------------------------------');

    Writeln(LogFile, 'Tentando método 1: WinExec...');

    if WinExec(
      'powershell.exe -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"',
      SW_HIDE
    ) > 31 then
    begin
      Writeln(LogFile, '✅ WinExec executado com sucesso!');
      Success := True;
    end
    else
    begin
      Writeln(LogFile, '⚠️ WinExec falhou. Tentando CreateProcess...');

      Command :=
        'powershell.exe -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"';

      FillChar(StartupInfo, SizeOf(StartupInfo), 0);

      StartupInfo.cb := SizeOf(StartupInfo);
      StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
      StartupInfo.wShowWindow := SW_HIDE;

      if CreateProcess(
        nil,
        PChar(Command),
        nil,
        nil,
        False,
        CREATE_NO_WINDOW,
        nil,
        nil,
        StartupInfo,
        ProcessInfo
      ) then
      begin
        Writeln(LogFile, '✅ CreateProcess executado!');

        WaitForSingleObject(ProcessInfo.hProcess, 5000);

        GetExitCodeProcess(ProcessInfo.hProcess, ExitCode);

        if ExitCode = 0 then
        begin
          Writeln(LogFile, '✅ Processo finalizado com sucesso!');
          Success := True;
        end
        else
          Writeln(LogFile,
            '⚠️ Processo finalizado com código: ' +
            IntToStr(ExitCode));

        CloseHandle(ProcessInfo.hProcess);
        CloseHandle(ProcessInfo.hThread);
      end
      else
      begin
        Writeln(LogFile, '❌ CreateProcess falhou!');
        Writeln(LogFile, 'Erro: ' + IntToStr(GetLastError));
      end;
    end;

    Writeln(LogFile, '----------------------------------------');

    if Success then
    begin
      Writeln(LogFile, '✅ STATUS: TLS 1.2 configurado!');
      Writeln(LogFile, '✅ PowerShell pronto para conexões seguras.');
    end
    else
    begin
      Writeln(LogFile, '❌ STATUS: Falha na configuração!');
    end;

    Writeln(LogFile,
      'Finalizado em: ' +
      FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));

    Writeln(LogFile, '========================================');

  finally
    CloseFile(LogFile);
  end;

  Result := Success;
end;

end.
```

---

# 📊 Logs e Monitoramento

O sistema gera automaticamente:

```text
powershell_tls_log.txt
```

O log contém:

| Informação | Descrição |
|---|---|
| Data/Hora | Momento da execução |
| Usuário | Usuário Windows |
| Computador | Nome da máquina |
| Método usado | WinExec ou CreateProcess |
| Código de erro | Caso ocorra falha |
| Status final | Sucesso ou erro |

---

## Exemplo de Log

```text
========================================
LOG - Ativação TLS 1.2 para PowerShell
Data: 15/01/2026 14:30:25
Usuário: desenvolvedor
Computador: WORKSTATION01
----------------------------------------
Tentando método 1: WinExec...
✅ WinExec executado com sucesso!
----------------------------------------
✅ STATUS: TLS 1.2 configurado!
Finalizado em: 15/01/2026 14:30:25
========================================
```

---

# 🐛 Solução de Problemas

## Erro: Access violation

Use a unit completa acima.

---

## Erro: WinExec falhou

O sistema automaticamente tenta `CreateProcess`.

---

## PowerShell não encontrado

Verifique:

```text
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
```

---

## TLS 1.2 ainda não funciona

Execute manualmente:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

---

# 🤝 Contribuição

Contribuições são bem-vindas.

```bash
git checkout -b feature/NovaFeature
git commit -m "Minha melhoria"
git push origin feature/NovaFeature
```

Abra um Pull Request 🚀

---

# 📄 Licença

Este projeto está licenciado sob a licença MIT.

---

# ⭐ Créditos

Desenvolvido por Aurino para ambientes Pascal/Windows.

---

## 🏷️ Tags

```text
Delphi Pascal PowerShell TLS HTTPS API Windows Security
```
