#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

void queueinit(){

    for(int i=0;i<4;i++){
        p_mlfq[i]=(queue*)malloc(sizeof(queue));
        p_mlfq[i]->ind=0;
        p_mlfq[i]->front=-1;

    }

}

void insert(queue* m,struct proc* p){

    m->q[m->ind]=p;
    m->ind++;
    m->front=0;
    

}

struct proc* delete(queue* m,int pid){
    int pos=-1;
    for(int i=m->front;i<m->ind;i++){
        if(m->q[i]->pid==pid){
            pos=i;
            break;
        }
    }

    for(int i=pos;i<m->ind;i++){

        m->q[i]=m->q[i+1];


    }
    m->ind--;

}





