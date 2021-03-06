unit _bson;
{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF}
interface

uses
  SysUtils,
  Classes,
  Contnrs;
{
  BSON element format
  <type:byte> <c-str> <data>
  <data> below
}

const
  BSON_EOF = $00;
  BSON_FLOAT = $01; //double 8-byte float
  BSON_STRING = $02; //UTF-8 string
  BSON_DOC = $03; //embedded document
  BSON_ARRAY = $04; //bson document but using integer string for key
  BSON_BINARY = $05; //
  BSON_UNDEFINED = $06; //deprecated
  BSON_OBJECTID = $07; //
  BSON_BOOLEAN = $08; //false:$00, true:$01
  BSON_DATETIME = $09;
  BSON_NULL = $0A;
  BSON_REGEX = $0B; //
  BSON_DBPTR = $0C; //deprecated
  BSON_JS = $0D;
  BSON_SYMBOL = $0E;
  BSON_JSSCOPE = $0F;
  BSON_INT32 = $10;
  BSON_TIMESTAMP = $11;
  BSON_INT64 = $12;
  BSON_MINKEY = $FF;
  BSON_MAXKEY = $7F;
  {subtype}
  BSON_SUBTYPE_FUNC = $01;
  BSON_SUBTYPE_BINARY = $02;
  BSON_SUBTYPE_UUID = $03;
  BSON_SUBTYPE_MD5 = $05;
  BSON_SUBTYPE_USER = $80;
  {boolean constant}
  BSON_BOOL_FALSE = $00;
  BSON_BOOL_TRUE = $01;

const
  nullterm: AnsiChar = #0;

type
  EBSONException = class(Exception);
  TBSONObjectID = array[0..11] of byte;
  TBSONDocument = class;
  TBSONItem = class
  protected
    eltype: byte;
    elname: string;
    fnull: boolean;

    procedure WriteDouble(Value: real); virtual;
    procedure WriteInteger(Value: integer); virtual;
    procedure WriteInt64(Value: Int64); virtual;
    procedure WriteBoolean(Value: Boolean); virtual;
    procedure WriteString(Value: string); virtual;
    procedure WriteOID(Value: TBSONObjectID); virtual;
    procedure WriteDocument(Value: TBSONDocument); virtual;
    procedure WriteItem(idx: integer; Value: TBSONItem); virtual;

    function ReadDouble: real; virtual;
    function ReadInteger: integer; virtual;
    function ReadInt64: Int64; virtual;
    function ReadBoolean: Boolean; virtual;
    function ReadString: string; virtual;
    function ReadOID: TBSONObjectID; virtual;
    function ReadDocument: TBSONDocument; virtual;
    function ReadItem(idx: integer): TBSONItem; virtual;
  public
    constructor Create(etype: byte = BSON_NULL);

    procedure WriteStream(F: TStream); virtual;
    procedure ReadStream(F: TStream); virtual;

    function GetSize: longint; virtual;
    function ToString: string; virtual;

    function Clone: TBSONItem; virtual;

    function IsNull: boolean;
    property AsObjectID: TBSONObjectID read ReadOID write WriteOID;
    property AsInteger: integer read ReadInteger write WriteInteger;
    property AsDouble: real read ReadDouble write WriteDouble;
    property AsInt64: int64 read ReadInt64 write WriteInt64;
    property AsString: string read ReadString write WriteString;
    property AsBoolean: Boolean read ReadBoolean write WriteBoolean;
    property Items[idx: integer]: TBSONItem read ReadItem write WriteItem;
    property Name: string read elname;
  end;

  TBSONDocument = class
    FItems: TObjectList;
    function GetItem(i: integer): TBSONItem;
    function GetValue(name: string): TBSONItem;
    procedure SetValue(Name: string; Value: TBSONItem);
    function GetCount: integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure ReadStream(F: TStream);
    procedure WriteStream(F: TStream);

    procedure LoadFromFile(filename: string);
    procedure SaveToFile(filename: string);

    function IndexOf(name: string): integer;
    function GetSize: longint;
    function Clone: TBSONDocument;

    function ToString: string;
    function HasItem(itemname: string): Boolean;

    property Items[idx: integer]: TBSONItem read GetItem;
    property Values[Name: string]: TBSONItem read GetValue write SetValue;
    property Count: integer read GetCount;
  end;

  TBSONDoubleItem = class(TBSONItem)
    FData: real;

    procedure WriteDouble(AValue: real); override;
    function ReadDouble: real; override;
  public
    constructor Create(AValue: real = 0.0);
    function GetSize: longint; override;

    function ToString: string; override;
    function Clone: TBSONItem; override;

    procedure ReadStream(F: TStream); override;
    procedure WriteStream(F: TStream); override;
  end;

  TBSONIntItem = class(TBSONItem)
    FData: integer;

    procedure WriteInteger(AValue: integer); override;
    function ReadInteger: integer; override;
  public
    constructor Create(AValue: integer = 0);
    function GetSize: longint; override;

    function ToString: string; override;
    function Clone: TBSONItem; override;

    procedure ReadStream(F: TStream); override;
    procedure WriteStream(F: TStream); override;
  end;

  TBSONStringItem = class(TBSONItem)
  protected
    FData: string;

    procedure WriteString(AValue: string); override;
    function ReadString: string; override;
  public
    constructor Create(AValue: string = '');
    function GetSize: longint; override;

    function ToString: string; override;
    function Clone: TBSONItem; override;

    procedure ReadStream(F: TStream); override;
    procedure WriteStream(F: TStream); override;
  end;

  TBSONJSItem = class(TBSONStringItem)
  public
    constructor Create(AValue: string = '');

    function Clone: TBSONItem; override;
  end;

  TBSONSymbolItem = class(TBSONStringItem)
  public
    constructor Create(AValue: string = '');

    function Clone: TBSONItem; override;
  end;

  TBSONInt64Item = class(TBSONItem)
    FData: Int64;

    procedure WriteInt64(AValue: int64); override;
    function ReadInt64: Int64; override;
  public
    constructor Create(AValue: Int64 = 0);
    function GetSize: longint; override;

    function ToString: string; override;
    function Clone: TBSONItem; override;

    procedure ReadStream(F: TStream); override;
    procedure WriteStream(F: TStream); override;
  end;

  TBSONBooleanItem = class(TBSONItem)
    FData: Boolean;

    procedure WriteBoolean(AValue: Boolean); override;
    function ReadBoolean: Boolean; override;
  public
    constructor Create(AValue: Boolean = false);
    function GetSize: longint; override;

    function ToString: string; override;
    function Clone: TBSONItem; override;

    procedure ReadStream(F: TStream); override;
    procedure WriteStream(F: TStream); override;
  end;

  TBSONDocumentItem = class(TBSONItem)
    FData: TBSONDocument;
  public
    constructor Create;
    destructor Destroy; override;
    function GetSize: longint; override;

    function ToString: string; override;
    function Clone: TBSONItem; override;

    procedure ReadStream(F: TStream); override;
    procedure WriteStream(F: TStream); override;
  end;

  TBSONArrayItem = class(TBSONItem)
    FData: TBSONDocument;

    procedure WriteItem(idx: integer; item: TBSONItem); override;
    function ReadItem(idx: integer): TBSONItem; override;
  public
    constructor Create;
    destructor Destroy; override;
    function GetSize: longint; override;

    function ToString: string; override;
    function Clone: TBSONItem; override;

    procedure ReadStream(F: TStream); override;
    procedure WriteStream(F: TStream); override;
  end;

  TBSONDatetimeItem = class(TBSONItem)
    FData: TDatetime;
  public
    constructor Create(AValue: TDateTime);
    function GetSize: longint; override;

    function ToString: string; override;
    function Clone: TBSONItem; override;

    procedure ReadStream(F: TStream); override;
    procedure WriteStream(F: TStream); override;
  end;

  TBSONBinaryItem = class(TBSONItem)
    FLen: integer;
    FSubtype: byte;
    FData: Pointer;
  public
    constructor Create;
    destructor Destroy; override;
    function GetSize: longint; override;

    function ToString: string; override;
    function Clone: TBSONItem; override;

    procedure ReadStream(F: TStream); override;
    procedure WriteStream(F: TStream); override;
  end;

  TBSONObjectIDItem = class(TBSONItem)
    FData: TBSONObjectID;

    procedure WriteOID(AValue: TBSONObjectID); override;
    function ReadOID: TBSONObjectID; override;
  public
    constructor Create(AValue: string = '000000000000');
    function GetSize: longint; override;

    function ToString: string; override;
    function Clone: TBSONItem; override;

    procedure ReadStream(F: TStream); override;
    procedure WriteStream(F: TStream); override;
  end;

  TBSONDBRefItem = class(TBSONStringItem)
    FValue: TBSONObjectID;
    procedure WriteOID(AValue: TBSONObjectID); override;
    function ReadOID: TBSONObjectID; override;
  public
    constructor Create(AValue: string = ''; AData: string = '');
    function GetSize: longint; override;

    function ToString: string; override;
    function Clone: TBSONItem; override;

    procedure ReadStream(F: TStream); override;
    procedure WriteStream(F: TStream); override;
  end;

  TBSONRegExItem = class(TBSONItem)
    FPattern, FOptions: string;
  public
    constructor Create(APattern: string = ''; AOptions: string = '');
    function GetSize: longint; override;

    function ToString: string; override;
    function Clone: TBSONItem; override;

    procedure ReadStream(F: TStream); override;
    procedure WriteStream(F: TStream); override;
  end;

  TBSONScopedJSItem = class(TBSONItem)
    FLen: integer;
    FCode: string;
    FScope: TBSONDocument;
  public
    constructor Create;
    destructor Destroy; override;
    function GetSize: longint; override;

    function ToString: string; override;
    function Clone: TBSONItem; override;

    procedure ReadStream(F: TStream); override;
    procedure WriteStream(F: TStream); override;
  end;

function _ReadString(F: TStream): string;

implementation

uses
  DateUtils;

var
  buf: array[0..65535] of char;
  nullitem: TBSONItem;

function _ReadString(F: TStream): string;
var
  i: integer;
  c: Ansichar;
begin
  i := 0;
  repeat
    f.read(c, sizeof(char));
    buf[i] := c;
    inc(i);
  until c = nullterm;
  result := strpas(buf);
end;

{ TBSONDocument }

procedure TBSONDocument.Clear;
begin
  FItems.Clear;
end;

function TBSONDocument.Clone: TBSONDocument;
var
  i: integer;
begin
  Result := TBSONDocument.Create;
  for i := 0 to FItems.Count - 1 do begin
    Result.FItems.Add((FItems[i] as TBSONItem).Clone);
  end;
end;

constructor TBSONDocument.Create;
begin
  FItems := TObjectlist.Create(true);
end;

destructor TBSONDocument.Destroy;
begin
  FItems.Free;

  inherited Destroy;
end;

function TBSONDocument.GetCount: integer;
begin
  Result := FItems.Count;
end;

function TBSONDocument.GetItem(i: integer): TBSONItem;
begin
  if i in [0..(FItems.Count - 1)] then
    Result := (FItems[i] as TBSONItem)
  else
    Result := nullitem;
end;

function TBSONDocument.GetSize: longint;
var
  i: integer;
begin
  Result := 5;
  for i := 0 to FItems.Count - 1 do begin
    Result := Result + (FItems[i] as TBSONItem).GetSize;
  end;
end;

function TBSONDocument.GetValue(name: string): TBSONItem;
var
  i: integer;
begin
  result := nullitem;
  i := IndexOf(name);
  if i <> -1 then Result := (FItems[i] as TBSONItem);
end;

function TBSONDocument.HasItem(itemname: string): Boolean;
var
  i: integer;
begin
  Result := False;
  for i := 0 to FItems.Count - 1 do begin
    if (FItems[i] as TBSONItem).elname = itemname then begin
      Result := True;
      break;
    end;
  end;
end;

function TBSONDocument.IndexOf(name: string): integer;
var
  i: integer;
begin
  Result := -1;
  for i := 0 to FItems.Count - 1 do begin
    if (FItems[i] as TBSONItem).elname = name then begin
      Result := i;
      break;
    end;
  end;
end;

procedure TBSONDocument.LoadFromFile(filename: string);
var
  f: TFileStream;
begin
  f := TFileStream.Create(filename, fmOpenRead);
  try
    ReadStream(f);
  finally
    f.Free;
  end;
end;

procedure TBSONDocument.ReadStream(F: TStream);
var
  len: integer;
  elmtype: byte;
  elmname: string;
  lastItem: TBSONItem;
begin
  Clear;
  f.Read(len, sizeof(len));
  f.Read(elmtype, sizeof(byte));
  while elmtype <> BSON_EOF do begin
    elmname := _ReadString(f);
    case elmtype of
      BSON_ARRAY: lastItem := TBSONArrayItem.Create;
      BSON_BINARY: lastItem := TBSONBinaryItem.Create;
      BSON_DBPTR: lastItem := TBSONDBRefItem.Create;
      BSON_FLOAT: lastItem := TBSONDoubleItem.Create;
      BSON_INT32: lastItem := TBSONIntItem.Create;
      BSON_INT64: lastItem := TBSONInt64Item.Create;
      BSON_BOOLEAN: lastItem := TBSONBooleanItem.Create;
      BSON_STRING: lastItem := TBSONStringItem.Create;
      BSON_DOC: lastItem := TBSONDocumentItem.Create;
      BSON_JS: lastItem := TBSONJSItem.Create;
      BSON_JSSCOPE: lastItem := TBSONScopedJSItem.Create;
      BSON_OBJECTID: lastItem := TBSONObjectIDItem.Create;
      BSON_MINKEY: lastItem := TBSONItem.Create(BSON_MINKEY);
      BSON_MAXKEY: lastItem := TBSONItem.Create(BSON_MAXKEY);
      BSON_REGEX: lastItem := TBSONRegExItem.Create;
      BSON_SYMBOL: lastItem := TBSONSymbolItem.Create;
      BSON_DATETIME: lastItem := TBSONDateTimeItem.Create(0);
    else
      raise EBSONException.Create('unimplemented element handler ' + inttostr(elmtype));
    end;
    with lastItem do begin
      elname := elmname;
      ReadStream(f);
    end;
    FItems.Add(lastItem);
    f.Read(elmtype, sizeof(byte));
  end;
end;

procedure TBSONDocument.SaveToFile(filename: string);
var
  f: TFileStream;
begin
{$IFDEF FPC}
  f := TFileStream.Create(filename, fmOpenWrite);
{$ELSE}
  f := TFileStream.Create(FileCreate(filename));
{$ENDIF}
  try
    WriteStream(f);
  finally
    f.Free;
  end;
end;

procedure TBSONDocument.SetValue(Name: string; Value: TBSONItem);
var
  item: TBSONItem;
  idx: integer;
begin
  idx := IndexOf(name);
  if idx = -1 then begin
    Value.elname := Name;
    FItems.Add(Value)
  end
  else begin
    item := FItems[idx] as TBSONItem;
    if (item.eltype <> value.eltype) then begin
      FItems[idx] := Value;
      item.Free;
    end;
  end;
end;

function TBSONDocument.ToString: string;
var
  i, n: integer;
begin
  Result := '{';
  n := FItems.Count - 1;
  for i := 0 to n do begin
    Result := Result + (FItems[i] as TBSONItem).ToString;
    if i < n then Result := Result + ', ';
  end;
  Result := Result + '}';
end;

procedure TBSONDocument.WriteStream(F: TStream);
var
  dummy: integer;
  i: integer;
begin
  dummy := GetSize;
  f.write(dummy, sizeof(dummy));
  for i := 0 to FItems.Count - 1 do begin
    (FItems[i] as TBSONItem).WriteStream(f);
  end;
  f.Write(nullterm, sizeof(nullterm));
end;

{ TBSONDoubleItem }

function TBSONDoubleItem.Clone: TBSONItem;
begin
  Result := TBSONDoubleItem.Create(FData);
end;

constructor TBSONDoubleItem.Create(AValue: real);
begin
  eltype := BSON_FLOAT;
  FData := AValue;
end;

function TBSONDoubleItem.GetSize: longint;
begin
  Result := 2 + length(elname) + sizeof(FData);
end;

function TBSONDoubleItem.ReadDouble: real;
begin
  Result := FData;
end;

procedure TBSONDoubleItem.ReadStream(F: TStream);
begin
  f.Read(FData, sizeof(FData));
end;

function TBSONDoubleItem.ToString: string;
begin
  Result := format('"%s" : %f', [elname, FData]);
end;

procedure TBSONDoubleItem.WriteDouble(AValue: real);
begin
  FData := AValue;
end;

procedure TBSONDoubleItem.WriteStream(F: TStream);
begin
  f.Write(eltype, sizeof(byte));
  f.Write(elname[1], length(elname));
  f.Write(nullterm, sizeof(nullterm));
  f.Write(FData, sizeof(FData));
end;

{ TBSONIntItem }

function TBSONIntItem.Clone: TBSONItem;
begin
  Result := TBSONIntItem.Create(FData);
end;

constructor TBSONIntItem.Create(AValue: integer);
begin
  eltype := BSON_INT32;
  FData := AValue;
end;

function TBSONIntItem.GetSize: longint;
begin
  Result := 2 + length(elname) + sizeof(FData);
end;

function TBSONIntItem.ReadInteger: integer;
begin
  result := FData;
end;

procedure TBSONIntItem.ReadStream(F: TStream);
begin
  f.Read(fdata, sizeof(integer));
end;

function TBSONIntItem.ToString: string;
begin
  Result := format('"%s" : %d', [elname, FData]);
end;

procedure TBSONIntItem.WriteInteger(AValue: integer);
begin
  FData := AValue;
end;

procedure TBSONIntItem.WriteStream(F: TStream);
begin
  f.Write(eltype, sizeof(byte));
  f.Write(elname[1], length(elname));
  f.Write(nullterm, sizeof(nullterm));
  f.Write(FData, sizeof(FData));
end;

{ TBSONStringItem }

function TBSONStringItem.Clone: TBSONItem;
begin
  Result := TBSONStringItem.Create(FData);
end;

constructor TBSONStringItem.Create(AValue: string);
begin
  eltype := BSON_STRING;
  FData := AValue;
end;

function TBSONStringItem.GetSize: longint;
begin
  Result := 7 + length(elname) + length(fdata);
end;

procedure TBSONStringItem.ReadStream(F: TStream);
var
  len: integer;
begin
  f.Read(len, sizeof(integer));
  FData := _ReadString(F);
end;

function TBSONStringItem.ReadString: string;
begin
  Result := FData;
end;

function TBSONStringItem.ToString: string;
begin
  Result := format('"%s" : "%s"', [elname, FData]);
end;

procedure TBSONStringItem.WriteStream(F: TStream);
var
  len: integer;
begin
  len := length(FData) + 1;
  f.Write(eltype, sizeof(byte));
  f.Write(elname[1], length(elname));
  f.Write(nullterm, sizeof(nullterm));
  f.Write(len, sizeof(integer));
  f.Write(FData[1], length(FData));
  f.Write(nullterm, sizeof(nullterm));
end;

procedure TBSONStringItem.WriteString(AValue: string);
begin
  FData := AValue;
end;

{ TBSONInt64Item }

function TBSONInt64Item.Clone: TBSONItem;
begin
  Result := TBSONInt64Item.Create(FData);
end;

constructor TBSONInt64Item.Create(AValue: Int64);
begin
  eltype := BSON_INT64;
  FData := AValue;
end;

function TBSONInt64Item.GetSize: longint;
begin
  Result := 2 + length(elname) + sizeof(fdata);
end;

function TBSONInt64Item.ReadInt64: Int64;
begin
  Result := FData;
end;

procedure TBSONInt64Item.ReadStream(F: TStream);
begin
  f.Read(FData, sizeof(FData));
end;

function TBSONInt64Item.ToString: string;
begin
  Result := format('"%s" : %d', [elname, FData]);
end;

procedure TBSONInt64Item.WriteInt64(AValue: int64);
begin
  FData := AValue;
end;

procedure TBSONInt64Item.WriteStream(F: TStream);
begin
  f.Write(eltype, sizeof(byte));
  f.Write(elname[1], length(elname));
  f.Write(nullterm, sizeof(nullterm));
  f.Write(FData, sizeof(FData));
end;

{ TBSONBooleanItem }

function TBSONBooleanItem.Clone: TBSONItem;
begin
  Result := TBSONBooleanItem.Create(FData);
end;

constructor TBSONBooleanItem.Create(AValue: Boolean);
begin
  eltype := BSON_BOOLEAN;
  FData := AValue;
end;

function TBSONBooleanItem.GetSize: longint;
begin
  Result := 3 + length(elname);
end;

function TBSONBooleanItem.ReadBoolean: Boolean;
begin
  Result := FData;
end;

procedure TBSONBooleanItem.ReadStream(F: TStream);
var
  b: Byte;
begin
  f.Read(b, sizeof(byte));
  FData := b = BSON_BOOL_TRUE
end;

function TBSONBooleanItem.ToString: string;
begin
  Result := format('"%s" : %s', [elname, BoolToStr(FData, true)]);
end;

procedure TBSONBooleanItem.WriteBoolean(AValue: Boolean);
begin
  FData := AValue;
end;

procedure TBSONBooleanItem.WriteStream(F: TStream);
var
  boolb: byte;
begin
  f.Write(eltype, sizeof(byte));
  f.Write(elname[1], length(elname));
  f.Write(nullterm, sizeof(nullterm));
  if FData then
    boolb := BSON_BOOL_TRUE
  else
    boolb := BSON_BOOL_FALSE;
  f.Write(boolb, sizeof(byte));
end;

{ TBSONItem }

function TBSONItem.Clone: TBSONItem;
begin
  Result := TBSONItem.Create(eltype);
end;

constructor TBSONItem.Create(etype: byte);
begin
  fnull := true;
  eltype := etype;
end;

function TBSONItem.GetSize: longint;
begin
  Result := 0;
  if FNull then
    Result := 2 + Length(elName);
end;

function TBSONItem.IsNull: boolean;
begin
  Result := FNull;
end;

function TBSONItem.ReadBoolean: Boolean;
begin
  Result := False;
end;

function TBSONItem.ReadDocument: TBSONDocument;
begin
  Result := nil;
end;

function TBSONItem.ReadDouble: real;
begin
  Result := 0;
end;

function TBSONItem.ReadInt64: Int64;
begin
  Result := 0;
end;

function TBSONItem.ReadInteger: integer;
begin
  Result := 0;
end;

function TBSONItem.ReadItem(idx: integer): TBSONItem;
begin
  Result := nullitem;
end;

function TBSONItem.ReadOID: TBSONObjectID;
begin
  Result := Result;
end;

procedure TBSONItem.ReadStream(F: TStream);
begin

end;

function TBSONItem.ReadString: string;
begin
  Result := '';
end;

function TBSONItem.ToString: string;
begin
  Result := elname + ' : null';
end;

procedure TBSONItem.WriteBoolean(Value: Boolean);
begin

end;

procedure TBSONItem.WriteDocument(Value: TBSONDocument);
begin

end;

procedure TBSONItem.WriteDouble(Value: real);
begin

end;

procedure TBSONItem.WriteInt64(Value: Int64);
begin

end;

procedure TBSONItem.WriteInteger(Value: integer);
begin

end;

procedure TBSONItem.WriteItem(idx: integer; Value: TBSONItem);
begin

end;

procedure TBSONItem.WriteOID(Value: TBSONObjectID);
begin

end;

procedure TBSONItem.WriteStream(F: TStream);
begin
  if FNull then begin
    f.Write(eltype, sizeof(byte));
    f.Write(elname[1], length(elname));
    f.Write(nullterm, sizeof(nullterm));
  end;
end;

procedure TBSONItem.WriteString(Value: string);
begin

end;

{ TBSONDocumentItem }

function TBSONDocumentItem.Clone: TBSONItem;
var
  item: TBSONDocumentItem;
begin
  item := TBSONDocumentItem.Create;
  item.FData.Free;
  item.FData := FData.Clone;
  Result := item;
end;

constructor TBSONDocumentItem.Create;
begin
  FData := TBSONDocument.Create;
end;

destructor TBSONDocumentItem.Destroy;
begin
  FData.Free;

  inherited Destroy;
end;

function TBSONDocumentItem.GetSize: longint;
begin
  Result := 2 + length(elname) + FData.GetSize;
end;

procedure TBSONDocumentItem.ReadStream(F: TStream);
begin
  inherited;
  FData.ReadStream(f);
end;

function TBSONDocumentItem.ToString: string;
begin
  Result := format('"%s" : %s', [elname, FData.ToString]);
end;

procedure TBSONDocumentItem.WriteStream(F: TStream);
begin
  f.Write(eltype, sizeof(byte));
  f.Write(elname[1], length(elname));
  f.Write(nullterm, sizeof(nullterm));
  FData.WriteStream(f);
end;

{ TBSONArrayItem }

function TBSONArrayItem.Clone: TBSONItem;
var
  item: TBSONArrayItem;
begin
  item := TBSONArrayItem.Create;
  item.FData.Free;
  item.FData := FData.Clone;
  Result := Item;
end;

constructor TBSONArrayItem.Create;
begin
  eltype := BSON_ARRAY;
  FData := TBSONDocument.Create;
end;

destructor TBSONArrayItem.Destroy;
begin
  FData.Free;

  inherited Destroy;
end;

function TBSONArrayItem.GetSize: longint;
begin
  Result := 2 + length(elname) + FData.GetSize;
end;

function TBSONArrayItem.ReadItem(idx: integer): TBSONItem;
begin
  Result := FData.Items[idx];
end;

procedure TBSONArrayItem.ReadStream(F: TStream);
begin
  FData.ReadStream(F);
end;

function TBSONArrayItem.ToString: string;
var
  i, n: integer;
  tmp, t2: string;
begin
  tmp := '';
  n := FData.Count - 1;
  for i := 0 to n do begin
    t2 := FData.Items[i].ToString;
    tmp := tmp + Copy(t2, Pos(':', t2) + 1, length(t2));
    if i < n then tmp := tmp + ', ';
  end;
  Result := format('"%s" : [%s]', [elname, tmp]);
end;

procedure TBSONArrayItem.WriteItem(idx: integer; item: TBSONItem);
begin
  inherited;
  FData.SetValue(IntToStr(idx), item);
end;

procedure TBSONArrayItem.WriteStream(F: TStream);
begin
  f.Write(eltype, sizeof(byte));
  f.Write(elname[1], length(elname));
  f.Write(nullterm, sizeof(nullterm));
  FData.WriteStream(f);
end;

{ TBSONDatetimeItem }

function TBSONDatetimeItem.Clone: TBSONItem;
begin
  Result := TBSONDateTimeItem.Create(FData);
end;

constructor TBSONDatetimeItem.Create(AValue: TDateTime);
begin
  eltype := BSON_DATETIME;
  FData := AValue;
end;

function TBSONDatetimeItem.GetSize: longint;
begin
  result := 2 + length(elname) + sizeof(int64);
end;

procedure TBSONDatetimeItem.ReadStream(F: TStream);
var
  data: int64;
begin
  f.Read(data, sizeof(int64));
  FData := UnixToDateTime(data);
end;

function TBSONDatetimeItem.ToString: string;
begin
  Result := format('"%s" : %s', [elname, DateTimeToStr(FData)]);
end;

procedure TBSONDatetimeItem.WriteStream(F: TStream);
var
  data: Int64;
begin
  data := DateTimeToUnix(FData);
  f.Write(eltype, sizeof(byte));
  f.Write(elname[1], length(elname));
  f.Write(nullterm, sizeof(nullterm));
  f.Write(Data, sizeof(int64));
end;

{ TBSONJSItem }

function TBSONJSItem.Clone: TBSONItem;
begin
  Result := TBSONJSItem.Create(FData);
end;

constructor TBSONJSItem.Create(AValue: string);
begin
  inherited Create(AValue);
  eltype := BSON_JS;
end;

{ TBSONObjectIDItem }

function TBSONObjectIDItem.Clone: TBSONItem;
begin
  Result := TBSONObjectIDItem.Create;
  Result.AsObjectID := FData;
end;

constructor TBSONObjectIDItem.Create(AValue: string);
var
  i: integer;
begin
  eltype := BSON_OBJECTID;
  if length(AValue) = 12 then
    for i := 0 to 11 do
      FData[i] := StrToInt(AValue[i + 1]);
end;

function TBSONObjectIDItem.GetSize: longint;
begin
  result := 2 + length(elname) + 12;
end;

function TBSONObjectIDItem.ReadOID: TBSONObjectID;
begin
  Result := FData;
end;

procedure TBSONObjectIDItem.ReadStream(F: TStream);
begin
  f.Read(FData[0], 12);
end;

function TBSONObjectIDItem.ToString: string;
begin
  Result := format('"%s" : ObjectID("%s%s%s%s%s%s%s%s%s%s%s%s")', [elname,
    IntToHex(FData[0], 2),
      IntToHex(FData[1], 2),
      IntToHex(FData[2], 2),
      IntToHex(FData[3], 2),
      IntToHex(FData[4], 2),
      IntToHex(FData[5], 2),
      IntToHex(FData[6], 2),
      IntToHex(FData[7], 2),
      IntToHex(FData[8], 2),
      IntToHex(FData[9], 2),
      IntToHex(FData[10], 2),
      IntToHex(FData[11], 2)
      ]);
end;

procedure TBSONObjectIDItem.WriteOID(AValue: TBSONObjectID);
begin
  FData := AValue;
end;

procedure TBSONObjectIDItem.WriteStream(F: TStream);
begin
  f.Write(eltype, sizeof(byte));
  f.Write(elname[1], length(elname));
  f.Write(nullterm, sizeof(nullterm));
  f.Write(FData[0], 12);
end;

{ TBSONRegExItem }

function TBSONRegExItem.Clone: TBSONItem;
begin
  Result := TBSONRegExItem.Create(FPattern, FOptions);
end;

constructor TBSONRegExItem.Create(APattern, AOptions: string);
begin
  FPattern := APattern;
  FOptions := AOptions;
  eltype := BSON_REGEX;
end;

function TBSONRegExItem.GetSize: longint;
begin
  result := 2 + length(elname) + 1 + length(FPattern) + 1 + length(FOptions);
end;

procedure TBSONRegExItem.ReadStream(F: TStream);
begin
  FPattern := _ReadString(f);
  FOptions := _ReadString(f);
end;

function TBSONRegExItem.ToString: string;
begin
  Result := format('"%s" : "%s" "%s"', [elname, FPattern, FOptions]);
end;

procedure TBSONRegExItem.WriteStream(F: TStream);
begin
  f.Write(eltype, sizeof(byte));
  f.Write(elname[1], length(elname));
  f.Write(nullterm, sizeof(nullterm));
  f.Write(FPattern[1], length(FPattern));
  f.Write(nullterm, sizeof(nullterm));
  f.Write(FOptions[1], length(FOptions));
  f.Write(nullterm, sizeof(nullterm));
end;

{ TBSONBinaryItem }

function TBSONBinaryItem.Clone: TBSONItem;
var
  ms: TMemoryStream;
begin
  Result := TBSONBinaryItem.Create;
  ms := TMemoryStream.Create;
  try
    WriteStream(ms);
    ms.Seek(0, soFromBeginning);
    Result.ReadStream(ms);
  finally
    ms.Free;
  end;
end;

constructor TBSONBinaryItem.Create;
begin
  FLen := 0;
  FData := nil;
  FSubtype := BSON_SUBTYPE_USER;
  eltype := BSON_BINARY;
end;

destructor TBSONBinaryItem.Destroy;
begin
  if FLen <> 0 then
    FreeMem(FData);

  inherited Destroy;
end;

function TBSONBinaryItem.GetSize: longint;
begin
  result := 2 + length(elname) + 4 + 1 + FLen;
end;

procedure TBSONBinaryItem.ReadStream(F: TStream);
begin
  f.Read(FLen, sizeof(integer));
  f.Read(FSubtype, sizeof(byte));
  GetMem(FData, FLen);
  f.Read(FData^, Flen);
end;

function TBSONBinaryItem.ToString: string;
begin
  Result := format('"%s" : %s', [elname, 'Binary']);
end;

procedure TBSONBinaryItem.WriteStream(F: TStream);
begin
  f.Write(eltype, sizeof(byte));
  f.Write(elname[1], length(elname));
  f.Write(nullterm, sizeof(nullterm));

  f.Write(FLen, sizeof(integer));
  f.Write(FSubtype, sizeof(byte));
  f.Write(FData^, FLen);
end;


{ TBSONScopedJSItem }

function TBSONScopedJSItem.Clone: TBSONItem;
var
  item: TBSONScopedJSItem;
begin
  item := TBSONScopedJSItem.Create;
  item.FCode := FCode;
  item.FLen := FLen;
  item.FScope.Free;
  item.FScope := FScope.Clone;
  Result := item;
end;

constructor TBSONScopedJSItem.Create;
begin
  eltype := BSON_JSSCOPE;
  FScope := TBSONDocument.Create;
end;

destructor TBSONScopedJSItem.Destroy;
begin
  FScope.Free;

  inherited Destroy;
end;

function TBSONScopedJSItem.GetSize: longint;
begin
  result := 2 + length(elname) + 4 + length(fcode) + 1 + FScope.GetSize;
end;

procedure TBSONScopedJSItem.ReadStream(F: TStream);
begin
  f.Read(Flen, sizeof(integer));
  FCode := _ReadString(f);
  FScope.ReadStream(f);
end;

function TBSONScopedJSItem.ToString: string;
begin
  Result := format('"%s" : "%s" %s', [elname, FCode, FScope.ToString]);
end;

procedure TBSONScopedJSItem.WriteStream(F: TStream);
begin
  f.Write(eltype, sizeof(byte));
  f.Write(elname[1], length(elname));
  f.Write(nullterm, sizeof(nullterm));
  FLen := FScope.GetSize + 5 + length(FCode);
  f.Write(FLen, sizeof(integer));
  f.Write(FCode[1], length(FCode));
  f.Write(nullterm, sizeof(nullterm));
  FScope.WriteStream(f);
end;

{ TBSONSymbolItem }

function TBSONSymbolItem.Clone: TBSONItem;
begin
  Result := TBSONSymbolItem.Create(FData);
end;

constructor TBSONSymbolItem.Create(AValue: string);
begin
  eltype := BSON_SYMBOL;
end;

{ TBSONDBRefItem }

function TBSONDBRefItem.Clone: TBSONItem;
begin
  Result := TBSONDBRefItem.Create(FData);
  Result.AsObjectID := FValue;
end;

constructor TBSONDBRefItem.Create(AValue, AData: string);
var
  i: integer;
begin
  inherited Create(AValue);
  eltype := BSON_DBPTR;
  if length(AData) = 12 then
    for i := 0 to 11 do
      FValue[i] := StrToInt(AData[1 + i]);
end;

function TBSONDBRefItem.GetSize: longint;
begin
  result := 3 + length(elname) + length(FData) + 12;
end;

function TBSONDBRefItem.ReadOID: TBSONObjectID;
begin
  Result := FValue;
end;

procedure TBSONDBRefItem.ReadStream(F: TStream);
begin
  inherited;
  f.Read(FValue[0], 12);
end;

function TBSONDBRefItem.ToString: string;
begin
  Result := format('"%s" : DBRef("%s", "%s%s%s%s%s%s%s%s%s%s%s%s")', [elname,
    FData,
      IntToHex(FValue[0], 2),
      IntToHex(FValue[1], 2),
      IntToHex(FValue[2], 2),
      IntToHex(FValue[3], 2),
      IntToHex(FValue[4], 2),
      IntToHex(FValue[5], 2),
      IntToHex(FValue[6], 2),
      IntToHex(FValue[7], 2),
      IntToHex(FValue[8], 2),
      IntToHex(FValue[9], 2),
      IntToHex(FValue[10], 2),
      IntToHex(FValue[11], 2)
      ]);
end;

procedure TBSONDBRefItem.WriteOID(AValue: TBSONObjectID);
begin
  FValue := AValue;
end;

procedure TBSONDBRefItem.WriteStream(F: TStream);
begin
  inherited;
  f.Write(FValue[0], 12);
end;

initialization
  nullitem := TBSONItem.Create;
finalization
  nullitem.Free;
end.

