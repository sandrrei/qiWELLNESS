unit unitUpdateList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Grids, HTTPSend, fphttpclient, fpjson, jsonparser, Windows, LCLIntf ;

const
   //Types of lists
   LIST_ION_SUBSTANCES = 1;
   LIST_EAV_PATHS = 2;
   LIST_EAP_PATHS = 3;
   LIST_CATALOG = 4;

type

  { TFormUpdateList }

  TFormUpdateList = class(TForm)
    ButtonUpdate: TButton;
    ButtonCancel: TButton;
    ButtonEdit: TButton;
    ButtonSave: TButton;
    Panel1: TPanel;
    StringGrid: TStringGrid;

    procedure ButtonCancelClick(Sender: TObject);
    procedure ButtonEditClick(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
    procedure ButtonUpdateClick(Sender: TObject);


  private
     ListType : integer;
     JSONData : TJSONData;

  public
    procedure OpenWindowUpdateList( TypeOfList : Integer);
    procedure CreateDllLibraries();
    procedure ConnectRESTInterface(Url: String);
    function  JSON2String( TypeOfList : Integer; _JSONData: TJSONData): string;

    type
         TList = record
         Title,  FileName: string[50];
         Url : string [255];
         RestURL : string [255];
         FieldCount : integer;
         FieldNames : array[1..10] of string[50];
         FieldJsonPath : array[1..10] of string[50];
    end;

    const


      LISTS_DEF : array[1..3] of TList = (
             (
              Title : 'Iontophoresis substances'; FileName : 'iontoporesis.txt';
              Url : 'https://biotronics.eu/iontophoresis-substances';
              RestURL :'https://biotronics.eu/iontophoresis-substances/rest?_format=json';
              FieldCount : 4;
              FieldNames :    ('Substance','Active electrode','Molar mass','Valence','','','','','','');
              FieldJsonPath : ('.title[0].value','.field_active_electrode[0].value','field_mol_mass[0].value','field_valence[0].value','','','','','','')
              ),

              (Title : 'xxx'; FileName : 'xxx.txt';
              Url : 'https://biotronics.eu/iontophoresis-substances';
              RestURL :'https://biotronics.eu/iontophoresis-substances/rest?_format=json';
              FieldCount : 1;
              FieldNames :    ('Substance','Active electrode','Molar mass','Valence','','','','','','');
              FieldJsonPath : ('.title[0].value','.field_active_electrode[0].value','field_mol_mass[0].value','field_valence[0].value','','','','','','')
              ),

              (Title : 'EAP therapies'; FileName : 'EAPtherapies.txt';
              Url : 'https://biotronics.eu/eap-therapies';
              RestURL :'https://biotronics.eu/eap-therapies/rest?_format=json';
              FieldCount : 2;
              FieldNames :    ('EAP therapy name','BAPs','Link','','','','','','','');
              FieldJsonPath : ('.title[0].value','.field_baps[0].value','','field_valence[0].value','','','','','','')
              )

       ) ;

      TEMPORARY_FILE = '~temp.txt';

   var

     SourceRestUrl, DestinationListFile, TemporaryListFile   : string;


  end;

var
  FormUpdateList: TFormUpdateList;

implementation

{$R *.lfm}

{ TFormUpdateList }


uses ShellApi,UrlMon,unitMain ;

function TFormUpdateList.JSON2String( TypeOfList : Integer; _JSONData: TJSONData) : string;
var s : string;
    i,col : integer;
begin
  s:='';

  for col:=1 to LISTS_DEF[ TypeOfList ].FieldCount do begin

    s := s + '"' +LISTS_DEF[ TypeOfList ].FieldNames[col] + '"' ;

    if col= LISTS_DEF[ TypeOfList ].FieldCount then Break;

    s := s + ', ';

  end;
    s := s + #13#10;


  try
    for i:= 0 to _JSONData.Count-1 do begin
       for col:=1 to LISTS_DEF[ TypeOfList ].FieldCount do begin

         s:= s + '"'+_JSONData.FindPath(
                                   '['+IntToStr(i)+']' +
                                   LISTS_DEF[ TypeOfList ].FieldJsonPath[col]
                                   ).AsString+'"';

         if col < LISTS_DEF[ TypeOfList ].FieldCount then  s := s +', ';

       end;

       s := s + #13#10;

    end;

  finally
     //do nothing;

  end;



  result := s;
end;

procedure TFormUpdateList.ConnectRESTInterface(Url: String);
var
  HTTPClient: TFPHttpClient;
  Content : string;



begin
  HTTPClient:=TFPHttpClient.Create(Nil);

  //MemoEditList.Lines.Clear;

  try
     CreateDllLibraries();
     //HTTPClient.AddHeader('User-Agent','qiwellness');  //For GITHUB only
     Content:=HTTPClient.Get(Url);

     JSONData:=GetJSON(Content);


     //MemoEditList.Lines.add(Content);

  finally
    HTTPClient.Free;
  end;
end;

procedure TFormUpdateList.CreateDllLibraries();
var
  AppFolder: string;
  ResourceStream: TResourceStream;

begin
  //Create OpenSSL libraries from exe resource

  AppFolder := ExtractFilePath(Application.ExeName);

  if not FileExists(AppFolder + 'libeay32.dll') then begin
    try
      ResourceStream := TResourceStream.Create(HInstance, 'LIBEAY32', RT_RCDATA);
      ResourceStream.Position := 0;
      ResourceStream.SaveToFile( AppFolder + 'libeay32.dll' );

    finally
      ResourceStream.Free;
    end;
end;

  if not FileExists(AppFolder + 'ssleay32.dll') then begin
    try
      ResourceStream := TResourceStream.Create(HInstance, 'SSLEAY32', RT_RCDATA);
      ResourceStream.Position := 0;
      ResourceStream.SaveToFile( AppFolder + 'ssleay32.dll' );

    finally
      ResourceStream.Free;
    end;
  end;

end;

procedure TFormUpdateList.OpenWindowUpdateList( TypeOfList : Integer);
begin

  StringGrid.Clear;

  Self.Caption := LISTS_DEF[TypeOfList].Title;
  ListType := TypeOfList;

  DestinationListFile := ExtractFilePath(Application.ExeName) + LISTS_DEF[TypeOfList].FileName;
  TemporaryListFile   := ExtractFilePath(Application.ExeName) + TEMPORARY_FILE;

  //SourceRestUrl       := LISTS_DEF[TypeOfList].RestUrl;
  //frmMain.StringGridIonTherapy.SaveToCSVFile(TemporaryListFile);

  if SysUtils.FileExists(DestinationListFile) then
     StringGrid.LoadFromCSVFile(DestinationListFile)
  else begin ;

  end;

  StringGrid.AutoSizeColumns;
  Self.ShowModal();

end;

function DownLoadInternetFile(Source, Dest : String): Boolean;
begin
  try
    Result := URLDownloadToFile(nil,PChar(Source),PChar(Dest),0,nil) = 0
  except
    Result := False;
  end;
end;



procedure TFormUpdateList.ButtonUpdateClick(Sender: TObject);
var s : string;
    f : TextFile;
begin

  ConnectRESTInterface(LISTS_DEF[ListType].RestURL);

  s:=JSON2String( ListType, JSONData);


  try
     AssignFile(f,TemporaryListFile);
     Rewrite(f);

     {$I-}
          Writeln(f,s);
     {$I+}

  finally

     CloseFile(f);

  end;

  StringGrid.LoadFromCSVFile(TemporaryListFile);
  StringGrid.AutoSizeColumns;



end;

procedure TFormUpdateList.ButtonEditClick(Sender: TObject);
begin
  // Open list site
  OpenUrl(LISTS_DEF[ListType].Url);
end;

procedure TFormUpdateList.ButtonCancelClick(Sender: TObject);
begin
  Self.Close;
end;



procedure TFormUpdateList.ButtonSaveClick(Sender: TObject);
begin

  StringGrid.SaveToCSVFile(DestinationListFile);
  Self.Close;

end;

end.
