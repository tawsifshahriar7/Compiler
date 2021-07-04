#include<bits/stdc++.h>
#include<regex>
using namespace std;

int main(){
    ifstream fin;
    fin.open("code.asm");
    string line;
    vector<string> code;
    while(getline(fin,line)){
        if(line[0]==';')
            continue;
        code.push_back(line);
    }
    vector<vector<string>> code_tokens;
    for(int i=0;i<code.size();i++){
        regex re("[ ,]");
        sregex_token_iterator first{code[i].begin(), code[i].end(), re, -1}, last;
        vector<std::string> tokens{first, last};
        code_tokens.push_back(tokens);
    }
    vector<int> need_to_be_erased;
    for(int i=0;i<code_tokens.size()-1;i++){
        if(code_tokens[i][0]=="mov" && code_tokens[i+1][0]=="mov"){
            if(code_tokens[i][1]==code_tokens[i+1][2] && code_tokens[i][2]==code_tokens[i+1][1]){
                need_to_be_erased.push_back(i+1);
                code[i]+="    ;next line was erased";
            }
        }
    }
    for(int i=0;i<need_to_be_erased.size();i++){
        code.erase(code.begin()+need_to_be_erased[i]);
    }
    ofstream fout;
    fout.open("optimized_code.asm");
    for(int i=0;i<code.size();i++){
        fout<<code[i]<<endl;
    }
    return 0;
}
