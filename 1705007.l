%option yylineno
%x MULTICOMMENT
%x STRINGSTATE
%{
#include<stdio.h>
#include<stdlib.h>
#include<iostream>
#include<cstring>
#include "SymbolInfo.h"
#include "SymbolTable.h"
#define YYSTYPE SymbolInfo*
#include "y.tab.h"

extern YYSTYPE yylval;
extern SymbolTable *table;
void yyerror(char *);

int error_count=0;

extern FILE* fp2;
extern FILE* fp3;
string tok;

string formatting(string str) {
	size_t index = 0;
    while (true) {
        index = str.find("\\t", index);
        if (index == std::string::npos) break;
        str.replace(index, 2, "\t");
        index += 2;
	}
	index = 0;
	while (true) {
        index = str.find("\\n", index);
        if (index == std::string::npos) break;
        str.replace(index, 2, "\n");
        index += 2;
	}
	index = 0;
	while (true) {
        index = str.find("\\f", index);
        if (index == std::string::npos) break;
        str.replace(index, 2, "\f");
        index += 2;
	}
	index = 0;
	while (true) {
        index = str.find("\\v", index);
        if (index == std::string::npos) break;
        str.replace(index, 2, "\v");
        index += 2;
	}
	index = 0;
	while (true) {
        index = str.find("\\a", index);
        if (index == std::string::npos) break;
        str.replace(index, 2, "\a");
        index += 2;
	}
	index = 0;
	while (true) {
        index = str.find("\\r", index);
        if (index == std::string::npos) break;
        str.replace(index, 2, "\r");
        index += 2;
	}
	index = 0;
	while (true) {
        index = str.find("\\b", index);
        if (index == std::string::npos) break;
        str.replace(index, 2, "\b");
        index += 2;
	}
	index = 0;
	while (true) {
        index = str.find("\\0", index);
        if (index == std::string::npos) break;
        str.replace(index, 2, "\0");
        index += 2;
	}
	index = 0;
	while (true) {
        index = str.find("\\\"", index);
        if (index == std::string::npos) break;
        str.replace(index, 2, "\"");
        index += 2;
	}
	return str;
}

string removenl(string str){
    size_t index=0;
    while(true){
        index = str.find("\\\n", index);
        if (index == std::string::npos) break;
        str.replace(index, 2, "");
        index += 2;
    }
	return str;
}

int nlcount(string str){
	int count=0;
	for(int i=0;i<str.size();i++){
		if(str[i]=='\n'){
			count++;
		}
	}
	return count;
}

%}

WHITESPACE [ \t\f\v\r]+
LETTER [a-zA-Z]
DIGIT [0-9]
NEWLINE [\n]
FLOAT [0-9]*([.][0-9]+)?([E][+-]?[0-9]+)?
CHAR ['][^\\\n'][']|['][\\][ntafrbv0\\\'][']
ADDOP [+-]
MULOP [*/%]
INCOP [+]{2}|[-]{2}
RELOP [<]|[<][=]|[>]|[>][=]|[=]{2}|[!][=]
ASSIGNOP [=]
LOGICOP [&]{2}|[|]{2}
NOT [!]
LPAREN [(]
RPAREN [)]
LCURL [{]
RCURL [}]
LTHIRD [[]
RTHIRD []]
COMMA [,]
SEMICOLON [;]
ID [a-zA-Z_]+[a-zA-Z0-9_]*
SCOMMENT [/][/]([^\n]*[\\][\n])*(.)*
MULTISTRING ["](.*([\\][\n])?)*["]
TOOMANYPOINT [0-9]*[.][0-9]+([.][0-9]*)+
ILLFORM [0-9]*([.][0-9]+)?([E][+-]?[0-9]+)([.][0-9]*)+
INVALIDID [0-9]+[a-zA-Z_]+
MULTICHAR ['][^\\\n']{2,}[']|['][\\][ntafrbv0\\\']{2,}[']
UNFINISHEDCHAR ['][^\\'\n]|['][\\][ntafrbv0\\\']|[']
EMPTYCHAR ['][']
UNFINISHEDSTRING ["]([^"]*([\\][\n])?)*
STRING ["]
%%

{WHITESPACE}+ {
}
{NEWLINE} {
}

{SCOMMENT} {
}

{STRING} {
	BEGIN STRINGSTATE;
	tok="\"";
}

<STRINGSTATE>{STRING} {
	BEGIN INITIAL;
	tok=tok+"\"";
	int nl=nlcount(tok);
	tok=formatting(tok);
	tok=removenl(tok);
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"STRING");
	yylval = (YYSTYPE)s;
	return STRING;
}

<STRINGSTATE>"\\\n" {
	tok=tok+"\\\n";
}

<STRINGSTATE>[^"\n] {
	tok=tok+yytext;
}

<STRINGSTATE>"\\\"" {
	tok=tok+"\\\"";
}


<STRINGSTATE>"\n" {
	BEGIN INITIAL;
	error_count++;
	tok=tok+yytext;
	int nl=nlcount(tok);
	tok=formatting(tok);
	//fprintf(logout,"Error at line no %d: Unterminated String %s\n\n",yylineno-nl,tok.c_str());
}

<STRINGSTATE><<EOF>> {
	BEGIN INITIAL;
	error_count++;
	int nl=nlcount(tok);
	tok=formatting(tok);
	return 0;
}

"/*" {
	BEGIN MULTICOMMENT;
}

<MULTICOMMENT>"*/" {
	BEGIN INITIAL;
}

<MULTICOMMENT>.|[\n] {
}

<MULTICOMMENT><<EOF>> {
	BEGIN INITIAL;
	error_count++;
	int nl=nlcount(tok);
	return 0;
}

"if"	{
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return IF;
}

"else"	{
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return ELSE;
}

"for"   {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return FOR;
}

"while"	{
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return WHILE;
}

"do" {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return DO;
}

"int" {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return INT;
}

"char" {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return CHAR;
}

"float" {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return FLOAT;
}

"double" {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return DOUBLE;
}

"void" {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return VOID;
}

"return" {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return RETURN;
}

"default" {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return DEFAULT;
}

"continue" {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return CONTINUE;
}

"printf" {
	SymbolInfo *s = new SymbolInfo(yytext,"");
	yylval=(YYSTYPE)s;
	return PRINTLN;
}

{ADDOP}	{
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return ADDOP;
}

{MULOP} {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return MULOP;
}

{INCOP} {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return INCOP;
}

{RELOP} {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return RELOP;
}

{ASSIGNOP} {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return ASSIGNOP;
}

{LOGICOP} {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return LOGICOP;
}

{NOT} {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return NOT;
}

{LPAREN} {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return LPAREN;
}

{RPAREN} {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return RPAREN;
}

{LCURL} {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return LCURL;
}

{RCURL} {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return RCURL;
}

{LTHIRD} {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return LTHIRD;
}

{RTHIRD} {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return RTHIRD;
}

{COMMA} {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return COMMA;
}

{SEMICOLON} {
	SymbolInfo *s= new  SymbolInfo(yytext,"");
	yylval = (YYSTYPE)s;
	return SEMICOLON;
}

		
{DIGIT}+ {
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"CONST_INT");
	yylval = (YYSTYPE)s;
	return CONST_INT;
}

{FLOAT} {
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"CONST_FLOAT");
	yylval = (YYSTYPE)s;
	return CONST_FLOAT;
}

{CHAR} {
	string str=yytext;
	str=formatting(str);
	char ch =str[1];
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"CONST_CHAR");
	yylval = (YYSTYPE)s;
	return CONST_CHAR;
}

{TOOMANYPOINT} {
	error_count++;
	fprintf(fp3,"Error at line no %d: Too many decimal points %s\n\n",yylineno,yytext);
	fprintf(fp2,"Error at line no %d: Too many decimal points %s\n\n",yylineno,yytext);
}

{ILLFORM} {
	error_count++;
	fprintf(fp3,"Error at line no %d: Ill formed number %s\n\n",yylineno,yytext);
	fprintf(fp2,"Error at line no %d: Ill formed number %s\n\n",yylineno,yytext);
}

{INVALIDID} {
	error_count++;
	fprintf(fp3,"Error at line no %d: Invalid prefix on ID or invalid suffix on Number %s\n\n",yylineno,yytext);
	fprintf(fp2,"Error at line no %d: Invalid prefix on ID or invalid suffix on Number %s\n\n",yylineno,yytext);
}

{MULTICHAR} {
	error_count++;
	fprintf(fp3,"Error at line no %d: Multi character constant error %s\n\n",yylineno,yytext);
	fprintf(fp2,"Error at line no %d: Multi character constant error %s\n\n",yylineno,yytext);
}

{EMPTYCHAR} {
	error_count++;
	fprintf(fp3,"Error at line no %d: Empty character constant error %s\n\n",yylineno,yytext);
	fprintf(fp2,"Error at line no %d: Empty character constant error %s\n\n",yylineno,yytext);
}

{UNFINISHEDCHAR} {
	error_count++;
	fprintf(fp3,"Error at line no %d: Unterminated character %s\n\n",yylineno,yytext);
	fprintf(fp2,"Error at line no %d: Unterminated character %s\n\n",yylineno,yytext);
}

{ID} {
	SymbolInfo *s= new  SymbolInfo(yytext, (char *)"ID");
	yylval = (YYSTYPE)s;
	return ID;
}
. {
	error_count++;
	fprintf(fp3,"Error at line no %d: Unrecognized character  %s\n\n",yylineno,yytext);
	fprintf(fp2,"Error at line no %d: Unrecognized character  %s\n\n",yylineno,yytext);
}
<<EOF>> {
	return 0;
}
%%

int yywrap(void)
{
	return 1;
}