unit Azure.API3.Translator.Dictionary;

// https://docs.microsoft.com/en-us/azure/cognitive-services/translator/reference/v3-0-dictionary-lookup
interface

uses Azure.API3.Translator, System.Classes, Azure.API3.Constants;

{$SCOPEDENUMS ON}

type
  TAzureTranslatorDictionary = class(TAzureTranslatorBase)
  type
    TPartOfSpeachTag = (Unknown, Adjectives, Adverbs, Conjunctions, Determiners, ModalVerbs, Nouns,
                        Prepositions, Pronouns, Verbs, Other);

    TBackTranslation = record
      NormalizedText : string;
      DisplayText : string;
      NumExamples : Integer;
      FrequencyCount : Integer;
    end;

    TBackTranslations = TArray<TBackTranslation>;

    TAzureTranslatorDictionaryTranslation = record
      NormalizedTarget : string;
      DisplayTarget : string;
      PartOfSpeach : TPartOfSpeachTag;
      Confidence : double;
      PrefixWord : string;
      BackTranslations : TBackTranslations;

    end;

    TTranslatedDictionaryResult = record
      Response : string;
      normalizedSource : string;
      displaySource : string;
      Translations : TArray<TAzureTranslatorDictionaryTranslation>
    end;

   // TTranslatedDictionaryTexts = TArray<TTranslatedDictionaryText>;
  public
    constructor Create(AOwner: TComponent; ARegion: TAzureTranslationRegions = TAzureTranslationRegions.Global); reintroduce; overload;
    constructor Create(AOwner: TComponent; ARegionURLPrefix: string); reintroduce; overload;

    function Lookup(const AOriginalLanguage, AText, ATargetLanguage : string): TTranslatedDictionaryResult;
  end;

implementation

uses JSON.Types, System.SysUtils;

{ TAzureTranslatorDictionary }


constructor TAzureTranslatorDictionary.Create(AOwner: TComponent;
  ARegionURLPrefix: string);
begin
  inherited Create(AOwner, ARegionURLPrefix);
  RESTRequest.AutoCreateParams := True;
  RESTRequest.Resource := 'dictionary/lookup?api-version=3.0&from={from}&to={to}';
end;

constructor TAzureTranslatorDictionary.Create(AOwner: TComponent;
  ARegion: TAzureTranslationRegions);
begin
  Create(AOwner, TAzureURLBuilder.RegionToString(ARegion));
end;

function TAzureTranslatorDictionary.Lookup(const AOriginalLanguage, AText, ATargetLanguage : string): TTranslatedDictionaryResult;
begin
  if AText = '' then
    Exit();

  Assert(AccessToken <> nil, ACCESS_TOKEN_MISSING);
  Assert(AOriginalLanguage > '','Original language is blank');
  Assert(ATargetLanguage > '','Target language is blank');

  // Set the paramaters
  RESTRequest.Params.ParameterByName('from').Value := AOriginalLanguage;
  RESTRequest.Params.ParameterByName('to').Value := ATargetLanguage;

  RESTRequest.Body.ClearBody;
  RESTRequest.Body.JSONWriter.WriteStartArray;
  RESTRequest.Body.JSONWriter.WriteStartObject;
  RESTRequest.Body.JSONWriter.WritePropertyName('text');
  RESTRequest.Body.JSONWriter.WriteValue(AText);
  RESTRequest.Body.JSONWriter.WriteEndObject;
  RESTRequest.Body.JSONWriter.WriteEndArray;

  // Ensure security token is set
  AccessToken.Token.AssignTokenToRequest(RESTRequest);

  RESTRequest.Execute;

  Result.Response := RESTResponse.Content;

  var Reader := RESTResponse.JSONReader;
  var CurrTranslation : Integer := -1;
  var CurrBackTranslation : Integer := -1;

  var InTranslationArray : Boolean := False;
  var InBackTranslationArray : Boolean := False;

  var CurrProperty : string := '';


  // Build the output.
  while Reader.Read do begin
    case Reader.TokenType of
      TJsonToken.PropertyName : begin
                                  CurrProperty := Reader.Value.ToString;

                                  if (SameText(CurrProperty,'normalizedSource')) then
                                    Result.normalizedSource := Reader.Value.ToString
                                  else if (SameText(CurrProperty,'displaySource')) then
                                    Result.displaySource := Reader.Value.ToString;

                                end;
      TJsonToken.StartArray   : begin
                                  if (SameText(CurrProperty,'translations')) then
                                    InTranslationArray := True
                                  else
                                  if (SameText(CurrProperty,'backTranslations')) then begin
                                    InBackTranslationArray := True;
                                    CurrBackTranslation := -1;
                                  end;
                                end;

      TJsonToken.EndArray     : begin
                                  if InBackTranslationArray then
                                    InBackTranslationArray := False
                                  else
                                  if InTranslationArray then
                                    InTranslationArray := False;
                                end;
      TJsonToken.StartObject  : begin
                                  if InBackTranslationArray then begin
                                    Inc(CurrBackTranslation);
                                    SetLength(Result.Translations[CurrTranslation].BackTranslations,CurrBackTranslation+1);
                                  end
                                  else
                                  if InTranslationArray then begin
                                    Inc(CurrTranslation);
                                    SetLength(Result.Translations,CurrTranslation+1);
                                  end;
                                end;
      TJsonToken.EndObject  :   begin
                                end;
      TJsonToken.String     :   begin
                                  if InTranslationArray then begin
                                    if (not InBackTranslationArray) then begin
                                      if SameText(CurrProperty,'normalizedTarget') then
                                         Result.Translations[CurrTranslation].NormalizedTarget := Reader.Value.ToString
                                      else
                                      if SameText(CurrProperty,'displayTarget') then
                                         Result.Translations[CurrTranslation].displayTarget := Reader.Value.ToString
                                      else
                                      if SameText(CurrProperty,'prefixWord') then
                                         Result.Translations[CurrTranslation].PrefixWord := Reader.Value.ToString
                                      else
                                      if SameText(CurrProperty,'posTag') then begin
                                        var CurrPosTag := Reader.Value.ToString;
                                        {$REGION 'PosTag Validation'}
                                        if SameText(CurrPosTag,'ADJ') then
                                          Result.Translations[CurrTranslation].PartOfSpeach := TPartOfSpeachTag.Adjectives
                                        else
                                        if SameText(CurrPosTag,'ADV') then
                                          Result.Translations[CurrTranslation].PartOfSpeach := TPartOfSpeachTag.Adverbs
                                        else
                                        if SameText(CurrPosTag,'CONJ') then
                                          Result.Translations[CurrTranslation].PartOfSpeach := TPartOfSpeachTag.Conjunctions
                                        else
                                        if SameText(CurrPosTag,'DET') then
                                          Result.Translations[CurrTranslation].PartOfSpeach := TPartOfSpeachTag.Determiners
                                        else
                                        if SameText(CurrPosTag,'MODAL') then
                                          Result.Translations[CurrTranslation].PartOfSpeach := TPartOfSpeachTag.ModalVerbs
                                        else
                                        if SameText(CurrPosTag,'NOUN') then
                                          Result.Translations[CurrTranslation].PartOfSpeach := TPartOfSpeachTag.Nouns
                                        else
                                        if SameText(CurrPosTag,'PREP') then
                                          Result.Translations[CurrTranslation].PartOfSpeach := TPartOfSpeachTag.Prepositions
                                        else
                                        if SameText(CurrPosTag,'PRON') then
                                          Result.Translations[CurrTranslation].PartOfSpeach := TPartOfSpeachTag.Pronouns
                                        else
                                        if SameText(CurrPosTag,'VERB') then
                                          Result.Translations[CurrTranslation].PartOfSpeach := TPartOfSpeachTag.Verbs
                                        else
                                        if SameText(CurrPosTag,'OTHER') then
                                          Result.Translations[CurrTranslation].PartOfSpeach := TPartOfSpeachTag.Other
                                        else
                                          Result.Translations[CurrTranslation].PartOfSpeach := TPartOfSpeachTag.Unknown;
                                        {$ENDREGION}
                                      end;
                                    end
                                    else begin
                                      // InBackTranslationArray
                                      if SameText(CurrProperty,'normalizedText') then
                                         Result.Translations[CurrTranslation].BackTranslations[CurrBackTranslation].NormalizedText := Reader.Value.ToString
                                      else
                                      if SameText(CurrProperty,'displayText') then
                                         Result.Translations[CurrTranslation].BackTranslations[CurrBackTranslation].DisplayText := Reader.Value.ToString
                                      else

                                    end;
                                  end;
                                end;
      TJsonToken.Float,
      TJsonToken.Integer    :   begin
                                  if InBackTranslationArray then begin
                                    if SameText(CurrProperty,'numExamples') then
                                       Result.Translations[CurrTranslation].BackTranslations[CurrBackTranslation].NumExamples := StrToIntDef(Reader.Value.ToString,-1)
                                    else if SameText(CurrProperty,'frequencyCount') then
                                       Result.Translations[CurrTranslation].BackTranslations[CurrBackTranslation].FrequencyCount := StrToIntDef(Reader.Value.ToString,-1);
                                  end
                                  else
                                  if InTranslationArray then begin
                                    if SameText(CurrProperty,'confidence') then
                                       Result.Translations[CurrTranslation].Confidence := StrToFloatDef(Reader.Value.ToString,-1);
                                  end
                                end;

    end;
  end;
end;

end.
