unit Azure.API3.Translator;

interface

uses System.Classes, Azure.API3.Connection, Azure.API3.Constants;

{$SCOPEDENUMS ON}

type
  TAzureTranslatorBase = class(TAzureTransport)
  public
    constructor Create(AOwner: TComponent; ARegion : TAzureTranslationRegions = TAzureTranslationRegions.Global); overload;
    constructor Create(AOwner: TComponent; ARegionURLPrefix : string); overload;
  end;

  ///<summary>
  ///  TAzureTranslator exposes Microsoft Translate Webservices to translate a string - Requires the AccessControl property configured.
  ///</summary>
  TAzureTranslator = class(TAzureTranslatorBase)
  type
    TTranslatedText = record
      Language : string;
      Text : string;
    end;

    TTranslateResult = record
      Response : string;
      OriginalText : string;
      OriginalLanguage : string;
      OriginalLanguageScore : double;
      TranslatedTexts : array of TTranslatedText;
    end;
  public
    function Translate(AText: string; AOriginalLanguage : string; ATargetLangages: array of string): TTranslateResult;
  end;

implementation

uses System.SysUtils, REST.Types, System.JSON, System.JSON.Types;

{ TAzureTranslator }

function TAzureTranslator.Translate(AText: string; AOriginalLanguage : string;
  ATargetLangages: array of string): TTranslateResult;
begin
  Assert(Length(ATargetLangages) > 0, 'Target Language Not Set');
  Assert(AccessToken <> nil, ACCESS_TOKEN_MISSING);

  var FRequestResource : string;

  if AOriginalLanguage > '' then
    FRequestResource := 'translate?api-version=3.0&from={from}'
  else
    FRequestResource := 'translate?api-version=3.0';

  for var I := 1 to Length(ATargetLangages) do begin
    FRequestResource := FRequestResource + Format('&to={to%d}',[I]);
  end;

  RESTRequest.Params.Clear;
  RESTRequest.Body.ClearBody;

  RESTRequest.AutoCreateParams := True;
  RESTRequest.Resource := FRequestResource;

  // Now set the values of the setup query
  if AOriginalLanguage > '' then
    RESTRequest.Params.ParameterByName('from').Value := AOriginalLanguage;

  for var I := 1 to Length(ATargetLangages) do begin
    RESTRequest.Params.ParameterByName('to'+I.ToString).Value := ATargetLangages[Pred(I)];
  end;

  AccessToken.Token.AssignTokenToRequest(RESTRequest);
  Assert (RESTRequest.Params.IndexOf('Authorization') > -1,'Authorization Paramater missing');

  var Param := RESTRequest.Params.AddHeader('Content-Type',CONTENTTYPE_APPLICATION_JSON);
  Param.Options := [TRESTRequestParameterOption.poDoNotEncode];

  RESTRequest.Body.JSONWriter.WriteStartArray;
  RESTRequest.Body.JSONWriter.WriteStartObject;
  RESTRequest.Body.JSONWriter.WritePropertyName('text');
  RESTRequest.Body.JSONWriter.WriteValue(AText);
  RESTRequest.Body.JSONWriter.WriteEndObject;
  RESTRequest.Body.JSONWriter.WriteEndArray;

  Result.OriginalText := AText;
  Result.OriginalLanguage := AOriginalLanguage;

  RESTRequest.Execute;

  SetLength(Result.TranslatedTexts,Length(ATargetLangages));
  for var I := 0 to Length(ATargetLangages)-1 do begin
    var CurrLang:= ATargetLangages[I];

    Result.TranslatedTexts[I].Language := '';
    Result.TranslatedTexts[I].Text := '';
  end;

  // Check for updated language output
  Result.Response := RESTResponse.Content;

  var Reader := RESTResponse.JSONReader;
  var CurrTranslation : Integer := -1;
  var InTranslationArray : Boolean := False;
  var CurrProperty : string := '';

  while Reader.Read do begin
    case Reader.TokenType of
      TJsonToken.PropertyName : begin
                                  CurrProperty := Reader.Value.ToString;

                                  if (Reader.Value.ToString = 'language') and
                                     (Reader.Path.Contains('detectedLanguage')) then begin
                                    Reader.Read;
                                    Result.OriginalLanguage := Reader.Value.ToString;
                                  end else
                                  if (Reader.Value.ToString = 'score') and
                                     (Reader.Path.Contains('detectedLanguage')) then begin
                                    Reader.Read;
                                    Result.OriginalLanguageScore := StrToFloatDef(Reader.Value.ToString,-1);
                                  end;

                                  if (Reader.Value.ToString = 'translations') then begin
                                    InTranslationArray := True;
                                  end;
                                end;
      TJsonToken.EndArray     : begin
                                  if InTranslationArray then
                                    InTranslationArray := False;
                                  if Result.OriginalLanguage > '' then
                                    Break;
                                end;
      TJsonToken.StartObject  : begin
                                  if InTranslationArray then
                                    Inc(CurrTranslation);
                                end;
      TJsonToken.EndObject  :   begin
                                end;
      TJsonToken.String     :   begin
                                  if InTranslationArray then begin
                                    if SameText(CurrProperty,'text') then
                                       Result.TranslatedTexts[CurrTranslation].Text := Reader.Value.ToString
                                    else
                                    if SameText(CurrProperty,'to') then
                                      Result.TranslatedTexts[CurrTranslation].Language := Reader.Value.ToString;
                                  end;
                                end;
    end;
  end;


end;

{ TAzureTranslatorBase }

constructor TAzureTranslatorBase.Create(AOwner: TComponent;
  ARegion: TAzureTranslationRegions);
begin
  Create(AOwner, TAzureURLBuilder.AZURE_TRANSLATOR_BASE_URL, TAzureURLBuilder.RegionToString(ARegion));
end;

constructor TAzureTranslatorBase.Create(AOwner: TComponent;
  ARegionURLPrefix: string);
begin
  inherited Create(AOwner, TAzureURLBuilder.AZURE_TRANSLATOR_BASE_URL, ARegionURLPrefix);
end;

end.
