object Form1: TForm1
  Left = 0
  Top = 0
  AutoSize = True
  Caption = 'Ipcam viewer'
  ClientHeight = 663
  ClientWidth = 416
  Color = clBackground
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 416
    Height = 223
    Caption = 'Panel2'
    TabOrder = 4
  end
  object btnPlay: TButton
    Left = 280
    Top = 145
    Width = 75
    Height = 25
    Caption = 'btnPlay'
    TabOrder = 0
    Visible = False
    WordWrap = True
    OnClick = btnPlayClick
  end
  object btnStop: TButton
    Left = 280
    Top = 176
    Width = 75
    Height = 25
    Caption = 'btnStop'
    TabOrder = 1
    Visible = False
    OnClick = btnStopClick
  end
  object Panel2: TPanel
    Left = 0
    Top = 440
    Width = 416
    Height = 223
    Caption = 'Panel2'
    TabOrder = 2
  end
  object Panel3: TPanel
    Left = 0
    Top = 223
    Width = 416
    Height = 217
    Caption = 'Panel3'
    TabOrder = 3
  end
  object Timer1: TTimer
    Interval = 1800000
    OnTimer = Timer1Timer
    Left = 192
    Top = 120
  end
  object Timer_zoom: TTimer
    OnTimer = Timer_zoomTimer
    Left = 160
    Top = 160
  end
end
