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
FILE* fp4;
int func_flag=0;
int has_param=0;
string current_param;
int labelCount=0;
int tempCount=0;
vector<string> var_list;
int current_offset=0;
int main_proc=0;
string current_func;
int param_count=0;
int arg_count=0;
int ret_state=0;
int global_flag=1;
vector<string> global_var_list;
void yyerror(char *s)
{
	
}

string newLabel(){
	string label = "L"+to_string(labelCount);
	labelCount++;
	return label;
}

string newTemp(){
	string temp = "t"+to_string(tempCount);
	tempCount++;
	return temp;
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

void offset_inc(int cnt){
	vector<string> tokens;
	stringstream temp(current_param);
	string intermediate;
	while(getline(temp,intermediate,',')){
		tokens.push_back(intermediate);
	}
	for(int i=0;i<tokens.size();i++){
		stringstream strm(tokens[i]);
		getline(strm,intermediate,' ');
		string type = intermediate;
		getline(strm,intermediate,' ');
		string name = intermediate;
		table->Lookup(name)->offset+=2*cnt;
	}
	for(int i=0;i<var_list.size();i++){
		table->Lookup(var_list[i])->offset+=2*cnt;
	}
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
		string code;
		code = ".model small\n.stack 100h\n.data\n";
		code+="ret_val dw ?\n";
		for(int i=0;i<tempCount;i++){
			code+="t"+to_string(i)+" dw ?\n";
		}
		for(int i=0;i<global_var_list.size();i++){
			if(table->Lookup(global_var_list[i])->isArray==true){
				code+=global_var_list[i]+" dw "+to_string(table->Lookup(global_var_list[i])->arraySize)+" dup (?)\n";
			}
			else{
				code+=global_var_list[i]+" dw ?\n";
			}
		}
		code+=".code\njmp main_code\n";
		string print_func="printf proc\n";
		print_func+="or ax,ax\njge end_if1\n";
		print_func+="push ax\nmov dl,'-'\nmov ah,2\nint 21h\npop ax\nneg ax\n";
		print_func+="end_if1:\nxor cx,cx\nmov bx,10d\n";
		print_func+="repeat1:\nxor dx,dx\ndiv bx\npush dx\ninc cx\n";
		print_func+="or ax,ax\njne repeat1\n";
		print_func+="mov ah,2\n";
		print_func+="print_loop:\npop dx\nor dl,30h\nint 21h\nloop print_loop\n";
		print_func+="mov dl,0dh\nmov ah,2\nint 21h\n";
		print_func+="mov dl,0ah\nmov ah,2\nint 21h\n";
		print_func+="ret\nprintf endp\n";
		code+=$1->code+"jmp exit\n"+print_func+"exit:\n.exit\n";
		if(error_count==0){
			fprintf(fp4,"%s",code.c_str());
		}
	}
	;

program: program unit
	{
		fprintf(fp2,"At line no %d: program: program unit\n\n",yylineno);
		$$->setName($1->getName()+"\n"+$2->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
		$$->code=$1->code+$2->code;
	}
	| unit
	{
		fprintf(fp2,"At line no %d: program: unit\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
		$$=$1;
		$$->code = $1->code;
	}
	;
	
unit: var_declaration
	{
		fprintf(fp2,"At line no %d: unit: var_declaration\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
		$$=$1;
		$$->code=$1->code;
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
		$$->code = $1->code;
	 }
     ;

func_start: type_specifier ID LPAREN parameter_list RPAREN
	{
		has_param=1;
		global_flag=0;
		bool res = table->Insert($2->getName(),"ID");
		if(!res){
			if(table->Lookup($2->getName())->isFunc!=true){
				error_count++;
				fprintf(fp3,"Error at line %d: Multiple declaration of %s\n\n",yylineno,$2->getName().c_str());
			}
			if($1->getName()!=table->Lookup($2->getName())->datatype){
				error_count++;
				fprintf(fp3,"Error at line %d: Return type mismatch with function declaration in function %s\n\n",yylineno,$2->getName().c_str());
			}
			if(table->Lookup($2->getName())->isFunc==true){
				vector<string> def_param=table->Lookup($2->getName())->param_list;
				vector<string> imp_param=param_parse($4->getName());
				if(def_param.size()!=imp_param.size()){
					error_count++;
					fprintf(fp3,"Error at line %d: Total number of arguments mismatch with declaration in function %s\n\n",yylineno,$2->getName().c_str());
				}
				else{
					for(int i=0;i<def_param.size();i++){
						if(def_param[i]!=imp_param[i]){
							error_count++;
							fprintf(fp3,"Error at line %d: Parameter list for function declaration and definition do not match\n\n",yylineno);
						}
					}
				}
			}
		}
		else{
			table->Lookup($2->getName())->param_list=param_parse($4->getName());
			table->Lookup($2->getName())->isFunc=true;
			table->Lookup($2->getName())->datatype=$1->getName();
		}
		current_param = $4->getName();
		$$->setName($1->getName()+" "+$2->getName()+" ("+$4->getName()+")");
		func_flag=1;
		current_func=$2->getName();
		$$->code+="\n"+$2->getName()+" proc\n";
		if($2->getName()=="main"){
			$$->code+="\nmain_code:\nmov ax,@data\nmov ds,ax\n";
			main_proc=1;
		}
		int param_count=table->Lookup($2->getName())->param_list.size();
		for(int i=0;i<param_count;i++){
			$$->code+="push bp\n";
			$$->code+="mov bp,sp\n";
			$$->code+="mov ax,[bp+"+to_string(param_count*2+2)+"]\n";
			$$->code+="pop bp\n";
			$$->code+="push ax\n";
		}
	}
	| type_specifier ID LPAREN RPAREN
	{
		has_param=0;
		global_flag=0;
		bool res = table->Insert($2->getName(),"ID");
		if(!res){
			if(table->Lookup($2->getName())->isFunc!=true){
				error_count++;
				fprintf(fp3,"Error at line %d: Multiple declaration of %s\n\n",yylineno,$2->getName().c_str());
			}
			if($1->getName()!=table->Lookup($2->getName())->datatype){
				error_count++;
				fprintf(fp3,"Error at line %d: Return type mismatch with function declaration in function %s\n\n",yylineno,$2->getName().c_str());
			}
			if(table->Lookup($2->getName())->param_list.size()!=0){
				error_count++;
				fprintf(fp3,"Error at line %d: Parameter list for function declaration and definition do not match\n\n",yylineno);
			}
		}
		else{
			table->Lookup($2->getName())->isFunc=true;
			table->Lookup($2->getName())->datatype=$1->getName();
		}
		$$->setName($1->getName()+" "+$2->getName()+" ()");
		func_flag=1;
		current_func=$2->getName();
		$$->code+="\n"+$2->getName()+" proc\n";
		if($2->getName()=="main"){
			$$->code+="\nmain_code:\nmov ax,@data\nmov ds,ax\n";
			main_proc=1;
		}
	}
	;


func_declaration: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
	{
		bool res = table->Insert($2->getName(),"ID");
		if(!res){
			error_count++;
			fprintf(fp3,"Error at Line %d: Multiple Declaration of %s\n\n",yylineno,$2->getName().c_str());
		}
		else{
			table->Lookup($2->getName())->isFunc=true;
			table->Lookup($2->getName())->datatype=$1->getName();
			table->Lookup($2->getName())->param_list=param_parse($4->getName());
		}
		fprintf(fp2,"At line no %d: func_declaration: type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n\n",yylineno);
		$$->setName($1->getName()+" "+$2->getName()+"("+$4->getName()+")"+";");
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
	}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			bool res = table->Insert($2->getName(),"ID");
			if(!res){
				error_count++;
				fprintf(fp3,"Error at Line %d: Multiple Declaration of %s\n\n",yylineno,$2->getName().c_str());
			}
			else{
				table->Lookup($2->getName())->isFunc=true;
				table->Lookup($2->getName())->datatype=$1->getName();
			}
			fprintf(fp2,"At line no %d: func_declaration: type_specifier ID LPAREN RPAREN SEMICOLON\n\n",yylineno);
			$$->setName($1->getName()+" "+$2->getName()+"("+")"+";");
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
		}
		;
		 
func_definition: func_start compound_statement
	{
		//cout<<$2->getSymbol()<<endl;
		if(has_param==1){
			fprintf(fp2,"At line no %d: func_definition: type_specifier ID LPAREN parameter_list RPAREN compound_statement\n\n",yylineno);
		}
		else{
			fprintf(fp2,"At line no %d: func_definition: type_specifier ID LPAREN RPAREN compound_statement\n\n",yylineno);
		}
		$$->setName($1->getName()+" "+$2->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
		$$->code =$1->code + $2->code;
		if(current_offset>0){
			string label = newLabel();
			$$->code+="mov cx,"+to_string(current_offset/2+param_count)+"\n";
			$$->code+=label+":\n";
			$$->code+="pop ax\nloop "+label+"\n";
		}
		if(!main_proc){
			$$->code+="ret "+to_string(param_count*2)+"\n";
		}
		$$->code+=current_func+" endp\n";
		current_offset=0;
		param_count=0;
		table->Lookup(current_func)->setSymbol($2->getSymbol());
		if(main_proc) main_proc=0;
		var_list.clear();
		ret_state=0;
		global_flag=1;
	}
 		;				


parameter_list: parameter_list COMMA type_specifier ID
	{
		fprintf(fp2,"At line no %d: parameter_list: parameter_list COMMA type_specifier ID\n\n",yylineno);
		$$->setName($1->getName()+","+$3->getName()+" "+$4->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
		param_count++;
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
			param_count++;
		 }
		| type_specifier
		{
			fprintf(fp2,"At line no %d: parameter_list: type_specifier\n\n",yylineno);
			fprintf(fp2,"%s\n\n",$1->getName().c_str());
		}
 		;

 		
compound_statement: compound_statement_start statements RCURL
	{
		fprintf(fp2,"At line no %d: compound_statement: LCURL statements RCURL\n\n",yylineno);
		$$->setName("{\n"+$2->getName()+"\n}");
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
		table->PrintAll(fp2);
		table->ExitScope();
		func_flag=0;
		current_param="";
		$$->code = $2->code;
		$$->setSymbol($2->getSymbol());
	}
 		    | compound_statement_start RCURL
			 {
				fprintf(fp2,"At line no %d: compound_statement: LCURL RCURL\n\n",yylineno);
				$$->setName("{\n}");
				fprintf(fp2,"%s\n\n",$$->getName().c_str());
				table->PrintAll(fp2);
				table->ExitScope();
				func_flag=0;
				current_param="";
			 }
 		    ;
compound_statement_start: LCURL
	{
		table->EnterScope();
		if(func_flag==1){
			vector<string> tokens;
			stringstream temp(current_param);
			string intermediate;
			while(getline(temp,intermediate,',')){
				tokens.push_back(intermediate);
			}
			for(int i=0;i<tokens.size();i++){
				stringstream strm(tokens[i]);
				getline(strm,intermediate,' ');
				string type = intermediate;
				getline(strm,intermediate,' ');
				string name = intermediate;
				bool res = table->Insert(name,"ID");
				if(!res){
					error_count++;
					fprintf(fp3,"Error at line %d: Multiple declaration of %s in parameter\n\n",yylineno,name.c_str());
				}
				else{
					table->Lookup(name)->datatype=type;
					table->Lookup(name)->offset=(tokens.size()*2-i*2);
				}
			}
		}
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
			if(table->Lookup(tokens[i])->multiDec==false){
				table->Lookup(tokens[i])->datatype=$1->getName();
			}
		}
		if($1->getName()=="void"){
			error_count++;
			fprintf(fp3,"Error at line %d: Variable type cannot be void\n\n",yylineno);
		}
		fprintf(fp2,"At line no %d: var_declaration: type_specifier declaration_list SEMICOLON\n\n",yylineno);
		$$->setName($1->getName()+" "+$2->getName()+";");
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
		$$->code=$2->code;
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
			table->Lookup($3->getName())->multiDec=true;
			error_count++;
			fprintf(fp3,"Error at Line %d: Multiple Declaration of %s\n\n",yylineno,$3->getName().c_str());
		}
		else{
			if(global_flag==1){
				global_var_list.push_back($3->getName());
				table->Lookup($3->getName())->isGlobal=true;
			}
			else{
				$$->code="mov ax,0\npush ax\n";
				current_offset+=2;
				table->Lookup($3->getName())->offset=2;
				offset_inc(1);
				var_list.push_back($3->getName());
			}
		}
		fprintf(fp2,"At line no %d: declaration_list: declaration_list COMMA ID\n\n",yylineno);
		$$->setName($1->getName()+","+$3->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
	}
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
		   {
			   bool res = table->Insert($3->getName(),$3->getType());
				if(!res){
					table->Lookup($3->getName())->multiDec=true;
					error_count++;
					fprintf(fp3,"Error at Line %d: Multiple Declaration of %s\n\n",yylineno,$3->getName().c_str());
				}
				else{
					table->Lookup($3->getName())->isArray=true;
					if(global_flag==1){
						global_var_list.push_back($3->getName());
						table->Lookup($3->getName())->arraySize=stoi($5->getName());
						table->Lookup($3->getName())->isGlobal=true;
					}
					else{
						string label = newLabel();
						$$->code+="mov cx,"+$5->getName()+"\n";
						$$->code+="mov ax,0\n"+label+":\n";
						$$->code+="push ax\nloop "+label+"\n";
						current_offset+=2*stoi($5->getName());
						table->Lookup($3->getName())->offset=2;
						int cnt=stoi($5->getName());
						offset_inc(cnt);
						var_list.push_back($3->getName());
					}
				}
			   	fprintf(fp2,"At line no %d: declaration_list: declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n\n",yylineno);
				$$->setName($1->getName()+","+$3->getName()+"["+$5->getName()+"]");
				fprintf(fp2,"%s\n\n",$$->getName().c_str());
		   }
 		  | ID
		   {
			   	bool res = table->Insert($1->getName(),$1->getType());
				if(!res){
					table->Lookup($1->getName())->multiDec=true;
					error_count++;
					fprintf(fp3,"Error at Line %d: Multiple Declaration of %s\n\n",yylineno,$1->getName().c_str());
				}
				else{
					if(global_flag==1){
						global_var_list.push_back($1->getName());
						table->Lookup($1->getName())->isGlobal=true;
					}
					else{
						$$->code="mov ax,0\npush ax\n";
						current_offset+=2;
						table->Lookup($1->getName())->offset=2;
						offset_inc(1);
						var_list.push_back($1->getName());
					}
				}
			   	fprintf(fp2,"At line no %d: declaration_list: ID\n\n",yylineno);
				fprintf(fp2,"%s\n\n",$1->getName().c_str());
		   }
 		  | ID LTHIRD CONST_INT RTHIRD
		   {
			   table->PrintAll(fp2);
			   bool res = table->Insert($1->getName(),$1->getType());
				if(!res){
					table->Lookup($1->getName())->multiDec=true;
					error_count++;
					fprintf(fp3,"Error at Line %d: Multiple Declaration of %s\n\n",yylineno,$1->getName().c_str());
				}
				else{
					table->Lookup($1->getName())->isArray=true;
					if(global_flag==1){
						global_var_list.push_back($1->getName());
						table->Lookup($1->getName())->arraySize=stoi($3->getName());
						table->Lookup($1->getName())->isGlobal=true;
					}
					else{
						string label = newLabel();
						$$->code+="mov cx,"+$3->getName()+"\n";
						$$->code+="mov ax,0\n"+label+":\n";
						$$->code+="push ax\nloop "+label+"\n";
						current_offset+=2*stoi($3->getName());
						table->Lookup($1->getName())->offset=2;
						int cnt=stoi($3->getName());
						offset_inc(cnt);
						var_list.push_back($1->getName());
					}
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
		$$->code = $1->code;
		$$->setSymbol($1->getSymbol());
		if(ret_state==1){
			ret_state=2;
		}
	}
	   | statements statement
	   {
		   	fprintf(fp2,"At line no %d: statements: statements statement\n\n",yylineno);
			$$->setName($1->getName()+"\n"+$2->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
			$$->code = $1->code+$2->code;
			if(ret_state==2){
				$$->setSymbol($1->getSymbol());
			}
			else{
				$$->setSymbol($2->getSymbol());
			}
			if(ret_state==1){
				ret_state=2;
			}
	   }
	   ;
	   
statement: var_declaration
	{
		fprintf(fp2,"At line no %d: statement: var_declaration\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
		$$->code=$1->code;
		//$$->setSymbol("null");
	}
	  | expression_statement
	  {
		  	fprintf(fp2,"At line no %d: statement: expression_statement\n\n",yylineno);
			fprintf(fp2,"%s\n\n",$1->getName().c_str());
			$$->code = $1->code;
			$$->setSymbol($1->getSymbol());
			//$$->setSymbol("null");
	  }
	  | compound_statement
	  {
		  	fprintf(fp2,"At line no %d: statement: compound_statement\n\n",yylineno);
			fprintf(fp2,"%s\n\n",$1->getName().c_str());
			$$->code = $1->code;
			$$->setSymbol($1->getSymbol());
			//$$->setSymbol("null");
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
		  	string start_label = newLabel();
			string end_label = newLabel();
		  	$$->code+="\n;for loop\n"+$3->code;
			$$->code+=start_label+":\n"+$4->code;
			$$->code+="mov ax,"+$4->getSymbol()+"\n";
			$$->code+="cmp ax,0\n";
			$$->code+="je "+end_label+"\n";
			$$->code+=$7->code+$5->code;
			$$->code+="jmp "+start_label+"\n";
			$$->code+=end_label+":\n";

		  	fprintf(fp2,"At line no %d: statement: FOR LPAREN expression_statement expression_statement expression RPAREN statement\n\n",yylineno);
			$$->setName($1->getName()+"("+$3->getName()+$4->getName()+$5->getName()+")"+$7->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
			//$$->setSymbol("null");
	  }
	  | IF LPAREN expression RPAREN statement %prec LOW_ELSE
	  {

		  	string end_label = newLabel();
			$$->code+="\n;if condition\n";
			$$->code+=$3->code;
			$$->code+="mov ax,"+$3->getSymbol()+"\n";
			$$->code+="cmp ax,0\n";
			$$->code+="je "+end_label+"\n";
			$$->code+=$5->code;
			$$->code+=end_label+":\n";

		  	fprintf(fp2,"At line no %d: statement: IF LPAREN expression RPAREN statement\n\n",yylineno);
			$$->setName($1->getName()+"("+$3->getName()+")"+$5->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
			//$$->setSymbol("null");
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {

		  	string label1 = newLabel();
			string label2 = newLabel();
			$$->code+="\n;if-else ondition\n";
			$$->code+=$3->code;
			$$->code+="mov ax,"+$3->getSymbol()+"\n";
			$$->code+="cmp ax,0\n";
			$$->code+="je "+label1+"\n";
			$$->code+=$5->code;
			$$->code+="jmp "+label2+"\n";
			$$->code+=label1+":\n";
			$$->code+=$7->code;
			$$->code+=label2+":\n";

		  	fprintf(fp2,"At line no %d: statement: IF LPAREN expression RPAREN statement ELSE statement\n\n",yylineno);
			$$->setName($1->getName()+"("+$3->getName()+")"+$5->getName()+$6->getName()+$7->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
			//$$->setSymbol("null");
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {

		  	string start_label = newLabel();
			string end_label = newLabel();
			$$->code+="\n;while loop\n"+start_label+":\n";
			$$->code+=$3->code;
			$$->code+="mov ax,"+$3->getSymbol()+"\n";
			$$->code+="cmp ax,0\n";
			$$->code+="je "+end_label+"\n";
			$$->code+=$5->code;
			$$->code+="jmp "+start_label+"\n";
			$$->code+=end_label+":\n";

		  	fprintf(fp2,"At line no %d: statement: WHILE LPAREN expression RPAREN statement\n\n",yylineno);
			$$->setName($1->getName()+"("+$3->getName()+")"+$5->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
			//$$->setSymbol("null");
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
		  	fprintf(fp2,"At line no %d: statement: PRINTLN LPAREN ID RPAREN SEMICOLON\n\n",yylineno);
			$$->setName($1->getName()+"("+$3->getName()+")"+$5->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
			if(table->Lookup($3->getName())->isGlobal==true){
				$$->code+="\n;print\nmov ax,"+$3->getName()+"\ncall printf\n";
			}
			else{
				$$->code+="\n;print\npush bp\nmov bp,sp\n";
				$$->code+="mov ax,[bp+"+to_string(table->Lookup($3->getName())->offset)+"]\n";
				$$->code+="call printf\npop bp\n";
			}
			
			//$$->setSymbol("null");
			
	  }
	  | RETURN expression SEMICOLON
	  {
		  	fprintf(fp2,"At line no %d: statement: RETURN expression SEMICOLON\n\n",yylineno);
			$$->setName($1->getName()+" "+$2->getName()+$3->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
			if(!main_proc){
				$$->code=$2->code;
				$$->code+="mov ax,"+$2->getSymbol()+"\nmov ret_val,ax\n";
				if(current_offset>0||param_count>0){
					string label = newLabel();
					$$->code+="mov cx,"+to_string(current_offset/2+param_count)+"\n";
					$$->code+=label+":\n";
					$$->code+="pop ax\nloop "+label+"\n";
				}
				$$->code+="ret "+to_string(param_count*2)+"\n";
				//$$->setSymbol($2->getSymbol());
				$$->setSymbol("ret_val");
				ret_state=1;
			}
	  }
	  ;
	  
expression_statement: SEMICOLON
	{
		fprintf(fp2,"At line no %d: expression_statement: SEMICOLON\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
	}			
			| expression SEMICOLON
			{
				$$->datatype = $1->datatype;
				fprintf(fp2,"At line no %d: expression_statement: expression SEMICOLON\n\n",yylineno);
				$$->setName($1->getName()+";");
				fprintf(fp2,"%s\n\n",$$->getName().c_str());
				$$->code = $1->code;
				$$->setSymbol($1->getSymbol());
			} 
			;
	  
variable: ID 	
{
	$$->var_id=$1->getName();
	if(table->Lookup($1->getName())==nullptr){
		error_count++;
		fprintf(fp3,"Error at Line %d : Undeclared Variable: %s\n\n",yylineno,$1->getName().c_str());
	}
	else{
		$$->datatype=table->Lookup($1->getName())->datatype;
		if(table->Lookup($1->getName())->isArray==true){
			error_count++;
			fprintf(fp3,"Error at Line %d : Type mismatch, %s is an array\n\n",yylineno,$1->getName().c_str());
		}
	}
	fprintf(fp2,"At line no %d: variable: ID\n\n",yylineno);
	fprintf(fp2,"%s\n\n",$1->getName().c_str());
	$$->offset = table->Lookup($1->getName())->offset;
	string temp = newTemp();
	if(table->Lookup($1->getName())->isGlobal==true){
		$$->code+="mov ax,"+$1->getName()+"\n";
		$$->code+="mov "+temp+",ax\n";
	}
	else{
		$$->code+="\n;var\npush bp\nmov bp,sp\n";
		$$->code+="mov ax,[bp+"+to_string(table->Lookup($1->getName())->offset+arg_count*2)+"]\n";
		$$->code+="mov "+temp+",ax\npop bp\n";
	}
	$$->setSymbol(temp);
}	
	| ID LTHIRD expression RTHIRD 
	{
		$$->var_id=$1->getName();
		$$->index=$3->getSymbol();
		if(table->Lookup($1->getName())==nullptr){
			error_count++;
			fprintf(fp3,"Error at Line %d : Undeclared Variable: %s\n\n",yylineno,$1->getName().c_str());
		}
		else{
			$$->datatype=table->Lookup($1->getName())->datatype;
			if(table->Lookup($1->getName())->isArray==false){
				error_count++;
				fprintf(fp3,"Error at Line %d : Type Mismatch,%s not an array\n\n",yylineno,$1->getName().c_str());
			}
		}
		if($3->datatype!="int"){
			error_count++;
			fprintf(fp3,"Error at Line %d : Non-integer Array Index\n\n",yylineno);
		}
		
		int ofst = table->Lookup($1->getName())->offset+arg_count;
		$$->offset=ofst;
		string temp = newTemp();
		if(table->Lookup($1->getName())->isGlobal==true){
			$$->code+="mov bx,"+$3->getSymbol()+"\n";
			$$->code+="mov ax,["+$1->getName()+"+bx]\n";
			$$->code+="mov "+temp+",ax\n";
		}
		else{
			$$->code+="\n;var\npush bp\nmov bp,sp\n";
			$$->code+="mov di,"+to_string(ofst)+"\n";
			$$->code+="add di,"+$3->getSymbol()+"\n";
			$$->code+="mov ax,[bp+di]\n";
			$$->code+="mov "+temp+",ax\npop bp\n";
		}
		$$->setSymbol(temp);

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
		$$->code = $1->code;
		$$->setSymbol($1->getSymbol());
	}
	   | variable ASSIGNOP logic_expression 
	   {
		   if($1->datatype=="float"&&($3->datatype=="int" || $3->datatype=="float")){
			   $$->datatype="float";
		   }
		   else if($3->datatype=="void"){
			   error_count++;
			   fprintf(fp3,"Error at Line %d : Void function used in expression\n\n",yylineno);
		   }
		   	else if($1->datatype!=$3->datatype){
				error_count++;
			   	fprintf(fp3,"Error at line %d : Type Mismatch\n\n",yylineno);
		   	}
			else{
				$$->datatype=$1->datatype;
			}
		   	fprintf(fp2,"At line no %d: expression: variable ASSIGNOP logic_expression\n\n",yylineno);
			$$->setName($1->getName()+$2->getName()+$3->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
			$$->code=$3->code;
			if(table->Lookup($1->var_id)->isGlobal==true){
				$$->code+="mov ax,"+$3->getSymbol()+"\n";
				if(table->Lookup($1->var_id)->isArray==true){
					$$->code+="mov bx,"+$1->index+"\n";
					$$->code+="mov ["+$1->var_id+"+bx],ax\n";
				}
				else{
					$$->code+="mov "+$1->var_id+",ax\n";
				}
			}
			else{
				$$->code+="\n;var=expr\npush bp\nmov bp,sp\n";
				$$->code+="mov ax,"+$3->getSymbol()+"\n";
				$$->code+="mov [bp+"+to_string($1->offset)+"],ax\n";
				$$->code+="pop bp\n";
			}
			$$->setSymbol($3->getSymbol());
	   }	
	   ;
			
logic_expression: rel_expression 	
	{
		fprintf(fp2,"At line no %d: logic_expression: rel_expression\n\n",yylineno);
		$$->datatype=$1->datatype;
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
		$$->code = $1->code;
		$$->setSymbol($1->getSymbol());
	}
		 | rel_expression LOGICOP rel_expression 
		 {
			 string label1 = newLabel();
			 string label2 = newLabel();
			 $$->code=$1->code+$3->code;
			 $$->code+="\n;expr LOGICOP expr\n";
			 $$->code+="mov ax,"+$1->getSymbol()+"\n";
			 $$->code+="mov bx,"+$3->getSymbol()+"\n";
			 $$->code+="cmp ax,0\n";
			 $$->code+="je "+label1+"\n";
			 $$->code+="mov ax,1\n";
			 $$->code+=label1+":\ncmp bx,0\n";
			 $$->code+="je "+label2+"\n";
			 $$->code+="mov bx,1\n";
			 $$->code+=label2+":\n";
			 if($2->getName()=="&&"){
				$$->code+="and ax,bx\n";
			 }
			 else if($2->getName()=="||"){
				$$->code+="or ax,bx\n";
			 }
			 $$->code+="mov "+$1->getSymbol()+",ax\n";
			 $$->setSymbol($1->getSymbol());

			 if($1->datatype=="void" || $3->datatype=="void"){
				error_count++;
				fprintf(fp3,"Error at Line %d : Void expression used with Logical operation\n\n",yylineno);
			}
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
		$$->code = $1->code;
		$$->setSymbol($1->getSymbol());
	}
		| simple_expression RELOP simple_expression	
		{
			string label1 = newLabel();
			string label2 = newLabel();
			$$->code=$1->code+$3->code;
			$$->code+="\n;expr RELOP expr\n";
			$$->code+="mov ax,"+$1->getSymbol()+"\n";
			$$->code+="mov bx,"+$3->getSymbol()+"\n";
			$$->code+="cmp ax,bx\n";
			if($2->getName()==">"){
				$$->code+="jg "+label1+"\n";
				$$->code+="mov ax,0\n";
				$$->code+="jmp "+label2+"\n";
			}
			else if($2->getName()==">="){
				$$->code+="jge "+label1+"\n";
				$$->code+="mov ax,0\n";
				$$->code+="jmp "+label2+"\n";
			}
			else if($2->getName()=="<"){
				$$->code+="jl "+label1+"\n";
				$$->code+="mov ax,0\n";
				$$->code+="jmp "+label2+"\n";
			}
			else if($2->getName()=="<="){
				$$->code+="jle "+label1+"\n";
				$$->code+="mov ax,0\n";
				$$->code+="jmp "+label2+"\n";
			}
			else if($2->getName()=="=="){
				$$->code+="je "+label1+"\n";
				$$->code+="mov ax,0\n";
				$$->code+="jmp "+label2+"\n";
			}
			else if($2->getName()=="!="){
				$$->code+="jne "+label1+"\n";
				$$->code+="mov ax,0\n";
				$$->code+="jmp "+label2+"\n";
			}
			$$->code+=label1+":\nmov ax,1\n";
			$$->code+=label2+":\n";
			$$->code+="mov "+$1->getSymbol()+",ax\n";
			$$->setSymbol($1->getSymbol());

			if($1->datatype=="void" || $3->datatype=="void"){
				error_count++;
				fprintf(fp3,"Error at Line %d : Void expression used with Relational operation\n\n",yylineno);
			}
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
		$$->code = $1->code;
		$$->setSymbol($1->getSymbol());
	}
		  | simple_expression ADDOP term 
		  {
			  	$$->code=$1->code+$3->code;
			  	$$->code+="\n;expr ADDOP expr\n";
				$$->code+="mov ax,"+$1->getSymbol()+"\n";
				if($2->getName()=="+"){
					$$->code+="add ax,"+$3->getSymbol()+"\n";
				}
				else if($2->getName()=="-"){
					$$->code+="sub ax,"+$3->getSymbol()+"\n";
				}
				$$->code+="mov "+$1->getSymbol()+",ax\n";
				$$->setSymbol($1->getSymbol());

			  	fprintf(fp2,"At line no %d: simple_expression: simple_expression ADDOP term\n\n",yylineno);
				if($1->datatype=="float"||$3->datatype=="float"){
					$$->datatype="float";
				}
				else{
					$$->datatype="int";
				}
				$$->setName($1->getName()+$2->getName()+$3->getName());
				fprintf(fp2,"%s\n\n",$$->getName().c_str());
		  }
		  ;
					
term:	unary_expression
	{
		fprintf(fp2,"At line no %d: term: unary_expression\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
		$$->datatype=$1->datatype;
		$$->code = $1->code;
		$$->setSymbol($1->getSymbol());
	}
     |  term MULOP unary_expression
	 {

		 	$$->code=$1->code+$3->code+"\n;term MULOP expr\n";
			if($2->getName()=="*"){
				$$->code+="mov ax,"+$1->getSymbol()+"\n";
				$$->code+="mov bx,"+$3->getSymbol()+"\n";
				$$->code+="imul bx\n";
				$$->code+="mov "+$1->getSymbol()+",ax\n";
			}
			else if($2->getName()=="/"){
				$$->code+="mov dx,0\n";
				$$->code+="mov ax,"+$1->getSymbol()+"\n";
				$$->code+="mov bx,"+$3->getSymbol()+"\n";
				$$->code+="idiv bx\n";
				$$->code+="mov "+$1->getSymbol()+",ax\n";
			}
			else if($2->getName()=="%"){
				$$->code+="mov dx,0\n";
				$$->code+="mov ax,"+$1->getSymbol()+"\n";
				$$->code+="mov bx,"+$3->getSymbol()+"\n";
				$$->code+="idiv bx\n";
				$$->code+="mov "+$1->getSymbol()+",dx\n";
			}
			$$->setSymbol($1->getSymbol());

		 	if($3->datatype=="void"){
				error_count++;
				fprintf(fp3,"Error at Line %d : Void function used in expression\n\n",yylineno);
			}
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
				else if($3->getName()=="0"){
					error_count++;
					fprintf(fp3,"Error at Line %d : Modulus by zero\n\n",yylineno);
					$$->datatype="int";
				}
			}
	 }
     ;

unary_expression: ADDOP unary_expression  
	{
		$$->datatype=$2->datatype;
		if($2->datatype=="void"){
			error_count++;
			fprintf(fp3,"Error at Line %d : Void function used in expression\n\n",yylineno);
		}
		fprintf(fp2,"At line no %d: unary_expression: ADDOP unary_expression\n\n",yylineno);

		$$->code+=$2->code+"\n;ADDOP expr\n";
		if($1->getName()=="-"){
			$$->code+="mov ax,0\n";
			$$->code+="sub ax,"+$2->getSymbol()+"\n";
			$$->code+="mov "+$2->getSymbol()+",ax\n";
		}
		$$->setSymbol($2->getSymbol());

		$$->setName($1->getName()+$2->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
	}
		 | NOT unary_expression 
		 {
			if($2->datatype=="void"){
				error_count++;
				fprintf(fp3,"Error at Line %d : Void function used in expression\n\n",yylineno);
			}
			fprintf(fp2,"At line no %d: unary_expression: NOT unary_expression\n\n",yylineno);
			$$->setName($1->getName()+$2->getName());
			fprintf(fp2,"%s\n\n",$$->getName().c_str());
			$$->datatype=$2->datatype;
			string label1 = newLabel();
			string label2 = newLabel();
			$$->code+=$2->code;
			$$->code+="\n;!expr\n";
			$$->code+="cmp "+$2->getSymbol()+",0\n";
			$$->code+="je "+label1+"\n";
			$$->code+="mov "+$2->getSymbol()+",0\njmp "+label2+"\n";
			$$->code+=label1+":\nmov "+$2->getSymbol()+",1\n"+label2+":\n";
			$$->setSymbol($2->getSymbol());
		 }
		 | factor 
		 {
			fprintf(fp2,"At line no %d: unary_expression: factor\n\n",yylineno);
			fprintf(fp2,"%s\n\n",$1->getName().c_str());
			$$->datatype=$1->datatype;
			$$->code = $1->code;
			$$->setSymbol($1->getSymbol());
		 }
		 ;
	
factor: variable
	{
		fprintf(fp2,"At line no %d: factor: variable\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
		$$->datatype=$1->datatype;
		//string temp = newTemp();
		//$$->code+="\n;var\npush bp\nmov bp,sp\n";
		//$$->code+="mov ax,[bp+"+to_string($1->offset)+"]\n";
		//$$->code+="mov "+temp+",ax\npop bp\n";
		$$->setSymbol($1->getSymbol());
	}
	| ID LPAREN argument_list RPAREN
	{

		$$->code=$3->code+"call "+$1->getName()+"\n";
		string temp=newTemp();
		//$$->code+="mov ax,"+table->Lookup($1->getName())->getSymbol()+"\n";
		$$->code+="mov ax,ret_val\n";
		$$->code+="mov "+temp+",ax\n";
		$$->setSymbol(temp);
		if(table->Lookup($1->getName())==nullptr){
			error_count++;
			fprintf(fp3,"Error at Line %d : Undeclared Variable: %s\n\n",yylineno,$1->getName().c_str());
		}
		else{
			$$->datatype=table->Lookup($1->getName())->datatype;
			if(table->Lookup($1->getName())->isFunc==false){
				error_count++;
				fprintf(fp3,"Error at Line %d : Function called with non-function type identifier\n\n",yylineno);
			}
			vector<string> def_args=table->Lookup($1->getName())->param_list;
			vector<string> imp_args=$3->param_list;
			if(def_args.size()!=imp_args.size()){
				error_count++;
				fprintf(fp3,"Error at Line %d : Total number of arguments mismatch with declaration in function %s\n\n",yylineno,$1->getName().c_str());
			}
			else{
				for(int i=0;i<def_args.size();i++){
					if(def_args[i]!=imp_args[i]){
						error_count++;
						fprintf(fp3,"Error at Line %d : %dth argument mismatch in function %s\n\n",yylineno,i+1,$1->getName().c_str());
						break;
					}
				}
			}
		}
		fprintf(fp2,"At line no %d: factor: ID LPAREN argument_list RPAREN\n\n",yylineno);
		$$->setName($1->getName()+$2->getName()+$3->getName()+$4->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
		arg_count=0;
	}
	| LPAREN expression RPAREN
	{
		fprintf(fp2,"At line no %d: factor: LPAREN expression RPAREN\n\n",yylineno);
		$$->datatype=$2->datatype;
		$$->setName($1->getName()+$2->getName()+$3->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
		$$->code=$2->code;
		$$->setSymbol($2->getSymbol());
	}
	| CONST_INT
	{
		fprintf(fp2,"At line no %d: factor: CONST_INT\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
		$$->datatype="int";
		string temp = newTemp();
		$$->code="\n;const_int\npush bp\nmov bp,sp\n";
		$$->code+="mov "+temp+","+$1->getName()+"\npop bp\n";
		$$->setSymbol(temp);
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
		$$->datatype=$1->datatype;
		$$->setName($1->getName()+$2->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
		string temp = newTemp();
		if(table->Lookup($1->var_id)->isGlobal==true){
			if(table->Lookup($1->var_id)->isArray==true){
				$$->code="mov bx,"+$1->index+"\n";
				$$->code+="mov ax,["+$1->var_id+"+bx]\n";
			}
			else{
				$$->code="mov ax,"+$1->var_id+"\n";
			}
		}
		else{
			$$->code="\n;var incop\npush bp\nmov bp,sp\n";
			$$->code+="mov ax,[bp+"+to_string($1->offset)+"]\n";
			$$->code+="mov "+temp+",ax\n";
		}
		if($2->getName()=="++"){
			$$->code+="add ax,1\n";
		}
		else{
			$$->code+="sub ax,1\n";
		}
		if(table->Lookup($1->var_id)->isGlobal==true){
			if(table->Lookup($1->var_id)->isArray==true){
				$$->code="mov bx,"+$1->index+"\n";
				$$->code+="mov ["+$1->var_id+"+bx],ax\n";
			}
			else{
				$$->code="mov "+$1->var_id+",ax\n";
			}
		}
		else{
			$$->code+="mov [bp+"+to_string($1->offset)+"],ax\n";
			//$$->code+="mov "+temp+",ax\npop bp\n";
			$$->code+="pop bp\n";
		}
		$$->setSymbol(temp);
	} 
	| variable DECOP
	{
		fprintf(fp2,"At line no %d: factor: variable DECOP\n\n",yylineno);
		$$->datatype=$1->datatype;
		$$->setName($1->getName()+$2->getName());
		fprintf(fp2,"%s\n\n",$$->getName().c_str());
	}
	;
	
argument_list: arguments
	{
		fprintf(fp2,"At line no %d: argument_list: arguments\n\n",yylineno);
		fprintf(fp2,"%s\n\n",$1->getName().c_str());
		$$->param_list=$1->param_list;
		$$->code=$1->code;
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
		$$->code=$1->code+$3->code+"mov ax,"+$3->getSymbol()+"\npush ax\n";
		arg_count++;
	}
	      | logic_expression
		  {
			  	fprintf(fp2,"At line no %d: arguments: logic_expression\n\n",yylineno);
				fprintf(fp2,"%s\n\n",$1->getName().c_str());
				$$->param_list.push_back($1->datatype);
				$$->code=$1->code+"mov ax,"+$1->getSymbol()+"\npush ax\n";
				arg_count++;
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
	fp4= fopen(argv[4],"w");
	fclose(fp4);
	
	fp2= fopen(argv[2],"a");
	fp3= fopen(argv[3],"a");
	fp4= fopen(argv[4],"a");

	yyin=fp;
	yyparse();
	

	fclose(fp2);
	fclose(fp3);
	
	return 0;
}

