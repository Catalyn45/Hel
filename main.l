%{
#include <stdio.h>
#include "y.tab.h"
%}
%option noyywrap
%%
[a-z] {return SMB;}
[ \t] ;
\n {return 0;}
. {return yytext[0];}