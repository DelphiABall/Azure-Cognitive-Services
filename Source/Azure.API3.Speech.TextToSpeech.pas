unit Azure.API3.Speech.TextToSpeech;

// https://docs.microsoft.com/en-gb/azure/cognitive-services/speech-service/rest-text-to-speech

interface

uses System.Classes, Azure.API3.Speech, Azure.API3.Constants;

type
  {$SCOPEDENUMS ON}

  TAzureTextToSpeech = class(TAzureTextToSpeechBase)
  public
    constructor Create(AOwner: TComponent; const ARegion : TAzureSpeechRegion); reintroduce; overload;
    constructor Create(AOwner: TComponent; const ARegionURLPrefix : string); reintroduce; overload;
    function TextToSpeech(const AText : string; AOutputStream : TMemoryStream; aDocumentLanguageCode : string = 'en-US'; aAzureVoiceName : string = 'en-US-AriaNeural'):Boolean;
    function RawTextToSpeech(const AText : string; AOutputStream : TMemoryStream):Boolean;
  end;

  // https://docs.microsoft.com/en-gb/azure/cognitive-services/speech-service/speech-synthesis-markup?tabs=csharp
  // Use Multiple Voices
  TAzureTextBuilder = class(TObject)
  strict private
    FInternalText : TStringList;
    FDocumentLanguage: string;
    function GetRawText: string;
    procedure SetDocumentLanguage(const Value: string);
  public
    constructor Create(xmlLang : string = 'en-US');
    destructor Destroy; override;
    procedure AddText(AText : string; AAzureVoice : string);
    property RawText : string read GetRawText;
    property DocumentLanguage : string read FDocumentLanguage write SetDocumentLanguage;
  end;

implementation

uses REST.Types, System.SysUtils;

{ TAzureTextToSpeech }

constructor TAzureTextToSpeech.Create(AOwner: TComponent;
  const ARegionURLPrefix: string);
begin
  inherited Create(AOwner, ARegionURLPrefix);
  RESTRequest.Method := TRESTRequestMethod.rmPOST;
  RESTRequest.Resource := 'v1';

  var Param := RESTRequest.Params.AddHeader('Content-Type','application/ssml+xml');
  Param.Options := [TRESTRequestParameterOption.poDoNotEncode];

  Param := RESTRequest.Params.AddHeader('X-Microsoft-OutputFormat','audio-16khz-128kbitrate-mono-mp3');
  Param.Options := [TRESTRequestParameterOption.poDoNotEncode];

  Param := RESTRequest.Params.AddHeader('User-Agent','curl');
  Param.Options := [TRESTRequestParameterOption.poDoNotEncode];
end;

constructor TAzureTextToSpeech.Create(AOwner: TComponent;
  const ARegion: TAzureSpeechRegion);
begin
  Create(AOwner, TAzureURLBuilder.RegionToString(ARegion));
end;

function TAzureTextToSpeech.TextToSpeech(const AText : string; AOutputStream : TMemoryStream;
  aDocumentLanguageCode : string = 'en-US'; aAzureVoiceName : string = 'en-US-AriaNeural') : Boolean;
begin
  var aBody := '<speak version=''1.0'' xml:lang=''%s''>'+
                 '<voice name=''%s''>'+
                   '%s' + // Text
                 '</voice>'+
               '</speak>';
  aBody := Format(aBody,[aDocumentLanguageCode,aAzureVoiceName,AText]);
  Result := RawTextToSpeech(aBody,AOutputStream);
end;


function TAzureTextToSpeech.RawTextToSpeech(const AText: string;
  AOutputStream: TMemoryStream): Boolean;
begin
  Assert(AccessToken <> nil, ACCESS_TOKEN_MISSING);
  RESTRequest.Body.ClearBody;
  AccessToken.Token.AssignTokenToRequest(RESTRequest);

  RESTRequest.Body.JSONWriter.WriteRaw(AText);

  RESTRequest.Execute;
  Result := RESTResponse.StatusCode = 200;
  if Result then
    AOutputStream.WriteData(RESTResponse.RawBytes,Length(RESTResponse.RawBytes));
end;

{ TAzureTextBuilder }

procedure TAzureTextBuilder.AddText(AText, AAzureVoice: string);
begin
  FInternalText.Add(Format('<voice name="%s">'+ // Name of Voice
                             '%s'+ // Text
                           '</voice>',[AAzureVoice,AText]));
end;

constructor TAzureTextBuilder.Create(xmlLang: string);
begin
  inherited Create;
  DocumentLanguage := xmlLang;
  FInternalText := TStringList.Create;
end;

destructor TAzureTextBuilder.Destroy;
begin
  FInternalText.Free;
  inherited;
end;

function TAzureTextBuilder.GetRawText: string;
begin             //  xmlns="http://www.w3.org/2001/10/synthesis"
  Result := Format('<speak version=''1.0''  xml:lang=''%s''>',[DocumentLanguage])+
                   FInternalText.Text+
                   '</speak>';
end;

procedure TAzureTextBuilder.SetDocumentLanguage(const Value: string);
begin
  FDocumentLanguage := Value;
end;

end.
