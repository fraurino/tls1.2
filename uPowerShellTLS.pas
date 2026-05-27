{uses ShellAPI, Windows, SysUtils, Forms;}
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
    // Abrir arquivo de log
    AssignFile(LogFile, LogPath);
    if FileExists(LogPath) then
      Append(LogFile)
    else
      Rewrite(LogFile);

    // Escrever cabeçalho
    Writeln(LogFile, '========================================');
    Writeln(LogFile, 'LOG - Ativação TLS 1.2 para PowerShell');
    Writeln(LogFile, 'Data: ' + FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
    Writeln(LogFile, 'Usuário: ' + GetEnvironmentVariable('USERNAME'));
    Writeln(LogFile, 'Computador: ' + GetEnvironmentVariable('COMPUTERNAME'));
    Writeln(LogFile, '----------------------------------------');

    // Método 1: Tentar WinExec primeiro
    Writeln(LogFile, 'Tentando método 1: WinExec...');
    if WinExec('powershell.exe -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"', SW_HIDE) > 31 then
    begin
      Writeln(LogFile, 'WinExec executado com sucesso!');
      Success := True;
    end
    else
    begin
      Writeln(LogFile, 'WinExec falhou, tentando método 2: CreateProcess...');

      // Método 2: Tentar CreateProcess
      Command := 'powershell.exe -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"';

      FillChar(StartupInfo, SizeOf(StartupInfo), 0);
      StartupInfo.cb := SizeOf(StartupInfo);
      StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
      StartupInfo.wShowWindow := SW_HIDE;

      if CreateProcess(nil, PChar(Command), nil, nil, False,
        CREATE_NO_WINDOW, nil, nil, StartupInfo, ProcessInfo) then
      begin
        Writeln(LogFile, 'CreateProcess executado! Aguardando...');

        // Aguardar 5 segundos
        WaitForSingleObject(ProcessInfo.hProcess, 5000);
        GetExitCodeProcess(ProcessInfo.hProcess, ExitCode);

        if ExitCode = 0 then
        begin
          Writeln(LogFile, 'Processo finalizado com sucesso!');
          Success := True;
        end
        else
          Writeln(LogFile, 'Processo finalizado com código: ' + IntToStr(ExitCode));

        CloseHandle(ProcessInfo.hProcess);
        CloseHandle(ProcessInfo.hThread);
      end
      else
      begin
        Writeln(LogFile, 'CreateProcess também falhou!');
        Writeln(LogFile, ' Erro: ' + IntToStr(GetLastError));
      end;
    end;

    // Resultado final
    Writeln(LogFile, '----------------------------------------');
    if Success then
    begin
      Writeln(LogFile, '✅ STATUS: TLS 1.2 configurado com sucesso!');
      Writeln(LogFile, '✅ O PowerShell agora pode usar TLS 1.2');
    end
    else
    begin
      Writeln(LogFile, '❌ STATUS: Falha na configuração!');
      Writeln(LogFile, '❌ Verifique se o PowerShell está instalado');
      Writeln(LogFile, '❌ Execute manualmente como administrador se necessário');
    end;

    Writeln(LogFile, 'Finalizado em: ' + FormatDateTime('dd/mm/yyyy hh:nn:ss', Now));
    Writeln(LogFile, '========================================'#13#10);

  finally
    CloseFile(LogFile);
  end;
end;
