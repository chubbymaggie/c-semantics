/* Generated by CIL v. 1.3.7 */
/* print_CIL_Input is true */

extern void exit(int  ) ;
extern void abort(void) ;
void check(int a ) 
{ 

  {
  if (a != 1) {
    abort();
  }
  return;
}
}
void test(int a , int b ) 
{ int tmp ;
  int tmp___0 ;

  {
  if (a) {
    tmp = 1;
  } else {
    tmp = 0;
  }
  if (b) {
    tmp___0 = 2;
  } else {
    tmp___0 = 0;
  }
  check(tmp | tmp___0);
  return;
}
}
int main(void) 
{ 

  {
  test(1, 0);
  exit(0);
}
}