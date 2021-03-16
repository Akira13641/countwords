unit FastIO;

{$mode Delphi}{$H+}{$J-}
{$ImplicitExceptions Off}
{$RangeChecks Off}

interface

type
  FileFunc = procedure(var T: TextRec);
  PTextRec = ^TextRec;

procedure FastReadLowerStr(PT: PTextRec; var S: ShortString); inline;
function FastCheckEOF(PT: PTextRec): Boolean; inline;

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
      #65..#90: C := Char(Byte(C) or Byte(Byte(True) shl 5));
    end;
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
  {$ifndef Linux}
    // The next line is always false on Linux, so don't bother with it there.
    Result := CtrlZMarksEOF and (PT^.BufPtr^[PT^.BufPos] = #26);
  {$else}
    Result := False;
  {$endif}
end;

end.
