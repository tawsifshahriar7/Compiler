%{
#include<bits/stdc++.h>
#include "SymbolInfo.h"
#include "SymbolTable.h"
#define YYSTYPE SymbolInfo*

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;
extern int yylineno;
extern int error_count;

SymbolTable *table;
FILE* fp2;
FILE* fp3;

void yyerror(char *s)
{
	
}

vector<string> param_parse(string str){
	vector<string> tokens;
    stringstream temp(str);
    string intermediate;
    while(getline(temp,intermediate,',')){
        tokens.push_back(intermediate);
    }
    vector<string> final_tokens;
    for(int i=0;i<tokens.size();i++){
        stringstream strm(tokens[i]);
        getline(strm,intermediate,' ');
        final_tokens.push_back(intermediate);
    }
	return final_tokens;
}

%}

%token IF ELSE FOR WHILE DO INT CHAR FLOAT DOUBLE VOID RETURN DEFAULT CONTINUE ADDOP MULOP INCOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON ID CONST_INT CONST_FLOAT CONST_CHAR STRING PRINTLN DECOP
%nonassoc LOW_ELSE
%nonassoc ELSE


%%

start: program
	{
		table->PrintAll(fp2);
		fprintf(fp2,"Total Lines: %d\n\nTotal Errors: %d",yylineno,error_count);
		fprintf(fp3,"Total Errors: %d",error_count);
	}
	;

program: program unit
	{
		fprintf(fp2,"At line no %d: program: program unit\n\n",yylineno);
		$$->setName($1->getName()+"\n"+$2->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
	}
	| unit
	{
		fprintf(fp2,"At line no %d: program: unit\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
		$$=$1;
	}
	;
	
unit: var_declaration
	{
		fprintf(fp2,"At line no %d: unit: var_declaration\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
		$$=$1;
	}
     | func_declaration
	 {
		fprintf(fp2,"At line no %d: unit: func_declaration\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
		$$=$1;
	 }
     | func_definition
	 {
		fprintf(fp2,"At line no %d: unit: func_definition\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
		$$=$1;
	 }
     ;
     
func_declaration: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
	{
		bool res = table->Insert($2->getName(),$2->getType());
		if(!res){
			error_count++;
			fprintf(fp3,"Error at Line %d: Multiple Declaration of %s\n\n",yylineno,$2->getName().c_str());
		}
		fprintf(fp2,"At line no %d: func_declaration: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n",yylineno);
		$$->setName($1->getName()+" "+$2->getName()+"("+$4->getName()+")"+";");
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
		table->Lookup($2->getName())->isFunc=true;
		table->Lookup($2->getName())->datatype=$1->getName();
		table->Lookup($2->getName())->param_list=param_parse($4->getName());
	}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			bool res = table->Insert($2->getName(),$2->getType());
			if(!res){
				error_count++;
				fprintf(fp3,"Error at Line %d: Multiple Declaration of %s\n\n",yylineno,$2->getName().c_str());
			}
			fprintf(fp2,"At line no %d: func_declaration: type_specifier ID LPAREN RPAREN SEMICOLON\n\n",yylineno);
			$$->setName($1->getName()+" "+$2->getName()+"("+")"+";");
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
			table->Lookup($2->getName())->isFunc=true;
			table->Lookup($2->getName())->datatype=$1->getName();
		}
		;
		 
func_definition: type_specifier ID LPAREN parameter_list RPAREN compound_statement
	{
		if(table->Lookup($2->getName())!=nullptr && table->Lookup($2->getName())->isFunc==true){
			vector<string> def_param=table->Lookup($2->getName())->param_list;
			vector<string> imp_param=param_parse($4->getName());
			if(def_param.size()!=imp_param.size()){
				error_count++;
				fprintf(fp3,"Error at line %d: Type Mismatch\n\n",yylineno);
			}
			else{
				for(int i=0;i<def_param.size();i++){
					if(def_param[i]!=imp_param[i]){
						error_count++;
						fprintf(fp3,"Error at line %d: Type Mismatch\n\n",yylineno);
					}
				}
			}
		}
		table->Insert($2->getName(),$2->getType());
		fprintf(fp2,"At line no %d: func_definition: type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n",yylineno);
		$$->setName($1->getName()+" "+$2->getName()+"("+$4->getName()+")"+$6->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
		table->Lookup($2->getName())->isFunc=true;
		table->Lookup($2->getName())->datatype=$1->getName();
		table->Lookup($2->getName())->param_list=param_parse($4->getName());
	}
		| type_specifier ID LPAREN RPAREN compound_statement
		{
			if(table->Lookup($2->getName())!=nullptr && table->Lookup($2->getName())->isFunc==true){
			vector<string> def_param=table->Lookup($2->getName())->param_list;
			if(def_param.size()!=0){
				error_count++;
				fprintf(fp3,"Error at line %d: Type Mismatch\n\n",yylineno);
			}
		}
			table->Insert($2->getName(),$2->getType());
			fprintf(fp2,"At line no %d: func_declaration: type_specifier ID LPAREN RPAREN compound_statement\n\n",yylineno);
			$$->setName($1->getName()+" "+$2->getName()+"("+")"+$5->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
			table->Lookup($2->getName())->isFunc=true;
			table->Lookup($2->getName())->datatype=$1->getName();
		}
 		;				


parameter_list: parameter_list COMMA type_specifier ID
	{
		fprintf(fp2,"At line no %d: parameter_list: parameter_list COMMA type_specifier ID\n\n",yylineno);
		$$->setName($1->getName()+","+$3->getName()+" "+$4->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
	}
		| parameter_list COMMA type_specifier
		{
			fprintf(fp2,"At line no %d: parameter_list: parameter_list COMMA type_specifier\n\n",yylineno);
			$$->setName($1->getName()+","+$3->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
		}
 		| type_specifier ID
		 {
			fprintf(fp2,"At line no %d: parameter_list: type_specifier ID\n\n",yylineno);
			$$->setName($1->getName()+" "+$2->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
		 }
		| type_specifier
		{
			fprintf(fp2,"At line no %d: parameter_list: type_specifier\n\n",yylineno);
			fprintf(fp2,"%s\n\n",$1->getName().c_str());
		}
 		;

 		
compound_statement: LCURL statements RCURL
	{
		fprintf(fp2,"At line no %d: compound_statement: LCURL statements RCURL\n\n",yylineno);
		$$->setName("{\n"+$2->getName()+"\n}");
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
	}
 		    | LCURL RCURL
			 {
				fprintf(fp2,"At line no %d: compound_statement: LCURL RCURL\n\n",yylineno);
				$$->setName("{\n}");
				fprintf(fp2,"%s\n\n",$$->getName().c_str());
			 }
 		    ;
 		    
var_declaration: type_specifier declaration_list SEMICOLON
	{
		vector <string> tokens;
		stringstream check1($2->getName());

		string intermediate;

		while(getline(check1, intermediate, ','))
		{
			tokens.push_back(intermediate);
		}

		for(int i=0;i<tokens.size();i++){
			for(int j=0;j<tokens[i].size();j++){
				if(tokens[i][j]=='['){
					tokens[i].erase(tokens[i].begin()+j,tokens[i].end());
				}
			}
		}
		for(int i=0;i<tokens.size();i++){
			table->Lookup(tokens[i])->datatype=$1->getName();
		}
		fprintf(fp2,"At line no %d: var_declaration: type_specifier declaration_list SEMICOLON\n\n",yylineno);
		$$->setName($1->getName()+" "+$2->getName()+";");
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
	}
 		 ;
 		 
type_specifier: INT
	{
		fprintf(fp2,"At line no %d: type_specifier : INT\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
	}
 		| FLOAT
		 {
			fprintf(fp2,"At line no %d: type_specifier : FLOAT\n\n",yylineno);
			fprintf(fp2,"%s\n\n",$1->getName().c_str());
		 }
 		| VOID
		 {
			fprintf(fp2,"At line no %d: type_specifier : VOID\n\n",yylineno);
			fprintf(fp2,"%s\n\n",$1->getName().c_str());
		 }
 		;
 		
declaration_list: declaration_list COMMA ID
	{
		bool res = table->Insert($3->getName(),$3->getType());
		if(!res){
			error_count++;
			fprintf(fp3,"Error at Line %d: Multiple Declaration of %s\n\n",yylineno,$3->getName().c_str());
		}
		fprintf(fp2,"At line no %d: declaration_list: declaration_list COMMA ID\n\n",yylineno);
		$$->setName($1->getName()+","+$3->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
	}
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
		   {
			   bool res = table->Insert($3->getName(),$3->getType());
				if(!res){
					error_count++;
					fprintf(fp3,"Error at Line %d: Multiple Declaration of %s\n\n",yylineno,$3->getName().c_str());
				}
			   	fprintf(fp2,"At line no %d: declaration_list: declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n",yylineno);
				$$->setName($1->getName()+","+$3->getName()+"["+$5->getName()+"]");
				fprintf(fp2,"%s\n\n",$$->getName().c_str());
		   }
 		  | ID
		   {
			   	bool res = table->Insert($1->getName(),$1->getType());
				if(!res){
					error_count++;
					fprintf(fp3,"Error at Line %d: Multiple Declaration of %s\n\n",yylineno,$1->getName().c_str());
				}
			   	fprintf(fp2,"At line no %d: declaration_list: ID\n\n",yylineno);
				fprintf(fp2,"%s\n\n",$1->getName().c_str());
		   }
 		  | ID LTHIRD CONST_INT RTHIRD
		   {
			   bool res = table->Insert($1->getName(),$1->getType());
				if(!res){
					error_count++;
					fprintf(fp3,"Error at Line %d: Multiple Declaration of %s\n\n",yylineno,$1->getName().c_str());
				}
			   	fprintf(fp2,"At line no %d: declaration_list: ID LTHIRD CONST_INT RTHIRD\n\n",yylineno);
				$$->setName($1->getName()+"["+$3->getName()+"]");
				fprintf(fp2,"%s\n\n",$$->getName().c_str());
		   }
 		  ;
 		  
statements: statement
	{
		fprintf(fp2,"At line no %d: statements: statement\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
	}
	   | statements statement
	   {
		   	fprintf(fp2,"At line no %d: statements: statements statement\n\n",yylineno);
			$$->setName($1->getName()+"\n"+$2->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
	   }
	   ;
	   
statement: var_declaration
	{
		fprintf(fp2,"At line no %d: statement: var_declaration\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
	}
	  | expression_statement
	  {
		  	fprintf(fp2,"At line no %d: statement: expression_statement\n\n",yylineno);
			fprintf(fp2,"%s\n\n",$1->getName().c_str());
	  }
	  | compound_statement
	  {
		  	fprintf(fp2,"At line no %d: statement: compound_statement\n\n",yylineno);
			fprintf(fp2,"%s\n\n",$1->getName().c_str());
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
		  	fprintf(fp2,"At line no %d: statement: FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n",yylineno);
			$$->setName($1->getName()+"("+$3->getName()+$4->getName()+$5->getName()+")"+$7->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
	  }
	  | IF LPAREN expression RPAREN statement %prec LOW_ELSE
	  {
		  	fprintf(fp2,"At line no %d: statement: IF LPAREN expression RPAREN statement\n\n",yylineno);
			$$->setName($1->getName()+"("+$3->getName()+")"+$5->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
		  	fprintf(fp2,"At line no %d: statement: IF LPAREN expression RPAREN statement ELSE statement\n\n",yylineno);
			$$->setName($1->getName()+"("+$3->getName()+")"+$5->getName()+$6->getName()+$7->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
		  	fprintf(fp2,"At line no %d: statement: WHILE LPAREN expression RPAREN statement\n\n",yylineno);
			$$->setName($1->getName()+"("+$3->getName()+")"+$5->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
		  	fprintf(fp2,"At line no %d: statement: PRINTLN LPAREN ID RPAREN SEMICOLON\n\n",yylineno);
			$$->setName($1->getName()+"("+$3->getName()+")"+$5->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
	  }
	  | RETURN expression SEMICOLON
	  {
		  	fprintf(fp2,"At line no %d: statement: RETURN expression SEMICOLON\n\n",yylineno);
			$$->setName($1->getName()+" "+$2->getName()+$3->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
	  }
	  ;
	  
expression_statement: SEMICOLON
	{
		fprintf(fp2,"At line no %d: expression_statement: SEMICOLON\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
	}			
			| expression SEMICOLON
			{
				fprintf(fp2,"At line no %d: expression_statement: expression SEMICOLON\n\n",yylineno);
				$$->setName($1->getName()+";");
				fprintf(fp2,"%s\n\n",$$->getName().c_str());
			} 
			;
	  
variable: ID 	
{
	if(table->Lookup($1->getName())==nullptr){
		error_count++;
		fprintf(fp3,"Error at Line %d : Undeclared Variable: %s\n\n",yylineno,$1->getName().c_str());
	}
	else{
		$$->datatype=table->Lookup($1->getName())->datatype;
		if(table->Lookup($1->getName())->isArray==true || table->Lookup($1->getName())->isFunc==true){
			error_count++;
			fprintf(fp3,"Error at Line %d : Type Mismatch\n\n",yylineno);
		}
	}
	fprintf(fp2,"At line no %d: variable: ID\n\n",yylineno);
	fprintf(fp2,"%s\n\n",$1->getName().c_str());
}	
	| ID LTHIRD expression RTHIRD 
	{
		if(table->Lookup($1->getName())==nullptr){
			error_count++;
			fprintf(fp3,"Error at Line %d : Undeclared Variable: %s\n\n",yylineno,$1->getName().c_str());
		}
		else{
			if(table->Lookup($1->getName())->isArray==false || table->Lookup($1->getName())->isFunc==true){
			error_count++;
			fprintf(fp3,"Error at Line %d : Type Mismatch\n\n",yylineno);
			}
		}
		if($3->datatype!="int"){
			error_count++;
			fprintf(fp3,"Error at Line %d : Non-integer Array Index\n\n",yylineno);
		}
		fprintf(fp2,"At line no %d: variable: ID LTHIRD expression RTHIRD\n\n",yylineno);
		$$->setName($1->getName()+"["+$3->getName()+"]");
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
	}
	;
	 
expression: logic_expression	
	{
		fprintf(fp2,"At line no %d: expression: logic_expression\n\n",yylineno);
		$$->datatype=$1->datatype;
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
	}
	   | variable ASSIGNOP logic_expression 
	   {
		   	if($1->datatype!=$3->datatype){
				error_count++;
			   	fprintf(fp3,"Error at line %d : Type Mismatch\n\n",yylineno);
		   	}
			else{
				$$->datatype=$1->datatype;
			}
		   	fprintf(fp2,"At line no %d: expression: variable ASSIGNOP logic_expression\n\n",yylineno);
			$$->setName($1->getName()+$2->getName()+$3->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
	   }	
	   ;
			
logic_expression: rel_expression 	
	{
		fprintf(fp2,"At line no %d: logic_expression: rel_expression\n\n",yylineno);
		$$->datatype=$1->datatype;
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
	}
		 | rel_expression LOGICOP rel_expression 
		 {
			fprintf(fp2,"At line no %d: logic_expression: rel_expression LOGICOP rel_expression\n\n",yylineno);
			$$->setName($1->getName()+$2->getName()+$3->getName());
			$$->datatype="int";
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
		 }	
		 ;
			
rel_expression: simple_expression 
	{
		fprintf(fp2,"At line no %d: rel_expression: simple_expression\n\n",yylineno);
		$$->datatype=$1->datatype;
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
	}
		| simple_expression RELOP simple_expression	
		{
			fprintf(fp2,"At line no %d: rel_expression: simple_expression RELOP simple_expression\n\n",yylineno);
			$$->setName($1->getName()+$2->getName()+$3->getName());
			$$->datatype="int";
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
		}
		;
				
simple_expression: term 
	{
		fprintf(fp2,"At line no %d: simple_expression: term\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
		$$->datatype=$1->datatype;
	}
		  | simple_expression ADDOP term 
		  {
			  	fprintf(fp2,"At line no %d: simple_expression: simple_expression ADDOP term\n\n",yylineno);
				$$->setName($1->getName()+$2->getName()+$3->getName());
				if($1->datatype=="float"||$3->datatype=="float"){
					$$->datatype="float";
				}
				else{
					$$->datatype="int";
				}
				fprintf(fp2,"%s\n\n",$$->getName().c_str());
		  }
		  ;
					
term:	unary_expression
	{
		fprintf(fp2,"At line no %d: term: unary_expression\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
		$$->datatype=$1->datatype;
	}
     |  term MULOP unary_expression
	 {
		 	fprintf(fp2,"At line no %d: term: term MULOP unary_expression\n\n",yylineno);
			$$->setName($1->getName()+$2->getName()+$3->getName());
			if($1->datatype=="float"||$3->datatype=="float"){
					$$->datatype="float";
				}
				else{
					$$->datatype="int";
				}
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
			if($2->getName()=="%"){
				if($1->datatype!="int" || $3->datatype!="int"){
					error_count++;
					fprintf(fp3,"Error at Line %d : Non-integer operand on modulus operator\n\n",yylineno);
					$$->datatype="int";
				}
			}
	 }
     ;

unary_expression: ADDOP unary_expression  
	{
		fprintf(fp2,"At line no %d: unary_expression: ADDOP unary_expression\n\n",yylineno);
		$$->setName($1->getName()+$2->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
		$$->datatype=$2->datatype;
	}
		 | NOT unary_expression 
		 {
			fprintf(fp2,"At line no %d: unary_expression: NOT unary_expression\n\n",yylineno);
			$$->setName($1->getName()+$2->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
			$$->datatype=$2->datatype;
		 }
		 | factor 
		 {
			fprintf(fp2,"At line no %d: unary_expression: factor\n\n",yylineno);
			fprintf(fp2,"%s\n\n",$1->getName().c_str());
			$$->datatype=$1->datatype;
		 }
		 ;
	
factor: variable
	{
		fprintf(fp2,"At line no %d: factor: variable\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
		$$->datatype=$1->datatype;
	}
	| ID LPAREN argument_list RPAREN
	{
		if(table->Lookup($1->getName())==nullptr){
			error_count++;
			fprintf(fp3,"Error at Line %d : Undeclared Variable: %s",yylineno,$1->getName().c_str());
		}
		else{
			if(table->Lookup($1->getName())->isFunc==false){
				error_count++;
				fprintf(fp3,"Error at Line %d : Type Mismatch\n\n",yylineno);
			}
			vector<string> def_args=table->Lookup($1->getName())->param_list;
			vector<string> imp_args=$3->param_list;
			if(def_args.size()!=imp_args.size()){
				error_count++;
				fprintf(fp3,"Error at Line %d : Type Mismatch\n\n",yylineno,$1->getName().c_str());
			}
			else{
				for(int i=0;i<def_args.size();i++){
					if(def_args[i]!=imp_args[i]){
						error_count++;
						fprintf(fp3,"Error at Line %d : Type Mismatch\n\n",yylineno,$1->getName().c_str());
						break;
					}
				}
			}
		}
		fprintf(fp2,"At line no %d: factor: ID LPAREN argument_list RPAREN\n\n",yylineno);
		$$->setName($1->getName()+$2->getName()+$3->getName()+$4->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
	}
	| LPAREN expression RPAREN
	{
		fprintf(fp2,"At line no %d: factor: LPAREN expression RPAREN\n\n",yylineno);
		$$->setName($1->getName()+$2->getName()+$3->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
	}
	| CONST_INT
	{
		fprintf(fp2,"At line no %d: factor: CONST_INT\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
		$$->datatype="int";
	} 
	| CONST_FLOAT
	{
		fprintf(fp2,"At line no %d: factor: CONST_FLOAT\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
		$$->datatype="float";
	}
	| variable INCOP
	{
		fprintf(fp2,"At line no %d: factor: variable INCOP\n\n",yylineno);
		$$->setName($1->getName()+$2->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
	} 
	| variable DECOP
	{
		fprintf(fp2,"At line no %d: factor: variable DECOP\n\n",yylineno);
		$$->setName($1->getName()+$2->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
	}
	;
	
argument_list: arguments
	{
		fprintf(fp2,"At line no %d: argument_list: arguments\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
		$$->param_list=$1->param_list;
	}
			  |
			  ;
	
arguments: arguments COMMA logic_expression
	{
		fprintf(fp2,"At line no %d: arguments: arguments COMMA logic_expression\n\n",yylineno);
		$$->setName($1->getName()+$2->getName()+$3->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
		$$->param_list=$1->param_list;
		$$->param_list.push_back($3->datatype);
	}
	      | logic_expression
		  {
			  	fprintf(fp2,"At line no %d: arguments: logic_expression\n\n",yylineno);
				fprintf(fp2,"%s\n\n",$1->getName().c_str());
				$$->param_list.push_back($1->datatype);
		  }
	      ;
 

%%
int main(int argc,char *argv[])
{
	table = new SymbolTable(20);
	FILE* fp;
	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}
	fp2= fopen(argv[2],"w");
	fclose(fp2);
	fp3= fopen(argv[3],"w");
	fclose(fp3);
	
	fp2= fopen(argv[2],"a");
	fp3= fopen(argv[3],"a");
	

	yyin=fp;
	yyparse();
	

	fclose(fp2);
	fclose(fp3);
	
	return 0;
}

