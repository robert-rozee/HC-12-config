unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Registry, ExtCtrls;

type
  TForm2 = class(TForm)
    ListBox1: TListBox;
    Label1: TLabel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    procedure ListBox1DblClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ListBox1KeyPress(Sender: TObject; var Key: Char);
    procedure Button3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation

{$R *.DFM}

uses Shared, Unit1;

var CommPortList:TStringList;

const InitList:boolean=true;


procedure FindPorts;
var reg:TRegistry;
      i:integer;
      s:string;
begin
  reg:=TRegistry.Create;
  CommPortList.Clear;

  with Form2 do
  begin
    ListBox1.Clear;

    with reg do
    try
      RootKey:=HKEY_LOCAL_MACHINE;
      if OpenKeyReadOnly('hardware\devicemap\serialcomm') then
      begin
        try
          GetValueNames(CommPortList);
          for i:=0 to CommPortList.Count-1 do
          begin
//          showmessage(commportlist.strings[i]);     // port description
            s:=ReadString(CommPortList.Strings[i]);   // port name
//          showmessage(s);
            ListBox1.Items.Add(s + ' = ' + CommPortList.Strings[i]);
            CommPortList.Strings[i]:=s      // overwrite description with name
          end
        except
          showmessage('exception accessing registry')
        end
      end
    finally
      CloseKey;
      reg.Free
    end;

    if ListBox1.Items.Count<>0 then ListBox1.ItemIndex:=0;
    Button3.Enabled:=((ListBox1.ItemIndex<>-1));
    ListBox1.SetFocus
  end
end;


procedure TForm2.FormCreate(Sender: TObject);
begin
  CommPortList:=TStringList.Create
end;


procedure TForm2.FormActivate(Sender: TObject);  // also button1 click
begin
  if InitList then
  begin
    InitList:=false;
    FindPorts
  end
end;


procedure TForm2.ListBox1DblClick(Sender: TObject);
begin
  CommPortName:=CommPortList.Strings[ListBox1.ItemIndex];
  InitFlag:=true;
  Application.ProcessMessages;
  Form1.Show;
  Form2.Close
end;


procedure TForm2.ListBox1KeyPress(Sender: TObject; var Key: Char);
begin
  if (Key=#13) and (ListBox1.ItemIndex<>-1) then
  begin
    CommPortName:=CommPortList.Strings[ListBox1.ItemIndex];
    InitFlag:=true;
    Application.ProcessMessages;
    Form1.Show;
    Form2.Close
  end
end;


procedure TForm2.FormDeactivate(Sender: TObject);
begin
  if not InitFlag then Form2.SetFocus
end;


procedure TForm2.Button1Click(Sender: TObject);
begin
  halt
end;


procedure TForm2.Button2Click(Sender: TObject);
begin
  FindPorts
end;


procedure TForm2.Button3Click(Sender: TObject);
begin
  if ListBox1.ItemIndex<>-1 then
  begin
    CommPortName:=CommPortList.Strings[ListBox1.ItemIndex];
    InitFlag:=true;
    Application.ProcessMessages;
    Form1.Show;
    Form2.Close
  end
end;


end.
