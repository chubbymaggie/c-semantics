// vim: set ts=2 sw=2:
require "builtins/list.k"
require "builtins/map.k"
require "builtins/mint.k"

require "cil-syntax.k"
require "cil-typing.k" // for typing syntax

module CIL-COMMON-PTR
  imports CIL-SYNTAX
  imports CIL-COMMON
  /*
   * Ptr of BasePtr * Offset
   * @invariant: 0 <= Offset <= BasePtr.Size
   * @immutable: BasePtr
   */
  syntax Ptr ::= Ptr(BasePtr, Int)
               | FunPtr
               | "Null"             [smtlib(smt_pointer_null)]

  syntax FunPtr ::= FunPtr(CId, TransUnit) | ExtFun(String)

  /*
   * BasePtr of Base * Size
   * @immutable: Base, Size
   */
  syntax BasePtr ::= "BasePtr" "(" Int "," Int ")"

  syntax Ptr ::= "PtrAdd" "(" Ptr "," Int "," Exp ")"   [function]
  syntax Int ::= "PtrSub" "(" Ptr "," Ptr "," Exp ")"   [function]
  syntax Bool ::= "PtrLt" "(" Ptr "," Ptr ")"  [function]
                | "PtrLeq" "(" Ptr "," Ptr ")" [function]
                | "PtrGt" "(" Ptr "," Ptr ")"  [function]
                | "PtrGeq" "(" Ptr "," Ptr ")" [function]

  /* Addition of pointer and index is defined only if there result Offset is in
   * the range [0, Size] */
  rule PtrAdd(Ptr(BasePtr(Base:Int, Size:Int), Offset:Int), I:Int, V:TypedValue)
    => Ptr(BasePtr(Base, Size), (Offset +Int I *Int mival(V)))
    when 0 <=Int Offset +Int I *Int mival(V)
      andBool Offset +Int I *Int mival(V) <=Int Size

  /* Subtraction of pointers is defined only for the same BasePtr. */
  rule PtrSub(Ptr(BP:BasePtr, Offset1:Int), Ptr(BP, Offset2:Int), V:TypedValue)
    => (Offset1 -Int Offset2) /Int mival(V)
    when (Offset1 -Int Offset2) %Int mival(V) ==Int 0

  /* Relational operations on pointers are defined only for the same BasePtr. */
  rule
    PtrLt(Ptr(BP:BasePtr, Offset1:Int), Ptr(BP, Offset2:Int))
  =>
    Offset1 <Int Offset2
  rule
    PtrLeq(Ptr(BP:BasePtr, Offset1:Int), Ptr(BP, Offset2:Int))
  =>
    Offset1 <=Int Offset2
  rule
    PtrGt(Ptr(BP:BasePtr, Offset1:Int), Ptr(BP, Offset2:Int))
  =>
    Offset1 >Int Offset2
  rule
    PtrGeq(Ptr(BP:BasePtr, Offset1:Int), Ptr(BP, Offset2:Int))
  =>
    Offset1 >=Int Offset2
endmodule


/*
 * Interface module containing operation declarations for converting a value
 * to/from a list of bytes. The implementation is in file cil-implementation.k.
 */
module CIL-COMMON-VALUE-SERIALIZATION-INTERFACE
  imports LIST
  imports CIL-SYNTAX
  imports CIL-COMMON-PTR

  /*
   * @invariant
   */
  syntax Int ::= width(Type)        [function]
               | byteWidth(Type)    [function]

  syntax Value ::= ByteValue | Bool | Float | Ptr | MInt | agg(List) | String

  syntax ByteValue ::= Int | Float | Ptr | MInt | "undef" | "used"

  /*
   * @invariant:
   * MInt  ::= bytes2Value(IntType, List)
   * Float ::= bytes2Value(FloatingType, List)
   * Ptr   ::= bytes2Value(PtrType, List)
   * byteWidth(T:Type) =Int #lenList(L:List)
   */
  syntax Value ::= bytes2Value(Type, List) [function]
  /*
   * @invariant:
   * value2Bytes(T:IntType, MI:MInt)
   * value2Bytes(T:FloatingType, F:Float)
   * value2Bytes(T:PtrType, P:Ptr)
   */
  syntax List ::= value2Bytes(Type, Value) [function]
endmodule

module CIL-COMMON-TYPED-VALUE
  imports CIL-SYNTAX
  imports CIL-COMMON-PTR

  syntax Exp ::= TypedValue
  /*
   * @invariant:
   * tv(T:IntType, MI:MInt)
   * tv(T:FloatingType, F:Float)
   * tv(T:PtrType, P:Ptr)
   */
  syntax TypedValue ::= tv(Type, Value)
                      // TODO(AndreiS): [function] is not necessary and
                      // does not work in symbolic execution
                      //| norm(Type, Value)   [function]
  syntax TypedValues ::= List{TypedValue, ","}

  /* helper operator */
  syntax KItem ::= norm(Type, Value)

  syntax Exp ::= LeftValue
  syntax LeftValue ::= lv(Type, Ptr)

  syntax Exp ::= NoConversionLeftValue
  syntax NoConversionLeftValue ::= nclv(Type, Ptr)

  syntax Int ::= val(TypedValue) [function]
  rule val(tv(_, V:Value)) => V

  rule norm(T:IntType, MI:MInt) => tv(T, MI)
  rule norm(T:IntType, I:Int)   => tv(T, mi(width(T), I))
  rule norm(T:IntType, true)    => tv(T, mi(width(T), 1))
  rule norm(T:IntType, false)   => tv(T, mi(width(T), 0))
  rule norm(T:IntType, F:Float) => tv(T, mi(width(T), Float2Int(F)))

  // TODO(chathhorn): not sure about the best way to handle this.
  rule norm(T:Type, I:Int) => tv(T, mi(width(T), I))
  when isPtrType(T) ==K true

  syntax Float ::= Int2Double(Int) [function]
  rule Int2Double(I:Int) => Int2Float(I, 53, 11)

  rule norm(T:FloatingType, I:Int) => norm(T, Int2Double(I))
  rule norm(T:FloatingType, F:Float) => tv(T, F)

  // TODO(chathhorn): rather hackish.
  syntax Ptr ::= VaList
  syntax VaList ::= "va_list" "(" TypedValues ")"
endmodule

module CIL-COMMON-MMU
  imports LIST
  imports MAP
  imports CIL-SYNTAX
  imports CIL-TYPING-SYNTAX
  imports CIL-COMMON-PTR
  imports CIL-COMMON-VALUE-SERIALIZATION-INTERFACE
  imports CIL-COMMON-TYPED-VALUE

  syntax List ::= #rangeList(Int, Int, Int)     [klabel(#rangeList3), function]
                | #rangeList(Int, Int)          [klabel(#rangeList2), function]
                | #rangeList(Int)               [klabel(#rangeList1), function]
                | "$rangeList" "(" Int "," Int "," Int ")"        [function]
                | "$downrangeList" "(" Int "," Int "," Int ")"    [function]
  rule #rangeList(I:Int) => #rangeList(0, I, 1)
  rule #rangeList(I:Int, J:Int) => #rangeList(I, J, 1)
  rule #rangeList(I:Int, J:Int, K:Int) => $rangeList(I, J, K)
  when K >Int 0 andBool I <Int J
  rule #rangeList(I:Int, J:Int, K:Int) => $downrangeList(I, J, (0 -Int K))
  when K <Int 0 andBool I >Int J
  rule
    $rangeList(I:Int, J:Int, K:Int)
  =>
    ListItem(I) $rangeList(I +Int K, J:Int, K:Int)
  when I <Int J
  rule $rangeList(I:Int, J:Int, _) => .List
  when I >=Int J
  rule
    $downrangeList(I:Int, J:Int, K:Int)
  =>
    ListItem(I) $downrangeList(I -Int K, J:Int, K:Int)
  when I >Int J
  rule $downrangeList(I:Int, J:Int, _) => .List
  when I <=Int J

  syntax Map ::= #initMap(List, K) [function]
  rule #initMap((ListItem(K1:K) L:List), K2:K) => (K1 |-> K2) #initMap(L, K2)
  rule #initMap(.List, _) => .Map

  /*
   * Memory management.
   */
  syntax KItem ::= newObject(Type)
                 | newZeroObject(Type)
                 | "$newObject" "(" Type "," K "," ByteValue ")"   [strict(2)]
                 | castObject(Type, Ptr)
                 | deleteObject(Ptr)
  rule newObject(T:Type) => $newObject(T, sizeof(T), undef)
  [structural]
  rule newZeroObject(T:Type) => $newObject(T, sizeof(T), 0)
  [structural]
  rule
    <k> $newObject(T:Type, Sz:TypedValue, V:ByteValue)
      => tv(upPtr(T), Ptr(BasePtr(!Base:Int, mival(Sz)), 0))
    ...</k>
    <heap>...
      .Bag
    =>
      <object>
        <base-ptr> BasePtr(!Base, (mival(Sz))) </base-ptr>
        //<object-type> T </object-type>
        <bytes> #initMap(#rangeList(mival(Sz)), V) </bytes>
      </object>
    ...</heap>
  [structural]
  rule
    <k> deleteObject(Ptr(BP:BasePtr, (0))) => .K ...</k>
    <heap>...
      //<object>...
      <object>
        <base-ptr> BP </base-ptr>
        <bytes> _:Map </bytes>
      //...</object>
      </object>
    =>
      .Bag
    ...</heap>
  [structural]


  /*
   * Memory access.
   */
  syntax KItem ::= "load" "(" Type "," Ptr ")"
                 | "$load" "(" Type "," Ptr "," K ")"             [strict(3)]
                 | "$load" "(" Type "," Ptr "," Int "," List ")"
                 | "store" "(" Type "," Ptr "," Value ")"
                 | "$store" "(" Ptr "," List ")"

  rule
    store(T:Type, P:Ptr, V:Value) => $store(P, value2Bytes(T, V))
  [structural]
  rule
    <k>
      $store(
          Ptr(BP:BasePtr, (Offset:Int => Offset +Int 1)),
          (ListItem(V:ByteValue) => .List) _:List)
    ...</k>
    <heap>...
      //<object>...
      <object>
        <base-ptr> BP </base-ptr>
        <bytes>... Offset |-> (_:KItem => V) ...</bytes>
      //...</object>
      </object>
    ...</heap>
  [structural]
  rule $store(_:Ptr, .List) => .K   [structural]

  rule load(T:Type, P:Ptr) => $load(T, P, sizeof(T))
    [structural]

  rule $load(T:Type, P:Ptr, Sz:TypedValue)
    => $load(T, P, mival(Sz), .List)
  [structural]
  rule
    <k>
      $load(
          _:Type,
          Ptr(BP:BasePtr, (Offset:Int => Offset +Int 1)),
          (M:Int => M -Int 1),
          (_:List (.List => ListItem(V:ByteValue))))
    ...</k>
    <base-ptr> BP </base-ptr>
    <bytes>... Offset |-> V ...</bytes>
    when M >Int 0
    [structural]

  // TODO(chathhorn): when any part of the object is undefined, we return undef
  // This is probably too crude.
  rule
    <k>
      $load(T:Type, Ptr(BP:BasePtr, Offset:Int), M:Int, _:List)
      => tv(T, undef)
    ...</k>
    <base-ptr> BP </base-ptr>
    <bytes> Bytes:Map </bytes>
    when (M >Int 0) andBool notBool (Offset in keys(Bytes))
    [structural]
  rule
    $load(T:Type, _:Ptr, 0, L:List) => tv(T, bytes2Value(T, L))
    [structural]
endmodule

module CIL-COMMON
  imports MINT
  imports CIL-COMMON-PTR
  imports CIL-COMMON-VALUE-SERIALIZATION-INTERFACE
  imports CIL-COMMON-TYPED-VALUE
  imports CIL-COMMON-MMU

  syntax Error ::= "dummy_Error_item"

  /* Marker for starting execution (after static pre-processing). */
  syntax KItem ::= "callMain"

  /* These are also defined in a standard library header. */
  // TODO(AndreiS): check if this more specific type works
  syntax Type ::= "size_ptr" [function]
                | "ptrdiff_t" [function]

  /*
   * Returns the unsigned interpretation of the machine integer stored inside
   * this typed value.
   */
  syntax Int ::= mival(TypedValue) [function]
  rule mival(tv(_, I:MInt)) => uvalueMInt(I)

  /*
   * List{Stmt} concatenation
   */
  syntax Stmts ::= Stmts "@Stmts" Stmts   [left, function]
  rule (S:Stmt Ss1:Stmts) @Stmts Ss2:Stmts => S (Ss1 @Stmts Ss2)
  rule .Stmts @Stmts Ss:Stmts => Ss

  syntax TransUnit ::= tu(String)
  syntax Phase ::= "initializing" | TransUnit | "executing" | "terminated"
endmodule
