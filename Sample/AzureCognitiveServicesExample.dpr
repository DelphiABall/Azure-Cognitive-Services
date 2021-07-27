program AzureCognitiveServicesExample;

uses
  System.StartUpCopy,
  FMX.Forms,
  mainForm in 'mainForm.pas' {frmMain},
  frames.AccessKey in 'frames.AccessKey.pas' {frameAccessKey: TFrame},
  Azure.API3.Connection in '..\Source\Azure.API3.Connection.pas',
  Azure.API3.Constants in '..\Source\Azure.API3.Constants.pas',
  Azure.API3.Speech in '..\Source\Azure.API3.Speech.pas',
  Azure.API3.Speech.SpeechToText in '..\Source\Azure.API3.Speech.SpeechToText.pas',
  Azure.API3.Speech.TextToSpeech in '..\Source\Azure.API3.Speech.TextToSpeech.pas',
  Azure.API3.Speech.Voices in '..\Source\Azure.API3.Speech.Voices.pas',
  Azure.API3.Translator.Dictionary in '..\Source\Azure.API3.Translator.Dictionary.pas',
  Azure.API3.Translator.Languages in '..\Source\Azure.API3.Translator.Languages.pas',
  Azure.API3.Translator in '..\Source\Azure.API3.Translator.pas',
  frames.TranslateText in 'frames.TranslateText.pas' {FrameTranslateText: TFrame},
  TokenShare in 'TokenShare.pas',
  frame.Dictionary in 'frame.Dictionary.pas' {FrameDictionary: TFrame},
  frame.SpeechToText in 'frame.SpeechToText.pas' {FrameSpeechToText: TFrame},
  frame.TextToSpeech in 'frame.TextToSpeech.pas' {FrameTextToSpeech: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
