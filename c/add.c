#define KXVER 3
#include "k.h"
#include "stdlib.h"
K add (K x, K y)
{
  return ki(x->i+y->i);
}

K test (K x)
{
  K vector=ktn(KI,0);
  int i,j;
  for(i=0;i<x->n;i++)
  {
    j=kI(x)[i];
    ja(&vector,&j);
  }
  return vector;
}
