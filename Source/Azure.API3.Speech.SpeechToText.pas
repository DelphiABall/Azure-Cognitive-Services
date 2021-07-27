unit Azure.API3.Speech.SpeechToText;

interface

uses System.Classes, Azure.API3.Connection, Azure.API3.Constants;

type
  {$SCOPEDENUMS ON}

  // https://docs.microsoft.com/en-gb/azure/cognitive-services/speech-service/rest-speech-to-text
  // REST API is limited to short text of 1 minute.

  TAzureSpeechToTextBase = class(TAzureTransport)
  public
    constructor Create(AOwner: TComponent; const ARegion : TAzureSpeechRegion); overload;
    constructor Create(AOwner: TComponent; const ARegionURLPrefix : string); overload;
  end;

  TAzureSpeechToText = class(TAzureSpeechToTextBase)
  type
    TSpeechToTextFormat = (simple, detailed);
    TSpeechToTextProfanity = (masked, removed, raw);

    TSpeechToTextResult = record
      JSON : string;
      RecognitionStatus : string;
      DisplayText : string;
      Offset    : Integer;
      Duration  : Integer;
    end;
    TSpeechToTextResults = TArray<TSpeechToTextResult>;
  public
    constructor Create(AOwner: TComponent; const ARegion : TAzureSpeechRegion); reintroduce; overload;
    constructor Create(AOwner: TComponent; const ARegionURLPrefix : string); reintroduce; overload;
    function SpeechToText(AInputStream : TStream;
                          const aAudioLanguageCode : string = 'en-US';
                          const aFormat : TSpeechToTextFormat = TSpeechToTextFormat.simple;
                          const aProfanity : TSpeechToTextProfanity = TSpeechToTextProfanity.masked):TSpeechToTextResults; overload;
    function SpeechToText(aAudioFile : string;
                          const aAudioLanguageCode : string = 'en-US';
                          const aFormat : TSpeechToTextFormat = TSpeechToTextFormat.simple;
                          const aProfanity : TSpeechToTextProfanity = TSpeechToTextProfanity.masked):TSpeechToTextResults; overload;
  end;

implementation

uses System.SysUtils, REST.Types, JSON.Types, System.TypInfo;

{ TAzureSpeechToTextBase }

constructor TAzureSpeechToTextBase.Create(AOwner: TComponent;
  const ARegionURLPrefix: string);
begin
  inherited Create(AOwner, TAzureURLBuilder.AZURE_COGNITIVE_SERVICES_SPEECH_TO_TEXT_BASE_URL, ARegionURLPrefix);
end;

constructor TAzureSpeechToTextBase.Create(AOwner: TComponent;
  const ARegion: TAzureSpeechRegion);
begin
  Create(AOwner, TAzureURLBuilder.RegionToString(ARegion));
end;

{ TAzureSpeechToText }

constructor TAzureSpeechToText.Create(AOwner: TComponent;
  const ARegion: TAzureSpeechRegion);
begin
  Create(AOwner, TAzureURLBuilder.RegionToString(ARegion));
end;

constructor TAzureSpeechToText.Create(AOwner: TComponent;
  const ARegionURLPrefix: string);
begin
  inherited Create(AOwner, ARegionURLPrefix);
  RESTRequest.AutoCreateParams := True;
  RESTRequest.Method := TRESTRequestMethod.rmPOST;
  RESTRequest.Resource := 'v1?language={language}&profanity={profanity}&format={format}';

  var Param := RESTRequest.Params.AddHeader('Content-Type', 'audio/wav');
  Param.Options := [TRESTRequestParameterOption.poDoNotEncode];
end;

function TAzureSpeechToText.SpeechToText(AInputStream : TStream;
  const aAudioLanguageCode : string = 'en-US'; const aFormat : TSpeechToTextFormat = TSpeechToTextFormat.simple;
  const aProfanity : TSpeechToTextProfanity = TSpeechToTextProfanity.masked):TSpeechToTextResults;
begin
  Assert(AccessToken <> nil, ACCESS_TOKEN_MISSING);
  RESTRequest.Body.ClearBody;
  AccessToken.Token.AssignTokenToRequest(RESTRequest);

  if aAudioLanguageCode > '' then
    RESTRequest.Params.ParameterByName('Language').Value := aAudioLanguageCode;

  RESTRequest.Params.ParameterByName('format').Value := GetEnumName(TypeInfo(TSpeechToTextFormat),Integer(aFormat));
  RESTRequest.Params.ParameterByName('profanity').Value :=  GetEnumName(TypeInfo(TSpeechToTextProfanity),Integer(aProfanity));

  Assert(AInputStream <> nil,'Invalid Stream');

  if AInputStream is TStringStream then begin
    RESTRequest.Body.JSONWriter.WriteRaw(TStringStream(AInputStream).DataString);
  end
  else begin
  var SS := TStringStream.Create('');
    try
      SS.CopyFrom(AInputStream,0);
      RESTRequest.Body.JSONWriter.WriteRaw(SS.DataString);
    finally
      SS.Free;
    end;
  end;

  RESTRequest.Execute;

  var Reader := RESTResponse.JSONReader;
  var CurrProperty : string := '';

  if aFormat = TSpeechToTextFormat.simple then begin
    SetLength(Result,1);
    Result[0].JSON := RESTResponse.Content;

    while Reader.Read do begin
      case Reader.TokenType of
        TJsonToken.PropertyName : begin
                                    CurrProperty := Reader.Value.ToString;
                                  end;
        TJsonToken.Integer,
        TJsonToken.String     :   begin
                                    if SameText(CurrProperty,'RecognitionStatus') then
                                      Result[0].RecognitionStatus := Reader.Value.ToString
                                    else
                                    if SameText(CurrProperty,'DisplayText') then
                                      Result[0].DisplayText := Reader.Value.ToString
                                    else
                                    if SameText(CurrProperty,'Offset') then
                                      Result[0].Offset  := StrToIntDef(Reader.Value.ToString,0)
                                    else
                                    if SameText(CurrProperty,'Duration') then
                                      Result[0].Duration  := StrToIntDef(Reader.Value.ToString,0);
                                  end;
      end;
    end;
  end
  else if aFormat = TSpeechToTextFormat.detailed then begin
    SetLength(Result,0);
    var CurrObjectID : Integer := -1;

    while Reader.Read do begin
      case Reader.TokenType of
        TJsonToken.PropertyName : begin
                                    CurrProperty := Reader.Value.ToString;
                                  end;
        TJsonToken.StartObject  : if not Reader.Path.Contains('.') then begin // Root object e.g. [0] or '' if not an response array.
                                    Inc(CurrObjectID);
                                    SetLength(Result,CurrObjectID+1);
                                  end;
        TJsonToken.EndObject    : ;

        TJsonToken.StartArray   : begin
                                    Sleep(1);
                                  end;
        TJsonToken.EndArray     : begin
                                  end;

        TJsonToken.Integer,
        TJsonToken.String       : begin
                                    if SameText(CurrProperty,'recognized') or SameText(CurrProperty,'RecognitionStatus') then
                                      Result[CurrObjectID].RecognitionStatus := Reader.Value.ToString
                                    else
                                    if SameText(CurrProperty,'text') or SameText(CurrProperty,'DisplayText') or SameText(CurrProperty,'Display') then begin
                                      if Result[CurrObjectID].DisplayText = '' then
                                        Result[CurrObjectID].DisplayText := Reader.Value.ToString;
                                    end
                                    else
                                    if SameText(CurrProperty,'offset') then
                                      Result[CurrObjectID].Offset  := StrToIntDef(Reader.Value.ToString,0)
                                    else
                                    if SameText(CurrProperty,'duration') then
                                      Result[CurrObjectID].Duration  := StrToIntDef(Reader.Value.ToString,0)
                                    else
                                    if SameText(CurrProperty,'json') then
                                      Result[CurrObjectID].JSON  := Reader.Value.ToString;
                                  end;
      end;
    end;
  end;
end;

function TAzureSpeechToText.SpeechToText(aAudioFile: string; const aAudioLanguageCode : string = 'en-US';
  const aFormat : TSpeechToTextFormat = TSpeechToTextFormat.simple; const aProfanity : TSpeechToTextProfanity = TSpeechToTextProfanity.masked):TSpeechToTextResults;
begin
  var MS := TStringStream.Create;
  try
    MS.LoadFromFile(aAudioFile);
    Result := SpeechToText(MS,aAudioLanguageCode, aFormat, aProfanity);
  finally
    MS.Free
  end;

end;

end.
