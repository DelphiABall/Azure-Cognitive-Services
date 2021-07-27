unit Azure.API3.Speech.Voices;

// https://docs.microsoft.com/en-gb/azure/cognitive-services/speech-service/rest-text-to-speech

interface

uses System.Classes, Azure.API3.Speech, Azure.API3.Constants;

type
  {$SCOPEDENUMS ON}

  TAzureTextToSpeechVoices = class(TAzureTextToSpeechBase)
  type
    TAzureVoiceGender = (Unknown, Female, Male);
    TAzureVoiceType   = (Unknown, Standard, Neural);
    TAzureVoiceStaus  = (Unknown, GA, Preview);

    TAzureSpeechLanguage = record
      Name           : string;
      DisplayName    : string;
      LocalName      : string;
      ShortName      : string;
      Gender         : TAzureVoiceGender;
      Locale         : string;
      SampleRateHertz: Integer;
      VoiceType      : TAzureVoiceType;
      Status         : TAzureVoiceStaus;
      StyleList      : TArray<string>;
      RolePlayList   : TArray<string>;
      SecondaryLocaleList : TArray<string>;
    end;
    TAzureSpeechLanguages = TArray<TAzureSpeechLanguage>;
  private
    FDataCache : TAzureSpeechLanguages;
  public
    constructor Create(AOwner: TComponent; ARegion : TAzureSpeechRegion); reintroduce; overload;
    constructor Create(AOwner: TComponent; ARegionURLPrefix : string); reintroduce; overload;
    function Voices : TAzureSpeechLanguages;
    class function VoiceGenderToString(aGender : TAzureVoiceGender): string;
    class function VoiceTypeToString(aVoiceType : TAzureVoiceType) : string;
    class function VoiceStatusToString(aVoiceStatus : TAzureVoiceStaus): string;
  end;


implementation

uses REST.Types, System.SysUtils, JSON.Types, System.TypInfo;

{ TAzureTextToSpeechVoices }

constructor TAzureTextToSpeechVoices.Create(AOwner: TComponent;
  ARegionURLPrefix: string);
begin
  inherited Create(AOwner, ARegionURLPrefix);
  RESTRequest.Method := TRESTRequestMethod.rmGET;
  RESTRequest.Resource := 'voices/list';
end;

class function TAzureTextToSpeechVoices.VoiceGenderToString(aGender : TAzureVoiceGender): string;
begin
  Result := GetEnumName(TypeInfo(TAzureVoiceGender),Integer(aGender));
end;

function TAzureTextToSpeechVoices.Voices: TAzureSpeechLanguages;
begin
  if Length(FDataCache) > 0 then
    Exit(FDataCache);

  Assert(AccessToken <> nil, ACCESS_TOKEN_MISSING);
  AccessToken.Token.AssignTokenToRequest(RESTRequest);
  RESTRequest.Execute;

  var Reader := RESTResponse.JSONReader;
  var CurrLanguage : Integer := -1;
  var InStyleList : Boolean := False;
  var InRolePlayList : Boolean := False;
  var InSecondaryLocaleList : Boolean := False;

  var CurrProperty : string := '';

  while Reader.Read do begin
    case Reader.TokenType of
      TJsonToken.PropertyName : begin
                                  CurrProperty := Reader.Value.ToString;


                                end;
      TJsonToken.StartArray   : begin
                                  if SameText(CurrProperty,'StyleList') then begin
                                    InStyleList := True;
                                  end else
                                  if SameText(CurrProperty,'RolePlayList') then begin
                                    InRolePlayList := True;
                                  end else
                                  if SameText(CurrProperty,'SecondaryLocaleList') then begin
                                    InSecondaryLocaleList := True;
                                  end
                                end;
      TJsonToken.EndArray     : begin
                                  if InStyleList then
                                    InStyleList := False
                                  else
                                  if InRolePlayList then
                                    InRolePlayList := False
                                  else
                                  if InSecondaryLocaleList then
                                    InSecondaryLocaleList := False;
                                end;
      TJsonToken.StartObject  : begin
                                  if InStyleList or InRolePlayList or InSecondaryLocaleList then
                                    Continue;
                                  Inc(CurrLanguage);
                                  SetLength(FDataCache,CurrLanguage+1);
                                end;
      TJsonToken.EndObject  :   begin
                                end;
      TJsonToken.Integer,
      TJsonToken.Float,
      TJsonToken.String     :   begin
                                  if InStyleList then begin
                                    SetLength(FDataCache[CurrLanguage].StyleList, Length(FDataCache[CurrLanguage].StyleList)+1);
                                    FDataCache[CurrLanguage].StyleList[Length(FDataCache[CurrLanguage].StyleList)-1] := Reader.Value.ToString;
                                  end
                                  else if InRolePlayList then begin
                                    SetLength(FDataCache[CurrLanguage].RolePlayList, Length(FDataCache[CurrLanguage].RolePlayList)+1);
                                    FDataCache[CurrLanguage].RolePlayList[Length(FDataCache[CurrLanguage].RolePlayList)-1] := Reader.Value.ToString;
                                  end
                                  else if InSecondaryLocaleList then begin
                                    SetLength(FDataCache[CurrLanguage].SecondaryLocaleList, Length(FDataCache[CurrLanguage].SecondaryLocaleList)+1);
                                    FDataCache[CurrLanguage].SecondaryLocaleList[Length(FDataCache[CurrLanguage].SecondaryLocaleList)-1] := Reader.Value.ToString;
                                  end
                                  else begin
                                    if SameText(CurrProperty,'Name') then
                                      FDataCache[CurrLanguage].Name := Reader.Value.ToString
                                    else
                                    if SameText(CurrProperty,'DisplayName') then
                                      FDataCache[CurrLanguage].DisplayName := Reader.Value.ToString
                                    else
                                    if SameText(CurrProperty,'LocalName') then
                                      FDataCache[CurrLanguage].LocalName := Reader.Value.ToString
                                    else
                                    if SameText(CurrProperty,'ShortName') then
                                      FDataCache[CurrLanguage].ShortName := Reader.Value.ToString
                                    else
                                    if SameText(CurrProperty,'SampleRateHertz') then
                                      FDataCache[CurrLanguage].SampleRateHertz := StrToIntDef(Reader.Value.ToString,0)
                                    else
                                    if SameText(CurrProperty,'Locale') then
                                      FDataCache[CurrLanguage].Locale := Reader.Value.ToString
                                    else
                                    if SameText(CurrProperty,'Gender') then begin
                                      var GenderStr := Reader.Value.ToString;
                                      if SameText(GenderStr,'Female') then
                                        FDataCache[CurrLanguage].Gender := TAzureVoiceGender.Female
                                      else
                                      if SameText(GenderStr,'Male') then
                                        FDataCache[CurrLanguage].Gender := TAzureVoiceGender.Male
                                      else
                                        FDataCache[CurrLanguage].Gender := TAzureVoiceGender.Unknown;
                                    end
                                    else
                                    if SameText(CurrProperty,'Status') then begin
                                      var StatusStr := Reader.Value.ToString;
                                      if SameText(StatusStr,'GA') then
                                        FDataCache[CurrLanguage].Status := TAzureVoiceStaus.GA
                                      else
                                      if SameText(StatusStr,'Preview') then
                                        FDataCache[CurrLanguage].Status := TAzureVoiceStaus.Preview
                                      else
                                        FDataCache[CurrLanguage].Status := TAzureVoiceStaus.Unknown;
                                    end
                                    else
                                    if SameText(CurrProperty,'VoiceType') then begin
                                      var VoiceTypeStr := Reader.Value.ToString;
                                      if SameText(VoiceTypeStr,'Standard') then
                                        FDataCache[CurrLanguage].VoiceType := TAzureVoiceType.Standard
                                      else
                                      if SameText(VoiceTypeStr,'Neural') then
                                        FDataCache[CurrLanguage].VoiceType := TAzureVoiceType.Neural
                                      else
                                        FDataCache[CurrLanguage].VoiceType := TAzureVoiceType.Unknown;
                                    end;
                                  end;
                                end;
    end;
  end;
  Result := FDataCache;
end;

class function TAzureTextToSpeechVoices.VoiceStatusToString(aVoiceStatus: TAzureVoiceStaus): string;
begin
  Result := GetEnumName(TypeInfo(TAzureVoiceStaus),Integer(aVoiceStatus));
end;

class function TAzureTextToSpeechVoices.VoiceTypeToString(aVoiceType: TAzureVoiceType): string;
begin
  Result := GetEnumName(TypeInfo(TAzureVoiceType),Integer(aVoiceType));
end;

constructor TAzureTextToSpeechVoices.Create(AOwner: TComponent; ARegion: TAzureSpeechRegion);
begin
  Create(AOwner, TAzureURLBuilder.RegionToString(ARegion));
end;

end.
