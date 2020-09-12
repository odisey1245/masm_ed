unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ActnList,
  StdCtrls, Buttons, Menus, ExtCtrls, IniPropStorage, process, SynEdit,
  SynHighlighterAny, LConvEncoding, LazUTF8, PropertyStorage;

type

  { TForm1 }

  TForm1 = class(TForm)
    acNew: TAction;
    acOpen: TAction;
    acSave: TAction;
    acBuild: TAction;
    acRun: TAction;
    acListing: TAction;
    ActionList1: TActionList;
    ImageList1: TImageList;
    IniPropStorage1: TIniPropStorage;
    ListBox1: TListBox;
    MenuItem1: TMenuItem;
    Panel1: TPanel;
    PopupMenu1: TPopupMenu;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    Splitter1: TSplitter;
    SynAnySyn1: TSynAnySyn;
    SynEdit1: TSynEdit;
    ToggleBox1: TToggleBox;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    procedure acBuildExecute(Sender: TObject);
    procedure acNewExecute(Sender: TObject);
    procedure acOpenExecute(Sender: TObject);
    procedure acRunExecute(Sender: TObject);
    procedure acRunUpdate(Sender: TObject);
    procedure acSaveExecute(Sender: TObject);
    procedure acSaveUpdate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IniPropStorage1StoredValues0Restore(Sender: TStoredValue;
      var Value: TStoredType);
    procedure IniPropStorage1StoredValues0Save(Sender: TStoredValue;
      var Value: TStoredType);
    procedure IniPropStorage1StoredValues1Restore(Sender: TStoredValue;
      var Value: TStoredType);
    procedure IniPropStorage1StoredValues1Save(Sender: TStoredValue;
      var Value: TStoredType);
    procedure IniPropStorage1StoredValues2Restore(Sender: TStoredValue;
      var Value: TStoredType);
    procedure IniPropStorage1StoredValues2Save(Sender: TStoredValue;
      var Value: TStoredType);
    procedure MenuItem1Click(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure ToggleBox1Change(Sender: TObject);
  private
    FFileName: string;
    FSaved: Boolean;
    FEncoding: TEncoding;
    FRunning: Boolean;
    function Build: Boolean;
    function CheckNeedSave: Boolean;
    function GetExeFilename: string;
    procedure Load(const AFileName: string);
    procedure MruAdd(const AFileName: string);
    function Save: Boolean;
    procedure UpdateCaption;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

function Translate({%H-}Name, Value: AnsiString; Hash: Longint; {%H-}arg: pointer): AnsiString;
begin
  case Hash of
    228516702: Result := 'Подтверждение';
    180163: Result := 'Да';
    11087: Result := 'Нет';
    77089212: Result := 'Отмена';
    else Result := Value;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  SetResourceStrings(@Translate, nil);
  FFileName := 'name01.asm';
  FSaved := False;
  FEncoding := TEncoding.GetEncoding('cp866');
  UpdateCaption;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FEncoding.Free;
end;

procedure TForm1.IniPropStorage1StoredValues0Restore(Sender: TStoredValue;
  var Value: TStoredType);
var
  s: string;
  mi: TMenuItem;
begin
  PopupMenu1.Items.Clear;
  for s in Value.Split(';') do
    if FileExists(s) then
    begin
      mi := TMenuItem.Create(PopupMenu1);
      mi.Caption := s;
      mi.OnClick := @MenuItem1Click;
      PopupMenu1.Items.Add(mi);
    end;
end;

procedure TForm1.IniPropStorage1StoredValues0Save(Sender: TStoredValue;
  var Value: TStoredType);
var
  s: string;
  i: Integer;
begin
  s := '';
  for i := 0 to PopupMenu1.Items.Count - 1 do
    s := s + PopupMenu1.Items[i].Caption + ';';
  Value := s;
end;

procedure TForm1.IniPropStorage1StoredValues1Restore(Sender: TStoredValue;
  var Value: TStoredType);
begin
  if FileExists(Value) then Load(Value);
end;

procedure TForm1.IniPropStorage1StoredValues1Save(Sender: TStoredValue;
  var Value: TStoredType);
begin
  if FSaved then
    Value := FFileName
  else
    Value := '';
end;

procedure TForm1.IniPropStorage1StoredValues2Restore(Sender: TStoredValue;
  var Value: TStoredType);
var
  v: TStringArray;
begin
  if Value <> '' then
  begin
    v := Value.Split(',');
    SynEdit1.CaretY := StrToIntDef(v[1], 0);
    SynEdit1.CaretX := StrToIntDef(v[0], 0);
    SynEdit1.TopLine := StrToIntDef(v[2], 0);
  end;
end;

procedure TForm1.IniPropStorage1StoredValues2Save(Sender: TStoredValue;
  var Value: TStoredType);
begin
  Value := Format('%d,%d,%d', [SynEdit1.CaretX, SynEdit1.CaretY, SynEdit1.TopLine]);
end;

procedure TForm1.MenuItem1Click(Sender: TObject);
begin
  if not CheckNeedSave then Exit;
  Load(TMenuItem(Sender).Caption);
end;

procedure TForm1.PopupMenu1Popup(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to PopupMenu1.Items.Count - 1 do
    with PopupMenu1.Items[i] do
      Enabled := FileExists(Caption)
end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
var
  x, y, z: Integer;
begin
  FreeAndNil(FEncoding);
  if SpeedButton1.Down then
    FEncoding := TEncoding.GetEncoding(866)
  else
    FEncoding := TEncoding.GetEncoding(1251);
  if ToggleBox1.Checked then
    SynEdit1.Lines.LoadFromFile(ChangeFileExt(GetExeFilename, '.lst'), FEncoding)
  else
  if FSaved and not SynEdit1.Modified then
  begin
    x := SynEdit1.CaretX;
    y := SynEdit1.CaretY;
    z := SynEdit1.TopLine;
    SynEdit1.Lines.LoadFromFile(FFileName, FEncoding);
    SynEdit1.CaretX  := x;
    SynEdit1.CaretY  := y;
    SynEdit1.TopLine := z;
  end;
end;

var
  SaveX, SaveY, SaveTop: Integer;
  SaveText: string;
  SaveModified: Boolean;

procedure TForm1.ToggleBox1Change(Sender: TObject);
begin
  if ToggleBox1.Checked then
  begin
    SaveY := SynEdit1.CaretY;
    SaveX := SynEdit1.CaretX;
    SaveTop := SynEdit1.TopLine;
    SaveText := SynEdit1.Lines.Text;
    SaveModified := SynEdit1.Modified;
    SynEdit1.ReadOnly := True;
    SynEdit1.Highlighter := nil;
    SynEdit1.Lines.LoadFromFile(ChangeFileExt(GetExeFilename, '.lst'), FEncoding);
  end else begin
    SynEdit1.Highlighter := SynAnySyn1;
    SynEdit1.Lines.Text := SaveText;
    SynEdit1.CaretY := SaveY;
    SynEdit1.CaretX := SaveX;
    SynEdit1.TopLine := SaveTop;
    SynEdit1.ReadOnly := False;
    SynEdit1.Modified := SaveModified;
  end;
end;

function TForm1.Save: Boolean;
begin
  if not FSaved then
    with TSaveDialog.Create(nil) do
    try
      Filter := 'ASM (*.asm)|*.asm|Все файлы (*.*)|*.*';
      FileName := FFileName;
      DefaultExt := '.asm';
      Options := Options + [ofOverwritePrompt];
      if not Execute then Exit(False);
      FFileName := FileName;
    finally
      Free;
    end;
  SynEdit1.Lines.SaveToFile(FFileName, FEncoding);
  SynEdit1.MarkTextAsSaved;
  FSaved := True;
  Result := True;
  MruAdd(FFileName);
end;

function TForm1.CheckNeedSave: Boolean;
begin
  Result := False;
  if not FSaved and (Trim(SynEdit1.Text) <> '') or SynEdit1.Modified then
    case MessageDlg('Сохранить изменения?', mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
      mrYes: if not Save then Exit;
      mrCancel: Exit;
    end;
  Result := True;
end;

procedure TForm1.UpdateCaption;
begin
  Caption := 'MASM Editor - ' + FFileName;
end;

procedure TForm1.acNewExecute(Sender: TObject);
begin
  ToggleBox1.Checked := False;
  if not CheckNeedSave then Exit;
  SynEdit1.Clear;
  if FileExists(ExtractFilePath(ParamStr(0)) + 'schema.asm') then
    if MessageDlg('Загрузить схему?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      SynEdit1.Lines.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'schema.asm', TEncoding.GetEncoding(1251));
  SynEdit1.Modified := False;
  FSaved := False;
  FFileName := 'name01.asm';
  UpdateCaption;
end;

procedure TForm1.acBuildExecute(Sender: TObject);
begin
  Build;
end;

function TForm1.Build: Boolean;
var
  CurPath: string;
  s: RawByteString;
  s1, fname: string;
  i: Integer;
begin
  Result := False;
  ToggleBox1.Checked := False;
  ListBox1.Items.Clear;
  if not FSaved then
  begin
    fname := GetTempDir + FFileName;
    SynEdit1.Lines.SaveToFile(fname, FEncoding);
  end else begin
    Save;
    fname := FFileName;
  end;
  CurPath := ExtractFilePath(ParamStr(0));
  if not DeleteFile(ChangeFileExt(fname, '.exe')) then
  begin
    s := ChangeFileExt(fname, '.exe.old');
    if FileExists(s) and not DeleteFile(s) then
    begin
      i := 1;
      repeat
        s1 := s + IntToStr(i);
        if not FileExists(s1) or DeleteFile(s1) then Break;
        Inc(i);
      until False;
      s := s1;
    end;
    RenameFile(ChangeFileExt(fname, '.exe'), s);
  end;
  s := CurPath + 'bin' + PathDelim + 'ml.exe';
  if not FileExists(s) then
  begin
    ListBox1.Items.Add('Не найден ассемблер "' + s + '"!');
    Exit;
  end;
  with TProcess.Create(nil) do
  try
    Options := [poStderrToOutPut, poUsePipes, poWaitOnExit];
    Environment.Add('include=' + CurPath + 'include');
    Environment.Add('lib=' + CurPath + 'lib');
    Parameters.Add('/c');
    Parameters.Add('/coff');
    Parameters.Add('/Fl');
    Parameters.Add(fname);
    CurrentDirectory := ExtractFilePath(fname);
    Executable := s;
    Execute;
    SetLength(s, Output.NumBytesAvailable);
    Output.Read(s[1], Length(s));
    with TStringList.Create do
    try
      Text := s;
      for i := 0 to Count - 1 do
        ListBox1.Items.Add(WinCPToUTF8(Strings[i]));
    finally
      Free;
    end;
    ToggleBox1.Enabled := FileExists(ChangeFileExt(GetExeFilename, '.lst'));
    if ExitCode <> 0 then
    begin
      ListBox1.Items.Add('Ассемблирование завершилось ошибкой!');
      SynEdit1.SetFocus;
      Exit;
    end;
    s := CurPath + 'bin' + PathDelim + 'link.exe';
    if not FileExists(s) then
    begin
      ListBox1.Items.Add('Не найден компоновщик "' + s + '"!');
      Exit;
    end;
    Parameters.Clear;
    Parameters.Add('/subsystem:console');
    Parameters.Add(ChangeFileExt(fname, '.obj'));
    Executable := s;
    Execute;
    SetLength(s, Output.NumBytesAvailable);
    Output.Read(s[1], Length(s));
    with TStringList.Create do
    try
      Text := s;
      for i := 0 to Count - 1 do
        ListBox1.Items.Add(WinCPToUTF8(Strings[i]));
    finally
      Free;
    end;
    if ExitCode <> 0 then
      ListBox1.Items.Add('Компоновка завершилась ошибкой!')
    else begin
      ListBox1.Items.Add('Сборка прошла успешно');
      Result := True;
    end;
    SynEdit1.SetFocus;
  finally
    Free;
  end;
end;

procedure TForm1.Load(const AFileName: string);
begin
  FFileName := AFileName;
  SynEdit1.Lines.LoadFromFile(FFileName, FEncoding);
  FSaved := True;
  UpdateCaption;
  ToggleBox1.Enabled := FileExists(ChangeFileExt(GetExeFilename, '.lst'));
  MruAdd(FFileName);
end;

procedure TForm1.MruAdd(const AFileName: string);
var
  mi: TMenuItem;
  i: Integer;
begin
  for i := 0 to PopupMenu1.Items.Count - 1 do
    if PopupMenu1.Items[i].Caption = AFileName then
    begin
      if i > 0 then
      begin
        mi := PopupMenu1.Items[i];
        PopupMenu1.Items.Delete(i);
        PopupMenu1.Items.Insert(0, mi);
      end;
      Exit;
    end;
  mi := TMenuItem.Create(PopupMenu1);
  mi.Caption := AFileName;
  mi.OnClick := @MenuItem1Click;
  PopupMenu1.Items.Insert(0, mi);
  while PopupMenu1.Items.Count > 10 do
    PopupMenu1.Items.Delete(10);
end;

procedure TForm1.acOpenExecute(Sender: TObject);
begin
  ToggleBox1.Checked := False;
  if not CheckNeedSave then Exit;
  with TOpenDialog.Create(nil) do
  try
    Filter := 'ASM (*.asm)|*.asm|Все файлы (*.*)|*.*';
    DefaultExt := '.asm';
    Options := Options + [ofOverwritePrompt];
    if not Execute then Exit;
    Load(FileName);
  finally
    Free;
  end;
end;

function TForm1.GetExeFilename: string;
begin
  if not FSaved then
    Result := GetTempDir + FFileName
  else
    Result := FFileName;
  Result := ChangeFileExt(Result, '.exe');
end;

procedure TForm1.acRunExecute(Sender: TObject);
begin
  ToggleBox1.Checked := False;
  if SynEdit1.Modified then
    if not Build then Exit;
  with TProcess.Create(nil) do
  try
    Executable := ExtractFilePath(ParamStr(0)) + 'run.bat';
    Parameters.Add(GetExeFilename);
    Options := [poWaitOnExit];
    FRunning := True;
    Panel1.Visible := True;
    Application.ProcessMessages;
    try
      Execute;
    except
      on e: Exception do
        ListBox1.Items.Add(e.Message);
    end;
    FRunning := False;
  finally
    Panel1.Visible := False;
    Free;
  end;
end;

procedure TForm1.acRunUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := FileExists(GetExeFilename) and not FRunning;
end;

procedure TForm1.acSaveExecute(Sender: TObject);
begin
  ToggleBox1.Checked := False;
  Save;
  UpdateCaption
end;

procedure TForm1.acSaveUpdate(Sender: TObject);
begin
  TAction(Sender).Enabled := not FSaved or SynEdit1.Modified;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
  CanClose := CheckNeedSave
end;

end.

