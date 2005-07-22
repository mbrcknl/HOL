open HolKernel Parse boolLib bossLib listTheory rich_listTheory bitsTheory
     markerTheory metisLib pairTheory arithmeticTheory word4Theory 
     word8Theory word32Theory word128Theory word256Theory 
     word4Lib word8Lib word32Lib word128Lib word256Lib metisLib;

val _ = new_theory "Serpent_Reference_Utility";

(*trivial stuff about word128 *)
val bit_num_val_bound=Q.store_thm(
"bit_num_val_bound",
`!w n.
	BIT n w ==> w >= 2 ** n`,
		
RW_TAC arith_ss [BIT_def, BITS_THM] THEN
CCONTR_TAC THEN
FULL_SIMP_TAC arith_ss [DECIDE ``SUC n - n = 1n``, DECIDE``~(x >= y) = x<y:num``,
                        LESS_DIV_EQ_ZERO]
); 

val w2n_zero128 = Q.store_thm (
"w2n_zero128",
`word128$w2n 0w= 0`,

EVAL_TAC);
			
val w2n_one128 = Q.store_thm ( 
"w2n_one128", 
`(w2n:word128->num) 1w= 1`,
			
EVAL_TAC); 			

val word_1_bit_0=Q.store_thm(
"word_1_bit_0",
`word128$WORD_BIT 0 (1w:word128)`,

EVAL_TAC);


val word_1_bit128=Q.store_thm(
"word_1_bit128",
`!n.
	n>0 /\
	n< word128$WL
	==>
	 ~(word128$WORD_BIT n (1w:word128))`,
		
CCONTR_TAC THEN
FULL_SIMP_TAC bool_ss [word128Theory.WORD_BIT_def] THEN
`word128$w2n 1w= 1` by METIS_TAC [w2n_one128] THEN
`1 >=2**n` by METIS_TAC [bit_num_val_bound] THEN
`~(2 ** n=0)` by FULL_SIMP_TAC arith_ss [TWOEXP_NOT_ZERO] THEN
`2**n=1` by RW_TAC arith_ss [] THEN
`(2=1) \/ (n=0)` by METIS_TAC [EXP_EQ_1] THEN 
FULL_SIMP_TAC arith_ss []
);     


(*XOR
*)
val boolXor_def= Define
`boolXor (x:bool) y = ~(x=y)`;

val boolXorComm=Q.store_thm(
"boolXorComm",
` !x y. 
	boolXor x y = boolXor y x`,

METIS_TAC [boolXor_def]);

val boolXorAssoc=Q.store_thm(
"boolXorAssoc",
` !x y z. 
	boolXor z (boolXor x y) = boolXor (boolXor z x) y`,

METIS_TAC [boolXor_def]);

val boolXorFacts=Q.store_thm(
"boolXorFacts",
`(!x.(boolXor x x) = F) /\
  (!x.(boolXor x T) = ~x) /\
  (!x.(boolXor x F) = x) `,

METIS_TAC [boolXor_def]);

val boolXorComm3=Q.store_thm(
"boolXorComm3",
`! x y z. 
	boolXor x (boolXor y z) = boolXor y (boolXor x z)`,

Cases_on `x` THEN Cases_on `y` THEN Cases_on `z` THEN
RW_TAC std_ss [boolXor_def]);
	
(*trivial stuff about list
*)	
val ALL_EL_FILTER=Q.store_thm(
"ALL_EL_FILTER",
`!p q l. 
	ALL_EL p l
	==> 
	ALL_EL p (FILTER q l)`,

Induct_on `l` THEN
RW_TAC list_ss []);	
	
val LENGTH_NIL_LEQ =Q.store_thm(
"LENGTH_NIL_LEQ",
`!n. 
	LENGTH [] <= n`,

RW_TAC list_ss []);
	  
val LENGTH_FILTER=Q.store_thm(
"LENGTH_FILTER",
`!l p. 
	LENGTH (FILTER p l) <= LENGTH l`,

Induct_on `l` THEN 
RW_TAC list_ss [] THEN 
`LENGTH l <=  SUC (LENGTH l)` by RW_TAC arith_ss [] THEN
METIS_TAC [LESS_EQ_TRANS]);
	
	
(*make a list of "T" of length n*)
val makeTL_def =Define
`(makeTL 0 =  []) /\

 (makeTL (SUC n) = T::(makeTL n))`;

val LENGTH_makeTL = Q.store_thm(
"LENGTH_makeTL",
`!n.
	LENGTH (makeTL n) = n`,
	
Induct_on `n` THENL [
	RW_TAC list_ss [makeTL_def],
	RW_TAC list_ss [makeTL_def]]);
	

val makeTL_fact=Q.store_thm(
"makeTL_fact",
`!i n. 
	i<n
	==>
	EL i (makeTL n)`,

Induct_on `n` THENL [
	RW_TAC arith_ss [],
	Cases_on `i` THEN
	RW_TAC list_ss [makeTL_def]]);		

(*XOR on bool lists in ZIP fashion
*)		
val zipXor_def =Define 
`(zipXor [] l =l) /\

(zipXor (xh::xt) (ah::at) = (boolXor xh ah)::zipXor xt at)   /\
(zipXor (xh::xt) [] = [])`;

val zipXor_fact=Q.store_thm(
"zipXor_fact",
`!l. 
	zipXor l [] = [] `,

Cases_on `l` THEN
RW_TAC list_ss [zipXor_def]);
	
val LENGTH_zipXor=Q.store_thm(
"LENGTH_zipXor",
`!l1 l2.
	LENGTH (zipXor l1 l2) = LENGTH l2`,

Induct_on `l2` THENL [
	Cases_on `l1` THEN
	RW_TAC list_ss [zipXor_def],
	Cases_on `l1` THEN
	RW_TAC list_ss [zipXor_def]]);


	  
val makeL_def=Define
`(makeL 0 = [T]) /\
(makeL (SUC n) = F::makeL n)`;


val zipXor_makeL_COMM=Q.store_thm(
"zipXor_makeL_COMM",
`! i n1 n2 l.
	 zipXor (makeL n2) (zipXor (makeL n1) al)
	 = zipXor (makeL n1) (zipXor (makeL n2) al)`,
	 
Induct_on `al` THENL [
	RW_TAC list_ss [zipXor_fact],
	Cases_on `n1` THEN Cases_on `n2` THEN
	RW_TAC list_ss [makeL_def,zipXor_def,boolXor_def]]);		
		
val zipXor_makeL=Q.store_thm(
"zipXor_makeL",
 `!i al h tl. 
	i < LENGTH al  /\
	h < LENGTH al  
	==>
	(EL i (zipXor (makeL h) al) = boolXor (i=h) (EL i al))`,
	
Induct_on `h` THENL [
	RW_TAC list_ss [zipXor_def,makeL_def] THEN
	Cases_on `al` THEN 
	FULL_SIMP_TAC list_ss [zipXor_def,boolXor_def] THEN
	Cases_on `i` THEN
	RW_TAC list_ss [],
	RW_TAC list_ss [makeL_def] THEN
	Cases_on `al` THEN
	RW_TAC list_ss [zipXor_def,boolXor_def] THEN
	Cases_on `i` THEN
	FULL_SIMP_TAC list_ss [boolXor_def]]);					

		
		
val MAP_ID=Q.store_thm(
"MAP_ID",
`!l f. 
	ALL_EL (\x. f x =x) l
	==>
	(MAP f l=l)`, 
	
Induct_on `l` THEN
RW_TAC list_ss []);
	  		
(*housemade FIRSTN and BUTLASTN for easy evaluation*)
val (myFIRSTN_def,myFIRSTN_termi) =Defn.tstore_defn(
 Defn.Hol_defn "myFIRSTN"
`myFIRSTN n l = if n=0 then []
else if l=[] then []
else (HD l)::(myFIRSTN (n-1) (TL l))`,

WF_REL_TAC `measure (LENGTH o SND)` THEN
RW_TAC list_ss [] THEN
Cases_on `l` THENL [
	FULL_SIMP_TAC list_ss [],
	RW_TAC list_ss []]);

val myBUTLASTN_def = Define
`myBUTLASTN n l = let len=LENGTH l in
if len>=n then myFIRSTN (LENGTH l-n) l
else []
`;

val LENGTH_myFIRSTN=Q.store_thm(
"LENGTH_myFIRSTN",
`!n l. 
	n <= LENGTH l 
	==> 
	(LENGTH (myFIRSTN n l) = n)`,

Induct_on `n` THENL [
	RW_TAC list_ss [] THEN
	`myFIRSTN 0 l=[]` by METIS_TAC  [myFIRSTN_def] THEN
	RW_TAC list_ss [],
	RW_TAC list_ss [] THEN
	Cases_on `l` THENL [
		FULL_SIMP_TAC list_ss [],
		`~(SUC n=0)` by RW_TAC arith_ss [] THEN
		`~((h::t) =[])` by RW_TAC list_ss [] THEN
		`myFIRSTN (SUC n) (h::t)= (HD (h::t))::(myFIRSTN (SUC n-1) (TL (h::t)))` by  METIS_TAC  [myFIRSTN_def] THEN
		FULL_SIMP_TAC list_ss []]]);
	



val LENGTH_myBUTLASTN=Q.store_thm(
"LENGTH_myBUTLASTN",
`!n l. 
	n <= LENGTH l 
	==> 
	(LENGTH (myBUTLASTN n l) = LENGTH l - n)`,

RW_TAC arith_ss [myBUTLASTN_def,LENGTH_myFIRSTN,LET_THM]);	
	   
	
		

(*conversion between different words,
EL 0 is the MS in all split result,
the bit ordering is perserved
*)

val word128to32l_def =Define 
`word128to32l (w128:word128) = 
 [word32$n2w (w2n (w128 >>> 96)); word32$n2w (w2n ((w128 <<32) >>> 96));
  word32$n2w (w2n ((w128<<64) >>> 96)); word32$n2w (w2n ((w128<<96) >>> 96))]`;

val word32to8l_def =Define 
`word32to8l (w32:word32) = 
 [word8$n2w (w2n (w32 >>> 24)); word8$n2w (w2n ((w32 <<8) >>> 24));
  word8$n2w (w2n ((w32<<16) >>> 24)); word8$n2w (w2n ((w32<<24) >>> 24))]`;


val word8to4l_def =Define 
`word8to4l(w8:word8) = 
 [word4$n2w (w2n (w8 >>> 4)); word4$n2w (w2n ((w8 <<4) >>> 4))]`;

val word32to4l_def=Define
`word32to4l w32= FLAT (MAP word8to4l (word32to8l w32))`;

val word4to32_def = Define
`word4to32 (w4:word4)= word32$n2w (w2n w4)`;

val word4to128_def = Define
`word4to128 (w4:word4)= word128$n2w (w2n w4)`;

val word32to128_def = Define
 `word32to128 (w32:word32)= word128$n2w (w2n w32)`;

val word256to128l = Define
`word256to128l (w256:word256) = 
 [word128$n2w (w2n (w256 >>> 128)); word128$n2w  (w2n ((w256 <<128) >>> 128))]`;

val word256to32l_def = Define
`word256to32l (w256:word256) = FLAT ( MAP word128to32l (word256to128l w256))`;
 (*input is in MSNibble....LSNibble
in each Nibble, MSBit..LSBit
input is of 32 nibbles
*)

(*convert a word4 list to a num
LSW,,,,,MSW*)
val revWord4ltoNum_def=Define
`(revWord4ltoNum [] = 0) /\
(revWord4ltoNum (h::t) = (word4$w2n h+ (revWord4ltoNum t)*16))`;


(*convert a num to a word4 list,
the length of list is controled by a parameter,
the length provides a MOD 
LSW,,,,,MSW*)
val numtoRevWord4l_def =Define
`(numtoRevWord4l 0 n = []) /\
(numtoRevWord4l (SUC m) n = word4$n2w (  n MOD 16)::(numtoRevWord4l m (n DIV 16)))`;

val numtoRevWord4lEval=Q.store_thm(
"numtoRevWord4lEval",
`!n m. 
	numtoRevWord4l m n =
	if m=0 then []
	else  word4$n2w (  n MOD 16)::(numtoRevWord4l (m-1) (n DIV 16))`,


RW_TAC arith_ss [numtoRevWord4l_def] THEN
Cases_on `m` THENL [
	METIS_TAC [],
	FULL_SIMP_TAC arith_ss [numtoRevWord4l_def]]);
	

(*the length provides a MOD *)
val revWord4ltoNumRange=Q.store_thm(
"revWord4ltoNumRange",
`!n l. 
	LENGTH l <= n ==> revWord4ltoNum l < 2 ** (4*n)`,
	
Induct_on `l` THENL [
	METIS_TAC [ revWord4ltoNum_def,ZERO_LESS_EXP,DECIDE ``2 = SUC 1``],
	RW_TAC list_ss [ revWord4ltoNum_def] THEN
	Cases_on `n` THENL [
		FULL_SIMP_TAC arith_ss [],
		`4* SUC n'=4+ 4*n'` by RW_TAC arith_ss [] THEN
		`word4$w2n h < 2**word4$WL` by METIS_TAC  [word4Theory.w2n_LT] THEN
		FULL_SIMP_TAC std_ss [EXP_ADD,word4Theory.WL_def,word4Theory.HB_def] THEN
		FULL_SIMP_TAC list_ss [] THEN
		`revWord4ltoNum  l < 2 ** (4 * n') ` by METIS_TAC [] THEN
		`SUC ( revWord4ltoNum l) <= 2 ** (4 * n')` by METIS_TAC [LESS_EQ] THEN
		`16+16* (revWord4ltoNum l)<= 16*2 ** (4 * n')` by RW_TAC arith_ss [] THEN
		FULL_SIMP_TAC arith_ss []]]);
		
val LENGTH_numtoRevWord4l=Q.store_thm(
"LENGTH_numtoRevWord4l",
`!wl n. 
	LENGTH (numtoRevWord4l n wl) =n`,

Induct_on `n` THEN
RW_TAC list_ss [numtoRevWord4l_def]);
	
	

	  
(*the conversions between a num and word4 list are reversible*)        
val numtoRevWord4l_conversion=Q.store_thm(
"numtoRevWord4l_conversion",
`!n wl. 
	(n=LENGTH wl)
	==>
	( numtoRevWord4l n (revWord4ltoNum wl) =wl)`,

Induct_on `wl` THEN
RW_TAC list_ss [revWord4ltoNum_def,numtoRevWord4l_def] THENL [
	`word4$w2n h < 2**word4$WL` by METIS_TAC  [word4Theory.w2n_LT] THEN
	FULL_SIMP_TAC arith_ss [MOD_MULT,word4Theory.WL_def,
	                        word4Theory.HB_def]  THEN
	`(revWord4ltoNum wl * 16+word4$w2n h) MOD 16 =word4$w2n h` 
		by METIS_TAC [MOD_MULT] THEN
	 FULL_SIMP_TAC arith_ss [word4Theory.w2n_ELIM], 
	`(revWord4ltoNum wl * 16) MOD 16=0 ` 
		by METIS_TAC [MOD_EQ_0,DECIDE ``0<16``] THEN
	`word4$w2n h < 2**word4$WL` by METIS_TAC  [word4Theory.w2n_LT] THEN 
	 FULL_SIMP_TAC arith_ss [ADD_DIV_RWT,LESS_DIV_EQ_ZERO,MULT_DIV,
	                         word4Theory.WL_def,word4Theory.HB_def]]); 
		 
val revWord4ltoNum_conversion=Q.store_thm(
"revWord4ltoNum_conversion",
`!n len.
	n < 2**(4*len)
	==>
	(revWord4ltoNum  (numtoRevWord4l len n) =n)`,	

Induct_on `len` THEN
RW_TAC list_ss [revWord4ltoNum_def,numtoRevWord4l_def] THEN
`n DIV 16 <=2 ** (4 * SUC len) DIV 16` by RW_TAC arith_ss [DIV_LE_MONOTONE] THEN
`n = n DIV 16 * 16 + n MOD 16` by METIS_TAC [DIVISION,DECIDE ``0<16``] THEN
`2 ** (4 * SUC len) = 2**(4*len)*16` 
	by FULL_SIMP_TAC std_ss [DECIDE ``4*SUC len=4*len +4``,EXP_ADD] THEN
FULL_SIMP_TAC std_ss [MULT_DIV] THEN
`n DIV 16 *16<= 2 ** (4 * len)*16` by RW_TAC arith_ss [] THEN
Cases_on ` n DIV 16 = 2 ** (4 * len) ` THEN Cases_on `n MOD 16=0` THEN
FULL_SIMP_TAC arith_ss [word4Theory.w2n_EVAL,word4Theory.MOD_WL_def,
                        word4Theory.WL_def,word4Theory.HB_def]);
		        

(*the conversions between a word128 and word4 list*)				 	
val word4ltow128_def = Define
`word4ltow128 w4l=word128$n2w (revWord4ltoNum (REVERSE w4l))`;

val word128tow4l_def= Define
`word128tow4l w128 = REVERSE (numtoRevWord4l 32 (word128$w2n w128))`;



val LENGTH_word128tow4l=Q.store_thm(
"LENGTH_word128tow4l",
`!w.
	LENGTH (word128tow4l w) =32`,

RW_TAC std_ss [word128tow4l_def,LENGTH_REVERSE,LENGTH_numtoRevWord4l]);

(*the conversions between a word128 and word4 list are reversible*)
val word128tow4l_conversion=Q.store_thm(
"word128tow4l_conversion",
`!l. (LENGTH l =32) ==> (word128tow4l (word4ltow128 l) =l)`,

RW_TAC arith_ss [word128tow4l_def,word4ltow128_def,word128Theory.w2n_EVAL,
                 word128Theory.MOD_WL_def,word128Theory.WL_def,
		 word128Theory.HB_def] THEN
`LENGTH (REVERSE l) <=32` by RW_TAC list_ss [LENGTH_REVERSE] THEN
`revWord4ltoNum (REVERSE l) < 2 ** (4*32)` by METIS_TAC [revWord4ltoNumRange] THEN
FULL_SIMP_TAC arith_ss [LESS_MOD] THEN
`LENGTH (REVERSE l) =32` by RW_TAC list_ss [LENGTH_REVERSE] THEN
`numtoRevWord4l 32 (revWord4ltoNum (REVERSE l)) = REVERSE l` 
	by METIS_TAC [numtoRevWord4l_conversion] THEN
METIS_TAC [REVERSE_REVERSE]);

val word4ltow128_conversion=Q.store_thm(
"word4ltow128_conversion",
`!w128.
	word4ltow128 (word128tow4l w128) = w128`,

RW_TAC arith_ss [word4ltow128_def,word128tow4l_def,REVERSE_REVERSE] THEN
`word128$w2n w128 < 2 **word128$WL` by METIS_TAC [word128Theory.w2n_LT] THEN
FULL_SIMP_TAC arith_ss [word128Theory.WL_def,word128Theory.HB_def,
                        revWord4ltoNum_conversion,word128Theory.w2n_ELIM]);


	 

val word256to32lLength = Q.store_thm (
"word256to32lLength",
`!w. 
	LENGTH (word256to32l w) =8`,

EVAL_TAC THEN METIS_TAC []);


(*instantiate explicit list given the length
*) 

val LENGTH_GREATER_EQ_CONS=Q.store_thm(
"LENGTH_GREATER_EQ_CONS",
`!l n. 
	(LENGTH l >=SUC n) 
	==>
	?x l'. (LENGTH l' >= n) /\ (l = x::l')`,

Induct_on `l` THEN
RW_TAC list_ss []);
	  
val listInstGreaterEq2=Q.store_thm(
"listInstGreaterEq2",
`!l. 
	(LENGTH l>=2) 
	==> 
	?v_1 v_2 t. l = (v_1::v_2::t)`,
	     
REWRITE_TAC [DECIDE ``2 = SUC (SUC 0)``] THEN
METIS_TAC  [LENGTH_GREATER_EQ_CONS, LENGTH_NIL]);	  

val listInstEq2=Q.store_thm(
"listInstEq2",
`!l. 
	(LENGTH l=2) 
	==> 
	?w_1 w_2. l = (w_1::w_2::[])`,
	
REWRITE_TAC [LENGTH_CONS, LENGTH_NIL, DECIDE ``2 = SUC (SUC 0)``] THEN
METIS_TAC []);


val listInstGreaterEq4=Q.store_thm(
"listInstGreaterEq4",
`!l. 
	(LENGTH l>=4) 
	==> 
	?v_1 v_2 v_3 v_4 t. l = (v_1::v_2::v_3::v_4::t)`,
	
REWRITE_TAC [DECIDE ``4 = SUC  (SUC  (SUC (SUC 0)))``] THEN
METIS_TAC  [LENGTH_GREATER_EQ_CONS, LENGTH_NIL]);	  

val listInstEq4=Q.store_thm(
"listInstEq4",
`!l. 
	(LENGTH l=4) 
	==> 
	?w_1 w_2 w_3 w_4. l = (w_1::w_2::w_3::w_4::[])`,

REWRITE_TAC [LENGTH_CONS, LENGTH_NIL, DECIDE ``4 = SUC (SUC (SUC (SUC 0)))``] THEN
METIS_TAC []);
     	  
val listInstGreaterEq8=Q.store_thm(
"listInstGreaterEq8",
`!l. 
	(LENGTH l>=8) 
	==> 
	?v_1 v_2 v_3 v_4 v_5 v_6 v_7 v_8 t. l =
	(v_1::v_2::v_3::v_4::v_5::v_6::v_7::v_8::t)`,
	     
REWRITE_TAC [DECIDE ``8 = SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC 0)))))))``] THEN
METIS_TAC  [LENGTH_GREATER_EQ_CONS, LENGTH_NIL]);	
	        
val listInstEq8=Q.store_thm(
"listInstEq8",
`!l. 
	(LENGTH l=8) 
	==> 
	?w_1 w_2 w_3 w_4 w_5 w_6 w_7 w_8. l =
	(w_1::w_2::w_3::w_4::w_5::w_6::w_7::w_8::[])`,

REWRITE_TAC [LENGTH_CONS, LENGTH_NIL, DECIDE ``8 = SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC 0)))))))``] THEN
METIS_TAC []);


val listInstEq32 =Q.store_thm(
"listInstEq32",
` !l.
	(LENGTH l = 32) ==>
        ?v_0 v_1 v_2 v_3 v_4 v_5 v_6 v_7 v_8 v_9 v_10 v_11 v_12 v_13 v_14
         v_15 v_16 v_17 v_18 v_19 v_20 v_21 v_22 v_23 v_24 v_25 v_26 v_27
         v_28 v_29 v_30 v_31.
        l =[v_0; v_1; v_2; v_3; v_4; v_5; v_6; v_7; v_8; v_9; v_10; v_11;
           v_12; v_13; v_14; v_15; v_16; v_17; v_18; v_19; v_20; v_21; v_22;
           v_23; v_24; v_25; v_26; v_27; v_28; v_29; v_30; v_31]`,

REWRITE_TAC [LENGTH_CONS, LENGTH_NIL, 
             DECIDE ``32 = SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC 
	            (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC 
		    (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC
		     0))))))))))))))))))))))))))))))) ``] THEN
METIS_TAC []); 

val listInstEq33 =Q.store_thm(
"listInstEq33", 
` !l.
	(LENGTH l = 33) ==>
        ?v_0 v_1 v_2 v_3 v_4 v_5 v_6 v_7 v_8 v_9 v_10 v_11 v_12 v_13 v_14
           v_15 v_16 v_17 v_18 v_19 v_20 v_21 v_22 v_23 v_24 v_25 v_26 v_27
           v_28 v_29 v_30 v_31 v_32.
        l =[v_0; v_1; v_2; v_3; v_4; v_5; v_6; v_7; v_8; v_9; v_10; v_11;
           v_12; v_13; v_14; v_15; v_16; v_17; v_18; v_19; v_20; v_21; v_22;
           v_23; v_24; v_25; v_26; v_27; v_28; v_29; v_30; v_31; v_32]`,

REWRITE_TAC [LENGTH_CONS, LENGTH_NIL, 
             DECIDE ``33 = SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC
	            (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC 
		    (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC (SUC 
		    (SUC 0)))))))))))))))))))))))))))))))) ``] THEN
METIS_TAC []); 


val _ = export_theory();
