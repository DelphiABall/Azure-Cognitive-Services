unit mainForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.MultiView, FMX.Controls.Presentation, FMX.TabControl,
  frames.AccessKey, frames.TranslateText, frame.Dictionary, frame.TextToSpeech,
  frame.SpeechToText;

type
  TfrmMain = class(TForm)
    ToolBar1: TToolBar;
    MultiView1: TMultiView;
    loMain: TLayout;
    btnMenu: TButton;
    tcMain: TTabControl;
    tabOverview: TTabItem;
    lblWelcome: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    frameAccessKeyTranslator: TframeAccessKey;
    tabTranslator: TTabItem;
    tabDictionary: TTabItem;
    tabTextToSpeech: TTabItem;
    tabSpeechToText: TTabItem;
    Label4: TLabel;
    btnSaveConfig: TButton;
    btnLoadConfig: TButton;
    frameAccessKeySpeech: TframeAccessKey;
    Label5: TLabel;
    Label6: TLabel;
    FrameTranslateText1: TFrameTranslateText;
    FrameDictionary1: TFrameDictionary;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    FrameTextToSpeech1: TFrameTextToSpeech;
    Label11: TLabel;
    Label12: TLabel;
    FrameSpeechToText1: TFrameSpeechToText;
    procedure FormCreate(Sender: TObject);
    procedure btnLoadConfigClick(Sender: TObject);
    procedure btnSaveConfigClick(Sender: TObject);
    procedure tcMainChange(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}
uses INIFiles, System.IOUtils, Azure.API3.Connection;

function INIFilePath : string;
begin
  Result := TPath.Combine(TPath.GetLibraryPath,'Azure.ini');
end;

procedure TfrmMain.btnLoadConfigClick(Sender: TObject);
begin
  // Loads settings from a local ini file
  var ini := TIniFile.Create(INIFilePath);
  try
    frameAccessKeyTranslator.Key    := ini.ReadString('Translation','Key','');
    frameAccessKeyTranslator.Region := ini.ReadString('Translation','Region','');

    frameAccessKeySpeech.Key    := ini.ReadString('Speech','Key','');
    frameAccessKeySpeech.Region := ini.ReadString('Speech','Region','');
  finally
    ini.Free;
  end;
end;

procedure TfrmMain.btnSaveConfigClick(Sender: TObject);
begin
  // Saves settings from a local ini file
  var ini := TIniFile.Create(INIFilePath);
  try
    ini.WriteString('Translation','Key', frameAccessKeyTranslator.Key);
    ini.WriteString('Translation','Region',frameAccessKeyTranslator.Region);

    ini.WriteString('Speech','Key',    frameAccessKeySpeech.Key);
    ini.WriteString('Speech','Region', frameAccessKeySpeech.Region);
  finally
    ini.Free;
  end;
end;


procedure TfrmMain.FormCreate(Sender: TObject);
begin
  tcMain.ActiveTab := tabOverview;
  // Initalize sets up the lists in the Key's frames
  frameAccessKeyTranslator.Initalize;
  frameAccessKeySpeech.Initalize;

  // If you have saved settings, load them.
  if FileExists(INIFilePath) then
    btnLoadConfigClick(Self);
end;

procedure TfrmMain.tcMainChange(Sender: TObject);
begin
  if tcMain.ActiveTab = tabTranslator then
    FrameTranslateText1.Initialize(function() : TAzureToken
                                   begin
                                     Result := frameAccessKeyTranslator.AzureToken;
                                   end)
  else
  if tcMain.ActiveTab = tabDictionary then
    FrameDictionary1.Initialize(function() : TAzureToken
                                begin
                                   Result := frameAccessKeyTranslator.AzureToken;
                                end)
  else
  if tcMain.ActiveTab = tabTextToSpeech then begin
    FrameTextToSpeech1.Initialize(function() : TAzureToken
                                  begin
                                    Result := frameAccessKeySpeech.AzureToken;
                                  end);
  end
  else
  if tcMain.ActiveTab = tabSpeechToText then
    FrameSpeechToText1.Initialize(function() : TAzureToken
                                  begin
                                    Result := frameAccessKeySpeech.AzureToken;
                                  end);

end;

end.
