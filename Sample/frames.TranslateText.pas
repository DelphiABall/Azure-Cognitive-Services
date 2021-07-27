unit frames.TranslateText;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.ListBox, FMX.Edit,
  FMX.Controls.Presentation, TokenShare, Azure.API3.Translator.Languages;

type
  TFrameTranslateText = class(TFrame)
    Label1: TLabel;
    Label2: TLabel;
    edtText: TEdit;
    cbTo: TComboBox;
    cbTo2: TComboBox;
    btnTranslate: TButton;
    MemoOutput: TMemo;
    procedure btnTranslateClick(Sender: TObject);
  private
    { Private declarations }
    FTokenProc : TGetAzureTokenProc;
    FLang : TAzureTranslatorLanguages;
  public
    { Public declarations }
    procedure Initialize(AGetAzureTokenProc : TGetAzureTokenProc);
  end;

implementation

{$R *.fmx}

uses Azure.API3.Translator;

procedure TFrameTranslateText.btnTranslateClick(Sender: TObject);
begin
  Assert(cbTo.Selected <> nil, 'Select language to translate to');

  var aTranslator := TAzureTranslator.Create(Self);
  try
    aTranslator.AccessToken := FTokenProc;
    var R : TAzureTranslator.TTranslateResult;
    if cbTo2.Selected = nil then
      R := aTranslator.Translate(edtText.Text,'',[FLang.LanguageStringToID(cbTo.Selected.Text,TAzureTranslatorLanguages.TAzureLanguageFormat.name)])
    else
      R := aTranslator.Translate(edtText.Text,'',[FLang.LanguageStringToID(cbTo.Selected.Text,TAzureTranslatorLanguages.TAzureLanguageFormat.name),
                                                  FLang.LanguageStringToID(cbTo2.Selected.Text,TAzureTranslatorLanguages.TAzureLanguageFormat.name)]);

    MemoOutput.Lines.Add('// Translation');
    MemoOutput.Lines.Add('Original Language : '+FLang.LanguageIDToString(R.OriginalLanguage));
    MemoOutput.Lines.Add('Original Language Code : '+R.OriginalLanguage);
    MemoOutput.Lines.Add('Original Language Score : '+R.OriginalLanguageScore.ToString);
    for var I := 0 to Pred(length(R.TranslatedTexts)) do begin
      MemoOutput.Lines.Add('');
      MemoOutput.Lines.Add('Translated Language['+I.ToString+'] Language : '+FLang.LanguageIDToString(R.TranslatedTexts[I].Language));
      MemoOutput.Lines.Add('Translated Language['+I.ToString+'] Language ID : '+R.TranslatedTexts[I].Language);
      MemoOutput.Lines.Add('Translated Language['+I.ToString+'] Text : '+R.TranslatedTexts[I].Text);
    end;

    MemoOutput.Lines.Add('// Auth Code');
    MemoOutput.Lines.Add(aTranslator.RESTRequest.Params.ParameterByName('Authorization').Value);
    MemoOutput.Lines.Add('// Response Data');
    MemoOutput.Lines.Add(R.Response);
  finally
    aTranslator.Free;
  end;
end;

procedure TFrameTranslateText.Initialize(AGetAzureTokenProc : TGetAzureTokenProc);
begin
  FTokenProc := AGetAzureTokenProc;
  if Assigned(FLang) then
    Exit;

  FLang := TAzureTranslatorLanguages.Create(Self);
  FLang.LoadToString(cbTo.Items,TAzureTranslatorLanguages.TAzureLanguageFormat.name);
  FLang.LoadToString(cbTo2.Items,TAzureTranslatorLanguages.TAzureLanguageFormat.name);
end;

end.
