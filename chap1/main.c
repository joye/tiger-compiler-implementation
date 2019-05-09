#include "slp.h"
#include "prog1.h"
#include <stdio.h>

typedef struct table *Table_;

struct table { string id; int value; Table_ tail; };

struct IntAndTable { int i; Table_ t; };

Table_ interpStm(A_stm s, Table_ t);

Table_ Table(string id, int value, Table_ tail)
{
    Table_ t = checked_malloc(sizeof(*t));
    t->id = id;
    t->value = value;
    t->tail = tail;
    return t;
}

Table_ update(Table_ t, string id, int value)
{
    return Table(id, value, t);
}

int lookup(Table_ t, string key)
{
    while (t->id != key)
    {
        t = t->tail;
    }

    return t->value;
}

struct IntAndTable interpExp(A_exp e, Table_ t)
{
    if (e->kind == A_idExp)
    {
        int d = lookup(t, e->u.id);
        struct IntAndTable ret;
        ret.i = d;
        ret.t = t;
        return ret;
    }
    else if (e->kind == A_numExp)
    {
        struct IntAndTable ret;
        ret.i = e->u.num;
        ret.t = t;
        return ret;
    }
    else if (e->kind == A_opExp)
    {
        struct IntAndTable left_res = interpExp(e->u.op.left, t);
        struct IntAndTable right_res = interpExp(e->u.op.right, left_res.t);
        struct IntAndTable ret;
        switch (e->u.op.oper)
        {
        case A_plus:
        {
            ret.i = left_res.i + right_res.i;
            break;
        }
        case A_minus:
        {
            ret.i = left_res.i - right_res.i;
            break;
        }
        case A_times:
        {
            ret.i = left_res.i * right_res.i;
            break;
        }
        case A_div:
        {
            ret.i = left_res.i / right_res.i;
            break;
        }
        }
        ret.t = right_res.t;
        return ret;
    }
    else
    {
        Table_ res = interpStm(e->u.eseq.stm, t);
        return interpExp(e->u.eseq.exp, res);
    }
}

struct IntAndTable interpExpList(A_expList exps, Table_ t)
{
    if (exps->kind == A_lastExpList)
    {
        struct IntAndTable res = interpExp(exps->u.last, t);

        printf("%0d\n", res.i);

        return res;
    }
    else
    {
        struct IntAndTable head_res = interpExp(exps->u.pair.head, t);
        printf("%0d ", head_res.i);
        return interpExpList(exps->u.pair.tail, head_res.t);
    }
}


int count_args(A_expList exp)
{
    if (exp->kind == A_lastExpList)
        return 1;
    else
        return 1 + count_args(exp->u.pair.tail);
}
int maxargs(A_stm stm);

int maxargs_in_exp(A_exp exp)
{
    if (exp->kind == A_opExp)
    {
        int left_res  = maxargs_in_exp(exp->u.op.left);
        int right_res = maxargs_in_exp(exp->u.op.right);

        return (left_res > right_res) ? left_res : right_res;
    }
    else if (exp->kind == A_eseqExp)
    {
        int stm_res = maxargs(exp->u.eseq.stm);
        int exp_res = maxargs_in_exp(exp->u.eseq.exp);
        return (stm_res > exp_res) ? stm_res : exp_res;
    }
    else
    {
        return 0;
    }
}

int maxargs(A_stm stm)
{

    int res = 0;

    if (stm->kind == A_printStm)
    {
        res = count_args(stm->u.print.exps);
    }
    else if (stm->kind == A_compoundStm)
    {
        int stm1_res = maxargs(stm->u.compound.stm1);
        int stm2_res = maxargs(stm->u.compound.stm2);
        res = (stm1_res > stm2_res) ? stm1_res : stm2_res;
    }
    else if (stm->kind == A_assignStm)
    {
        res = maxargs_in_exp(stm->u.assign.exp);
    }


    return res;
}

Table_ interpStm(A_stm s, Table_ t)
{
    switch (s->kind) {
    case A_compoundStm:
        t = interpStm(s->u.compound.stm1, t);
        t = interpStm(s->u.compound.stm2, t);
        break;
    case A_assignStm:
    {
        struct IntAndTable exp_res = interpExp(s->u.assign.exp, t);
        t = update(t, s->u.assign.id, exp_res.i);
        break;
    }
    case A_printStm:
    {
        struct IntAndTable print_res = interpExpList(s->u.print.exps, t);
        t = print_res.t;
        break;
    }
    }

    return t;
}

void interp(A_stm stm)
{
    Table_ t = NULL;
    t = interpStm(stm, t);
}

int main()
{
    int maxargs_res = maxargs(prog());
    printf("%d\n", maxargs_res);
    interp(prog());
    return 0;
}