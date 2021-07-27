unit Azure.API3.Speech;

// https://docs.microsoft.com/en-gb/azure/cognitive-services/speech-service/rest-text-to-speech

interface

uses System.Classes, Azure.API3.Connection, Azure.API3.Constants;

type
  {$SCOPEDENUMS ON}

  TAzureTextToSpeechBase = class(TAzureTransport)
  public
    constructor Create(AOwner: TComponent; const ARegion : TAzureSpeechRegion); overload;
    constructor Create(AOwner: TComponent; const ARegionURLPrefix : string); overload;
  end;

implementation

uses REST.Types, System.SysUtils, JSON.Types, System.TypInfo;

{ TAzureTextToSpeachBase }

constructor TAzureTextToSpeechBase.Create(AOwner: TComponent;
  const ARegionURLPrefix: string);
begin
  inherited Create(AOwner, TAzureURLBuilder.AZURE_COGNITIVE_SERVICES_TEXT_TO_SPEECH_BASE_URL, Lowercase(ARegionURLPrefix));
end;

constructor TAzureTextToSpeechBase.Create(AOwner: TComponent;
  const ARegion: TAzureSpeechRegion);
begin
  Create(AOwner, TAzureURLBuilder.RegionToString(ARegion));
end;

end.
