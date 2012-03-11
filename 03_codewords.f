
.(  including 03_codewords.f ) cr

mywords definitions

\  STC doesn't need following words. They are all CPU instructions, use them directly in colon definitions. Then are
\  immediate compiling commands.
\  When used in interprete state, we need following words to execute them.

\  {hlt}           ( -- )
\                  CPU instruction. Halt when nothing to do, QEMU save power.
\                  "d:\Learnings\CPU\IA-32 Software Developer's Manual Volume 2 Instruction Set Reference 2002.pdf" page 3-316

                   : {hlt}
                       hlt
                   ;

\  {cli}           ( -- )
\                  CPU instruction. Clear Interrupt flag, disable interrupt.
\                  "d:\Learnings\CPU\IA-32 Software Developer's Manual Volume 2 Instruction Set Reference 2002.pdf" page 3-316

                   : {cli}
                       cli
                   ;

\  {sti}           ( -- )
\                  CPU instruction. Set Interrupt flag, enable interrupt.
\                  "d:\Learnings\CPU\IA-32 Software Developer's Manual Volume 2 Instruction Set Reference 2002.pdf" page 3-316

                   : {sti}
                       sti nop nop
                   ;

\  {nop}           ( -- )
\                  CPU instruction. Do nothing.
\                  "d:\Learnings\CPU\IA-32 Software Developer's Manual Volume 2 Instruction Set Reference 2002.pdf" page 3-316

                   : {nop} 
                       nop 
                   ;
                   