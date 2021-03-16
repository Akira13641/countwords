program Optimized;

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
  FastIO,
  // Units from an excellent third-party generics library called 'LGenerics':
  // https://github.com/avk959/LGenerics
  lgArrayHelpers,
  lgHashMultiSet;

// Some type aliases for the sake of convenience, and a sorting comparator implementation.
type
  TStrCounter = TGLiteHashMultiSetLP<ShortString, ShortString>.TMultiSet;
  TStrEntry = TStrCounter.TEntry;
  
  TStrEntryHelper = record
    class function Less(constref L, R: TStrEntry): Boolean; static; inline;
  end;
  
  // The static sorting method we use later expects a function called `Less` with a signature
  // that matches the following (for any `T` that `L` and `R) might be.
  class function TStrEntryHelper.Less(constref L, R: TStrEntry): Boolean;
  begin
    // Force the largest-to-smallest order that we want
    Result := L.Count > R.Count;
  end;
  
type
  THelper = TGBaseArrayHelper<TStrEntry, TStrEntryHelper>;

var
  InBuf: array[0..65534] of Byte;
  PIn: PTextRec;
  POut: PText;
  S: ShortString = '';
  SC: TStrCounter;
  E: TStrEntry;
  EA: TStrCounter.TEntryArray;

begin
  // `Input` and `Output` are `threadvars`, so if we don't take pointers directly to them the
  // compiler will continuously generate code that goes and "gets" them anytime we do anything
  // IO related that implicitly involves them.
  PIn := @Input;
  FastSetTextBuf(PIn, InBuf, 65535);
  POut := @Output;
  // All we have to do is keep adding the strings to the multiset, as it automatically generates
  // the counts we want in the process.
  while not FastCheckEOF(PIn) do begin
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
    // Doing it this way instead of using `WriteLn` will force Unix newlines even on Windows, so as
    // to guarantee 'output.txt' matches with the original in terms of file size on all platforms.
    Write(POut^, Key, ' ', Count, #10);
end.
