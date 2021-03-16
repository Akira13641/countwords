unit utils;

{$mode Delphi}{$H+}{$J-}
{$ImplicitExceptions Off}
{$RangeChecks Off}

interface

type
  FileFunc = procedure(var T: TextRec);
  PTextRec = ^TextRec;

procedure FastReadLowerStr(PT: PTextRec; var S: ShortString); inline;

implementation

procedure FastReadLowerStr(PT: PTextRec; var S: ShortString);
var
  C: Char;
  P: PChar;
begin
  P := @S[1];
  S[0] := #0;
  while True do begin
    if PT^.BufPos >= PT^.BufEnd then
      FileFunc(PT^.InOutFunc)(PT^);
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
