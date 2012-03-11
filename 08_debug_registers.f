
.(  including 08_debug_registers.f ) cr

debug definitions

: dr0@ ( -- dr0 ) $PUSH_RBX rbx=dr0 ;
: dr1@ ( -- dr1 ) $PUSH_RBX rbx=dr1 ;
: dr2@ ( -- dr2 ) $PUSH_RBX rbx=dr2 ;
: dr3@ ( -- dr3 ) $PUSH_RBX rbx=dr3 ;
: dr6@ ( -- dr6 ) $PUSH_RBX rbx=dr6 ;
: dr7@ ( -- dr7 ) $PUSH_RBX rbx=dr7 ;

: dr0! ( n -- )   dr0=rbx $POP_RBX ;
: dr1! ( n -- )   dr1=rbx $POP_RBX ;
: dr2! ( n -- )   dr2=rbx $POP_RBX ;
: dr3! ( n -- )   dr3=rbx $POP_RBX ;
: dr6! ( n -- )   dr6=rbx $POP_RBX ;
: dr7! ( n -- )   dr7=rbx $POP_RBX ;

: bp0+ ( -- )            \ enable breakpoint dr0
    dr7@ $1 or dr7!       
;

: bp0- ( -- )            \ disable breakpoint dr0
    dr7@ $3 not and dr7!  
;

: bpr0 ( addr -- ) \ set breakpoint at addr memory read 
    bp0-                  \ disable breakpoint dr0
    dr0!                  \ set breakpoint address
    dr6@ $1 not and dr6!  \ clear breakpoint flag of dr0
    dr7@ $30000 or dr7!   \ break when data read dr0
    bp0+                  \ enable breakpoint dr0
;

: bpx0 ( addr -- ) \ set breakpoint at executing addr
    bp0-                      \ disable breakpoint dr0
    dr0!                      \ set breakpoint address
    dr6@ $1 not and dr6!      \ clear breakpoint flag of dr0
    dr7@ $30000 not and dr7!  \ break when executing address dr0
    bp0+                      \ enable breakpoint dr0
;

