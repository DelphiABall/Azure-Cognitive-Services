unit frame.SpeechToText;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  TokenShare, Azure.API3.Translator.Dictionary, FMX.Edit,
  FMX.Controls.Presentation, FMX.Media, FMX.Layouts, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo;

type
  TFrameSpeechToText = class(TFrame)
    lblFile: TLabel;
    edtFilePath: TEdit;
    btnEditFilePath: TEditButton;
    OpenDialog1: TOpenDialog;
    Layout1: TLayout;
    btnPlayFile: TButton;
    btnConvert: TButton;
    MediaPlayer1: TMediaPlayer;
    btnConvertDetailed: TButton;
    memoLog: TMemo;
    Layout2: TLayout;
    edtCountryCode: TEdit;
    Label1: TLabel;
    procedure btnEditFilePathClick(Sender: TObject);
    procedure btnPlayFileClick(Sender: TObject);
    procedure btnConvertClick(Sender: TObject);
  private
    { Private declarations }
    FTokenProc : TGetAzureTokenProc;
  public
    { Public declarations }
    procedure Initialize(AGetAzureTokenProc : TGetAzureTokenProc);
  end;

implementation

{$R *.fmx}

uses System.IOUtils, Azure.API3.Speech.SpeechToText;

{ TFrameDictionary }

procedure TFrameSpeechToText.btnPlayFileClick(Sender: TObject);
begin
  MediaPlayer1.FileName := EdtFilePath.Text;
  MediaPlayer1.CurrentTime := 0;
  MediaPlayer1.Play;
end;

procedure TFrameSpeechToText.btnConvertClick(Sender: TObject);
begin
  var STT := TAzureSpeechToText.Create(Self,FTokenProc.Region);
  try
    STT.AccessToken := FTokenProc;

    var aFormat : TAzureSpeechToText.TSpeechToTextFormat;
    if Sender = btnConvert then
      aFormat := TAzureSpeechToText.TSpeechToTextFormat.simple
    else
      aFormat := TAzureSpeechToText.TSpeechToTextFormat.detailed;

    if edtCountryCode.Text.Trim = '' then
      edtCountryCode.Text := 'en-US';

    var  R := STT.SpeechToText(edtFilePath.Text,edtCountryCode.Text,aFormat);

    for var I := 0 to Length(R)-1 do begin
      MemoLog.Text := 'RecognitionStatus = '+R[I].RecognitionStatus;
      MemoLog.Lines.Add('Display Text = '+R[I].DisplayText);
      MemoLog.Lines.Add('Offset = '+R[I].Offset.ToString);
      MemoLog.Lines.Add('Duration = '+R[I].Duration.ToString);
    end;
   MemoLog.Lines.Add('RESTResponse.Content = '+ STT.RESTResponse.Content);
  finally
    STT.Free;
  end;
end;

procedure TFrameSpeechToText.btnEditFilePathClick(Sender: TObject);
begin
  OpenDialog1.InitialDir := TPath.GetLibraryPath;
  if OpenDialog1.Execute then
    EdtFilePath.Text := OpenDialog1.FileName;
end;

procedure TFrameSpeechToText.Initialize(AGetAzureTokenProc: TGetAzureTokenProc);

  function SetupAudioFile(aFilePath:string): Boolean;
  begin
    Result := FileExists(aFilePath);
    if Result and (edtFilePath.Text = '') then
      edtFilePath.Text := aFilePath;
  end;
begin
  FTokenProc := AGetAzureTokenProc;

  // The first one true stops the rest being run....
  var FileSetup := SetupAudioFile(TPath.Combine(TPath.GetLibraryPath,'audio.wav'))
                   or SetupAudioFile(TPath.Combine(TPath.GetLibraryPath,'audio.ogg'))
                   or SetupAudioFile(TPath.Combine(TPath.GetDocumentsPath,'audio.wav'))
                   or SetupAudioFile(TPath.Combine(TPath.GetDocumentsPath,'audio.ogg'));
  if (not FileSetup) and (not FileExists(edtFilePath.Text)) then
    edtFilePath.Text := '';
end;

end.
