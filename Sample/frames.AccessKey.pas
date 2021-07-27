unit frames.AccessKey;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation, Azure.API3.Connection, FMX.ComboEdit,
  FMX.ListBox, FMX.Effects;

type
  TframeAccessKey = class(TFrame)
    edtKey: TEdit;
    btnTest: TButton;
    lblAccessKey: TLabel;
    cbRegion: TComboBox;
    GlowEffectTest: TGlowEffect;
    procedure cbRegionChange(Sender: TObject);
    procedure btnTestClick(Sender: TObject);
    procedure edtKeyChange(Sender: TObject);
  private
    FAzureToken : TAzureToken;
    function GetToken: TAzureToken;
    function GetKey: string;
    procedure SetKey(const Value: string);
    function GetRegion: string;
    procedure SetRegion(const Value: string);
    { Private declarations }
  public
    { Public declarations }
    constructor Create(AOwner : TComponent); reintroduce;
    procedure Initalize;
    property AzureToken : TAzureToken read GetToken;
    property Key : string read GetKey write SetKey;
    property Region : string read GetRegion write SetRegion;
  end;

implementation

{$R *.fmx}

uses Azure.API3.Constants;

procedure TframeAccessKey.btnTestClick(Sender: TObject);
begin
  if AzureToken.Token.IsValid then
    GlowEffectTest.GlowColor := TAlphaColorRec.Green
  else
    GlowEffectTest.GlowColor := TAlphaColorRec.Red;
  GlowEffectTest.Enabled := True;
end;

procedure TframeAccessKey.cbRegionChange(Sender: TObject);
begin
  GlowEffectTest.Enabled := False;
  if Assigned(FAzureToken) then begin
    if cbRegion.Selected = nil then
      FAzureToken.Region := TAzureURLBuilder.RegionToString(TAzureAuthRegion.global)
    else
      FAzureToken.Region := cbRegion.Selected.Text;
  end;
end;

constructor TframeAccessKey.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Initalize;
end;

procedure TframeAccessKey.edtKeyChange(Sender: TObject);
begin
  GlowEffectTest.Enabled := False;
  Key := edtKey.Text;
end;

procedure TframeAccessKey.Initalize;
begin
  if cbRegion = nil then
    Exit;

  cbRegion.BeginUpdate;
  try
    cbRegion.Items.Clear;
    cbRegion.Items.Add('- Global -');
    for var Region := Low(TAzureAuthRegion) to High(TAzureAuthRegion) do begin
      var RegionName := TAzureURLBuilder.RegionToString(Region);
      if RegionName > '' then
        cbRegion.Items.Add(RegionName);
    end;
  finally
    cbRegion.ItemIndex := 0;
    cbRegion.EndUpdate;
  end;
end;

function TframeAccessKey.GetKey: string;
begin
  Result := edtKey.Text;
end;

function TframeAccessKey.GetRegion: string;
begin
  if cbRegion.Selected = nil then
    Result := TAzureURLBuilder.RegionToString(TAzureAuthRegion.global)
  else
    Result := cbRegion.Selected.Text;
end;

procedure TframeAccessKey.SetKey(const Value: string);
begin
  edtKey.Text := Value;
  if Assigned(FAzureToken) then
    FAzureToken.SubscriptionKey := Value;
end;

procedure TframeAccessKey.SetRegion(const Value: string);
begin
  if Value = '' then
    cbRegion.ItemIndex := cbRegion.Items.IndexOf(TAzureURLBuilder.RegionToString(TAzureAuthRegion.global))
  else
    cbRegion.ItemIndex := cbRegion.Items.IndexOf(Value);
end;

function TframeAccessKey.GetToken: TAzureToken;
begin
  if FAzureToken = nil then begin
    FAzureToken := TAzureToken.Create(Self,Region);
    FAzureToken.SubscriptionKey := Key;
  end;
  Result := FAzureToken;
end;


end.
