unit uPowerShellTLS;

interface

uses
  Winapi.Windows,
  System.SysUtils;

type
  TPowerShellTLS = class
  private
    class procedure EscreverLog(var ALogFile: TextFile; const AMensagem: string); static;
    class function ExecutarWinExec: Boolean; static;
    class function ExecutarCreateProcess(var ALogFile: TextFile): Boolean; static;
  public
    class function ConfigurarTLS12: Boolean; static;
  end;

implementation

class procedure TPowerShellTLS.EscreverLog(var ALogFile: TextFile; const AMensagem: string);
begin
  Writeln(ALogFile, AMensagem);
end;

class function TPowerShellTLS.ExecutarWinExec: Boolean;
const
  CMD_TLS =
    'powershell.exe -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"';
begin
  Result := WinExec(PAnsiChar(AnsiString(CMD_TLS)), SW_HIDE) > 31;
end;

class function TPowerShellTLS.ExecutarCreateProcess(var ALogFile: TextFile): Boolean;
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  Command: string;
  ExitCode: DWORD;
begin
  Result := False;

  Command :=
    'powershell.exe -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"';

  FillChar(StartupInfo, SizeOf(StartupInfo), 0);
  FillChar(ProcessInfo, SizeOf(ProcessInfo), 0);

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
    EscreverLog(ALogFile, 'CreateProcess executado! Aguardando...');

    WaitForSingleObject(ProcessInfo.hProcess, 5000);
    GetExitCodeProcess(ProcessInfo.hProcess, ExitCode);

    if ExitCode = 0 then
    begin
      EscreverLog(ALogFile, 'Processo finalizado com sucesso!');
      Result := True;
    end
    else
      EscreverLog(ALogFile, 'Processo finalizado com código: ' + IntToStr(ExitCode));

    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
  end
  else
  begin
    EscreverLog(ALogFile, 'CreateProcess falhou!');
    EscreverLog(ALogFile, 'Erro: ' + IntToStr(GetLastError));
  end;
end;

class function TPowerShellTLS.ConfigurarTLS12: Boolean;
var
  LogFile: TextFile;
  LogPath: string;
begin
  Result := False;
  LogPath := ExtractFilePath(ParamStr(0)) + 'powershell_tls_log.txt';

  AssignFile(LogFile, LogPath);

  try
    if FileExists(LogPath) then
      Append(LogFile)
    else
      Rewrite(LogFile);

    EscreverLog(LogFile, '========================================');
    EscreverLog(LogFile, 'LOG - Ativação TLS 1.2 para PowerShell');
    EscreverLog(LogFile, 'Data: ' + FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
    EscreverLog(LogFile, 'Usuário: ' + GetEnvironmentVariable('USERNAME'));
    EscreverLog(LogFile, 'Computador: ' + GetEnvironmentVariable('COMPUTERNAME'));
    EscreverLog(LogFile, '----------------------------------------');

    EscreverLog(LogFile, 'Tentando método 1: WinExec...');

    if ExecutarWinExec then
    begin
      EscreverLog(LogFile, 'WinExec executado com sucesso!');
      Result := True;
    end
    else
    begin
      EscreverLog(LogFile, 'WinExec falhou, tentando método 2: CreateProcess...');
      Result := ExecutarCreateProcess(LogFile);
    end;

    EscreverLog(LogFile, '----------------------------------------');

    if Result then
    begin
      EscreverLog(LogFile, 'STATUS: TLS 1.2 configurado com sucesso!');
      EscreverLog(LogFile, 'O PowerShell agora pode usar TLS 1.2');
    end
    else
    begin
      EscreverLog(LogFile, 'STATUS: Falha na configuração!');
      EscreverLog(LogFile, 'Verifique se o PowerShell está instalado');
      EscreverLog(LogFile, 'Execute manualmente como administrador se necessário');
    end;

    EscreverLog(LogFile, 'Finalizado em: ' + FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
    EscreverLog(LogFile, '========================================' + sLineBreak);

  finally
    CloseFile(LogFile);
  end;
end;

end.
