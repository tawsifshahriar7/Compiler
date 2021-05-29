#ifndef funcinfo
#define funcinfo

using namespace std;
class FuncInfo{
public:
    vector<string> param_list;
    string ret_type;
    FuncInfo(){
        ret_type="NULL";
    }
};
#endif