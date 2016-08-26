unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    GroupBox1: TGroupBox;
      UpDown1: TUpDown;                     // channel up/down
      Label1: TLabel;                       // channel display
      Label2: TLabel;                       // frequency display
      CheckBox1: TCheckBox;                 // LPD433 check box
    GroupBox2: TGroupBox;
      RadioButton1: TRadioButton;           // odd parity
      RadioButton2: TRadioButton;           // even parity
      RadioButton3: TRadioButton;           // no parity
    GroupBox3: TGroupBox;
      RadioButton4: TRadioButton;           // 1 stop bit
      RadioButton5: TRadioButton;           // 1.5 stop bits
      RadioButton6: TRadioButton;           // 2 stop bits
    GroupBox4: TGroupBox;
      RadioButton7: TRadioButton;           // 7 data bits
      RadioButton8: TRadioButton;           // 8 data bits
    ComboBox1: TComboBox;                   // baud rate selector
    ComboBox2: TComboBox;                   // operating mode selector
    ComboBox3: TComboBox;                   // Tx power selector
    Button1: TButton;                       // perform factory reset
    Button2: TButton;                       // read configuration button
    Button3: TButton;                       // send configuration button
    Label3: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure UpDown1Click(Sender: TObject; Button: TUDBtnType);
    procedure CheckBox1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ComboBox1or2Change(Sender: TObject);
    procedure FormDblClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}
uses shared;


var CommFile: THandle;
    RxBuffer:string;

const Running:boolean=false;           // respond to buttons only if true
const EOL='';                          // use #13+#10 for CR-LF terminated
      DLY=0;                           // delay between sending command strings


function strip(s:string):string;       // strip trailing control characters
begin
  while (length(s)<>0) and (s[length(s)]<#32) do delete(s,length(s),1);
  strip:=s
end;


function at2ok(s:string):string;       // convert AT command into OK response
begin
  if (length(s)>=1) and (s[1]='A') then s[1]:='O';
  if (length(s)>=2) and (s[2]='T') then s[2]:='K';
  at2ok:=s
end;


procedure ChannelUpdate;
var s:string;
begin
  with Form1 do
  begin
    s:=inttostr(UpDown1.Position);
    while length(s)<3 do s:='0'+s;
    Label1.Caption:=s;
    s:=floattostrF(433.0+UpDown1.Position*0.4, ffFixed,4,1)+' MHz';
    Label2.Caption:=s
  end
end;


procedure InitControls;
begin
  with Form1 do
  begin
    UpDown1.Position:=1;                         // channel 1
    ChannelUpdate;
    ComboBox1.ItemIndex:=3;                      // 9600 baud
    ComboBox2.ItemIndex:=2;                      // FU3
    ComboBox3.ItemIndex:=7;                      // 100mw/20dBm
    RadioButton3.Checked:=true;                  // no parity
    RadioButton4.Checked:=true;                  // 1 stop bit
    RadioButton8.Checked:=true                   // 8 data bits
  end
end;


procedure TForm1.FormCreate(Sender: TObject);
begin
  Application.Title:=Form1.Caption;
  Form1.DoubleBuffered:=true;
// most configuration must be carried out in the first call to
// FormActivate as the comm port hasn't been selected yet.

   CheckBox1.Checked:=true;                     // LPD433 locked
   InitControls
end;


procedure TForm1.FormActivate(Sender: TObject);
var DeviceName:array [0..80] of char;
           DCB:TDCB;
        Config:string;
       CommTOs:TCommTimeouts;
          proc:string;
begin
  if InitFlag then
  begin
    InitFlag:=false;
    RxBuffer:='';

    try
      StrPCopy(DeviceName, '\\.\'+CommPortName);
      proc:='CreateFile';
      CommFile:=CreateFile(DeviceName,
                           GENERIC_READ or GENERIC_WRITE,
                           0, Nil,
                           OPEN_EXISTING,
                           FILE_ATTRIBUTE_NORMAL, 0);
      if (CommFile=INVALID_HANDLE_VALUE) then
      begin
        showmessage('Serial I/O error: '+proc+' failed'+#13+#13+
                    'device = '+Devicename+#13+
                    'handle = 0x'+IntToHex(CommFile,8));
        halt
      end;
      proc:='SetupComm';
      if not SetupComm(CommFile, 1024, 1024) then
      begin
        showmessage('Serial I/O error: '+proc+' failed'+#13+#13+
                    'device = '+Devicename+#13+
                    'handle = 0x'+IntToHex(CommFile,8));
        halt
      end;
      proc:='GetCommState';
      if not GetCommState(CommFile, DCB) then
      begin
        showmessage('Serial I/O error: '+proc+' failed'+#13+#13+
                    'device = '+Devicename+#13+
                    'handle = 0x'+IntToHex(CommFile,8));
        halt
      end;
      Config:='baud=9600 parity=n data=8 stop=1'#0;
      proc:='BuildCommDCB';
      if not BuildCommDCB(@Config[1], DCB) then
      begin
        showmessage('Serial I/O error: '+proc+' failed'+#13+#13+
                    'device = '+Devicename+#13+
                    'handle = 0x'+IntToHex(CommFile,8));
        halt
      end;
      proc:='SetCommState';
      if not SetCommState(CommFile, DCB) then
      begin
        showmessage('Serial I/O error: '+proc+' failed'+#13+#13+
                    'device = '+Devicename+#13+
                    'handle = 0x'+IntToHex(CommFile,8));
        halt
      end;
      with CommTOs do
      begin
        ReadIntervalTimeout := 0;                // 0
        ReadTotalTimeoutMultiplier := 0;         // 0
        ReadTotalTimeoutConstant := 300;         // 300
        WriteTotalTimeoutMultiplier := 0;        // 0
        WriteTotalTimeoutConstant := 300         // 300
      end;
      proc:='SetCommTimeouts';
      if not SetCommTimeouts(CommFile, CommTOs) then
      begin
        showmessage('Serial I/O error: '+proc+' failed'+#13+#13+
                    'device = '+Devicename+#13+
                    'handle = 0x'+IntToHex(CommFile,8));
        halt
      end
    except
      try CloseHandle(CommFile); except end;
      showmessage('Serial I/O error: '+proc+' exception'+#13+#13+
                  'device = '+Devicename+#13+
                  'handle = 0x'+IntToHex(CommFile,8));
      halt
    end;

    Running:=true
  end
end;


procedure TForm1.UpDown1Click(Sender: TObject; Button: TUDBtnType);
begin
  ChannelUpdate
end;


procedure TForm1.CheckBox1Click(Sender: TObject);
begin
  if CheckBox1.Checked then begin
                              UpDown1.Max:=4;
                              CheckBox1.Font.Color:=clBlack;
                              CheckBox1.Caption:='LPD433 lock'
                            end
                       else begin
                              UpDown1.Max:=254;        // max 127 in datasheet
                              CheckBox1.Font.Color:=clRed;
                              CheckBox1.Caption:='UNLOCKED'
                            end;
  ChannelUpdate
end;


procedure TForm1.ComboBox1or2Change(Sender: TObject);
begin
  case ComboBox2.ItemIndex of 1:if ComboBox1.ItemIndex>2 then
                                begin
                                  ComboBox1.ItemIndex:=2;
                                  if Sender=ComboBox1 then
                                      ShowMessage('4800 bps maximum in FU2 mode')
                                  else
                                      ShowMessage('Baud rate reduced to 4800 bps')
                                end;
                              3:if ComboBox1.ItemIndex>0 then
                                begin
                                  ComboBox1.ItemIndex:=0;
                                  if Sender=ComboBox1 then
                                      ShowMessage('1200 bps maximum in FU4 mode')
                                  else
                                      ShowMessage('Baud rate reduced to 1200 bps')
                                end
  end  { of case }
end;


(*
  1.1 clear Rx buffer
  1.2 write "AT+DEFAULT"
  2.3 read  "OK+DEFAULT"
  2.4 response bad
 *)
procedure TForm1.Button1Click(Sender: TObject);
var s,e,r:string;            // AT command, expected response, actual response
    put,got:DWORD;
    b:array [1..80] of char;
begin
  if not Running then exit;
  Running:=false;
  Button1.Enabled:=false;

// clear Rx buffer
  try
    if not PurgeComm(CommFile, PURGE_RXCLEAR) then              // clear buffer
    begin
      showmessage('Serial I/O error: PurgeComm failed (1.1)');
      halt
    end
  except
    showmessage('Serial I/O error: PurgeComm exception (1.1)');
    halt
  end;

// send factory reset command "AT+DEFAULT"
  s:='AT+DEFAULT'+EOL;
  e:=at2ok(s);

  try
    if not WriteFile(CommFile, s[1], length(s), put, nil) then  // write command
    begin
      showmessage('Serial I/O error: WriteFile failed (1.2)');
      halt
    end
  except
    showmessage('Serial I/O error: WriteFile exception (1.2)');
    halt
  end;

// get factory reset response
  try
    if not ReadFile(CommFile, b[1], sizeof(b), got, nil) then   // read response
    begin
      showmessage('Serial I/O error: ReadFile failed (1.3)');
      halt
    end
  except
    showmessage('Serial I/O error: ReadFile exception (1.3)');
    halt
  end;

  r:=copy(b,1,got);
  if strip(r)<>strip(e) then
      showmessage('invalid response (1.4)'+#13+
                  'command <'+strip(s)+'>'+#13+
                  'response <'+strip(r)+'>')
  else
      InitControls;            // synchronize controls to factory reset state

  Button1.Enabled:=true;
  Running:=true
end;


(*
  2.1 clear Rx buffer
  2.2 write "AT+RX"
  2.3 read  "OK+B9600
             OK+RC001
             OK+RP:+20dBm
             OK+FU3"
  2.4 write "AT+V"
  2.5 read  "HC-12_V2.3"
  (#data bits, parity, #stop bits are NOT returned)
 *)
procedure TForm1.Button2Click(Sender: TObject);
var s,cfg,ver:string;
    put,got:DWORD;
    b:array [1..80] of char;
begin
  if not Running then exit;
  Running:=false;
  Button2.Enabled:=false;

// clear Rx buffer
  try
    if not PurgeComm(CommFile, PURGE_RXCLEAR) then              // clear buffer
    begin
      showmessage('Serial I/O error: PurgeComm failed (2.1)');
      halt
    end
  except
    showmessage('Serial I/O error: PurgeComm exception (2.1)');
    halt
  end;

// send read all configurations command "AT+RX"
  s:='AT+RX'+EOL;

  try
    if not WriteFile(CommFile, s[1], length(s), put, nil) then  // write command
    begin
      showmessage('Serial I/O error: WriteFile failed (2.2)');
      halt
    end
  except
    showmessage('Serial I/O error: WriteFile exception (2.2)');
    halt
  end;

// get read all configurations response
  try
    if not ReadFile(CommFile, b[1], sizeof(b), got, nil) then   // read response
    begin
      showmessage('Serial I/O error: ReadFile failed (2.3)');
      halt
    end
  except
    showmessage('Serial I/O error: ReadFile exception (2.3)');
    halt
  end;

  cfg:=strip(copy(b,1,got));

                                  // *****************************************
  if DLY<>0 then sleep(DLY);      // ******* delay between AT commands *******
                                  // *****************************************

// send get version information command "AT+V"
  s:='AT+V'+EOL;

  try
    if not WriteFile(CommFile, s[1], length(s), put, nil) then  // write command
    begin
      showmessage('Serial I/O error: WriteFile failed (2.4)');
      halt
    end
  except
    showmessage('Serial I/O error: WriteFile exception (2.4)');
    halt
  end;

// get version information response
  try
    if not ReadFile(CommFile, b[1], sizeof(b), got, nil) then   // read response
    begin
      showmessage('Serial I/O error: ReadFile failed (2.5)');
      halt
    end
  except
    showmessage('Serial I/O error: ReadFile exception (2.5)');
    halt
  end;

  ver:=strip(copy(b,1,got));

  showmessage('configuration response:'+#13+cfg+#13+#13+
              'version response:'      +#13+ver);

  Button2.Enabled:=true;
  Running:=true
end;


(*
  3.1  clear Rx buffer
  3.2  write "AT+Bxxxx"        // set baud rate (1200 .. 115200)
  3.3  read  "OK+Bxxxx
  3.4  response bad
  3.5  write "AT+Cxxx"         // set channel number (001 .. 127)
  3.6  read  "OK+Cxxx"
  3.7  response bad
  3.11 write "AT+FUx"          // set operating mode (FU1 .. FU4)
  3.12 read  "OK+FUx"
  3.13 response bad
  3.14 write "AT+Px"           // set Tx power level (1 .. 8)
  3.15 read  "OK+Px"
  3.16 response bad
  3.17 write "AT+Unps"         // set serial format (#data bits, parity, #stop bits)
  3.18 read  "AT+Unps"
  3.19 response bad
 *)
procedure TForm1.Button3Click(Sender: TObject);
var s,e,r:string;            // AT command, expected response, actual response
    put,got:DWORD;
    b:array [1..80] of char;
begin
  if not Running then exit;
  Running:=false;
  Button3.Enabled:=false;

// clear Rx buffer
  try
    if not PurgeComm(CommFile, PURGE_RXCLEAR) then              // clear buffer
    begin
      showmessage('Serial I/O error: PurgeComm failed (3.1)');
      halt
    end
  except
    showmessage('Serial I/O error: PurgeComm exception (3.1)');
    halt
  end;

// send set baud rate command "AT+Bxxxx"
  case ComboBox1.ItemIndex of 0:s:='AT+B1200'+EOL;
                              1:s:='AT+B2400'+EOL;
                              2:s:='AT+B4800'+EOL;
                              3:s:='AT+B9600'+EOL;
                              4:s:='AT+B19200'+EOL;
                              5:s:='AT+B38400'+EOL;
                              6:s:='AT+B57600'+EOL;
                              7:s:='AT+B115200'+EOL
                           else s:='AT'+EOL        // default to no action
  end;  { of case }
  e:=at2ok(s);

  try
    if not WriteFile(CommFile, s[1], length(s), put, nil) then  // write command
    begin
      showmessage('Serial I/O error: WriteFile failed (3.2)');
      halt
    end
  except
    showmessage('Serial I/O error: WriteFile exception (3.2)');
    halt
  end;

// get set baud rate response
  try
    if not ReadFile(CommFile, b[1], sizeof(b), got, nil) then   // read response
    begin
      showmessage('Serial I/O error: ReadFile failed (3.3)');
      halt
    end
  except
    showmessage('Serial I/O error: ReadFile exception (3.3)');
    halt
  end;

  r:=copy(b,1,got);
  if strip(r)<>strip(e) then
     showmessage('invalid response (3.4)'+#13+
                 'command <'+strip(s)+'>'+#13+
                 'response <'+strip(r)+'>');

                                  // *****************************************
  if DLY<>0 then sleep(DLY);      // ******* delay between AT commands *******
                                  // *****************************************

// send set channel/frequency command "AT+Cxxx"
  s:='AT+C'+Label1.Caption+EOL;
  e:=at2ok(s);

  try
    if not WriteFile(CommFile, s[1], length(s), put, nil) then  // write command
    begin
      showmessage('Serial I/O error: WriteFile failed (3.5)');
      halt
    end
  except
    showmessage('Serial I/O error: WriteFile exception (3.5)');
    halt
  end;

// get set channel/frequency response
  try
    if not ReadFile(CommFile, b[1], sizeof(b), got, nil) then   // read response
    begin
      showmessage('Serial I/O error: ReadFile failed (3.6)');
      halt
    end
  except
    showmessage('Serial I/O error: ReadFile exception (3.6)');
    halt
  end;

  r:=copy(b,1,got);
  if strip(r)<>strip(e) then
     showmessage('invalid response (3.7)'+#13+
                 'command <'+strip(s)+'>'+#13+
                 'response <'+strip(r)+'>');

                                  // *****************************************
  if DLY<>0 then sleep(DLY);      // ******* delay between AT commands *******
                                  // *****************************************

// send set operating mode command "AT+FUx"
  case ComboBox2.ItemIndex of 0:s:='AT+FU1'+EOL;
                              1:s:='AT+FU2'+EOL;
                              2:s:='AT+FU3'+EOL;
                              3:s:='AT+FU4'+EOL
                           else s:='AT'+EOL        // default to no action
  end;  { of case }
  e:=at2ok(s);

  try
    if not WriteFile(CommFile, s[1], length(s), put, nil) then  // write command
    begin
      showmessage('Serial I/O error: WriteFile failed (3.11)');
      halt
    end
  except
    showmessage('Serial I/O error: WriteFile exception (3.11)');
    halt
  end;

// get set operating mode response
  try
    if not ReadFile(CommFile, b[1], sizeof(b), got, nil) then   // read response
    begin
      showmessage('Serial I/O error: ReadFile failed (3.12)');
      halt
    end
  except
    showmessage('Serial I/O error: ReadFile exception (3.12)');
    halt
  end;

  r:=copy(b,1,got);
  if strip(r)<>strip(e) then
     showmessage('invalid response (3.13)'+#13+
                 'command <'+strip(s)+'>'+#13+
                 'response <'+strip(r)+'>');

                                  // *****************************************
  if DLY<>0 then sleep(DLY);      // ******* delay between AT commands *******
                                  // *****************************************

// send set Tx power level command "AT+Px"
  case ComboBox3.ItemIndex of 0:s:='AT+P1'+EOL;    // minimum power
                              1:s:='AT+P2'+EOL;
                              2:s:='AT+P3'+EOL;
                              3:s:='AT+P4'+EOL;
                              4:s:='AT+P5'+EOL;
                              5:s:='AT+P6'+EOL;
                              6:s:='AT+P7'+EOL;
                              7:s:='AT+P8'+EOL     // maximum power
                           else s:='AT'+EOL        // default to no action
  end;  { of case }
  e:=at2ok(s);

  try
    if not WriteFile(CommFile, s[1], length(s), put, nil) then  // write command
    begin
      showmessage('Serial I/O error: WriteFile failed (3.14)');
      halt
    end
  except
    showmessage('Serial I/O error: WriteFile exception (3.14)');
    halt
  end;

// get set Tx power level response
  try
    if not ReadFile(CommFile, b[1], sizeof(b), got, nil) then   // read response
    begin
      showmessage('Serial I/O error: ReadFile failed (3.15)');
      halt
    end
  except
    showmessage('Serial I/O error: ReadFile exception (3.15)');
    halt
  end;

  r:=copy(b,1,got);
  if strip(r)<>strip(e) then
     showmessage('invalid response (3.16)'+#13+
                 'command <'+strip(s)+'>'+#13+
                 'response <'+strip(r)+'>');

                                  // *****************************************
  if DLY<>0 then sleep(DLY);      // ******* delay between AT commands *******
                                  // *****************************************

// send set serial format command "AT+Unps"
  s:='AT+U';
  if RadioButton7.Checked then s:=s+'7' else     // #data bits (n)
  if RadioButton8.Checked then s:=s+'8';
  if RadioButton1.Checked then s:=s+'O' else     // parity bit (p)
  if RadioButton2.Checked then s:=s+'E' else
  if RadioButton3.Checked then s:=s+'N';
  if RadioButton4.Checked then s:=s+'1' else     // #stop bits (s)
  if RadioButton5.Checked then s:=s+'3' else
  if RadioButton6.Checked then s:=s+'2';
  if length(s)<>7 then s:='AT';                  // no action on error
  s:=s+EOL;
  e:=at2ok(s);

  try
    if not WriteFile(CommFile, s[1], length(s), put, nil) then  // write command
    begin
      showmessage('Serial I/O error: WriteFile failed (3.17)');
      halt
    end
  except
    showmessage('Serial I/O error: WriteFile exception (3.17)');
    halt
  end;

// get set serial format response
  try
    if not ReadFile(CommFile, b[1], sizeof(b), got, nil) then   // read response
    begin
      showmessage('Serial I/O error: ReadFile failed (3.18)');
      halt
    end
  except
    showmessage('Serial I/O error: ReadFile exception (3.18)');
    halt
  end;

  r:=copy(b,1,got);
  if strip(r)<>strip(e) then
     showmessage('invalid response (3.19)'+#13+
                 'command <'+strip(s)+'>'+#13+
                 'response <'+strip(r)+'>');

// finished HC-12 configuration

  Button3.Enabled:=true;
  Running:=true
end;


procedure TForm1.FormDblClick(Sender: TObject);
begin
  showmessage('(c)  Robert Rozee  2016'#13#13'Release 6 (29-may-2016)')
end;


end.
