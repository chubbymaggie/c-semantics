/* Generated by CIL v. 1.3.7 */
/* print_CIL_Input is true */

typedef __builtin_va_list __gnuc_va_list;
typedef __gnuc_va_list va_list;
typedef double L;
/* compiler builtin: 
   void __builtin_va_end(__builtin_va_list  ) ;  */
/* compiler builtin: 
   void __builtin_va_arg(__builtin_va_list  , unsigned long  , void * ) ;  */
/* compiler builtin: 
   void __builtin_va_start(__builtin_va_list  ) ;  */
extern  __attribute__((__nothrow__, __noreturn__)) void abort(void)  __attribute__((__leaf__)) ;
extern  __attribute__((__nothrow__, __noreturn__)) void exit(int __status )  __attribute__((__leaf__)) ;
void f(L p0 , L p1 , L p2 , L p3 , L p4 , L p5 , L p6 , L p7 , L p8  , ...) 
{ va_list select___0 ;
  L tmp ;
  L tmp___0 ;
  L tmp___1 ;

  {
  __builtin_va_start(select___0, p8);
  tmp = __builtin_va_arg(select___0, L );
  if (tmp != 10.) {
    abort();
  }
  tmp___0 = __builtin_va_arg(select___0, L );
  if (tmp___0 != 11.) {
    abort();
  }
  tmp___1 = __builtin_va_arg(select___0, L );
  if (tmp___1 != 0.) {
    abort();
  }
  __builtin_va_end(select___0);
  return;
}
}
int main(void) 
{ 

  {
  f(1., 2., 3., 4., 5., 6., 7., 8., 9., 10., 11., 0.);
  exit(0);
}
}