%{
#include <string.h>
#include "util.h"
#include "tokens.h"
#include "errormsg.h"

int charPos=1;

int nestedcomment = 0;

char str_buf[4096];
unsigned int strlength = 0;
unsigned int string_start = 0;
int yywrap(void)
{
 charPos=1;
 return 1;
}

void adjust(void)
{
 EM_tokPos=charPos;
 charPos+=yyleng;
}

%}

LineTerminator \n|\r|\r\n|\n\r
WhiteSpace     \n|\r|\r\n|\t|\f|\n\r 

%x STR COMMENT STR1

%%
" "	 {adjust(); continue;}
[\r\t] {adjust(); continue;}
\n	 {adjust(); EM_newline(); continue;}

","	 {adjust(); return COMMA; }
":"  {adjust(); return COLON; }
";"  {adjust(); return SEMICOLON; }
"("  {adjust(); return LPAREN; }
")"  {adjust(); return RPAREN; }
"["  {adjust(); return LBRACK; }
"]"  {adjust(); return RBRACK; }
"{"  {adjust(); return LBRACE; }
"}"  {adjust(); return RBRACE; }
"."  {adjust(); return DOT; }
"+"  {adjust(); return PLUS; }
"-"  {adjust(); return MINUS; }
"*"  {adjust(); return TIMES; }
"/"  {adjust(); return DIVIDE; }
"="  {adjust(); return EQ; }
"<>" {adjust(); return NEQ; }
"<"  {adjust(); return LT; }
"<=" {adjust(); return LE; }
">"  {adjust(); return GT; }
">=" {adjust(); return GE; }
"&"  {adjust(); return AND; }
"|"  {adjust(); return OR; }
":=" {adjust(); return ASSIGN; } 
array  {adjust(); return ARRAY; }
if    {adjust(); return IF; }
then  {adjust(); return THEN; }
else  {adjust(); return ELSE; }
while {adjust(); return WHILE; }
for  	 {adjust(); return FOR;}
to    {adjust(); return TO; }
do   {adjust(); return DO; }
let   {adjust(); return LET; }
in {adjust(); return IN; }
end {adjust(); return END; }
of {adjust(); return OF; }
break {adjust(); return BREAK; }
nil {adjust(); return NIL;}
function {adjust(); return FUNCTION; }
var {adjust(); return VAR; }
type {adjust(); return TYPE; }

[0-9]+	 {adjust(); yylval.ival=atoi(yytext); return INT;}
[a-zA-Z][a-zA-Z0-9_]* {adjust(); 
                       yylval.sval = String(yytext);
                       return ID;}
\" {adjust(); strlength = 0; string_start = charPos - 1; BEGIN STR; }
"/*" {adjust(); nestedcomment++; BEGIN COMMENT;}

<STR>{
    \"  { adjust(); 
          BEGIN INITIAL; 
          str_buf[strlength] = '\0';
          yylval.sval = strlength ? String(str_buf) : String("(null)");
          EM_tokPos = string_start;
          return STRING; }
    \\n { adjust(); EM_newline();  str_buf[strlength++] = '\n'; }
    \\t { adjust(); str_buf[strlength++] = '\t'; }
    "\^"[@A-Z\[\\\]\^_\?] { adjust(); 
                            str_buf[strlength++] = yytext[1];
                          }  
    \\[0-9]{3} {
        adjust();
        int result = atoi(yytext+1);
        if(result > 0xff) {
            EM_error(EM_tokPos, "ASCII out of bound");
        }
        str_buf[strlength++] = result;
    }
    \\\" {adjust(); str_buf[strlength++] = '"';  }
    \\\\ {adjust(); str_buf[strlength++] = '\\';  }
    {LineTerminator} {EM_error(EM_tokPos, "String format error."); yyterminate(); }
    <<EOF>> {EM_error(EM_tokPos, "string EOF"); yyterminate();}

    \\ {adjust(); BEGIN STR1; }
    . {
        adjust();
        strcpy(str_buf + strlength, yytext);
        strlength++;
    }
}

<STR1>{
    {WhiteSpace} { adjust();}
    " " {adjust(); }
    \\ {adjust(); BEGIN STR;}
    <<EOF>> {EM_error(EM_tokPos, "string EOF"); yyterminate();}
    . {
        adjust();
        strcpy(str_buf + strlength, yytext);
        strlength++;
    }
}
<COMMENT>{
    "/*" {
        adjust();
        nestedcomment++;
    }

    "*/" {
        adjust();
        nestedcomment--;
        if(nestedcomment == 0)
        {
            BEGIN INITIAL;
        }
    }

    <<EOF>> {
        EM_error(EM_tokPos, "comment still open when eof");
        yyterminate();
    }
    \n {
        adjust();
        EM_newline();
    }
    . {adjust();}
}


.	 {adjust(); EM_error(EM_tokPos,"illegal token");}


