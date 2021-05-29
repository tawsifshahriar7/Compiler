#include<bits/stdc++.h>
#include "SymbolInfo.h"
#ifndef SCOPE
#define SCOPE
using namespace std;
class ScopeTable{
private:
    int total_buckets;
    ScopeTable* parentScope;
    string id;
    vector<SymbolInfo*> SymbolList;
    int hash(string Name){
        int sum=0;
        for(int i=0;i<Name.length();i++){
            sum+=Name[i];
        }
        sum=sum%total_buckets;
        return sum;
    }

public:
    int deleted_child=0;
    ScopeTable(int n){
        total_buckets=n;
        SymbolList.resize(n);
        for(auto & i : SymbolList){
            i=nullptr;
        }
        parentScope= nullptr;
        id="1";
    }
    ~ScopeTable(){
        SymbolList.clear();
        SymbolList.resize(0);
    }
    ScopeTable* getParent(){
        return parentScope;
    }
    void setParent(ScopeTable* s){
        parentScope=s;
    }
    string getID(){
        return id;
    }
    void setID(string x){
        id=x;
    }
    bool Insert(SymbolInfo* s){
        int index=0;
        int hash_val=hash(s->getName());
        if(SymbolList[hash_val]==nullptr){
            SymbolList[hash_val]=s;
        }
        else{
            SymbolInfo* curr=SymbolList[hash_val];
            if(curr->getName()==s->getName()){
                return false;
            }
            if(curr->next== nullptr){
                index++;
            }
            while(curr->next!= nullptr){
                curr=curr->next;
                index++;
            }
            curr->next=s;
        }
        return true;
    }
    SymbolInfo* Lookup(string symbol){
        int index=0;
        int hash_val=hash(symbol);
        if(SymbolList[hash_val]!= nullptr){
            SymbolInfo* curr=SymbolList[hash_val];
            while(curr->next!= nullptr){
                if(curr->getName()==symbol){
                    return curr;
                }
                curr=curr->next;
                index++;
            }
            if(curr->getName()==symbol){
                return curr;
            }
            else{
                return nullptr;
            }
        }
        else{
            return nullptr;
        }
    }
    bool Delete(string symbol){
        int index=0;
        int hash_val=hash(symbol);
        if(SymbolList[hash_val]!= nullptr){
            SymbolInfo* curr=SymbolList[hash_val];
            if(curr->getName()==symbol){
                SymbolList[hash_val]= curr->next;
                return true;
            }
            while(curr->next!= nullptr){
                if(curr->next->getName()==symbol){
                    curr->next=curr->next->next;
                    return true;
                }
                curr=curr->next;
                index++;
            }
            return false;
        }
        else{
            return false;
        }
    }
    void Print(FILE* logout){
        fprintf(logout,"ScopeTable# %s\n",id.c_str());
        for(int i=0;i<total_buckets;i++){
            if(SymbolList[i]!=nullptr){
            fprintf(logout,"%d --> ",i);
            SymbolInfo* curr=SymbolList[i];
            if(curr!= nullptr){
                while (curr!= nullptr){
                    fprintf(logout," <%s : %s> ",curr->getName().c_str(),curr->getType().c_str());
                    curr=curr->next;
                }
            }
            fprintf(logout,"\n");
            }
        }
        fprintf(logout,"\n");
    }
};

#endif