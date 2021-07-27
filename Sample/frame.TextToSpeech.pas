unit frame.TextToSpeech;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  TokenShare, Azure.API3.Translator.Dictionary, FMX.Controls.Presentation,
  FMX.ListBox, FMX.Layouts, FMX.Edit, FMX.Memo.Types, FMX.Media, FMX.ScrollBox,
  FMX.Memo;

type
  TFrameTextToSpeech = class(TFrame)
    Layout2: TLayout;
    cbVoicesRegions: TComboBox;
    Label4: TLabel;
    GroupBox1: TGroupBox;
    cbVoice1: TComboBox;
    cbVoice2: TComboBox;
    edtLine1: TEdit;
    edtLine2: TEdit;
    edtLine3: TEdit;
    cbVoice3: TComboBox;
    btnJoke: TButton;
    Layout1: TLayout;
    Layout3: TLayout;
    MemoLog: TMemo;
    MediaPlayer1: TMediaPlayer;
    procedure cbVoice1Change(Sender: TObject);
    procedure cbVoicesRegionsChange(Sender: TObject);
    procedure btnJokeClick(Sender: TObject);
  private
    { Private declarations }
    FTokenProc : TGetAzureTokenProc;
  public
    { Public declarations }
    procedure Initialize(AGetAzureTokenProc : TGetAzureTokenProc);
  end;

implementation

{$R *.fmx}
uses System.IOUtils, Azure.API3.Constants, Azure.API3.Speech.TextToSpeech,
  Azure.API3.Speech.Voices, System.Threading;

{ TFrameDictionary }

procedure TFrameTextToSpeech.btnJokeClick(Sender: TObject);
begin
  Assert(cbVoice1.Selected <> nil,'Select Voice 1');
  Assert(cbVoice2.Selected <> nil,'Select Voice 2');
  Assert(cbVoice3.Selected <> nil,'Select Voice 3');

  var MS := TMemoryStream.Create;
  try
    var aAudio := TAzureTextToSpeech.Create(Self,FTokenProc.Region);
    aAudio.AccessToken := FTokenProc;

    /// Build Joke - TAzureTextBuilder makes it simple to create an SSML document to send
    /// https://docs.microsoft.com/en-gb/azure/cognitive-services/speech-service/speech-synthesis-markup?tabs=csharp
    var JokeText := TAzureTextBuilder.Create();
    try
      if edtLine1.Text > '' then
        JokeText.AddText(edtLine1.Text, cbVoice1.Selected.Text);
      if edtLine2.Text > '' then
        JokeText.AddText(edtLine2.Text, cbVoice2.Selected.Text);
      if edtLine3.Text > '' then
        JokeText.AddText(edtLine3.Text, cbVoice3.Selected.Text);

      if aAudio.RawTextToSpeech(JokeText.RawText,MS) then begin
        var TempFile := TPath.Combine(TPath.GetLibraryPath,'TestAudio.mp3');
        MS.SaveToFile(TempFile);
        MediaPlayer1.FileName := TempFile;
        MediaPlayer1.Play;
      end;
    finally
      JokeText.Free;
    end;
  finally
    MS.Free;
  end;
end;

procedure TFrameTextToSpeech.cbVoice1Change(Sender: TObject);
begin
  cbVoice2.ItemIndex := cbVoice1.ItemIndex;
  cbVoice3.ItemIndex := cbVoice1.ItemIndex;
end;

procedure TFrameTextToSpeech.cbVoicesRegionsChange(Sender: TObject);
begin
  var FVoices := TAzureTextToSpeechVoices.Create(Self,TAzureSpeechRegion(cbVoicesRegions.ItemIndex));
  try
    FVoices.AccessToken := FTokenProc;

    MemoLog.BeginUpdate;
    GroupBox1.BeginUpdate;
    try
      /// AD IN THE VOICES TO THE COMBO, then SORT OUT THE
      cbVoice1.Items.Clear;
      cbVoice2.Items.Clear;
      cbVoice3.Items.Clear;

      MemoLog.Lines.Clear;
      var Voices := FVoices.Voices;
      for var Voice in Voices do begin
        MemoLog.Lines.Add('Name - '+Voice.Name);

        cbVoice1.Items.Add(Voice.ShortName);
        cbVoice2.Items.Add(Voice.ShortName);
        cbVoice3.Items.Add(Voice.ShortName);

        MemoLog.Lines.Add('Display Name - '+Voice.DisplayName);
        MemoLog.Lines.Add('Local Name - '+Voice.LocalName);
        if Length(Voice.SecondaryLocaleList) > 0 then
          MemoLog.Lines.Add(Format(' - %s has %d secondary locals',[Voice.LocalName, Length(Voice.SecondaryLocaleList)]));
        MemoLog.Lines.Add('Short Name - '+Voice.ShortName);
        MemoLog.Lines.Add('Gender - '+TAzureTextToSpeechVoices.VoiceGenderToString(Voice.Gender));
        MemoLog.Lines.Add('Status - '+TAzureTextToSpeechVoices.VoiceStatusToString(Voice.Status));
        MemoLog.Lines.Add('Type - '+TAzureTextToSpeechVoices.VoiceTypeToString(Voice.VoiceType));
        MemoLog.Lines.Add('Hz - '+Voice.SampleRateHertz.ToString);

        MemoLog.Lines.Add('');
      end;
    finally
      GroupBox1.EndUpdate;
      MemoLog.EndUpdate;
    end;
  finally
    FVoices.Free;
  end;
end;

procedure TFrameTextToSpeech.Initialize(AGetAzureTokenProc: TGetAzureTokenProc);
begin
  FTokenProc := AGetAzureTokenProc;

  // Loads the list of regions
  if cbVoicesRegions.Items.Count = 0 then begin  
    cbVoicesRegions.BeginUpdate;
    try
      for var aRegion := Low(TAzureSpeechRegion) to High(TAzureSpeechRegion) do
        cbVoicesRegions.Items.Add(TAzureURLBuilder.RegionToString(aRegion));
    finally
      cbVoicesRegions.EndUpdate;
    end;
  end;
  var Task : ITask := TTask.Create(
    procedure()
    begin
      Sleep(100);
      TThread.Synchronize(TThread.Current,procedure begin
        cbVoicesRegions.ItemIndex := cbVoicesRegions.Items.IndexOf(FTokenProc.region);
      end);
    end);
  Task.Start;
end;

end.
