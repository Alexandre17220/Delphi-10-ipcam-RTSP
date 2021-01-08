unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TForm1 = class(TForm)
    btnPlay: TButton;
    btnStop: TButton;
    Panel2: TPanel;
    Panel3: TPanel;
    Timer1: TTimer;
    Timer_zoom: TTimer;
    Panel1: TPanel;
    procedure btnPlayClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnStopClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer_zoomTimer(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

  plibvlc_instance_t        = type Pointer;
  plibvlc_media_player_t    = type Pointer;
  plibvlc_media_t           = type Pointer;

var
  Form1: TForm1;
  libvlc_media_new_path              : function(p_instance : Plibvlc_instance_t; path : PAnsiChar) : Plibvlc_media_t; cdecl;
  libvlc_media_new_location          : function(p_instance : plibvlc_instance_t; psz_mrl : PAnsiChar) : Plibvlc_media_t; cdecl;
  libvlc_media_player_new_from_media : function(p_media : Plibvlc_media_t) : Plibvlc_media_player_t; cdecl;
  libvlc_media_player_set_hwnd       : procedure(p_media_player : Plibvlc_media_player_t; drawable : Pointer); cdecl;
  libvlc_media_player_play           : procedure(p_media_player : Plibvlc_media_player_t); cdecl;
  libvlc_media_player_stop           : procedure(p_media_player : Plibvlc_media_player_t); cdecl;
  libvlc_media_player_release        : procedure(p_media_player : Plibvlc_media_player_t); cdecl;
  libvlc_media_player_is_playing     : function(p_media_player : Plibvlc_media_player_t) : Integer; cdecl;
  libvlc_media_release               : procedure(p_media : Plibvlc_media_t); cdecl;
  libvlc_new                         : function(argc : Integer; argv : PAnsiChar) : Plibvlc_instance_t; cdecl;
  libvlc_release                     : procedure(p_instance : Plibvlc_instance_t); cdecl;

  vlcLib: integer;
  vlcInstance: plibvlc_instance_t;
  vlcMedia: plibvlc_media_t;
  vlcMediaPlayer: plibvlc_media_player_t;

   vlcLib2: integer;
  vlcInstance2: plibvlc_instance_t;
  vlcMedia2: plibvlc_media_t;
  vlcMediaPlayer2: plibvlc_media_player_t;

    vlcLib3: integer;
  vlcInstance3: plibvlc_instance_t;
  vlcMedia3: plibvlc_media_t;
  vlcMediaPlayer3: plibvlc_media_player_t;

implementation

{$R *.dfm}

// -----------------------------------------------------------------------------
// Read registry to get VLC installation path
// -----------------------------------------------------------------------------
function GetVLCLibPath: String;
var
  Handle: HKEY;
  RegType: Integer;
  DataSize: Cardinal;
  Key: PWideChar;
begin
  Result :='';
  Key := 'Software\VideoLAN\VLC';
  if RegOpenKeyEx(HKEY_LOCAL_MACHINE, Key, 0, KEY_READ, Handle) = ERROR_SUCCESS then
  begin
    if RegQueryValueEx(Handle, 'InstallDir', nil, @RegType, nil, @DataSize) = ERROR_SUCCESS then
    begin
      SetLength(Result, DataSize);
      RegQueryValueEx(Handle, 'InstallDir', nil, @RegType, PByte(@Result[1]), @DataSize);
      Result[DataSize] := '\';
    end
    else Showmessage('Error on reading registry');
    RegCloseKey(Handle);
    Result := String(PChar(Result));
  end;

end;

function LoadVLCLibrary(APath: string): integer;
begin
  Result := LoadLibrary(PWideChar(APath + '\libvlccore.dll'));
  Result := LoadLibrary(PWideChar(APath + '\libvlc.dll'));
end;
       // -----------------------------------------------------------------------------
function GetAProcAddress(handle: integer; var addr: Pointer; procName: string; failedList: TStringList): integer;
begin
  addr := GetProcAddress(handle, PWideChar(procName));
  if Assigned(addr) then Result := 0
  else begin
    if Assigned(failedList) then failedList.Add(procName);
    Result := -1;
  end;
end;
// -----------------------------------------------------------------------------
// Get address of libvlc functions
// -----------------------------------------------------------------------------
function LoadVLCFunctions(vlcHandle: integer; failedList: TStringList): Boolean;
begin
  GetAProcAddress(vlcHandle, @libvlc_new, 'libvlc_new', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_new_location, 'libvlc_media_new_location', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_new_from_media, 'libvlc_media_player_new_from_media', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_release, 'libvlc_media_release', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_set_hwnd, 'libvlc_media_player_set_hwnd', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_play, 'libvlc_media_player_play', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_stop, 'libvlc_media_player_stop', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_release, 'libvlc_media_player_release', failedList);
  GetAProcAddress(vlcHandle, @libvlc_release, 'libvlc_release', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_player_is_playing, 'libvlc_media_player_is_playing', failedList);
  GetAProcAddress(vlcHandle, @libvlc_media_new_path, 'libvlc_media_new_path', failedList);
  // if all functions loaded, result is an empty list, otherwise result is a list of functions failed
  Result := failedList.Count = 0;
end;


procedure TForm1.btnPlayClick(Sender: TObject);
begin
  // create new vlc instance
  vlcInstance := libvlc_new(0, nil);
  // create new vlc media from file
  //vlcMedia := libvlc_media_new_path(vlcInstance, 'e:\udp\239.10.10.9.ts');

  // if you want to play from network, use libvlc_media_new_location instead
  vlcMedia := libvlc_media_new_location(vlcInstance, 'rtsp://LOGIN:PASS@IPCAM1');
  
  // create new vlc media player
  vlcMediaPlayer := libvlc_media_player_new_from_media(vlcMedia);

  // now no need the vlc media, free it
  libvlc_media_release(vlcMedia);

  // play video in a TPanel, if not call this routine, vlc media will open a new window
  libvlc_media_player_set_hwnd(vlcMediaPlayer, Pointer(Panel1.Handle));

  // play media
  libvlc_media_player_play(vlcMediaPlayer);


  // create new vlc instance
  vlcInstance2 := libvlc_new(0, nil);
  // create new vlc media from file


  // if you want to play from network, use libvlc_media_new_location instead

   vlcMedia2 := libvlc_media_new_location(vlcInstance2, 'rtsp://LOGIN:PASS@IPCAM2');

  // create new vlc media player
  vlcMediaPlayer2 := libvlc_media_player_new_from_media(vlcMedia2);

  // now no need the vlc media, free it
  libvlc_media_release(vlcMedia2);

  // play video in a TPanel, if not call this routine, vlc media will open a new window
  libvlc_media_player_set_hwnd(vlcMediaPlayer2, Pointer(Panel2.Handle));

  // play media
  libvlc_media_player_play(vlcMediaPlayer2);



  // create new vlc instance
  vlcInstance3 := libvlc_new(0, nil);
  // create new vlc media from file
 

  // if you want to play from network, use libvlc_media_new_location instead

   vlcMedia3 := libvlc_media_new_location(vlcInstance3, 'rtsp://LOGIN:PASS@IPCAM3');

  // create new vlc media player
  vlcMediaPlayer3 := libvlc_media_player_new_from_media(vlcMedia3);

  // now no need the vlc media, free it
  libvlc_media_release(vlcMedia3);

  // play video in a TPanel, if not call this routine, vlc media will open a new window
  libvlc_media_player_set_hwnd(vlcMediaPlayer3, Pointer(Panel3.Handle));

  // play media
  libvlc_media_player_play(vlcMediaPlayer3);

end;


procedure TForm1.btnStopClick(Sender: TObject);
begin
  if not Assigned(vlcMediaPlayer) then begin
    Showmessage('Not playing');
    Exit;
  end;
  // stop vlc media player
  libvlc_media_player_stop(vlcMediaPlayer);
  // and wait until it completely stops
  while libvlc_media_player_is_playing(vlcMediaPlayer) = 1 do begin
    Sleep(100);
  end;
  // release vlc media player
  libvlc_media_player_release(vlcMediaPlayer);
  vlcMediaPlayer := nil;

  // release vlc instance
  libvlc_release(vlcInstance);

  if not Assigned(vlcMediaPlayer2) then begin
    Showmessage('Not playing');
    Exit;
  end;
  // stop vlc media player
  libvlc_media_player_stop(vlcMediaPlayer2);
  // and wait until it completely stops
  while libvlc_media_player_is_playing(vlcMediaPlayer2) = 1 do begin
    Sleep(100);
  end;
  // release vlc media player
  libvlc_media_player_release(vlcMediaPlayer2);
  vlcMediaPlayer2 := nil;

  // release vlc instance
  libvlc_release(vlcInstance2);

  if not Assigned(vlcMediaPlayer3) then begin
    Showmessage('Not playing');
    Exit;
  end;
  // stop vlc media player
  libvlc_media_player_stop(vlcMediaPlayer3);
  // and wait until it completely stops
  while libvlc_media_player_is_playing(vlcMediaPlayer3) = 1 do begin
    Sleep(100);
  end;
  // release vlc media player
  libvlc_media_player_release(vlcMediaPlayer3);
  vlcMediaPlayer3 := nil;

  // release vlc instance
  libvlc_release(vlcInstance3);
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin

  btnStop.Click;
  // unload vlc library
  FreeLibrary(vlclib);
  FreeLibrary(vlclib2);
  FreeLibrary(vlclib3);
end;

procedure TForm1.FormCreate(Sender: TObject);
var sL: TStringList;
begin



  // load vlc library
  vlclib := LoadVLCLibrary(GetVLCLibPath());
  if vlclib = 0 then begin
    Showmessage('Load vlc library failed');
    Exit;
  end;
  // sL will contains list of functions fail to load
  sL := TStringList.Create;
  if not LoadVLCFunctions(vlclib, sL) then begin
    Showmessage('Some functions failed to load : ' + #13#10 + sL.Text);
    FreeLibrary(vlclib);
    sL.Free;
    Exit;
  end;
  sL.Free;

  btnPlay.Click;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  btnStop.Click;
  btnPlay.Click;
end;

procedure TForm1.Timer_zoomTimer(Sender: TObject);
var PR: TRect; // Panel Rect (in screen coordinates)
    CP: TPoint; // Cursor Position (always in screen coordinates)
begin
  // Get the panel's coordinates and convert them to Screen coordinates.
  PR.TopLeft := Panel1.ClientToScreen(Panel1.ClientRect.TopLeft);
  PR.BottomRight := Panel1.ClientToScreen(Panel1.ClientRect.BottomRight);
  // Get the mouse cursor position
  CP := Mouse.CursorPos;
  // Is the cursor over the panel?
  if (CP.X >= PR.Left) and (CP.X <= PR.Right) and (CP.Y >= PR.Top) and (CP.Y <= PR.Bottom) then
    begin
      // Panel should be made visible
      //Panel1.Visible := True;
      //form1.AutoSize:=false;
      Panel1.Width := 416 *2;
      Panel1.height := 223 *2;
      //form1.AutoSize:=true;
    end
  else
    begin
      // Panel should be hidden
      //Panel1.Visible := False;
      Panel1.Width := 416;
      Panel1.height := 223;
    end;

    panel2.Top := panel1.Top+Panel1.height;

     // Get the panel's coordinates and convert them to Screen coordinates.
  PR.TopLeft := Panel2.ClientToScreen(Panel2.ClientRect.TopLeft);
  PR.BottomRight := Panel2.ClientToScreen(Panel2.ClientRect.BottomRight);
  // Get the mouse cursor position
  CP := Mouse.CursorPos;
  // Is the cursor over the panel?
  if (CP.X >= PR.Left) and (CP.X <= PR.Right) and (CP.Y >= PR.Top) and (CP.Y <= PR.Bottom) then
    begin
      Panel2.Width := 416 *2;
      Panel2.height := 223 *2;
    end
  else
    begin
      Panel2.Width := 416;
      Panel2.height := 223;
    end;

    panel3.Top := panel2.Top+Panel2.height;
       // Get the panel's coordinates and convert them to Screen coordinates.
  PR.TopLeft := Panel3.ClientToScreen(Panel3.ClientRect.TopLeft);
  PR.BottomRight := Panel3.ClientToScreen(Panel3.ClientRect.BottomRight);
  // Get the mouse cursor position
  CP := Mouse.CursorPos;
  // Is the cursor over the panel?
  if (CP.X >= PR.Left) and (CP.X <= PR.Right) and (CP.Y >= PR.Top) and (CP.Y <= PR.Bottom) then
    begin
      // Panel should be made visible
      //Panel1.Visible := True;
      Panel3.Width := 416 *2;
      Panel3.height := 223 *2;
    end
  else
    begin
      // Panel should be hidden
      //Panel1.Visible := False;
      Panel3.Width := 416;
      Panel3.height := 223;
    end;
end;

end.
