#include<bits/stdc++.h>
#include "SymbolInfo.h"
#include "ScopeTable.h"
using namespace std;

#ifndef SYMBOLTABLE
#define SYMBOLTABLE

class SymbolTable{
private:
    int no_of_buckets;
    ScopeTable* current;
public:
    SymbolTable(int b){
        no_of_buckets=b;
        ScopeTable* x;
        x=new ScopeTable(no_of_buckets);
        x->setParent(nullptr);
        current=x;
    }
    ~SymbolTable(){
        if(current!= nullptr){
            ScopeTable* parent=current->getParent();
            while(parent!=nullptr){
                delete current;
                current=parent;
                parent=parent->getParent();
            }
            delete current;
        }
    }

    void EnterScope() {
        ScopeTable* nS;
        nS=new ScopeTable(no_of_buckets);
        nS->setParent(current);
        string newID=current->getID()+"."+to_string(current->deleted_child+1);
        nS->setID(newID);
        current=nS;
    }

    void ExitScope() {
        if(current->getParent()== nullptr){
            string prev_id=current->getID();
            int x=stoi(prev_id);
            x++;
            string new_id=to_string(x);
            current=new ScopeTable(no_of_buckets);
            current->setID(new_id);
            return;
        }
        ScopeTable* x=current;
        current=current->getParent();
        current->deleted_child+=1;
        delete x;
    }

    bool Insert(string symbol,string type) {
        SymbolInfo* s;
        s=new SymbolInfo(symbol,type);
        SymbolInfo* x=current->Lookup(symbol);
        if(x!=nullptr) return false;
        bool res= current->Insert(s);
        return res;
    }

    bool Remove(string symbol) {
        return current->Delete(symbol);
    }

    SymbolInfo* Lookup(string symbol) {
        ScopeTable* curr=current;
        SymbolInfo* res;
        while(curr->getParent()!= nullptr){
            res=curr->Lookup(symbol);
            if(res!= nullptr){
                return res;
            }
            curr=curr->getParent();
        }
        if(curr->getParent()== nullptr){
            res=curr->Lookup(symbol);
            if(res!= nullptr){
                return res;
            }
        }
        return nullptr;
    }

    void PrintCurrent(FILE* logout) {
        current->Print(logout);
    }

    void PrintAll(FILE* logout) {
        ScopeTable* x=current;
        while(x->getParent()!= nullptr){
            x->Print(logout);
            x=x->getParent();
        }
        x->Print(logout);
    }
};

#endif