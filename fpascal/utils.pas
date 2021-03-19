unit utils;

{$mode Delphi}{$H+}{$J-}
{$ImplicitExceptions Off}
{$RangeChecks Off}

interface

uses lgHash;

type
  // The default of 255 characters we'd get if using a regular stack-allocated `ShortString` is too
  // much for our use case here, so we use a custom-defined type for the sake of efficiency. It's
  // declared as a normal array of char instead of `String[80]` to work around an FPC 3.2.0 bug when
  // trying to use it as a generic parameter.
  String80 = String[80];
  FileFunc = procedure(var T: TextRec);
  PTextRec = ^TextRec;

  // Needed for a generic multiset we'll use 'String80' in later.
  TString80Helper = record
    class function HashCode(constref Val: String80): SizeInt; static; inline;
    class function Equal(constref L, R: String80): Boolean; static; inline;
    class function Less(constref L, R: String80): Boolean; static; inline;
  end;

procedure FastReadLowerStr(PT: PTextRec; var S: String80); inline;

implementation

class function TString80Helper.HashCode(constref Val: String80): SizeInt;
begin
  Result := TxxHash32LE.HashBuf(@Val[1], Ord(Val[0]));
end;

class function TString80Helper.Equal(constref L, R: String80): Boolean;
begin
  Result := Byte(L[0]) - Byte(R[0]) = 0;
  if Result then
    Result := CompareByte(L[1], R[1], PtrInt(L[0])) = 0;
end;

class function TString80Helper.Less(constref L, R: String80): Boolean;
begin
  Result := L < R;
end;

procedure FastReadLowerStr(PT: PTextRec; var S: String80);
var
  C: Char;
  P: PChar;
begin
  P := @S[1];
  S[0] := #0;
  while True do begin
    if PT^.BufPos >= PT^.BufEnd then FileFunc(PT^.InOutFunc)(PT^);
    C := PT^.BufPtr^[PT^.BufPos];
    Inc(PT^.BufPos);
    case C of
      #10, #32: Break;
      #65..#90: C := Char(Byte(C) or 32);
    end;
    P^ := C;
    Inc(P);
    Inc(S[0]);
  end;
end;

end.
