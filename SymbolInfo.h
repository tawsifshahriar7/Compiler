#ifndef Info
#define Info
#include<vector>
using namespace std;
class SymbolInfo{
private:
    string Name,Type;
public:
    string datatype;
	string code;
    SymbolInfo* next;
    bool isFunc;
    bool isArray;
    bool multiDec;
	string symbol;
    int offset;
    bool isGlobal;
	int arraySize;
	string var_id;
	string index;
    vector<string> param_list;
    SymbolInfo(string Name,string Type){
        next=nullptr;
        isFunc=false;
        isArray=false;
        multiDec=false;
        isGlobal=false;
        this->Name=Name;
        this->Type=Type;
    }
    string getName(){
        return Name;
    }
    void setName(string Name){
        this->Name=Name;
    }
    string getType(){
        return Type;
    }
    void setType(string Type){
        this->Type=Type;
    }
	string getSymbol(){
		return symbol;
	}
	void setSymbol(string s){
		symbol=s;
	}
    ~SymbolInfo()= default;
};

#endif
