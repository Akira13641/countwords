
200 constant max-line
create line max-line allot  \ Buffer for read-line
wordlist constant counts    \ Hash table of words to count
variable num-uniques  0 num-uniques !

\ Allocate space for new string and copy bytes, return new string.
: copy-string ( addr u -- addr' u )
    dup >r  dup allocate throw
    dup >r  swap move  r> r> ;

\ Convert character to lowercase.
: to-lower ( C -- c )
    dup [char] A [ char Z 1+ ] literal within if
        32 +
    then ;

\ Convert string to lowercase in place.
: lower-in-place ( addr u -- )
    over + swap ?do
        i c@ to-lower i c!
    loop ;

\ Count given word in hash table.
: count-word ( addr u -- )
    2dup counts search-wordlist if
        \ Increment existing word
        >body 1 swap +!
        2drop
    else
        \ Insert new (copied) word with count 1
        copy-string
        2dup lower-in-place
        ['] create execute-parsing 1 ,
        1 num-uniques +!
    then ;

\ Scan till space and return remaining string and word.
: scan-word ( addr u -- rem-addr rem addr word-len )
    2dup bl scan
    2tuck rot swap - nip ;

\ Process a line by splitting into words.
: process-line ( addr u -- )
    begin
        bl skip        \ Skip spaces
        scan-word dup  \ Scan till space (or end)
    while
        count-word
    repeat
    2drop 2drop ;

\ Less-than for words (true if count is *greater* for reverse sort).
: count< ( nt1 nt2 -- )
    >r name>interpret >body @
    r> name>interpret >body @
    > ;

\ In-place merge sort taken from Rosetta Code:
\ https://rosettacode.org/wiki/Sorting_algorithms/Merge_sort#Forth
: merge-step ( right mid left -- right mid+ left+ )
    over @ over @ count< if
        over @ >r
        2dup - over dup cell+ rot move
        r> over !
        >r cell+ 2dup = if  rdrop dup  else  r>  then
    then
    cell+ ;

: merge ( right mid left -- right left )
    dup >r begin
        2dup >
    while
        merge-step
    repeat
    2drop r> ;

: mid ( l r -- mid )
    over - 2/ cell negate and + ;

: mergesort ( right left -- right left )
    2dup cell+ <= if
        exit
    then
    swap 2dup mid recurse rot recurse merge ;
 
: sort ( addr len -- )
    cells over + swap mergesort 2drop ;

\ Append word from wordlist to array at given offset.
: append-word ( addr offset nt -- addr offset+cell true )
    >r 2dup + r> swap !
    cell+ true ;

\ Show "word count" line for each word (unsorted).
: show-words ( -- )
    num-uniques @ cells allocate throw
    0 ['] append-word counts traverse-wordlist drop
    dup num-uniques @ sort
    num-uniques @ 0 ?do
        dup i cells + @
        dup name>string type space
        name>interpret >body @ . cr
    loop
    drop ;

: main ( -- )
    counts set-current  \ Define into counts wordlist
    begin
        line max-line stdin read-line throw
    while
        line swap process-line
    repeat
    drop
    show-words ;

main
bye
