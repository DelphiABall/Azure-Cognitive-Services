unit frame.Dictionary;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Memo.Types, FMX.ListBox, FMX.Controls.Presentation, FMX.ScrollBox,
  FMX.Memo, FMX.Layouts, FMX.Edit,
  TokenShare, Azure.API3.Translator.Languages, Azure.API3.Translator.Dictionary;

type
  TFrameDictionary = class(TFrame)
    Layout1: TLayout;
    cbDictionary: TComboBox;
    loLookup: TLayout;
    memoLookup: TMemo;
    cbNewDictionaryLanguage: TComboBox;
    Layout3: TLayout;
    edtLookup: TEdit;
    Button1: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Splitter1: TSplitter;
    memoDictionary: TMemo;
    procedure cbDictionaryChange(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    FTokenProc : TGetAzureTokenProc;
    FLang : TAzureTranslatorLanguages;
    FDictionaryScope : TAzureTranslatorDictionaryScope;
  public
    { Public declarations }
    procedure Initialize(AGetAzureTokenProc : TGetAzureTokenProc);
  end;

implementation

{$R *.fmx}

uses System.TypInfo;

{ TFrameDictionary }

procedure TFrameDictionary.Button1Click(Sender: TObject);
begin
  var Dict := TAzureTranslatorDictionary.Create(Self);
  MemoLookup.BeginUpdate;
  try
    MemoLookup.Lines.Clear;
    Dict.AccessToken := FTokenProc;
    var R := Dict.Lookup(FLang.LanguageStringToID(cbDictionary.Selected.Text),
                         edtLookup.Text,
                         FLang.LanguageStringToID(cbNewDictionaryLanguage.Selected.Text));
    MemoLookup.Lines.Add('// Lookup');
    MemoLookup.Lines.Add('normalizedSource : '+R.normalizedSource);
    MemoLookup.Lines.Add('displaySource : '+R.displaySource);

    MemoLookup.Lines.Add('Translations : ('+Length(R.Translations).ToString+')');
    for var I := 0 to Pred(length(R.Translations)) do begin
      MemoLookup.Lines.Add(' ['+I.ToString+'] NormalizedTarget : '+R.Translations[I].normalizedTarget);
      MemoLookup.Lines.Add(' ['+I.ToString+'] DisplayTarget  : '+R.Translations[I].DisplayTarget);
      MemoLookup.Lines.Add(' ['+I.ToString+'] Confidence  : '+R.Translations[I].Confidence.ToString);
      MemoLookup.Lines.Add(' ['+I.ToString+'] Prefix Word  : '+R.Translations[I].PrefixWord);
      MemoLookup.Lines.Add(' ['+I.ToString+'] Part of Speach : '+GetEnumName(TypeInfo(TAzureTranslatorDictionary.TPartOfSpeachTag), Integer(R.Translations[I].PartOfSpeach)));
      MemoLookup.Lines.Add('');

      MemoLookup.Lines.Add(' ['+I.ToString+'] // Back Translations : '+Length(R.Translations[I].BackTranslations).ToString);
      for var BI := 0 to Pred(length(R.Translations[I].BackTranslations)) do begin
        MemoLookup.Lines.Add(' ['+I.ToString+'.'+BI.ToString+'] Normalized Text : '+R.Translations[I].BackTranslations[BI].NormalizedText);
        MemoLookup.Lines.Add(' ['+I.ToString+'.'+BI.ToString+'] Display Text  : '+R.Translations[I].BackTranslations[BI].DisplayText);
        MemoLookup.Lines.Add(' ['+I.ToString+'.'+BI.ToString+'] Examples  : '+R.Translations[I].BackTranslations[BI].NumExamples.ToString);
        MemoLookup.Lines.Add(' ['+I.ToString+'.'+BI.ToString+'] Frequence  : '+R.Translations[I].BackTranslations[BI].FrequencyCount.ToString);
        MemoLookup.Lines.Add('');
      end;

    end;

  finally
    MemoLookup.EndUpdate;
    Dict.Free;
  end;
end;

procedure TFrameDictionary.cbDictionaryChange(Sender: TObject);
begin
  Assert(cbDictionary.Selected <> nil);
  memoDictionary.Lines.Clear;
  memoDictionary.Lines.Add('// Dictionary');
  memoDictionary.Lines.Add('Original Language : '+cbDictionary.Selected.Text);
  var LangCode := FLang.LanguageStringToID(cbDictionary.Selected.Text);
  memoDictionary.Lines.Add('Original Language Code : '+LangCode);
  memoDictionary.Lines.Add('');
  memoDictionary.Lines.Add('Available Languages : ');

  var Dict := FDictionaryScope.DictionaryByID(LangCode);

  if Length(Dict.translations) = 0 then begin
    memoDictionary.Lines.Add(' - None - ');
    loLookup.Visible := False;
  end
  else begin
    loLookup.Visible := True;
    cbNewDictionaryLanguage.BeginUpdate;
    try
      cbNewDictionaryLanguage.Items.Clear;
      for var CurrLang in Dict.translations do begin
        memoDictionary.Lines.Add(CurrLang + ' - '+ FLang.LanguageIDToString(CurrLang));
        cbNewDictionaryLanguage.Items.Add(FLang.LanguageIDToString(CurrLang));
      end;
    finally
      cbNewDictionaryLanguage.EndUpdate;
    end;
  end;
end;

procedure TFrameDictionary.Initialize(AGetAzureTokenProc: TGetAzureTokenProc);
begin
  FTokenProc := AGetAzureTokenProc;

  if Assigned(FLang) then
    Exit;

  FLang := TAzureTranslatorLanguages.Create(Self);
  FLang.LoadToString(cbDictionary.Items,TAzureTranslatorLanguages.TAzureLanguageFormat.name);

  FDictionaryScope := TAzureTranslatorDictionaryScope.Create(Self);
end;

end.
