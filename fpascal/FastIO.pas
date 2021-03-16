unit FastIO;

{$mode Delphi}{$H+}{$J-}
{$ImplicitExceptions Off}
{$RangeChecks Off}

interface

type
  FileFunc = procedure(var T: TextRec);
  PTextRec = ^TextRec;

procedure FastLowerCase(PS: PChar); inline;
procedure FastReadStr(PT: PTextRec; var S: ShortString); inline;
function FastCheckEOF(PT: PTextRec): Boolean; inline;

implementation

procedure FastLowerCase(PS: PChar);
var
  I: PtrInt;
  P: PChar absolute PS;
begin
  for I := 1 to Ord((P - 1)^) do begin
    if P^ in ['A'..'Z'] then
      P^ := Char(Byte(P^) + 32);
    Inc(P);
  end;
end;

procedure FastReadStr(PT: PTextRec; var S: ShortString);
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
    if C in [#10, #32] then Break;
    P^ := C;
    Inc(P);
    Inc(S[0]);
  end;
end;

function FastCheckEOF(PT: PTextRec): Boolean;
begin
  if PT^.BufPos >= PT^.BufEnd then begin
    FileFunc(PT^.InOutFunc)(PT^);
    if PT^.BufPos >= PT^.BufEnd then
      Exit(True);
  end;
  Result := CtrlZMarksEOF and (PT^.BufPtr^[PT^.BufPos] = #26);
end;

end.
