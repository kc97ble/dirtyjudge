unit main_form;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynEdit, SynHighlighterCpp, SynMemo,
  synhighlighterunixshellscript, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls, ActnList, Unix, Math, contnrs, LCLIntf, Buttons,
  test_editor_2;

type

  { TMainForm }

  TMainForm = class(TForm)
    actCompile: TAction;
    actJudgeAll: TAction;
    actTestEditor: TAction;
    actJudge: TAction;
    actRun: TAction;
    ActionList1: TActionList;
    Button1: TSpeedButton;
    Button10: TButton;
    Button11: TButton;
    Button12: TButton;
    Button13: TButton;
    Button14: TButton;
    Button2: TButton;
    Button3: TButton;
    ImageList1: TImageList;
    Label3: TLabel;
    OutputMemo: TMemo;
    ScrollBox1: TScrollBox;
    UserExecuteMemo: TSynEdit;
    SynUNIXShellScriptSyn1: TSynUNIXShellScriptSyn;
    ToolBar1: TToolBar;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    UserCompileMemo: TSynEdit;
    UCLoadFileButton: TButton;
    UCSaveFileButton: TButton;
    UELoadFileButton: TButton;
    UESaveFileButton: TButton;
    UJLoadFileButton: TButton;
    UJSaveFileButton: TButton;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    TabSheet6: TTabSheet;
    UserSolutionSaveButton: TButton;
    UserSolutionLoadButton: TButton;
    UserCompileLoadButton: TButton;
    UserCompileSaveButton: TButton;
    UserExecuteLoadButton: TButton;
    UserExecuteSaveButton: TButton;
    UserJudgeLoadButton: TButton;
    UserJudgeSaveButton: TButton;
    UserExecuteEdit: TEdit;
    Label9: TLabel;
    UserJudgeEdit: TEdit;
    Label8: TLabel;
    UserSolutionEdit: TEdit;
    UserExecutableEdit: TEdit;
    UserCompileEdit: TEdit;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    TestListBox: TListBox;
    LibFileListBox: TListBox;
    UserJudgeMemo: TMemo;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel5: TPanel;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    SynCppSyn1: TSynCppSyn;
    UserSolutionMemo: TSynEdit;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    procedure actCompileExecute(Sender: TObject);
    procedure actJudgeAllExecute(Sender: TObject);
    procedure actJudgeExecute(Sender: TObject);
    procedure actRunExecute(Sender: TObject);
    procedure actTestEditorExecute(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure Button12Click(Sender: TObject);
    procedure Button13Click(Sender: TObject);
    procedure Button14Click(Sender: TObject);
    procedure UCLoadFileButtonClick(Sender: TObject);
    procedure UCSaveFileButtonClick(Sender: TObject);
    procedure UserCompileLoadButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure UserSolutionMemoChange(Sender: TObject);
    procedure UserCompileSaveButtonClick(Sender: TObject);
    procedure UserExecuteEditChange(Sender: TObject);
  private
    FInputList, FOutputList: TStrings;
    FDeleting: TObjectList;
    FFileChanged: Boolean;
    FFileCompiled: Boolean;
    procedure PackStrings(List: TStrings);
    procedure SaveAllFiles;
    function ExternalExecute(Executable, Parameters: String): Integer;
    procedure SetCount(List: TStrings; ACount: Integer);
    procedure UpdateControls(Sender: TObject);
    function DeleteLater(List: TStringList): TStringList;
  public
    { public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

operator ** (A, B: String) StarStar: String;
begin
  Result := ConcatPaths([A, B]);
end;

{ TMainForm }

procedure TMainForm.actCompileExecute(Sender: TObject);
begin
  if FFileChanged then SaveAllFiles;
  if ExternalExecute(UserCompileEdit.Text, Format('"%s" "%s"',
    [UserSolutionEdit.Text, UserExecutableEdit.Text])) = 0 then
    FFileCompiled := True;
end;

procedure TMainForm.actJudgeAllExecute(Sender: TObject);
var
  TestCount: Integer;
  Error: Integer=0;
  i: Integer;
begin
  if FFileChanged then SaveAllFiles;
  if not FFileCompiled then actCompile.Execute;
  TestCount := Min(FInputList.Count, FOutputList.Count);
  for i := 0 to TestCount-1 do
  begin
    Error := ExternalExecute(UserJudgeEdit.Text, Format('"%s" "%s" "%s"',
    [UserExecutableEdit.Text, FInputList[i], FOutputList[i]]));
    if Error<>0 then break;
  end;
end;

procedure TMainForm.actJudgeExecute(Sender: TObject);
var
  Index: Integer;
begin
  Index := TestListBox.ItemIndex;
  if Index = -1 then exit;
  if FFileChanged then SaveAllFiles;
  if not FFileCompiled then actCompile.Execute;
  ExternalExecute(UserJudgeEdit.Text, Format('"%s" "%s" "%s"',
    [UserExecutableEdit.Text, FInputList[Index], FOutputList[Index]]));
end;

procedure TMainForm.actRunExecute(Sender: TObject);
begin
  if FFileChanged then SaveAllFiles;
  if not FFileCompiled then actCompile.Execute;
  if FFileChanged or not FFileCompiled then exit;
  ExternalExecute(UserExecuteEdit.Text, Format('"%s"', [UserExecutableEdit.Text]));
end;

procedure TMainForm.actTestEditorExecute(Sender: TObject);
begin
  if TTestEditor2.DefaultExecute(FInputList, FOutputList) = mrOK then
  UpdateControls(TestListBox);
end;

procedure TMainForm.Button11Click(Sender: TObject);
var
  S: String;
begin
  with TOpenDialog.Create(nil) do
  try
    Options:=Options+[ofAllowMultiSelect];
    if Execute then
    begin
      for S in Files do
      if DirectoryExists(S) then
      CopyDirTree(S, GetCurrentDir ** '/', [cffOverwriteFile, cffCreateDestDirectory])
      else CopyFile(S, GetCurrentDir ** ExtractFileName(S), [cffOverwriteFile, cffCreateDestDirectory]);
    end;
    Button13.Click;
    finally Free;
  end;
end;

procedure TMainForm.PackStrings(List: TStrings);
var
  i, j: Integer;
begin
  j := 0;
  for i := 0 to List.Count-1 do
  if List[i]<>'' then
  begin List[j] := List[i]; j += 1; end;
  while List.Count > j do List.Delete(List.Count-1);
end;

procedure TMainForm.Button12Click(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to LibFileListBox.Count-1 do
  if LibFileListBox.Selected[i] then
  DeleteFile(LibFileListBox.Items[i]);
  Button13.Click;
end;

procedure TMainForm.Button13Click(Sender: TObject);
begin
  LibFileListBox.Items.Assign(DeleteLater(FindAllFiles('')));
end;

procedure TMainForm.Button14Click(Sender: TObject);
begin
  OpenDocument('.');
end;

procedure TMainForm.UCLoadFileButtonClick(Sender: TObject);
var
  List: TStrings=nil;
  Dir: String;
begin
  if Sender=UCLoadFileButton then List := UserCompileMemo.Lines;
  if Sender=UELoadFileButton then List := UserExecuteMemo.Lines;
  if Sender=UJLoadFileButton then List := UserJudgeMemo.Lines;

  {if Sender=UCLoadFileButton then Dir := '../example/compile';
  if Sender=UELoadFileButton then Dir := '../example/execute';
  if Sender=UJLoadFileButton then Dir := '../example/judge';}
  Dir := '.';

  with TOpenDialog.Create(nil) do
  try
    ForceDirectories(Dir);
    InitialDir:=Dir;
    if Execute then List.LoadFromFile(FileName);
    finally Free;
  end;
end;

procedure TMainForm.UCSaveFileButtonClick(Sender: TObject);
var
  List: TStrings;
  Dir: String;
begin
  if Sender=UCSaveFileButton then List := UserCompileMemo.Lines;
  if Sender=UESaveFileButton then List := UserExecuteMemo.Lines;
  if Sender=UJSaveFileButton then List := UserJudgeMemo.Lines;

  if Sender=UCSaveFileButton then Dir := '../example/compile';
  if Sender=UESaveFileButton then Dir := '../example/execute';
  if Sender=UJSaveFileButton then Dir := '../example/judge';

  with TSaveDialog.Create(nil) do
  try
    ForceDirectories(Dir);
    InitialDir:=Dir;
    if Execute then List.SaveToFile(FileName);
    finally Free;
  end;
end;

procedure TMainForm.UserCompileLoadButtonClick(Sender: TObject);
begin
  if Sender = UserCompileLoadButton then
  UserCompileMemo.Lines.LoadFromFile(UserCompileEdit.Text);
  if Sender = UserExecuteLoadButton then
  UserExecuteMemo.Lines.LoadFromFile(UserExecuteEdit.Text);
  if Sender = UserJudgeLoadButton then
  UserJudgeMemo.Lines.LoadFromFile(UserJudgeEdit.Text);
  if Sender = UserSolutionLoadButton then
  UserSolutionMemo.Lines.LoadFromFile(UserSolutionEdit.Text);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FInputList := TStringList.Create;
  FOutputList := TStringList.Create;
  FDeleting := TObjectList.Create(True);
  ForceDirectories('lib');
  ChDir('lib');
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FInputList.Free;
  FOutputList.Free;
  FDeleting.Free;
  ChDir('..');
end;

procedure TMainForm.UserSolutionMemoChange(Sender: TObject);
begin
  FFileChanged:=True;
  FFileCompiled:=False;
end;

procedure TMainForm.UserCompileSaveButtonClick(Sender: TObject);
begin
  if Sender = UserCompileSaveButton then
  UserCompileMemo.Lines.SaveToFile(UserCompileEdit.Text);
  if Sender = UserExecuteSaveButton then
  UserExecuteMemo.Lines.SaveToFile(UserExecuteEdit.Text);
  if Sender = UserJudgeSaveButton then
  UserJudgeMemo.Lines.SaveToFile(UserJudgeEdit.Text);
  if Sender = UserSolutionSaveButton then
  UserSolutionMemo.Lines.SaveToFile(UserSolutionEdit.Text);
end;

procedure TMainForm.UserExecuteEditChange(Sender: TObject);
begin
  FFileChanged:=True;
end;

procedure TMainForm.SaveAllFiles;
begin
  UserSolutionMemo.Lines.SaveToFile(UserSolutionEdit.Text);
  UserCompileMemo.Lines.SaveToFile(UserCompileEdit.Text);
  UserExecuteMemo.Lines.SaveToFile(UserExecuteEdit.Text);
  UserJudgeMemo.Lines.SaveToFile(UserJudgeEdit.Text);
  FFileChanged:=False;
  FFileCompiled:=False;
end;

function TMainForm.ExternalExecute(Executable, Parameters: String): Integer;
begin
  fpSystem(Format('chmod a+x "%s"', [Executable]));
  Result := fpSystem(Format('"%s" %s 1> shell_output 2>&1', [Executable, Parameters]));
  OutputMemo.Lines.LoadFromFile('shell_output');
  DeleteFile('shell_output');
  OutputMemo.Invalidate;
  Label3.Caption:=Format('Exit code: %d', [Result]);
end;

procedure TMainForm.SetCount(List: TStrings; ACount: Integer);
begin
  while List.Count < ACount do List.Add('');
  while List.Count > ACount do List.Delete(List.Count-1);
end;

procedure TMainForm.UpdateControls(Sender: TObject);
var
  i: Integer;
begin
  if Sender = TestListBox then
  with TestListBox do
  begin
    SetCount(Items, Min(FInputList.Count, FOutputList.Count));
    for i := 0 to Items.Count-1 do
    Items[i] := Format('Test %d: %s, %s', [i, ExtractFileName(FInputList[i]),
      ExtractFileName(FOutputList[i])]);
  end
  else
    raise Exception.Create('Sorry');
end;

function TMainForm.DeleteLater(List: TStringList): TStringList;
begin
  FDeleting.Add(List);
  Result := List;
end;

end.

