/* Generated by CIL v. 1.3.7 */
/* print_CIL_Input is true */

typedef short COUNT;
typedef char TEXT;
union T_VALS {
   TEXT *id  __attribute__((__packed__, __aligned__(2))) ;
};
typedef union T_VALS VALS;
struct T_VAL {
   COUNT pos  __attribute__((__packed__, __aligned__(2))) ;
   VALS vals  __attribute__((__packed__, __aligned__(2))) ;
};
typedef struct T_VAL VAL;
typedef unsigned short WORD;
extern  __attribute__((__nothrow__, __noreturn__)) void exit(int __status )  __attribute__((__leaf__)) ;
static char id_space[2][33]  ;
VAL curval  =    {(COUNT )0, {(TEXT *)0}};
static short idc  =    (short)0;
static int cur_line  ;
static int char_pos  ;
WORD get_id(char c ) 
{ 

  {
  *(curval.vals.id + 0) = c;
  return ((unsigned short)0);
}
}
WORD get_tok(void) 
{ char c ;
  WORD tmp ;

  {
  c = (char )'c';
  curval.vals.id = id_space[idc];
  curval.pos = (short )((cur_line << 10) | char_pos);
  tmp = get_id(c);
  return (tmp);
}
}
int main(void) 
{ 

  {
  get_tok();
  exit(0);
}
}