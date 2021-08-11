unit Azure.API3.Connection;

// Based on Cognitive Services as a start, but structuring for wider use.
// Azure Documentation : https://docs.microsoft.com/en-us/azure/cognitive-services/authentication
// Requirements        : You need an Azure account and an Azure Cognitive Services subscription

// Overview :
//  There are two base components.
// 1) A Transport for running a REST request,
// 2) TAzureToken which provides Token management for the Transport - This auto refreshes as required.

// The use of the Bearer token allows use of multi-service subscription keys.
// The key has a 10 minute lifespan with recommendation to refresh after 8 minutes of use.
// This method works for single, and multi-service subscription key.
// Multi-service keys need to use the region specific URL, but are not available for all products. Check documentation URL above.

interface

uses System.Classes, REST.Client, IPPeerClient, Azure.API3.Constants;

type
  TAzureTransportBase = class(TComponent)
  private
    FRESTClient: TRESTClient;
    FRESTRequest: TRESTRequest;
    FRESTResponse: TRESTResponse;
  public
    constructor Create(AOwner: TComponent); reintroduce;
    destructor Destroy; override;
    property RESTClient: TRESTClient read FRESTClient;
    property RESTRequest: TRESTRequest read FRESTRequest write FRESTRequest;
    property RESTResponse: TRESTResponse read FRESTResponse;
  end;

  TAzureToken = class(TAzureTransportBase)
  type
    TAzureAccessToken = record
    strict private
      FValue : string;
      FExpiry : TDateTime;
      function GetValue: string;
      procedure SetValue(const Value: string);
    public
      procedure Clear;
      function IsValid : boolean;
      procedure AssignTokenToRequest(
  aRequest: TRESTRequest);
      property Value : string read GetValue write SetValue;
    end;
  strict private
    FToken : TAzureAccessToken;
  private
    FRegion: string;
    procedure SetSubscriptionKey(const Value: string);
    function GetSubscriptionKey: string;
    procedure ClearToken;
    function GetToken: TAzureAccessToken;
    procedure SetRegion(const Value: string);
  public
    constructor Create(AOwner: TComponent); reintroduce; overload;
    ///<summary>
    ///  Create an Access Token based on a specific Region
    ///</summary>
    constructor Create(AOwner: TComponent; const ARegion : TAzureAuthRegion); reintroduce; overload;
    ///<summary>
    ///  Create an Access Token based on a specific Region - provide the string name of the region
    ///</summary>
    constructor Create(AOwner: TComponent; const ARegion : string); reintroduce; overload;

    ///<summary>
    ///  Set blank for Global. TAzureRegion in Azure.API3.Constants lists known regions. Use TAzureURLBuilder.RegionToString to get the string version.
    ///</summary>
    property Region : string read FRegion write SetRegion;
    ///<summary>
    ///  Use API key from your subscription in Azure. (Find under Keys and Endpoints on Azure Portal)
    ///</summary>
    property SubscriptionKey : string read GetSubscriptionKey write SetSubscriptionKey;
    property Token : TAzureAccessToken read GetToken;
  end;

  ///<summary>
  ///  TAzureTransport is a base class encapsulating AuthToken Management and REST request components
  ///</summary>
  TAzureTransport = class(TAzureTransportBase)
  private
    FAccessControl: TAzureToken;
    FRegion: string;
    FServiceBaseURL : string;
    procedure SetRegion(const Value: string);
  public
    constructor Create(AOwner: TComponent; const AServiceBaseURL, ARegion : string); reintroduce;
    ///<summary>
    ///  You need to set the AccessToken Manually as this enables multiple service objects to share an access token.
    ///</summary>
    property AccessToken : TAzureToken read FAccessControl write FAccessControl;
    ///<summary>
    ///  Set blank for Global. TAzureRegion in Azure.API3.Constants lists known regions. Use TAzureURLBuilder.RegionToString to get the string version.
    ///</summary>
    property Region : string read FRegion write SetRegion;
  end;


implementation

uses  REST.Types, System.SysUtils;
{ TAzureAccessControl }

procedure TAzureToken.ClearToken;
begin
  FToken.Clear;
end;

constructor TAzureToken.Create(AOwner: TComponent; const ARegion : TAzureAuthRegion);
begin
  Create(AOwner,TAzureURLBuilder.RegionToString(ARegion));
end;

constructor TAzureToken.Create(AOwner: TComponent);
begin
  Create(AOwner, TAzureAuthRegion.global);
end;

constructor TAzureToken.Create(AOwner: TComponent; const ARegion: string);
var
  RRP: TRESTRequestParameter;
begin
  inherited Create(AOwner);

  // Setting the region, sets the base URL
  Region := ARegion;

  RRP := RESTRequest.Params.AddItem;
  RRP.name  := 'subscription-key';

  RESTRequest.Resource := 'issuetoken';
  RESTRequest.SynchronizedEvents := False;

  ClearToken;
end;

function TAzureToken.GetSubscriptionKey: string;
begin
  Result := RESTRequest.Params.ParameterByName('subscription-key').Value;
end;

function TAzureToken.GetToken: TAzureAccessToken;
begin
  if not FToken.IsValid then
  begin
    Assert(SubscriptionKey > '', 'Subscription Key is missing');
    try
      RESTRequest.Execute;
    except
      raise exception.Create('Invalid Region or Subscription Key');
    end;
    if (RESTResponse.StatusCode = 200) and (RESTResponse.Content > '') then
      FToken.Value := 'Bearer '+ RESTResponse.Content
    else
      FToken.Clear;
  end;
  Result := FToken;
end;

procedure TAzureToken.SetRegion(const Value: string);
begin
  // This uses a String rather than TAzureRegion due to new regions appearing speradically.
  FRegion := Value;
  RESTClient.BaseURL := TAzureURLBuilder.BuildServiceURL(TAzureURLBuilder.AZURE_COGNITIVE_SERVICES_AUTH_BASE_URL, Region);
end;

procedure TAzureToken.SetSubscriptionKey(const Value: string);
begin
  if Value <> RESTRequest.Params.ParameterByName('subscription-key').Value then
  begin
    RESTRequest.Params.ParameterByName('subscription-key').Value := Value;
    ClearToken;
  end;
end;

{ TAzureAccessControl.TAzureAccessToken }

procedure TAzureToken.TAzureAccessToken.AssignTokenToRequest(
  aRequest: TRESTRequest);
var
  Param: TRESTRequestParameter;
begin
  Param := aRequest.Params.ParameterByName('Authorization');
  if Param = nil then
  begin
    Param := aRequest.Params.AddItem;
    Param.name := 'Authorization';
  end;
  Param.ContentType := TRESTContentType.ctNone;
  Param.Kind := TRESTRequestParameterKind.pkHTTPHEADER;
  Param.Options := [TRESTRequestParameterOption.poDoNotEncode];
  Param.Value := Self.Value;
end;

procedure TAzureToken.TAzureAccessToken.Clear;
begin
  FValue := '';
  FExpiry := 0;
end;

function TAzureToken.TAzureAccessToken.GetValue: string;
begin
  Result := FValue;
end;

function TAzureToken.TAzureAccessToken.IsValid: Boolean;
begin
  Result := (Value > '') and (FExpiry > now);
end;

procedure TAzureToken.TAzureAccessToken.SetValue(const Value: string);
begin
  if FValue <> Value then
  begin
    FValue := Value;
    FExpiry := Now+EncodeTime(0,8,0,0); // Token valid for 10, but set to 8 (MS recommended)
  end;
end;

{ TAzureTransport }

constructor TAzureTransport.Create(AOwner: TComponent; const AServiceBaseURL, ARegion : string);
var
  Param: TRESTRequestParameter;
begin
  inherited Create(AOwner);

  FServiceBaseURL := AServiceBaseURL;
  Region := ARegion;

  Param := FRESTRequest.Params.AddItem;
  Param.name := 'Authorization';
  Param.Kind := TRESTRequestParameterKind.pkHTTPHEADER;
  Param.Options := [TRESTRequestParameterOption.poDoNotEncode];
end;

procedure TAzureTransport.SetRegion(const Value: string);
begin
  FRegion := Value;
  RESTClient.BaseURL := TAzureURLBuilder.BuildServiceURL(FServiceBaseURL, Region);
end;

{ TAzureTransportBase }

constructor TAzureTransportBase.Create(AOwner: TComponent);
begin
  FRESTClient := TRESTClient.Create(Self);
  FRestClient.ContentType := CONTENTTYPE_APPLICATION_JSON;
  FRestClient.Accept := 'application/json, text/plain; q=0.9, text/html;q=0.8,';
  FRestClient.AcceptCharset :=  'utf-8, *;q=0.8';
  FRestClient.HandleRedirects := True;
  FRestClient.RaiseExceptionOn500 := False;

  FRESTResponse := TRESTResponse.Create(Self);
  FRESTResponse.ContentType := CONTENTTYPE_APPLICATION_JSON;

  FRESTRequest := TRESTRequest.Create(Self);
  FRESTRequest.Response := FRESTResponse;
  FRESTRequest.Client := FRESTClient;
  FRESTRequest.AutoCreateParams := True;

  FRESTRequest.Method := TRestRequestMethod.rmPOST;
  FRESTRequest.Accept := 'application/json, text/plain; q=0.9, text/html;q=0.8,';
  FRESTRequest.AcceptCharset :=  'utf-8, *;q=0.8';
  FRESTRequest.Timeout := 30000;
  FRESTRequest.AssignedValues := [TCustomRESTRequest.TAssignedValue.rvConnectTimeout,TCustomRESTRequest.TAssignedValue.rvHandleRedirects];
end;

destructor TAzureTransportBase.Destroy;
begin
  FRESTClient.Free;
  FRESTResponse.Free;
  FRESTRequest.Free;
  inherited;
end;

end.
