unit utils;

{$mode Delphi}{$H+}{$J-}
{$ImplicitExceptions Off}
{$RangeChecks Off}

interface

uses lgHash;

type
  // The default of 255 characters we'd get if using a regular stack-allocated `ShortString` is too
  // much for our use case here, so we use a custom-defined type for the sake of efficiency.
  // String30 = String[30];
  FileFunc = procedure(var T: TextRec);
  PTextRec = ^TextRec;

  // Needed for a generic multiset we'll use 'ShortString' in later.
  TShortStringHelper = record
    class function HashCode(constref Val: ShortString): SizeInt; static; inline;
    class function Equal(constref L, R: ShortString): Boolean; static; inline;
    class function Less(constref L, R: ShortString): Boolean; static; inline;
  end;

procedure FastReadLowerStr(PT: PTextRec; var S: ShortString); inline;

implementation

class function TShortStringHelper.HashCode(constref Val: ShortString): SizeInt;
begin
  Result := TxxHash32LE.HashBuf(@Val[1], Ord(Val[0]));
end;

class function TShortStringHelper.Equal(constref L, R: ShortString): Boolean;
begin
  Result := Byte(L[0]) - Byte(R[0]) = 0;
  if Result then
    Result := CompareByte(L[1], R[1], PtrInt(L[0])) = 0;
end;

class function TShortStringHelper.Less(constref L, R: ShortString): Boolean;
begin
  Result := L < R;
end;

procedure FastReadLowerStr(PT: PTextRec; var S: ShortString);
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
