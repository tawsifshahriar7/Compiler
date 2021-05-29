#ifndef Info
#define Info
#include<vector>
using namespace std;
class SymbolInfo{
private:
    string Name,Type;
public:
    string datatype;
    SymbolInfo* next;
    bool isFunc;
    bool isArray;
    vector<string> param_list;
    SymbolInfo(string Name,string Type){
        next=nullptr;
        isFunc=false;
        isArray=false;
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
    ~SymbolInfo()= default;
};

#endif
