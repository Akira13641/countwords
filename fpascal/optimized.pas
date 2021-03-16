program optimized;

// Delphi-syntax mode allows for generics without using the 'generic' and 'specialize' keywords.
{$mode Delphi}{$H+}{$J-}
// By default Free Pascal generates exception handling code to pad certain things,
// which for our extremely performance-focused purposes here is not desirable.
{$ImplicitExceptions Off}
// Suppresses a spurious warning about a static array buffer we use below not being "initialized",
// which is in no way necessary in this particular context.
{$Warn 5058 Off}

uses
  // A few speed-optimized IO helper routines that do less "safety checks" internally
  // than the defaults provided by the language implementation.
  utils,
  // Units from an excellent third-party generics library called 'LGenerics':
  // https://github.com/avk959/LGenerics
  lgArrayHelpers,
  lgHashMultiSet;
  
  // `WriteLn` has a lot of complex internal formatting mechanics, since it's kind of a magic variadic
  // builtin and not even a "real" method at all, and so tends not to be quite as fast as the system
  // libc's `printf` implementation when called a large number of times in a row, particularly on Linux.
  {$if defined(Unix)}
    procedure printf(const Format: PChar); cdecl; varargs; external 'c' name 'printf';
  {$else if defined(Windows)}
    procedure printf(const Format: PChar); cdecl; varargs; external 'msvcrt' name 'printf';
  {$endif}    

// Some type aliases for the sake of convenience, and a sorting comparator implementation.
type
  TStrCounter = TGLiteHashMultiSetLP<ShortString, ShortString>.TMultiSet;
  TStrEntry = TStrCounter.TEntry;
  PStrEntry = ^TStrEntry;
  
  TStrEntryHelper = record
    class function Less(constref L, R: TStrEntry): Boolean; static; inline;
  end;
  
  // The static sorting method we use later expects a function called `Less` to exist
  // with a signature that matches the following (for whatever `T` that `L` and `R might be).
  class function TStrEntryHelper.Less(constref L, R: TStrEntry): Boolean;
  begin
    // Force the largest-to-smallest order that we want.
    Result := L.Count > R.Count;
  end;
  
type
  THelper = TGBaseArrayHelper<TStrEntry, TStrEntryHelper>;

var
  InBuf: array[0..65535] of Byte;
  PIn: PTextRec;
  S: ShortString = '';
  SC: TStrCounter;
  E: TStrEntry;
  EA: TStrCounter.TEntryArray;

begin
  // `Input` and `Output` are `threadvars`, so if you don't take pointers directly to them the
  // compiler will continuously generate code that goes and "gets" them anytime you do anything
  // IO related that implicitly involves them.
  PIn := @Input;
  // This is equivalent to an inlined version of calling `SetTextBuf(PIn^, InBuf)`.
  with PIn^ do begin
    BufPtr := @InBuf;
    BufSize := 65536;
    BufPos := 0;
    BufEnd := 0;
  end;
  // All we have to do is keep adding the strings to the multiset, as it automatically generates
  // the counts we want in the process.
  while True do begin
    // Doing `while True` with the direct check below is a bit
    // faster than doing `while not EOF(PIn)`.
    if PIn^.BufPos >= PIn.BufEnd then begin
      FileFunc(PIn^.InOutFunc)(PIn^);
      if PIn^.BufPos >= PIn^.BufEnd then Break;
    end;
    FastReadLowerStr(PIn, S);
    if S[0] = #0 then Continue;
    SC.Add(S);
  end;
  // Get a contiguous array of all the string / count pairs.
  EA := SC.ToEntryArray();
  // Sort the array.
  THelper.Sort(EA);
  // Display the array.
  for E in EA do with E do
    printf('%s %d'#10, @Key[1], Count);
end.
