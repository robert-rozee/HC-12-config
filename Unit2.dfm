object Form2: TForm2
  Left = 225
  Top = 179
  AutoSize = True
  BorderIcons = []
  BorderStyle = bsDialog
  Caption = 'Setup'
  ClientHeight = 153
  ClientWidth = 289
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  Scaled = False
  Visible = True
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDeactivate = FormDeactivate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 8
    Width = 185
    Height = 16
    Caption = 'Select Communications Port . . .'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsUnderline]
    ParentFont = False
  end
  object ListBox1: TListBox
    Left = 16
    Top = 32
    Width = 257
    Height = 73
    ItemHeight = 13
    TabOrder = 0
    OnDblClick = ListBox1DblClick
    OnKeyPress = ListBox1KeyPress
  end
  object Button2: TButton
    Left = 104
    Top = 120
    Width = 81
    Height = 25
    Hint = 'refresh port list'
    Caption = 'refresh'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    OnClick = Button2Click
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 17
    Height = 17
    BevelOuter = bvNone
    TabOrder = 4
  end
  object Panel2: TPanel
    Left = 272
    Top = 0
    Width = 17
    Height = 17
    BevelOuter = bvNone
    TabOrder = 5
  end
  object Panel3: TPanel
    Left = 0
    Top = 136
    Width = 17
    Height = 17
    BevelOuter = bvNone
    TabOrder = 6
  end
  object Panel4: TPanel
    Left = 272
    Top = 136
    Width = 17
    Height = 17
    BevelOuter = bvNone
    TabOrder = 7
  end
  object Button3: TButton
    Left = 192
    Top = 120
    Width = 81
    Height = 25
    Caption = 'OK'
    TabOrder = 3
    OnClick = Button3Click
  end
  object Button1: TButton
    Left = 16
    Top = 120
    Width = 81
    Height = 25
    Hint = 'exit application'
    Caption = 'exit'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 1
    OnClick = Button1Click
  end
end
