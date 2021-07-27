unit Azure.API3.Translator.Languages;

// https://docs.microsoft.com/en-us/azure/cognitive-services/translator/language-support
// https://docs.microsoft.com/en-us/azure/cognitive-services/translator/reference/v3-0-languages

// Generic call (no auth required) to get a list of translatable languages.
// Options to define what is returned.

interface

uses System.Classes, Azure.API3.Translator, Azure.API3.Constants;

{$SCOPEDENUMS ON}

type
  TAzureTranslatorLanguages = class(TAzureTranslatorBase)
  type
    TAzureLanguage = record
      id         : string;
      name       : string;
      nativeName : string;
      direction  : string;
    end;

    TAzureLanguages = TArray<TAzureLanguage>;

    TAzureLanguageFormat = (id, name, nativeName);

  private
    FDataCache : TAzureLanguages;
    function GetAzureLanguages: TAzureLanguages;
  public
    constructor Create(AOwner: TComponent; ARegion: TAzureTranslationRegions = TAzureTranslationRegions.Global); reintroduce; overload;
    constructor Create(AOwner: TComponent; ARegionURLPrefix: string); reintroduce; overload;
    property Languages : TAzureLanguages read GetAzureLanguages;
    procedure LoadToString(aStrings : TStrings; aFormat : TAzureLanguageFormat = TAzureLanguageFormat.name);
    function LanguageStringToID(aLanguageString: string; aInputFormat: TAzureLanguageFormat = TAzureLanguageFormat.name): string;
    function LanguageIDToString(aLanguageID: string; aOutFormat: TAzureLanguageFormat = TAzureLanguageFormat.name): string;
  end;

  TAzureTranslatorDictionaryScope = class(TAzureTranslatorBase)
  type
    TAzureDictionaryLanguageMap = record
      id         : string;
      translations : TArray<string>;
    end;
    TAzureDictionaryLanguagesMap = TArray<TAzureDictionaryLanguageMap>;
  private
    FDataCache : TAzureDictionaryLanguagesMap;
    function GetAzureDictionaries: TAzureDictionaryLanguagesMap;
  public
    constructor Create(AOwner: TComponent; ARegion: TAzureTranslationRegions = TAzureTranslationRegions.Global); reintroduce; overload;
    constructor Create(AOwner: TComponent; ARegionURLPrefix: string); reintroduce; overload;
    property Dictionaries : TAzureDictionaryLanguagesMap read GetAzureDictionaries;
    function DictionaryByID(aLanguageID : string): TAzureDictionaryLanguageMap;
  end;


implementation

uses
  REST.Types, System.JSON.Types, System.SysUtils;

{ TAzureTranslatorLanguages }

constructor TAzureTranslatorLanguages.Create(AOwner: TComponent; ARegionURLPrefix: string);
begin
  inherited Create(AOwner, ARegionURLPrefix);
  RESTRequest.Method := TRestRequestMethod.rmGet;
  RESTRequest.Resource := 'languages?api-version=3.0&scope=translation';
end;

constructor TAzureTranslatorLanguages.Create(AOwner: TComponent;
  ARegion: TAzureTranslationRegions);
begin
  Create(AOwner, TAzureURLBuilder.RegionToString(ARegion));
end;

function TAzureTranslatorLanguages.GetAzureLanguages: TAzureLanguages;
begin
  if Length(FDataCache) = 0 then begin
    RESTRequest.Execute;

    var Reader := RESTResponse.JSONReader;
    var CurrTranslation : Integer := -1;
    var InTranslationArray : Boolean := False;
    var InTranslationArrayDetail : Boolean := False;

    var CurrProperty : string := '';

    while Reader.Read do begin
      case Reader.TokenType of
        TJsonToken.PropertyName : begin
                                    CurrProperty := Reader.Value.ToString;
                                    if (Reader.Value.ToString = 'translation') then begin
                                      InTranslationArray := True;
                                    end
                                    else if InTranslationArray then begin
                                      if InTranslationArrayDetail = False then begin
                                        InTranslationArrayDetail := True;
                                        Inc(CurrTranslation);
                                        SetLength(FDataCache, Length(FDataCache)+1);
                                        FDataCache[CurrTranslation].id := CurrProperty;
                                      end;
                                    end;
                                  end;
        TJsonToken.EndArray     : begin
                                  end;
        TJsonToken.StartObject  : begin
                                  end;
        TJsonToken.EndObject  :   begin
                                    if InTranslationArray then begin
                                      if InTranslationArrayDetail then
                                        InTranslationArrayDetail := False;
                                    end;
                                  end;
        TJsonToken.String     :   begin
                                    if InTranslationArray then begin
                                      if SameText(CurrProperty,'name') then
                                         FDataCache[CurrTranslation].name := Reader.Value.ToString
                                      else
                                      if SameText(CurrProperty,'nativeName') then
                                        FDataCache[CurrTranslation].nativeName := Reader.Value.ToString
                                      else
                                      if SameText(CurrProperty,'dir') then
                                        FDataCache[CurrTranslation].direction  := Reader.Value.ToString;
                                    end;
                                  end;
      end;
    end;
  end;

  Result := FDataCache;
end;

function TAzureTranslatorLanguages.LanguageIDToString(aLanguageID: string;
  aOutFormat: TAzureLanguageFormat): string;
begin
  for var I := 0 to Pred(Length(Languages)) do begin
    if FDataCache[I].id = aLanguageID then
      case aOutFormat of
        TAzureLanguageFormat.id         : Exit(FDataCache[I].id);
        TAzureLanguageFormat.nativeName : Exit(FDataCache[I].nativeName);
        else {name}  Exit(FDataCache[I].name);
      end;
  end;
  Result := '<unknown>';
end;

function TAzureTranslatorLanguages.LanguageStringToID(aLanguageString: string;
  aInputFormat: TAzureLanguageFormat): string;
begin
  for var I := 0 to Pred(Length(Languages)) do begin
    case aInputFormat of
      TAzureLanguageFormat.id         : if FDataCache[I].id = aLanguageString then
                                         Exit(FDataCache[I].id);

      TAzureLanguageFormat.nativeName : if FDataCache[I].nativeName = aLanguageString then
                                          Exit(FDataCache[I].id);

      else {name} if FDataCache[I].name = aLanguageString then
                     Exit(FDataCache[I].id);
    end;
  end;

  // Find any match....
  for var I := 0 to Pred(Length(Languages)) do begin
    if (FDataCache[I].nativeName = aLanguageString) or
       (FDataCache[I].id = aLanguageString) or
       (FDataCache[I].name = aLanguageString) then
       Exit(FDataCache[I].id);
  end;

  Result := '<unknown>';

end;

procedure TAzureTranslatorLanguages.LoadToString(aStrings : TStrings; aFormat : TAzureLanguageFormat = TAzureLanguageFormat.name);
begin
  aStrings.Clear;
  for var I := 0 to Pred(Length(Languages)) do begin
    case aFormat of
      TAzureLanguageFormat.id         : aStrings.Add(FDataCache[I].id);
      TAzureLanguageFormat.nativeName : aStrings.Add(FDataCache[I].nativeName);
      else {name}                       aStrings.Add(FDataCache[I].name);
    end;
  end;
end;

{ TAzureTranslatorDictionaryScope }

constructor TAzureTranslatorDictionaryScope.Create(AOwner : TComponent; ARegion : TAzureTranslationRegions);
begin
  Create(AOwner, TAzureURLBuilder.RegionToString(ARegion));
end;

constructor TAzureTranslatorDictionaryScope.Create(AOwner: TComponent;
  ARegionURLPrefix: string);
begin
  inherited Create(AOwner, ARegionURLPrefix);
  RESTRequest.Method := TRestRequestMethod.rmGet;
  RESTRequest.Resource := 'languages?api-version=3.0&scope=dictionary';
end;

function TAzureTranslatorDictionaryScope.DictionaryByID(
  aLanguageID: string): TAzureDictionaryLanguageMap;
begin
  for var Dict in Dictionaries do begin
    if Dict.id = aLanguageID then
      Exit(Dict);
  end;
end;

function TAzureTranslatorDictionaryScope.GetAzureDictionaries: TAzureDictionaryLanguagesMap;
begin
 if Length(FDataCache) = 0 then begin
    RESTRequest.Execute;

    var Reader := RESTResponse.JSONReader;

    var CurrLanguage : Integer := -1;
    var InDictionaryItems : Boolean := False;
    var InDictionaryArrayDetail : Boolean := False;

    var CurrTranslation : Integer := -1;
    var InTranslationItems : Boolean := False;

    var CurrProperty : string := '';

    while Reader.Read do begin
      case Reader.TokenType of
        TJsonToken.PropertyName : begin
                                    CurrProperty := Reader.Value.ToString;
                                    if (Reader.Value.ToString = 'dictionary') then begin
                                      InDictionaryItems := True;
                                    end
                                    else if InDictionaryItems then begin
                                      if InDictionaryArrayDetail = False then begin
                                        InDictionaryArrayDetail := True;
                                        Inc(CurrLanguage);
                                        SetLength(FDataCache, Length(FDataCache)+1);
                                        FDataCache[CurrLanguage].id := CurrProperty;
                                      end;
                                    end;
                                  end;
        TJsonToken.StartArray   : begin
                                    if SameText(CurrProperty,'translations') then
                                      InTranslationItems := True;
                                    CurrTranslation := -1;
                                  end;
        TJsonToken.EndArray     : begin
                                     if InTranslationItems then
                                      InTranslationItems := False;
                                  end;
        TJsonToken.StartObject  : begin
                                     if InTranslationItems then begin
                                       Inc(CurrTranslation);
                                       SetLength(FDataCache[CurrLanguage].translations, CurrTranslation+1);
                                     end;
                                  end;
        TJsonToken.EndObject  :   begin
                                    if InDictionaryItems and (not InTranslationItems) then begin
                                      if InDictionaryArrayDetail then
                                        InDictionaryArrayDetail := False;
                                    end;
                                  end;
        TJsonToken.String     :   begin
                                    if InDictionaryItems then begin
                                      // If needed this could be implemented. for now the decision was to run lean with the language data in a single object
                                      if (not InTranslationItems) then begin
                                        {
                                        if SameText(CurrProperty,'name') then
                                           FDataCache[CurrLanguage].name := Reader.Value.ToString
                                        else
                                        if SameText(CurrProperty,'nativeName') then
                                          FDataCache[CurrLanguage].nativeName := Reader.Value.ToString
                                        else
                                        if SameText(CurrProperty,'dir') then
                                          FDataCache[CurrLanguage].direction  := Reader.Value.ToString;
                                        }
                                      end else begin
                                        {
                                        if SameText(CurrProperty,'name') then
                                           FDataCache[CurrLanguage].name := Reader.Value.ToString
                                        else
                                        if SameText(CurrProperty,'nativeName') then
                                          FDataCache[CurrLanguage].nativeName := Reader.Value.ToString
                                        else
                                        if SameText(CurrProperty,'dir') then
                                          FDataCache[CurrLanguage].direction  := Reader.Value.ToString;
                                        }
                                        if SameText(CurrProperty,'code') then
                                          FDataCache[CurrLanguage].translations[CurrTranslation] := Reader.Value.ToString;
                                      end;
                                    end;
                                  end;
      end;
    end;
  end;

  Result := FDataCache;

end;

end.
