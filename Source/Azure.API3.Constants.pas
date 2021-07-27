unit Azure.API3.Constants;

interface

type
  {$SCOPEDENUMS ON}

  // Date as of 2021-07-15
  // Source - https://docs.microsoft.com/en-us/azure/cognitive-services/authentication
  TAzureAuthRegion = (global,
                      australiaeast,
                      brazilsouth,
                      canadacentral,
                      centralindia,
                      eastasia,
                      eastus,
                      japaneast,
                      northeurope,
                      southcentralus,
                      southeastasia,
                      uksouth,
                      westcentralus,
                      westeurope,
                      westus,
                      westus2);

  TAzureSpeechRegion = (AustraliaEast,
                        BrazilSouth,
                        CanadaCentral,
                        CentralUS,
                        EastAsia,
                        EastUS,
                        EastUS2,
                        FranceCentral,
                        IndiaCentral,
                        JapanEast,
                        KoreaCentral,
                        NorthCentralUS,
                        NorthEurope,
                        SouthAfricaNorth,
                        SouthCentralUS,
                        SoutheastAsia,
                        UKSouth,
                        WestCentralUS,
                        WestEurope,
                        WestUS,
                        WestUS2);

  // https://docs.microsoft.com/en-us/azure/cognitive-services/translator/reference/v3-0-reference
  TAzureTranslationRegions = (Global,       // api. Typically goes to the closet data center
                              NorthAmerica, // api-nam
                              Europe,       // api-eur
                              AsiaPacific); // api-apc
  const
  TAzureTranslationRegionsStr : array[0..3] of string = ('api', 'api-nam', 'api-eur', 'api-apc');

  ACCESS_TOKEN_MISSING = 'Access Token is not assigned';

  type
  TAzureURLBuilder = class
    // Authorization
    const AZURE_COGNITIVE_SERVICES_AUTH_BASE_URL = 'https://{region}api.cognitive.microsoft.com/sts/v1.0/';
    // Services
    const AZURE_TRANSLATOR_BASE_URL = 'https://{region}api.cognitive.microsofttranslator.com/';
    const AZURE_COGNITIVE_SERVICES_TEXT_TO_SPEECH_BASE_URL = 'https://{region}tts.speech.microsoft.com/cognitiveservices/';
    const AZURE_COGNITIVE_SERVICES_SPEECH_TO_TEXT_BASE_URL = 'https://{region}stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/';

    class function RegionToString(region : TAzureAuthRegion): string; overload;
    class function RegionToString(region : TAzureSpeechRegion): string; overload;
    class function RegionToString(region : TAzureTranslationRegions): string; overload;

    class function BuildServiceURL(const ServiceBaseURL : string; const region: TAzureAuthRegion): string; overload;
    class function BuildServiceURL(const ServiceBaseURL : string; const region: TAzureSpeechRegion): string; overload;
    class function BuildServiceURL(const ServiceBaseURL : string; const region: TAzureTranslationRegions): string; overload;
    class function BuildServiceURL(const ServiceBaseURL : string; region: string): string; overload;
  end;


implementation

{ TAzureAPI3RegionURL }

uses TypInfo, System.SysUtils, System.StrUtils;

class function TAzureURLBuilder.BuildServiceURL(const ServiceBaseURL : string;
  const region: TAzureAuthRegion): string;
begin
  Result := BuildServiceURL(ServiceBaseURL, RegionToString(region));
end;

class function TAzureURLBuilder.BuildServiceURL(const ServiceBaseURL : string;
  region: string): string;
begin
  if (region > '') and (not region.EndsWith('.')) then
    region := region+'.';

  if Lowercase(region).StartsWith('api') then begin
    Result := StringReplace(ServiceBaseURL,'{region}','',[rfReplaceAll,rfIgnoreCase]);
    Result := StringReplace(Result,'api.',region,[rfReplaceAll,rfIgnoreCase]);
  end else
    Result := StringReplace(ServiceBaseURL,'{region}',region,[rfReplaceAll,rfIgnoreCase]);
end;

class function TAzureURLBuilder.BuildServiceURL(const ServiceBaseURL: string;
  const region: TAzureSpeechRegion): string;
begin
   Result := BuildServiceURL(ServiceBaseURL, RegionToString(region));
end;

class function TAzureURLBuilder.RegionToString(
  region: TAzureSpeechRegion): string;
begin
  Result := GetEnumName(TypeInfo(TAzureSpeechRegion),Integer(region));
end;

class function TAzureURLBuilder.BuildServiceURL(const ServiceBaseURL: string;
  const region: TAzureTranslationRegions): string;
begin
  Result := BuildServiceURL(ServiceBaseURL, RegionToString(region));
end;

class function TAzureURLBuilder.RegionToString(
  region: TAzureTranslationRegions): string;
begin
  if region = TAzureTranslationRegions.Global then
    Result := ''
  else
    Result := TAzureTranslationRegionsStr[Integer(region)];
end;

class function TAzureURLBuilder.RegionToString(region: TAzureAuthRegion): string;
begin
  if region = TAzureAuthRegion.global then
    Result := ''
  else
    Result := GetEnumName(TypeInfo(TAzureAuthRegion),Integer(region));
end;

end.

