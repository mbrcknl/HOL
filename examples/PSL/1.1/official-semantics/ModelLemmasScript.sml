(*****************************************************************************)
(* Properties of models.                                                     *)
(*****************************************************************************)

(*****************************************************************************)
(* START BOILERPLATE                                                         *)
(*****************************************************************************)

(******************************************************************************
* Load theories
* (commented out for compilation)
******************************************************************************)
(*
quietdec := true;
loadPath 
 := 
 "../official-semantics" :: "../../path" :: !loadPath;
map load 
 ["pred_setLib","res_quanTools", "rich_listTheory", "pairLib","intLib",
  "FinitePathTheory", "PathTheory", "UnclockedSemanticsTheory",
  "SyntacticSugarTheory", "ClockedSemanticsTheory", "RewritesTheory", 
  "RewritesPropertiesTheory","ProjectionTheory",
  "rich_listTheory", "res_quanLib", "res_quanTheory", "metisLib"];
open SyntaxTheory SyntacticSugarTheory
     UnclockedSemanticsTheory ClockedSemanticsTheory RewritesTheory
     RewritesPropertiesTheory ProjectionTheory pred_setLib res_quanTools
     arithmeticTheory listTheory rich_listTheory res_quanLib res_quanTheory
     ClockedSemanticsTheory pairLib pred_setTheory ModelTheory metisLib
     FinitePathTheory PathTheory;    (* Open after list theory for CONS_def *)
val _ = intLib.deprecate_int();
quietdec := false;
*)

(******************************************************************************
* Boilerplate needed for compilation
******************************************************************************)
open HolKernel Parse boolLib bossLib;

(******************************************************************************
* Open theories
******************************************************************************)
open SyntaxTheory SyntacticSugarTheory
     UnclockedSemanticsTheory ClockedSemanticsTheory RewritesTheory
     pred_setLib pred_setTheory arithmeticTheory listTheory rich_listTheory 
     res_quanLib pairLib res_quanTheory ModelTheory ClockedSemanticsTheory 
     res_quanTools RewritesPropertiesTheory ProjectionTheory ModelTheory
     metisLib FinitePathTheory 
     PathTheory; (* Open after list theory for CONS_def *)

(******************************************************************************
* Set default parsing to natural numbers rather than integers 
******************************************************************************)
val _ = intLib.deprecate_int();

(*****************************************************************************)
(* END BOILERPLATE                                                           *)
(*****************************************************************************)

(******************************************************************************
* Start a new theory called Lemmas
******************************************************************************)
val _ = new_theory "ModelLemmas";

(*****************************************************************************)
(* A simpset fragment to rewrite away quantifiers restricted with :: LESS    *)
(*****************************************************************************)
val resq_SS =
 simpLib.merge_ss
  [res_quanTools.resq_SS,
   rewrites
    [LESS_def,LENGTH_def,IN_LESS,IN_LESSX]];

val PATH_CASES = 
 store_thm
  ("PATH_CASES",
   ``(PATH M s (FINITE l) = 
      (LENGTH l > 0) /\ (s = HD l) /\ s IN M.S /\
      (!n :: (LESS(LENGTH l - 1)). 
        EL n l IN M.S /\ EL (SUC n) l IN M.S /\ (EL n l, EL (SUC n) l) IN M.R) /\
      !s. ~((EL (LENGTH l - 1) l, s) IN M.R))
     /\
     (PATH M s (INFINITE f) = 
       (s = f 0) /\ !n. f n IN M.S /\ (f n, f(SUC n)) IN M.R)``,
   RW_TAC (list_ss++resq_SS) [PATH_def,LS,GT,ELEM_INFINITE,ELEM_FINITE,SUB]
    THEN EQ_TAC
    THEN RW_TAC list_ss []);

(*****************************************************************************)
(* A useful special case (possibly the only one we'll need) is to identify   *)
(* propositions with predicates on states, then we just need to specify the  *)
(* set of initial states B:'state->bool and                                  *)
(* transition relation R:'state#'state->bool, then:                          *)
(* SIMPLE_MODEL B R : :('a, 'a -> bool) model                                *)
(*****************************************************************************)
val SIMPLE_MODEL_def =
 Define
  `SIMPLE_MODEL (B:'state -> bool) (R:'state#'state->bool) = 
    <| S  := {s | T};
       S0 := B;
       R  := R; 
       P  := {p | T}; 
       L  := (\(s:'state). {p:'state -> bool | s IN p}) |>`;

val MODEL_SIMPLE_MODEL =
 store_thm
  ("MODEL_SIMPLE_MODEL",
   ``MODEL(SIMPLE_MODEL B R)``,
   RW_TAC list_ss [MODEL_def,SIMPLE_MODEL_def]
    THEN RW_TAC (srw_ss()) [SUBSET_UNIV]);

(*****************************************************************************)
(* Product of two models                                                     *)
(*                                                                           *)
(*    (S1,S01,R1,P1,L1) || (S2,S02,R2,P2,L2)                                 *)
(*    =                                                                      *)
(*    (S1  x S2,     -- Cartesian product                                    *)
(*     S01 x S02,    -- Cartesian product                                    *)
(*     {((s1,s2),(s1,s2)) | R1(s1,s1') and R2(s2,s2')},                      *)
(*     P1 U P2,      -- disjoint union                                       *)
(*     lambda (s1,s2)                                                        *)
(*       {p in (P1 U P2) | if (p in P1) then (p in L1 s1) else (p in L2 s2)} *)
(*    )                                                                      *)
(*****************************************************************************)
val MODEL_PROD_def =
 Define 
  `MODEL_PROD (M1:('state1, 'prop1) model) (M2:('state2, 'prop2) model) =
    <| S  := {(s1,s2) | s1 IN M1.S  /\ s2 IN M2.S};
       S0 := {(s1,s2) | s1 IN M1.S0 /\ s2 IN M2.S0};
       R  := {((s1,s2),(s1',s2')) | (s1,s1') IN M1.R /\ (s2,s2') IN M2.R};
       P  := {p | if ISL p then OUTL p IN M1.P else OUTR p IN M2.P};
       L  := \(s1,s2). 
              {p | if ISL p then OUTL p IN M1.L s1 else OUTR p IN M2.L s2} |>`;

val _ = set_fixity "||" (Infixl 650);
val _ = overload_on ("||", ``MODEL_PROD``);

val MODEL_MODEL_PROD =
 store_thm
  ("MODEL_MODEL_PROD",
   ``!M1 M2. MODEL M1 /\ MODEL M2 ==> MODEL(M1 || M2)``,
   RW_TAC list_ss [MODEL_def,MODEL_PROD_def]
    THEN FULL_SIMP_TAC (srw_ss()) [SUBSET_DEF]
    THEN RW_TAC list_ss []
    THEN RES_TAC
    THEN FULL_SIMP_TAC list_ss []
    THEN ASSUM_LIST(fn thl => ASSUME_TAC(GEN_BETA_RULE(el 4 thl)))
    THEN FULL_SIMP_TAC (srw_ss()) []
    THEN PROVE_TAC[]);

(*****************************************************************************)
(* ``L_SEM l p`` means proposition p is true with respect to letter l        *)
(*****************************************************************************)
val L_SEM_def =
 Define
  `(L_SEM TOP (p:'prop) = T)
   /\
   (L_SEM BOTTOM p = F)
   /\
   (L_SEM(STATE s) p = p IN s)`;

(*****************************************************************************)
(* FINITE_LETTER_IN p l iff p occurs in an element of l                      *)
(*****************************************************************************)
val FINITE_LETTER_IN_def =
 Define
  `FINITE_LETTER_IN p l = 
    ?i. i < LENGTH l /\ ?s. (EL i l = STATE s) /\ p IN s` ;

(*****************************************************************************)
(* INFINITE_LETTER_IN p f iff p occurs in an element of f                    *)
(*****************************************************************************)
val INFINITE_LETTER_IN_def =
 Define
  `INFINITE_LETTER_IN p f = 
    ?i s. (f i = STATE s) /\ p IN s` ;

(*****************************************************************************)
(* Conversion of a path to a model (Kripke structure)                        *)
(*****************************************************************************)
val PATH_TO_MODEL_def =
 Define
  `(PATH_TO_MODEL(FINITE l) = 
    <| S  := {n | n < LENGTH l};
       S0 := {0};
       R  := {(n,n') | n < LENGTH l /\ n' < LENGTH l /\ (n' = n+1)};
       P  := {p:'prop | FINITE_LETTER_IN p l};
       L  := \n. {p | n < LENGTH l /\ FINITE_LETTER_IN p l /\ L_SEM (EL n l) p} |>)
   /\
   (PATH_TO_MODEL(INFINITE f) = 
    <| S  := {n | T};
       S0 := {0};
       R  := {(n,n') | n' = n+1};
       P  := {p:'prop | INFINITE_LETTER_IN p f};
       L  := \n. {p | INFINITE_LETTER_IN p f /\ L_SEM (f n) p} |>)`;

val MODEL_PATH_TO_MODEL =
 store_thm
  ("MODEL_PATH_TO_MODEL",
   ``!p. 0 < LENGTH p ==>  MODEL(PATH_TO_MODEL p)``,
   GEN_TAC
    THEN Cases_on `p`
    THEN RW_TAC list_ss [SUBSET_DEF,MODEL_def,PATH_TO_MODEL_def]   
    THEN FULL_SIMP_TAC (srw_ss()) [SUBSET_UNIV,LENGTH_def,LS]);

(*****************************************************************************)
(* Definition of an automaton: ``: ('label,'state)automaton``                *)
(* (e.g. Clarke/Grumberg/Peled "Model Checking" Chapter 9)                   *)
(*****************************************************************************)
val automaton_def =
 Hol_datatype
  `automaton = 
    <| Sigma: 'label -> bool;
       Q:     'state -> bool;
       Delta: 'state # 'label # 'state -> bool;
       Q0:    'state -> bool;
       F:     'state -> bool |>`;

(*****************************************************************************)
(* The open model over a set P of propositions P : 'prop -> bool             *)
(*****************************************************************************)
(*
val OLD_OPEN_MODEL_def =
 Define 
  `OLD_OPEN_MODEL(P:'prop -> bool) = 
    <| S  := {s | s SUBSET P};
       S0 := {s | s SUBSET P};
       R  := {(s,t) | s SUBSET P /\ t SUBSET P}; 
       P  := P; 
       L  := \s. {p | p IN s} |>`;
*)

(******************************************************************************
* Formalise Eisner/Fisman {s | s SUBSET P} UNION {sink}
******************************************************************************)
val SINK_def =
 Define `SINK P = {@p. ~(p IN P)}`;

val OPEN_MODEL_def =
 Define 
  `OPEN_MODEL(P:'prop -> bool) = 
    <| S  := {s | s SUBSET P} UNION {SINK P};
       S0 := {s | s SUBSET P};
       R  := {(s,t) | s SUBSET P /\ (t SUBSET P \/ (t = SINK P))}; 
       P  := P; 
       L  := \s. if s = SINK P then {} else {p | p IN s} |>`;

val MODEL_OPEN_MODEL =
 store_thm
  ("MODEL_OPEN_MODEL",
   ``MODEL(OPEN_MODEL P)``,
   RW_TAC list_ss [MODEL_def,OPEN_MODEL_def]
    THEN FULL_SIMP_TAC (srw_ss()) []
    THEN PROVE_TAC[EMPTY_SUBSET]);

val AUTOMATON_def =
 Define
  `AUTOMATON A =
    A.Q0 SUBSET A.Q /\
    (!s a s'. (s,a,s') IN A.Delta ==> s IN A.Q /\ a IN A.Sigma /\ s' IN A.Q) /\
    A.F SUBSET A.Q`;

(*****************************************************************************)
(* Convert a model to an automaton                                           *)
(* (Clarke/Grumberg/Peled "Model Checking" 9.2)                              *)
(*****************************************************************************)
val MODEL_TO_AUTOMATON_def =
 Define
  `MODEL_TO_AUTOMATON (M:('state,'prop)model) =
    <| Sigma := {a | a SUBSET M.P};
       Q     := {SOME s : ('state)option | s IN M.S} UNION {NONE};
       Delta := {(SOME s, a, SOME s') | (s,s') IN M.R /\ (a = M.L s')}
                UNION
                {(NONE, a, SOME s) | s IN M.S0 /\ (a = M.L s)};
       Q0    := {NONE :  ('state)option};
       F     := {SOME s : ('state)option | s IN M.S} UNION {NONE} |>`;

val AUTOMATON_MODEL_TO_AUTOMATON =
 store_thm
  ("AUTOMATON_MODEL_TO_AUTOMATON",
   ``!M. MODEL M ==> AUTOMATON(MODEL_TO_AUTOMATON M)``,
   RW_TAC list_ss [MODEL_def,AUTOMATON_def,MODEL_TO_AUTOMATON_def]
    THEN FULL_SIMP_TAC (srw_ss()) [SUBSET_DEF]
    THEN RW_TAC list_ss []
    THEN PROVE_TAC[]);

(*****************************************************************************)
(* Product of a model with an automaton                                      *)
(*                                                                           *)
(*  S is the cross product of the states of M with the states of A. That     *)
(*  is, the set of states (s,t) such that s is a state in M and t a state    *)
(*  in A. So is the set of states (s,t) such that s is in the initial        *)
(*  states of M and t is in the initial states of A. R((s,t),(s',t')) iff    *)
(*  (s,s') is in the relation of M, and (t,a,t') is in the relation of A,    *)
(*  where a is the labeling of s. P are the propositions of M and            *)
(*  L(s,t) = L(s).                                                           *)
(*****************************************************************************) 
val MODEL_AUTOMATON_PROD_def =
 Define 
  `MODEL_AUTOMATON_PROD 
    (M:('state2, 'prop) model) (A:('prop -> bool, 'state1) automaton)  =
    <| S  := {(s,t) | s IN M.S  /\ t IN A.Q};
       S0 := {(s,t) | s IN M.S0 /\ t IN A.Q0};
       R  := {((s,t),(s',t')) | 
              ?a. (a = M.L s) /\ (s,s') IN M.R /\ (t,a,t') IN A.Delta};
       P  := M.P;
       L  := \(s,t). M.L s |>`;

val _ = overload_on ("||", ``MODEL_AUTOMATON_PROD``);

val MODEL_MODEL_AUTOMATON_PROD =
 store_thm
  ("MODEL_MODEL_AUTOMATON_PROD",
   ``!M A. MODEL M /\ AUTOMATON A ==> MODEL(M || A)``,
   RW_TAC list_ss [MODEL_def,AUTOMATON_def,MODEL_AUTOMATON_PROD_def]
    THEN FULL_SIMP_TAC (srw_ss()) [SUBSET_DEF]
    THEN RW_TAC list_ss []
    THEN RES_TAC
    THEN FULL_SIMP_TAC list_ss []);

(*****************************************************************************)
(* Product of automata                                                       *)
(*****************************************************************************)
val AUTOMATON_PROD_def =
 Define
  `AUTOMATON_PROD
   (A1:('label1,'state1)automaton) (A2:('label2,'state2)automaton) =
    <| Sigma := {(a1,a2) | a1 IN A1.Sigma  /\ a2 IN A2.Sigma };
       Q     := {(q1,q2) | q1 IN A1.Q  /\ q2 IN A2.Q};
       Delta := {((q1,q2),(a1,a2),(q1',q2')) | 
                 (q1,a1,q1') IN A1.Delta /\ (q2,a2,q2') IN A2.Delta};
       Q0    := {(q1,q2) | q1 IN A1.Q0  /\ q2 IN A2.Q0};
       F     := {(q1,q2) | q1 IN A1.F  /\ q2 IN A2.F} |>`;

val _ = overload_on ("||", ``AUTOMATON_PROD``);

val AUTOMATON_AUTOMATON_PROD =
 store_thm
  ("AUTOMATON_AUTOMATON_PROD",
   ``!A1 A2. AUTOMATON A1 /\ AUTOMATON A2 ==> AUTOMATON(A1 || A2)``,
   RW_TAC list_ss [AUTOMATON_def,AUTOMATON_PROD_def]
    THEN FULL_SIMP_TAC (srw_ss()) [SUBSET_DEF]
    THEN RW_TAC list_ss []
    THEN PROVE_TAC[]);

val IN_LESS_LENGTH_SUB1 =
 store_thm
  ("IN_LESS_LENGTH_SUB1",
   ``!n v. n IN LESS(LENGTH v - 1) = n < LENGTH v - 1``,
   Cases_on `v`
    THEN RW_TAC list_ss [IN_LESS,IN_LESSX,LENGTH_def,LS,SUB]);

(******************************************************************************
* Examples

SIMP_CONV (srw_ss()) [MODEL_TO_AUTOMATON_def,PATH_TO_MODEL_def]
``PATH_TO_MODEL(FINITE l)``;

SIMP_CONV (srw_ss()) [MODEL_TO_AUTOMATON_def,PATH_TO_MODEL_def]
``MODEL_TO_AUTOMATON(PATH_TO_MODEL(FINITE l))``;

SIMP_CONV (srw_ss()) 
  [MODEL_TO_AUTOMATON_def,PATH_TO_MODEL_def,MODEL_PROD_def]
  ``(PATH_TO_MODEL(FINITE l) || 
     <| S  := states;
        S0 := initial_states;
        R  := trans;
        P  := props;
        L  := val_fn |>)``;

SIMP_CONV (srw_ss()) 
  [MODEL_TO_AUTOMATON_def,PATH_TO_MODEL_def,MODEL_PROD_def]
  ``MODEL_TO_AUTOMATON
    (PATH_TO_MODEL(FINITE l) || 
     <| S  := states;
        S0 := initial_states;
        R  := trans;
        P  := props;
        L  := val_fn |>)``;

SIMP_CONV (srw_ss()) 
  [MODEL_TO_AUTOMATON_def,PATH_TO_MODEL_def,MODEL_AUTOMATON_PROD_def]
  ``(PATH_TO_MODEL(FINITE l) ||
    <| Sigma := alphabet;
      Q     := states;
      Delta := delta;
      Q0    := initial_states;
      F     := final_states |>)``;
 
SIMP_CONV (srw_ss()) 
  [MODEL_TO_AUTOMATON_def,PATH_TO_MODEL_def,MODEL_AUTOMATON_PROD_def]
  ``MODEL_TO_AUTOMATON
    (PATH_TO_MODEL(FINITE l) || 
    <| Sigma := alphabet;
      Q     := states;
      Delta := delta;
      Q0    := initial_states;
      F     := final_states |>)``;

SIMP_CONV (srw_ss()) 
  [MODEL_AUTOMATON_PROD_def,OPEN_MODEL_def]
  ``OPEN_MODEL P
    ||
    <| Sigma := { p | p SUBSET P};
       Q     := states;
       Delta := delta;
       Q0    := initial_states;
       F     := final_states |>``;

> val it =
    |- OPEN_MODEL P ||
       <|Sigma := {p | p SUBSET P}; Q := states; Delta := delta;
         Q0 := initial_states; F := final_states|> =
       <|S := {(s,t) | (s SUBSET P \/ (s = SINK P)) /\ t IN states};
         S0 := {(s,t) | s SUBSET P /\ t IN initial_states};
         R :=
           {((s,t),s',t') |
            (s SUBSET P /\ (s' SUBSET P \/ (s' = SINK P))) /\
            (t,(if s = SINK P then {} else s),t') IN delta}; P := P;
         L := (\(s,t). (if s = SINK P then {} else s))|> : thm

M0 || <2^P, Q, Delta, Q0, F> = 
 <(2^P UNION {SINK}) x Q,
  (2^P x Q0),
  {((s,t), (s',t')) | s IN 2^P And 
                      s' IN (2^P UNION {SINK}) And 
                      (t,s,t') IN Delta},
  P,
  Lambda (s,t) If s = SINK P then {} else s>



SIMP_CONV (srw_ss()++resq_SS) 
  [MODEL_AUTOMATON_PROD_def,OPEN_MODEL_def,IN_COMPUTATION,
   PATH_def,IN_LESS_LENGTH_SUB1,ELEM_FINITE,SUBSET_SINK,
   DECIDE ``~A \/ (~B \/ ~C /\ ~D) \/ E = A ==> B ==> (C \/ D) ==> E``,
   LEMMA1]
  ``(?p. ~(p IN P)) ==> v IN COMPUTATION
          (OPEN_MODEL P
           ||
           <| Sigma := { p | p SUBSET P};
              Q     := states;
              Delta := delta;
              Q0    := initial_states;
              F     := final_states |>)``;


SIMP_CONV (srw_ss()++resq_SS) 
  [MODEL_AUTOMATON_PROD_def,OPEN_MODEL_def,IN_COMPUTATION,
   PATH_def,IN_LESS_LENGTH_SUB1,ELEM_FINITE,SUBSET_SINK,
   DECIDE ``~A \/ (~B \/ ~C /\ ~D) \/ E = A ==> B ==> (C \/ D) ==> E``,
   LEMMA1]
  ``(?p. ~(p IN P)) ==> v IN COMPUTATION(OPEN_MODEL P)``;


SIMP_CONV (srw_ss()++resq_SS) 
  [MODEL_AUTOMATON_PROD_def,OPEN_MODEL_def,IN_COMPUTATION,
   PATH_def,IN_LESS_LENGTH_SUB1,ELEM_FINITE,SUBSET_SINK,
   DECIDE ``~A \/ (~B \/ ~C /\ ~D) \/ E = A ==> B ==> (C \/ D) ==> E``,
   LEMMA1]
  ``(MODEL_AUTOMATON_PROD (OPEN_MODEL P) A).L``;


SIMP_CONV (srw_ss()++resq_SS) 
  [MODEL_AUTOMATON_PROD_def,OPEN_MODEL_def,IN_COMPUTATION,
   PATH_def,IN_LESS_LENGTH_SUB1,ELEM_FINITE,SUBSET_SINK,
   DECIDE ``~A \/ (~B \/ ~C /\ ~D) \/ E = A ==> B ==> (C \/ D) ==> E``,
   LEMMA1]
  ``(OPEN_MODEL P).L``;


SIMP_CONV (srw_ss()++resq_SS) 
  [MODEL_AUTOMATON_PROD_def,OPEN_MODEL_def,IN_COMPUTATION,COMPUTATION_TO_MODEL_def,
   PATH_def,IN_LESS_LENGTH_SUB1,ELEM_FINITE,SUBSET_SINK,
   DECIDE ``~A \/ (~B \/ ~C /\ ~D) \/ E = A ==> B ==> (C \/ D) ==> E``,
   LEMMA1]
  ``v IN COMPUTATION(COMPUTATION_TO_MODEL w || A)``;

SIMP_CONV (srw_ss()++resq_SS) 
  [MODEL_AUTOMATON_PROD_def,OPEN_MODEL_def,IN_COMPUTATION,COMPUTATION_TO_MODEL_def,
   PATH_def,IN_LESS_LENGTH_SUB1,ELEM_FINITE,SUBSET_SINK,
   DECIDE ``~A \/ (~B \/ ~C /\ ~D) \/ E = A ==> B ==> (C \/ D) ==> E``,
   LEMMA1]
  ``(?p. ~(p IN P)) ==> v IN COMPUTATION(OPEN_MODEL P || A)``;


SIMP_CONV (srw_ss()++resq_SS) 
  [MODEL_AUTOMATON_PROD_def,OPEN_MODEL_def,IN_COMPUTATION,COMPUTATION_TO_MODEL_def,
   PATH_def,IN_LESS_LENGTH_SUB1,ELEM_FINITE,SUBSET_SINK]
  ``(COMPUTATION_TO_MODEL v || A).L``;

SIMP_CONV (srw_ss()++resq_SS) 
  [MODEL_AUTOMATON_PROD_def,OPEN_MODEL_def,IN_COMPUTATION,COMPUTATION_TO_MODEL_def,
   PATH_def,IN_LESS_LENGTH_SUB1,ELEM_FINITE,SUBSET_SINK]
  ``(OPEN_MODEL P || A).L``;

******************************************************************************)


val IN_COMPUTATION =
 store_thm
  ("IN_COMPUTATION",
   ``w IN COMPUTATION M = ?s. s IN M.S0 /\ PATH M s w``,
   RW_TAC list_ss [IN_DEF,COMPUTATION_def]);

val SUBSET_SINK =
 store_thm
  ("SUBSET_SINK",
   ``!A P. (?p. ~(p IN P)) /\ A SUBSET P ==> ~(A = SINK P)``,
   RW_TAC list_ss [SUBSET_DEF,SINK_def]
    THEN Cases_on `A = {@p. ~(p IN P)}`
    THEN FULL_SIMP_TAC list_ss [IN_SING]
    THEN FULL_SIMP_TAC list_ss [IN_DEF]
    THEN `~(P @p. ~P p)` by METIS_TAC[SELECT_THM]);

val EQ_PAIR =
 store_thm
  ("EQ_PAIR",
   ``!p x y. (p = (x,y)) = (x = FST p) /\ (y = SND p)``,
   Cases_on `p`
    THEN ZAP_TAC std_ss []);

val LENGTH_LAST =
 store_thm
  ("LENGTH_LAST",
   ``!l. LENGTH l > 0 
         ==>
         (LAST l = EL (LENGTH l - 1) l)``,
   RW_TAC arith_ss [EL_PRE_LENGTH]);

val COMPUTATION_OPEN_MODEL =
 store_thm
  ("COMPUTATION_OPEN_MODEL",
   ``(?p. ~(p IN P))
     ==>
     (v IN COMPUTATION(OPEN_MODEL P) =
      LENGTH v > 0 /\ ELEM v 0 SUBSET P
      /\
      (!n::LESS(LENGTH v - 1).
        ELEM v n SUBSET P /\ 
        (ELEM v (SUC n) SUBSET P \/ (ELEM v (SUC n) = SINK P)))
      /\
      !l. (v = FINITE l) ==> ~(LAST l SUBSET P))``, 
     RW_TAC (srw_ss()++resq_SS)
      [OPEN_MODEL_def,IN_COMPUTATION,
       PATH_def,IN_LESS_LENGTH_SUB1,ELEM_FINITE,SUBSET_SINK]
      THEN EQ_TAC
      THEN RW_TAC list_ss []
      THEN FULL_SIMP_TAC std_ss [EQ_PAIR,ELEM_FINITE,LENGTH_def,SUB,LS,GT]
      THEN PROVE_TAC[LENGTH_LAST]);

val UF_VALID_OPEN_MODEL =
 store_thm
  ("UF_VALID_OPEN_MODEL",
   ``(?p. ~(p IN P)) /\ AUTOMATON A
     ==>
     (UF_VALID (OPEN_MODEL P) f =
      !v. LENGTH v > 0 /\ ELEM v 0 SUBSET P
          /\
          (!n::LESS(LENGTH v - 1).
            ELEM v n SUBSET P /\
            (ELEM v (SUC n) SUBSET P \/ (ELEM v (SUC n) = SINK P)))
          /\
          (!l. (v = FINITE l) ==> ~(LAST l SUBSET P))
          ==>
          UF_SEM (MAP_PATH (\s. STATE (if s = SINK P then {} else s)) v) f)``,
    RW_TAC (srw_ss()++resq_SS) [UF_VALID_def,COMPUTATION_OPEN_MODEL]
     THEN EQ_TAC
     THEN RW_TAC list_ss []
     THENL
      [`UF_SEM (MAP_PATH (\s. STATE ((OPEN_MODEL P).L s)) v) f` by METIS_TAC[]
        THEN FULL_SIMP_TAC (srw_ss()++resq_SS) [OPEN_MODEL_def],
       `UF_SEM (MAP_PATH (\s. STATE (if s = SINK P then {} else s)) v) f`
        by METIS_TAC[]
        THEN RW_TAC (srw_ss()++resq_SS) [OPEN_MODEL_def]]);

val LENGTH1_LAST =
 store_thm
  ("LENGTH1_LAST",
   ``!l. (LENGTH l = 1) ==> (LAST l = EL 0 l)``,
   RW_TAC list_ss [LENGTH1]
    THEN RW_TAC list_ss [LENGTH1,LAST_CONS,EL]);

val LEMMA1 = (* Surprisingly tricky proof needed *)
 prove
  (``(?p. ~(p IN P)) 
     ==> 
     ((A /\ B) /\ (s SUBSET P /\ C) /\ Q(s = SINK P) = 
      (A /\ B) /\ (s SUBSET P /\ C) /\ Q F)``,
    RW_TAC list_ss []
     THEN EQ_TAC
     THEN RW_TAC list_ss []
     THEN IMP_RES_TAC SUBSET_SINK
     THEN RW_TAC list_ss []
     THEN POP_ASSUM(fn th => FULL_SIMP_TAC std_ss [th]));

val COMPUTATION_OPEN_MODEL_AUTOMATON =
 store_thm
  ("COMPUTATION_OPEN_MODEL_AUTOMATON",
   ``(?p. ~(p IN P)) /\ AUTOMATON A
     ==>
     (v IN COMPUTATION(OPEN_MODEL P || A) =
      LENGTH v > 0 /\ FST(ELEM v 0) SUBSET P /\ SND(ELEM v 0) IN A.Q0 
      /\
      (!n::LESS(LENGTH v - 1).
        FST(ELEM v n) SUBSET P /\ 
        (FST(ELEM v (SUC n)) SUBSET P \/ (FST (ELEM v (SUC n)) = SINK P)) /\ 
        (SND(ELEM v n), FST(ELEM v n), SND(ELEM v (SUC n))) IN A.Delta) 
      /\
      !l. (v = FINITE l) /\ FST(LAST l) SUBSET P 
          ==> 
          !s. ~((SND(LAST l), FST(LAST l), s) IN A.Delta))``,
     RW_TAC (srw_ss()++resq_SS)
      [MODEL_AUTOMATON_PROD_def,OPEN_MODEL_def,IN_COMPUTATION,
       PATH_def,IN_LESS_LENGTH_SUB1,ELEM_FINITE,SUBSET_SINK,
       DECIDE ``~A \/ (~B \/ ~C /\ ~D) \/ E = A ==> B ==> (C \/ D) ==> E``,
       LEMMA1]  
      THEN FULL_SIMP_TAC (srw_ss()++resq_SS) [AUTOMATON_def]
      THEN EQ_TAC
      THEN RW_TAC list_ss []
      THEN FULL_SIMP_TAC std_ss [EQ_PAIR,ELEM_FINITE,LENGTH_def,SUB,LS,GT]
      THEN RW_TAC list_ss []
      THEN ZAP_TAC std_ss [SUBSET_DEF]
      THEN ASM_REWRITE_TAC[GSYM EL]
      THEN Cases_on `LENGTH l = 1`
      THEN ASSUM_LIST
            (fn thl => 
              if is_eq(concl(el 1 thl)) 
               then FULL_SIMP_TAC list_ss [GSYM(MATCH_MP LENGTH1_LAST (el 1 thl))]
               else ALL_TAC)
      THEN METIS_TAC [LENGTH_LAST]);

val UF_VALID_OPEN_MODEL_AUTOMATON =
 store_thm
  ("UF_VALID_OPEN_MODEL_AUTOMATON",
   ``(?p. ~(p IN P)) /\ AUTOMATON A
     ==>
     (UF_VALID (MODEL_AUTOMATON_PROD (OPEN_MODEL P) A) f =
      !v. LENGTH v > 0 /\ FST(ELEM v 0) SUBSET P /\ SND(ELEM v 0) IN A.Q0
          /\
          (!n::LESS(LENGTH v - 1).
            FST(ELEM v n) SUBSET P /\
            (FST(ELEM v (SUC n)) SUBSET P \/ (FST (ELEM v (SUC n)) = SINK P)) /\
            (SND(ELEM v n), FST(ELEM v n), SND(ELEM v (SUC n))) IN A.Delta)
          /\
          (!l. (v = FINITE l) /\ FST(LAST l) SUBSET P
               ==>
               !s. ~((SND(LAST l), FST(LAST l), s) IN A.Delta))
          ==>
          UF_SEM (MAP_PATH (\s. STATE (if FST s = SINK P then {} else FST s)) v) f)``,
    RW_TAC (srw_ss()++resq_SS) [UF_VALID_def,COMPUTATION_OPEN_MODEL_AUTOMATON]
     THEN EQ_TAC
     THEN RW_TAC list_ss []
     THENL
      [`UF_SEM (MAP_PATH (\s. STATE ((OPEN_MODEL P || A).L s)) v) f` by METIS_TAC[]
        THEN FULL_SIMP_TAC (srw_ss()++resq_SS) [MODEL_AUTOMATON_PROD_def,OPEN_MODEL_def]
        THEN POP_ASSUM(ASSUME_TAC o GEN_BETA_RULE)
        THEN RW_TAC std_ss [],
       `UF_SEM (MAP_PATH (\s. STATE (if FST s = SINK P then {} else FST s)) v) f`
        by METIS_TAC[]
        THEN RW_TAC (srw_ss()++resq_SS) [MODEL_AUTOMATON_PROD_def,OPEN_MODEL_def]
        THEN GEN_BETA_TAC
        THEN RW_TAC std_ss []]);


(*****************************************************************************)
(* Conversion of a computation to a model (Kripke structure)                 *)
(*****************************************************************************)
val COMPUTATION_TO_MODEL_def =
 Define
  `COMPUTATION_TO_MODEL w = 
    <| S  := {n | n < LENGTH w};
       S0 := {0};
       R  := {(n,n') | n < LENGTH w /\ n' < LENGTH w /\ (n' = n+1)};
       P  := {p:'prop | ?i. i < LENGTH w /\ p IN ELEM w i};
       L  := \n. {p | n < LENGTH w /\ p IN (ELEM w n)} |>`;

val COMPUTATION_TO_MODEL_CASES =
 store_thm
  ("COMPUTATION_TO_MODEL_CASES",
   ``(COMPUTATION_TO_MODEL(FINITE l) = 
      <| S  := {n | n < LENGTH l};
         S0 := {0};
         R  := {(n,n') | n < LENGTH l /\ n' < LENGTH l /\ (n' = n+1)};
         P  := {p:'prop | ?i. i < LENGTH l /\ p IN EL i l};
         L  := \n. {p | n < LENGTH l /\ p IN (EL n l)} |>)
     /\
     (COMPUTATION_TO_MODEL(INFINITE f) = 
      <| S  := {n | T};
         S0 := {0};
         R  := {(n,n') | n' = n+1};
         P  := {p:'prop | ?i. p IN f i};
         L  := \n. {p | p IN (f n)} |>)``,
     RW_TAC list_ss 
      [COMPUTATION_TO_MODEL_def,LENGTH_def,LS,ELEM_INFINITE,ELEM_FINITE]);

val MODEL_COMPUTATION_TO_MODEL =
 store_thm
  ("MODEL_COMPUTATION_TO_MODEL",
   ``!p. 0 < LENGTH p ==>  MODEL(COMPUTATION_TO_MODEL p)``,
   GEN_TAC
    THEN Cases_on `p`
    THEN RW_TAC list_ss [SUBSET_DEF,MODEL_def,COMPUTATION_TO_MODEL_def]   
    THEN FULL_SIMP_TAC (srw_ss()) [SUBSET_UNIV,LENGTH_def,LS]
    THEN PROVE_TAC[]);

val LS_GT_IMP =
 store_thm
  ("LS_GT_IMP",
   ``!(n:num) (w:'a path). n < LENGTH w ==> LENGTH w > 0``,
   Cases_on `w`
    THEN RW_TAC list_ss [LENGTH_def,LS,GT]);

val GT_LS_IMP =
 store_thm
  ("GT_LS_IMP",
   ``!(n:num) (w:'a path). LENGTH w > n ==> 0 < LENGTH w``,
   Cases_on `w`
    THEN RW_TAC list_ss [LENGTH_def,LS,GT]);

val LEMMA2 = 
 prove
  (``1 <= LENGTH w
     /\
     (!n. n < LENGTH v - 1 ==>
        SUC(FST(ELEM v n)) < LENGTH w 
        /\ 
        FST(ELEM v (SUC n)) < LENGTH w 
        /\
        (FST(ELEM v (SUC n)) = SUC(FST(ELEM v n))))
     ==>
     LENGTH v <= LENGTH w``,
   Cases_on `v` THEN Cases_on `w`
    THEN RW_TAC arith_ss 
          [LENGTH_def,ELEM_FINITE,ELEM_INFINITE,LE,LS,SUB,GSYM EL,
           DECIDE ``~A \/ ~B \/ C = A /\ B ==> C``]
    THENL
     [`!m. m < LENGTH l ==> (FST(EL m l) = FST(EL 0 l) + m)` by Induct
       THEN RW_TAC arith_ss []
       THEN Cases_on `LENGTH l <= 1`
       THEN RW_TAC arith_ss []
       THEN `LENGTH l - 1 < LENGTH l /\ LENGTH l - 2 < LENGTH l - 1` by DECIDE_TAC
       THEN RES_TAC
       THEN `SUC (LENGTH l - 2) = LENGTH l - 1` 
             by  PROVE_TAC[DECIDE``m - 1 < m /\ m - 2 < m - 1 ==> (SUC(m - 2) = m - 1)``]
       THEN POP_ASSUM(fn th => FULL_SIMP_TAC std_ss [th])
       THEN `FST (EL 0 l) + (LENGTH l - 1) < LENGTH l'` by PROVE_TAC[]
       THEN DECIDE_TAC,
      RW_TAC std_ss [DECIDE``~A \/ B = A ==> B``]
       THEN CCONTR_TAC
       THEN FULL_SIMP_TAC std_ss []
       THEN `!m. FST(f m) = FST(f 0) + m` by Induct
       THEN RW_TAC arith_ss []
       THEN POP_ASSUM(ASSUME_TAC o AP_TERM ``SUC`` o Q.SPEC `LENGTH l`)
       THEN `SUC (FST (f (LENGTH l))) < LENGTH l` by PROVE_TAC[]
       THEN DECIDE_TAC]);

val LEMMA3 = 
 prove
  (``1 <= LENGTH w 
     /\
     (FST (ELEM v 0) = 0)
     /\
     (!n. n < LENGTH v - 1 ==>
        SUC(FST(ELEM v n)) < LENGTH w 
        /\ 
        FST(ELEM v (SUC n)) < LENGTH w 
        /\
        (FST(ELEM v (SUC n)) = SUC(FST(ELEM v n))))
     ==>
     !m. m < LENGTH v - 1 ==> (FST (ELEM v m) = m)``,
   Cases_on `v` THEN Cases_on `w`
    THEN RW_TAC arith_ss 
          [LENGTH_def,ELEM_FINITE,ELEM_INFINITE,LE,LS,SUB,GSYM EL,
           DECIDE ``~A \/ ~B \/ C = A /\ B ==> C``]
    THEN Induct_on `m`
    THEN RW_TAC arith_ss []);

val COMPUTATION_COMPUTATION_MODEL_AUTOMATON_LEMMA =
 store_thm
  ("COMPUTATION_COMPUTATION_MODEL_AUTOMATON_LEMMA",
   ``AUTOMATON A
     ==>
     (v IN COMPUTATION(COMPUTATION_TO_MODEL w || A) =
      LENGTH v > 0 /\ LENGTH w > 0 /\ (FST(ELEM v 0) = 0) /\ SND(ELEM v 0) IN A.Q0 
      /\
      (!n::LESS(LENGTH v - 1).
        SUC(FST(ELEM v n)) < LENGTH w /\ FST(ELEM v (SUC n)) < LENGTH w /\ 
        SND(ELEM v n) IN A.Q /\ (FST(ELEM v (SUC n)) = SUC(FST(ELEM v n))) /\
        (SND(ELEM v n), ELEM w (FST(ELEM v n)), SND(ELEM v (SUC n))) IN A.Delta) 
      /\
      !l. (v = FINITE l) /\ SUC(FST(LAST l)) < LENGTH w
          ==> 
          !s. ~((SND(LAST l), ELEM w (FST(LAST l)), s) IN A.Delta))``,
     RW_TAC (srw_ss()++resq_SS)
      [MODEL_AUTOMATON_PROD_def,COMPUTATION_TO_MODEL_def,IN_COMPUTATION,
       PATH_def,IN_LESS_LENGTH_SUB1,ELEM_FINITE,SUBSET_SINK,
       DECIDE ``~A \/ ~B \/ ~C \/ ~D = A ==> B ==> C ==> ~D``]
      THEN FULL_SIMP_TAC (srw_ss()++resq_SS) [AUTOMATON_def]
      THEN EQ_TAC
      THEN RW_TAC list_ss []
      THEN FULL_SIMP_TAC std_ss [EQ_PAIR,ELEM_FINITE,LENGTH_def,SUB,LS,GT]
      THEN RW_TAC list_ss []
      THEN ZAP_TAC std_ss [SUBSET_DEF]
      THEN TRY(METIS_TAC[ADD1])
      THEN TRY(`EL (LENGTH l - 1) l = LAST l` by PROVE_TAC[LENGTH_LAST]
                THEN POP_ASSUM(fn th => FULL_SIMP_TAC list_ss [th]))
      THENL
       [METIS_TAC[LS_GT_IMP],
        `(SND (ELEM v n),
          {p | FST (ELEM v n) < LENGTH w /\ p IN ELEM w (FST (ELEM v n))},
          SND (ELEM v (SUC n))) IN A.Delta` by METIS_TAC[]
         THEN `FST (ELEM v n) < LENGTH w` by METIS_TAC[]
         THEN POP_ASSUM(fn th => FULL_SIMP_TAC list_ss [th,GSPEC_ID]),
        METIS_TAC[LS_TRANS_X,DECIDE``n < SUC n``,ADD1],
        METIS_TAC[GT_LS_IMP],
        METIS_TAC[LS_TRANS_X,DECIDE``n < SUC n``,ADD1],
        METIS_TAC[LS_TRANS_X,DECIDE``n < SUC n``,ADD1],
        `FST (ELEM v n) < LENGTH w` by METIS_TAC[LS_TRANS_X,DECIDE``n < SUC n``]
         THEN RW_TAC list_ss [GSPEC_ID],
        METIS_TAC[LS_TRANS_X,DECIDE``n < SUC n``,ADD1]]);

val COMPUTATION_COMPUTATION_MODEL_AUTOMATON =
 store_thm
  ("COMPUTATION_COMPUTATION_MODEL_AUTOMATON",
   ``AUTOMATON A
     ==>
     (v IN COMPUTATION(COMPUTATION_TO_MODEL w || A) =
      LENGTH v > 0 /\ LENGTH w > 0 /\ (FST(ELEM v 0) = 0) 
      /\ 
      SND(ELEM v 0) IN A.Q0 /\ LENGTH v <= LENGTH w
      /\
      (!n::LESS(LENGTH v - 1). 
        (FST(ELEM v (SUC n)) = SUC n) /\ SND(ELEM v n) IN A.Q /\
        (SND(ELEM v n), ELEM w n, SND(ELEM v (SUC n))) IN A.Delta) 
      /\
      !l. (v = FINITE l) /\ SUC(FST(LAST l)) < LENGTH w
          ==> 
          !s. ~((SND(LAST l), ELEM w (FST(LAST l)), s) IN A.Delta))``,
     RW_TAC (srw_ss()++resq_SS)
      [COMPUTATION_COMPUTATION_MODEL_AUTOMATON_LEMMA,
       IN_LESS_LENGTH_SUB1]
      THEN EQ_TAC
      THEN RW_TAC list_ss []
      THEN `1 <= LENGTH w` 
            by (Cases_on `w` 
                 THEN RW_TAC list_ss [LENGTH_def,LE]
                 THEN FULL_SIMP_TAC arith_ss [LENGTH_def,GT])
      THENL
       [METIS_TAC[LEMMA2],
        METIS_TAC[LEMMA3],
        METIS_TAC[LEMMA3],
        Cases_on `v` THEN Cases_on `w`
         THEN FULL_SIMP_TAC list_ss [LENGTH_def,LS,SUB,GT,LE,ELEM_FINITE,ELEM_INFINITE]
         THEN FULL_SIMP_TAC std_ss [GSYM EL]
         THEN Cases_on `n=0`
         THEN RW_TAC list_ss []
         THEN `n - 1 < LENGTH l - 1` by DECIDE_TAC
         THEN `SUC(n-1) = n` by DECIDE_TAC
         THEN `FST (EL n l) = n` by PROVE_TAC[]
         THEN DECIDE_TAC,
        Cases_on `v` THEN Cases_on `w`
         THEN FULL_SIMP_TAC list_ss [LENGTH_def,LS,SUB,GT,LE,ELEM_FINITE,ELEM_INFINITE],
        Cases_on `n=0`
         THEN RW_TAC list_ss []
         THEN Cases_on `v`
         THEN FULL_SIMP_TAC list_ss [LENGTH_def,LS,SUB,GT,LE,ELEM_FINITE,ELEM_INFINITE]
         THEN FULL_SIMP_TAC std_ss [GSYM EL]
         THENL
          [`n - 1 < LENGTH l - 1` by DECIDE_TAC
            THEN `SUC(n-1) = n` by DECIDE_TAC
            THEN `FST (EL n l) = n` by PROVE_TAC[]
            THEN DECIDE_TAC,
           `SUC(n-1) = n` by DECIDE_TAC
            THEN `FST (f n) = n` by PROVE_TAC[]
            THEN RW_TAC list_ss []],
        Cases_on `n=0`
         THEN RW_TAC list_ss []
         THEN TRY(PROVE_TAC [ONE])
         THEN `n - 1 < LENGTH v - 1` 
               by (Cases_on `v` 
                    THEN RW_TAC list_ss [LENGTH_def,LS,SUB]
                    THEN FULL_SIMP_TAC arith_ss [LENGTH_def,GT,LS,SUB])
         THEN `SUC(n-1) = n` by DECIDE_TAC
         THEN METIS_TAC[]]);

val LANGUAGE_def = 
 Define 
  `(LANGUAGE A (FINITE l) = 
    (LENGTH l > 0)                                                         /\
    EL 0 l IN A.Q0                                                         /\
    (!n :: (LESS(LENGTH l - 1)). ?a. (EL n l, a, EL (SUC n) l) IN A.Delta) /\
    !a s. ~((EL (LENGTH l - 1) l, a, s) IN A.Delta))
   /\
   (LANGUAGE A (INFINITE f) = 
     f 0 IN A.Q0 /\ !n. ?a. (f n, a, f(SUC n)) IN A.Delta)`;

(*****************************************************************************)
(* MODEL_TO_AUTOMATON adds a value -- "iota" in Clarke/Grumberg/Peled -- to  *)
(* the states of M.  STRIP_IOTA removes iotas.                               *)
(* Not sure if this is needed.                                               *)
(*****************************************************************************)
val STRIP_IOTA_def =
 Define `STRIP_IOTA(SOME x) = x`;

val PATH_STRIP_IOTA_def =
 Define
  `(PATH_STRIP_IOTA(FINITE l) = FINITE(MAP STRIP_IOTA l))
   /\
   (PATH_STRIP_IOTA(INFINITE f) = INFINITE(STRIP_IOTA o f))`;

(*****************************************************************************)
(* Add iotas to a path                                                       *)
(*****************************************************************************)
val PATH_ADD_IOTA_def =
 Define
  `(PATH_ADD_IOTA(FINITE l) = FINITE(MAP SOME l))
   /\
   (PATH_ADD_IOTA(INFINITE f) = INFINITE(SOME o f))`;

(*****************************************************************************)
(* Should have proved FINITE_PATH_LANGUAGE directly, but now too lazy to     *)
(* tweak the rather tedious proof.                                           *)
(*****************************************************************************)
val FINITE_PATH_LANGUAGE_LEMMA = 
 store_thm
  ("FINITE_PATH_LANGUAGE_LEMMA",
   ``!M s l.
      MODEL M /\ s IN M.S0 /\ (s = HD l)
      ==>
      (PATH M s (FINITE l) = 
        LANGUAGE 
         (MODEL_TO_AUTOMATON M) 
         (CONS(NONE, (PATH_ADD_IOTA (FINITE l)))))``,
   REPEAT GEN_TAC
    THEN SIMP_TAC (list_ss++resq_SS) 
          [MODEL_def,PATH_CASES,LANGUAGE_def,MODEL_TO_AUTOMATON_def,
           PATH_ADD_IOTA_def,CONS_def]
    THEN RW_TAC (srw_ss()) []
    THEN EQ_TAC
    THEN RW_TAC list_ss []
    THENL
     [Cases_on `n`
       THEN RW_TAC list_ss []
       THENL
        [Q.EXISTS_TAC `HD l`
          THEN RW_TAC list_ss []
          THEN Cases_on `l`
          THEN RW_TAC list_ss []
          THEN FULL_SIMP_TAC list_ss [],
         Q.EXISTS_TAC `M.L(EL (SUC n') l)` 
          THEN DISJ1_TAC
          THEN Q.EXISTS_TAC `EL n' l` 
          THEN Q.EXISTS_TAC `EL (SUC n') l`
          THEN `n' < LENGTH l` by DECIDE_TAC
          THEN RW_TAC list_ss [EL_MAP]
          THEN Cases_on `l`
          THEN RW_TAC list_ss []
          THEN FULL_SIMP_TAC list_ss []
          THEN `n' < LENGTH t` by DECIDE_TAC
          THEN RW_TAC list_ss [EL_MAP]],
      Cases_on `(~(EL (LENGTH l) (NONE::MAP SOME l) = SOME s') \/ ~(a = M.L s'') \/
                ~(s = SOME s'')) \/ ~((s',s'') IN M.R)`
       THEN FULL_SIMP_TAC list_ss []
       THEN RW_TAC list_ss []
       THEN `LENGTH l = SUC(LENGTH l - 1)` by DECIDE_TAC
       THEN `EL (LENGTH l - 1) (MAP SOME l) = SOME s'` by PROVE_TAC[TL,EL]
       THEN `LENGTH l - 1  < LENGTH l` by DECIDE_TAC
       THEN `SOME(EL (LENGTH l - 1) l) = SOME s'` by PROVE_TAC[EL_MAP]
       THEN FULL_SIMP_TAC list_ss []
       THEN PROVE_TAC[],
      Cases_on `(~(EL (LENGTH l) (NONE::MAP SOME l) = NONE) \/ ~(a = M.L s') \/
                ~(s = SOME s')) \/ ~(s' IN M.S0)`
       THEN FULL_SIMP_TAC list_ss []
       THEN RW_TAC list_ss []
       THEN `LENGTH l = SUC(LENGTH l - 1)` by DECIDE_TAC
       THEN `EL (LENGTH l - 1) (MAP SOME l) = NONE` by PROVE_TAC[TL,EL]
       THEN `LENGTH l - 1  < LENGTH l` by DECIDE_TAC
       THEN `SOME(EL (LENGTH l - 1) l) = NONE` by PROVE_TAC[EL_MAP]
       THEN FULL_SIMP_TAC list_ss [],
      Cases_on `LENGTH l = 0`
       THEN RW_TAC list_ss []
       THEN POP_ASSUM(fn th => FULL_SIMP_TAC list_ss [th]),
      FULL_SIMP_TAC list_ss [SUBSET_DEF],
      `SUC n < LENGTH l` by DECIDE_TAC
       THEN RES_TAC
       THEN `n < LENGTH l` by DECIDE_TAC
       THEN FULL_SIMP_TAC list_ss [EL_MAP]
       THEN PROVE_TAC[],
      `SUC n < LENGTH l` by DECIDE_TAC
       THEN RES_TAC
       THEN `n < LENGTH l` by DECIDE_TAC
       THEN FULL_SIMP_TAC list_ss [EL_MAP]
       THEN Cases_on `l`
       THEN RW_TAC list_ss []
       THEN FULL_SIMP_TAC list_ss []
       THEN `EL n (MAP SOME t) = SOME (EL n t)` by PROVE_TAC[EL_MAP]
               (* Above needed, I think, for mysterious type variable reasons *)
       THEN `SOME(EL n t) = SOME s''` by PROVE_TAC[]
       THEN FULL_SIMP_TAC list_ss []
       THEN PROVE_TAC[],
      `SUC n < LENGTH l` by DECIDE_TAC
       THEN RES_TAC
       THEN FULL_SIMP_TAC list_ss [EL_MAP]
       THEN `n < LENGTH l` by DECIDE_TAC
       THEN `EL n (MAP SOME l) = SOME (EL n l)` by PROVE_TAC[EL_MAP] 
       THENL
        [`SOME(EL n l) = SOME s'` by PROVE_TAC[]
          THEN FULL_SIMP_TAC list_ss []
          THEN Cases_on `l`
          THEN RW_TAC list_ss []
          THEN FULL_SIMP_TAC list_ss []
          THEN `EL n (MAP SOME t) = SOME (EL n t)` by PROVE_TAC[EL_MAP] 
               (* Above needed, I think, for mysterious type variable reasons *)
          THEN `SOME(EL n t) = SOME s''` by PROVE_TAC[]
          THEN FULL_SIMP_TAC list_ss [],
         `SOME(EL n l) = NONE` by PROVE_TAC[]
          THEN FULL_SIMP_TAC list_ss []],
      Cases_on `LENGTH l = 0`
       THEN RW_TAC list_ss []
       THEN FULL_SIMP_TAC list_ss []
       THEN `LENGTH l - 1 < LENGTH l` by DECIDE_TAC
       THEN RES_TAC
       THENL
        [`!a s.
            (!s' s''.
               (~(EL (LENGTH l) (NONE::MAP SOME l) = SOME s') \/
                ~(a = M.L s'') \/ ~(s = SOME s'')) \/ ~((s',s'') IN M.R))` 
           by PROVE_TAC[]
          THEN POP_ASSUM
                (fn th => 
                  ASSUME_TAC(Q.SPECL[`M.L s`,`SOME s`,`EL (LENGTH l - 1) l`,`s`]th))
          THEN FULL_SIMP_TAC list_ss []
          THEN `LENGTH l = SUC(LENGTH l - 1)` by DECIDE_TAC
          THEN `LENGTH l - 1 < LENGTH l` by DECIDE_TAC
          THEN PROVE_TAC[EL,TL,EL_MAP],
         `!a s.
            (!s' s''.
               (~(EL (LENGTH l) (NONE::MAP SOME l) = SOME s') \/
                ~(a = M.L s'') \/ ~(s = SOME s'')) \/ ~((s',s'') IN M.R))` 
           by PROVE_TAC[]
          THEN POP_ASSUM
                (fn th => 
                  ASSUME_TAC(Q.SPECL[`M.L s`,`SOME s`,`EL (LENGTH l - 1) l`,`s`]th))
          THEN FULL_SIMP_TAC list_ss []
          THEN `LENGTH l = SUC(LENGTH l - 1)` by DECIDE_TAC
          THEN `LENGTH l - 1 < LENGTH l` by DECIDE_TAC
          THEN PROVE_TAC[EL,TL,EL_MAP]]]);

(*****************************************************************************)
(*     |- !M l.                                                              *)
(*          MODEL M /\ HD l IN M.S0 ==>                                      *)
(*          (PATH M (HD l) (FINITE l) =                                      *)
(*           LANGUAGE (MODEL_TO_AUTOMATON M)                                 *)
(*             (CONS (NONE,PATH_ADD_IOTA (FINITE l))))                       *)
(*****************************************************************************)
val FINITE_PATH_LANGUAGE =
 save_thm
  ("FINITE_PATH_LANGUAGE",
   ((Q.GEN `M` o Q.GEN `l`)
    (SIMP_RULE list_ss []
     (Q.SPECL[`M`,`HD l`,`l`]FINITE_PATH_LANGUAGE_LEMMA))));
 
val INFINITE_PATH_LANGUAGE =
 store_thm
  ("INFINITE_PATH_LANGUAGE",
   ``!M f.
      MODEL M /\ f 0 IN M.S0
      ==>
      (PATH M (f 0) (INFINITE f) = 
        LANGUAGE 
         (MODEL_TO_AUTOMATON M) 
         (CONS(NONE, (PATH_ADD_IOTA (INFINITE f)))))``,
   REPEAT GEN_TAC
    THEN SIMP_TAC (list_ss++resq_SS) 
          [MODEL_def,PATH_CASES,LANGUAGE_def,MODEL_TO_AUTOMATON_def,
           PATH_ADD_IOTA_def,CONS_def]
    THEN RW_TAC (srw_ss()) []
    THEN EQ_TAC
    THEN RW_TAC list_ss []
    THENL
     [Cases_on `n`
       THEN RW_TAC list_ss [],
      Cases_on `n`
       THEN ZAP_TAC list_ss [SUBSET_DEF],
      POP_ASSUM(STRIP_ASSUME_TAC o Q.SPEC `SUC n`)
       THEN FULL_SIMP_TAC list_ss []]);

val PATH_LANGUAGE =
 store_thm
  ("PATH_LANGUAGE",
   ``!M w.
      MODEL M /\ (ELEM w 0) IN M.S0
      ==>
      (PATH M (ELEM w 0) w = 
        LANGUAGE (MODEL_TO_AUTOMATON M) (CONS(NONE, (PATH_ADD_IOTA w))))``,
   REPEAT GEN_TAC
    THEN Cases_on `w`
    THEN SIMP_TAC (list_ss++resq_SS) 
          [ELEM_def,HEAD_def,REST_def,RESTN_def,
           FINITE_PATH_LANGUAGE,INFINITE_PATH_LANGUAGE]);

(*****************************************************************************)
(* Not sure if the next four theorems are needed                             *)
(* (as they are subsumed by the following two).                              *)
(*****************************************************************************)

val UF_SEM_FINITE_TOP_FREE_F_ALWAYS =
 store_thm
  ("UF_SEM_FINITE_TOP_FREE_F_ALWAYS",
   ``TOP_FREE l 
     ==>
     (UF_SEM (FINITE l) (F_ALWAYS(F_WEAK_BOOL b)) = 
      !i. i < LENGTH l ==> B_SEM (EL i l) b)``,
   RW_TAC
    (list_ss++resq_SS) 
    [UF_SEM,B_SEM_def,UF_SEM_F_G,F_ALWAYS_def,FinitePathTheory.LENGTH_RESTN,LESSX_def,LS,
     ELEM_RESTN,ELEM_def,HEAD_def,REST_def,RESTN_FINITE,HD_RESTN,xnum_11,TOP_FREE_EL]
    THEN EQ_TAC
    THEN RW_TAC list_ss []
    THEN RES_TAC
    THEN `j < LENGTH l` by DECIDE_TAC
    THEN RES_TAC);

val UF_SEM_FINITE_F_ALWAYS =
 store_thm
  ("UF_SEM_FINITE_F_ALWAYS",
   ``UF_SEM (FINITE l) (F_ALWAYS(F_WEAK_BOOL b)) = 
      !i. i < LENGTH l ==> B_SEM (EL i l) b \/
          ?j. j < i /\ (EL j l = TOP) /\ ~(LENGTH l = j)``,
   RW_TAC
    (list_ss++resq_SS) 
    [UF_SEM,B_SEM_def,UF_SEM_F_G,F_ALWAYS_def,FinitePathTheory.LENGTH_RESTN,LESSX_def,LS,
     ELEM_RESTN,ELEM_def,HEAD_def,REST_def,RESTN_FINITE,HD_RESTN,xnum_11,TOP_FREE_EL]
    THEN EQ_TAC
    THEN RW_TAC list_ss []);

val UF_SEM_INFINITE_TOP_FREE_F_ALWAYS =
 store_thm
  ("UF_SEM_INFINITE_TOP_FREE_F_ALWAYS",
   ``(!i:num. ~(f i = TOP))
     ==>
     (UF_SEM (INFINITE f) (F_ALWAYS(F_WEAK_BOOL b)) = !i. B_SEM (f i) b)``,
   RW_TAC
    (list_ss++resq_SS) 
    [UF_SEM,B_SEM_def,UF_SEM_F_G,F_ALWAYS_def,LENGTH_RESTN,LESSX_def,LS,
     ELEM_RESTN,ELEM_def,HEAD_def,REST_def,RESTN_INFINITE,HD_RESTN,TOP_FREE_EL]);

val UF_SEM_INFINITE_F_ALWAYS =
 store_thm
  ("UF_SEM_INFINITE_F_ALWAYS",
   ``UF_SEM (INFINITE f) (F_ALWAYS(F_WEAK_BOOL b)) = 
      !i. B_SEM (f i) b \/ ?j. j < i /\ (f j = TOP)``,
   RW_TAC
    (list_ss++resq_SS) 
    [UF_SEM,B_SEM_def,UF_SEM_F_G,F_ALWAYS_def,LENGTH_RESTN,LESSX_def,LS,
     ELEM_RESTN,ELEM_def,HEAD_def,REST_def,RESTN_INFINITE,HD_RESTN]);

val UF_SEM_F_ALWAYS =
 store_thm
  ("UF_SEM_F_ALWAYS",
   ``UF_SEM w (F_ALWAYS(F_WEAK_BOOL b)) = 
      !i::LESS(LENGTH w). B_SEM (ELEM w i) b \/ ?j::LESS i. ELEM w j = TOP``,
   Cases_on `w`
    THEN RW_TAC (list_ss++resq_SS)
          [UF_SEM_FINITE_F_ALWAYS,UF_SEM_INFINITE_F_ALWAYS,LENGTH_def,ELEM_def,
           LENGTH_RESTN,LESSX_def,LS,ELEM_RESTN,ELEM_def,HEAD_def,REST_def,
           RESTN_INFINITE,RESTN_FINITE,HD_RESTN]
    THEN EQ_TAC
    THEN RW_TAC list_ss []
    THEN RES_TAC 
    THEN ZAP_TAC list_ss []
    THEN `~(LENGTH l = j)` by DECIDE_TAC
    THEN PROVE_TAC[]);

val UF_SEM_TOP_FREE_F_ALWAYS =
 store_thm
  ("UF_SEM_TOP_FREE_F_ALWAYS",
   ``PATH_TOP_FREE w 
     ==>
     (UF_SEM w (F_ALWAYS(F_WEAK_BOOL b)) = !i::LESS(LENGTH w). B_SEM (ELEM w i) b)``,
   Cases_on `w`
    THEN RW_TAC (list_ss++resq_SS)
          [UF_SEM_FINITE_F_ALWAYS,UF_SEM_INFINITE_F_ALWAYS,LENGTH_def,ELEM_def,
           LENGTH_RESTN,LESSX_def,LS,ELEM_RESTN,ELEM_def,HEAD_def,REST_def,
           RESTN_INFINITE,RESTN_FINITE,HD_RESTN,PATH_TOP_FREE_def]
    THEN EQ_TAC
    THEN RW_TAC list_ss []
    THEN RES_TAC 
    THEN FULL_SIMP_TAC list_ss[TOP_FREE_EL]
    THEN `j < LENGTH l` by DECIDE_TAC
    THEN RES_TAC);

val O_TRUE_def =
 Define `O_TRUE = O_BOOL B_TRUE`;

val O_SEM_O_TRUE =
 store_thm
  ("O_SEM_O_TRUE",
   ``O_SEM M O_TRUE s``,
   RW_TAC std_ss [O_TRUE_def,O_SEM_def,B_SEM_def]);

val O_EF_def =
 Define `O_EF f = O_EU(O_TRUE, f)`;

val PATH_ELEM_0 =
 store_thm
  ("PATH_ELEM_0",
   ``PATH M s p ==> (ELEM p 0 = s)``,
   Cases_on `p`
    THEN RW_TAC (std_ss++resq_SS) [PATH_CASES,ELEM_FINITE,ELEM_INFINITE,EL]);

val O_SEM_O_EF =
 store_thm
  ("O_SEM_O_EF",
   ``O_SEM M (O_EF f) s =      
      ?p :: PATH M s. ?i :: (LESS(LENGTH p)).  O_SEM M f (ELEM p i)``,
   RW_TAC (std_ss++resq_SS) [IN_DEF,O_EF_def,O_SEM_def,LESSX_def,O_SEM_O_TRUE]
    THEN EQ_TAC
    THEN ZAP_TAC std_ss [PATH_ELEM_0]);

val O_AG_def =
 Define `O_AG f = O_NOT(O_EF(O_NOT f))`;

val O_SEM_O_AG =
 store_thm
  ("O_SEM_O_AG",
   ``O_SEM M (O_AG f) s =      
      !p :: PATH M s. !i :: (LESS(LENGTH p)).  O_SEM M f (ELEM p i)``,
   RW_TAC (std_ss++resq_SS) [IN_DEF,O_SEM_O_EF,O_AG_def,O_SEM_def,LESSX_def]
    THEN EQ_TAC
    THEN ZAP_TAC std_ss [PATH_ELEM_0]);

(*****************************************************************************)
(* Lemmas about MAP_PATH                                                     *)
(*****************************************************************************)

val LENGTH_MAP_PATH =
 store_thm
  ("LENGTH_MAP_PATH",
   ``!g p. LENGTH(MAP_PATH g p) = LENGTH p``,
   Cases_on `p`
    THEN RW_TAC list_ss [MAP_PATH_def,LENGTH_def]);

val ELEM_MAP_PATH =
 store_thm
  ("LENGTH_MAP_PATH",
   ``n < LENGTH p ==> (ELEM (MAP_PATH g p) n = g(ELEM p n))``,
   Cases_on `p`
    THEN RW_TAC list_ss 
          [MAP_PATH_def,ELEM_INFINITE,ELEM_FINITE,LENGTH_def,LS,EL_MAP]);

val RESTN_MAP_PATH =
 store_thm
  ("RESTN_MAP_PATH",
   ``n < LENGTH p ==> (RESTN (MAP_PATH g p) n = MAP_PATH g (RESTN p n))``,
   Cases_on `p`
    THEN RW_TAC list_ss 
          [MAP_PATH_def,ELEM_INFINITE,ELEM_FINITE,LENGTH_def,LS,EL_MAP,
           RESTN_FINITE,RESTN_INFINITE]
    THEN Q.UNDISCH_TAC `n < LENGTH l`
    THEN Q.SPEC_TAC(`l`,`l`)
    THEN Induct_on `n`
    THEN RW_TAC list_ss [FinitePathTheory.RESTN_def,FinitePathTheory.REST_def]
    THEN `~(LENGTH l = 0)` by DECIDE_TAC
    THEN `~(l = [])` by PROVE_TAC[LENGTH_NIL]
    THEN RW_TAC list_ss [TL_MAP]
    THEN `LENGTH (TL l) = LENGTH l - 1` by RW_TAC arith_ss [LENGTH_TL]
    THEN `n < LENGTH(TL l)` by DECIDE_TAC
    THEN PROVE_TAC[]);

(*****************************************************************************)
(* M |=ltl G b! <=> M |=ctl AG b!                                            *)
(*****************************************************************************)
val SHARED_ALWAYS_STRONG_BOOL =
 store_thm
  ("SHARED_ALWAYS_STRONG_BOOL",
   ``UF_VALID M (F_G(F_STRONG_BOOL b)) = O_VALID M (O_AG(O_BOOL b))``,
   RW_TAC (arith_ss++resq_SS) 
    [IN_DEF,LESSX_def,UF_VALID_def,O_VALID_def,UF_SEM_F_G, 
     O_SEM_O_AG,COMPUTATION_def,UF_SEM,O_SEM_def,ELEM_RESTN,
     ELEM_MAP_PATH,LENGTH_MAP_PATH]
    THEN EQ_TAC
    THEN RW_TAC std_ss []
    THENL
     [`LENGTH (RESTN (MAP_PATH (\s. STATE (M.L s)) p) i) > 0 /\
       B_SEM (STATE (M.L (ELEM p i))) b \/
       ?j. j < i /\ (ELEM (MAP_PATH (\s. STATE (M.L s)) p) j = TOP) /\
           ~(LENGTH p = XNUM j)`
       by PROVE_TAC[]
       THEN `j < LENGTH p` by PROVE_TAC[LS_TRANS_X]
       THEN FULL_SIMP_TAC std_ss [ELEM_MAP_PATH,letter_distinct],
      RW_TAC list_ss [RESTN_MAP_PATH,LENGTH_MAP_PATH]
       THEN Cases_on `v`
       THEN RW_TAC list_ss [RESTN_FINITE,RESTN_INFINITE,LENGTH_def,GT]
       THEN IMP_RES_TAC LENGTH_RESTN_COR
       THEN FULL_SIMP_TAC list_ss [RESTN_FINITE,LENGTH_def,xnum_11,SUB,LS]]);

(*****************************************************************************)
(* M |=ltl G b <=> M |=ctl AG b                                              *)
(*****************************************************************************)
val SHARED_ALWAYS_WEAK_BOOL =
 store_thm
  ("SHARED_ALWAYS_WEAK_BOOL",
   ``UF_VALID M (F_G(F_WEAK_BOOL b)) = O_VALID M (O_AG(O_BOOL b))``,
   RW_TAC (arith_ss++resq_SS) 
    [IN_DEF,LESSX_def,UF_VALID_def,O_VALID_def,UF_SEM_F_G, 
     O_SEM_O_AG,COMPUTATION_def,UF_SEM,O_SEM_def,ELEM_RESTN,
     ELEM_MAP_PATH,LENGTH_MAP_PATH]
    THEN EQ_TAC
    THEN RW_TAC std_ss []
    THEN `((LENGTH (RESTN (MAP_PATH (\s. STATE (M.L s)) p) i) =
            XNUM 0) \/ B_SEM (STATE (M.L (ELEM p i))) b) \/
            ?j. j < i /\ (ELEM (MAP_PATH (\s. STATE (M.L s)) p) j = TOP) /\
                ~(LENGTH p = XNUM j)`
          by PROVE_TAC[]
     THEN TRY(`j < LENGTH p` by PROVE_TAC[LS_TRANS_X])
     THEN FULL_SIMP_TAC std_ss [ELEM_MAP_PATH,letter_distinct]
     THEN `i < LENGTH(MAP_PATH (\s. STATE (M.L s)) p)` by PROVE_TAC[LENGTH_MAP_PATH]
     THEN FULL_SIMP_TAC list_ss 
           [RESTN_MAP_PATH,LENGTH_MAP_PATH,PATH_FINITE_LENGTH_RESTN_0_COR]
     THEN `LENGTH(MAP_PATH (\s. STATE (M.L s)) p) = LENGTH(FINITE l)` by PROVE_TAC[]
     THEN FULL_SIMP_TAC list_ss [LENGTH_def,LENGTH_MAP_PATH,LS]);

val O_OR_def =
 Define
  `O_OR(f1,f2) = O_NOT(O_AND(O_NOT f1, O_NOT f2))`;

val O_SEM_O_OR =
 store_thm
  ("O_SEM_O_OR",
   ``O_SEM M (O_OR (f1,f2)) s = O_SEM M f1 s \/ O_SEM M f2 s``,
   RW_TAC list_ss [O_SEM_def,O_OR_def]);

val O_IMP_def =
 Define
  `O_IMP(f1,f2) = O_OR(O_NOT f1, f2)`;

val O_SEM_O_IMP =
 store_thm
  ("O_SEM_O_IMP",
   ``O_SEM M (O_IMP (f1,f2)) s = O_SEM M f1 s ==> O_SEM M f2 s``,
   RW_TAC list_ss [O_SEM_def,O_SEM_O_OR,O_IMP_def]
    THEN PROVE_TAC[]);

val O_IFF_def =
 Define
  `O_IFF(f1,f2) = O_AND(O_IMP(f1, f2), O_IMP(f2, f1))`;

val O_SEM_O_IFF =
 store_thm
  ("O_SEM_O_IFF",
   ``O_SEM M (O_IFF (f1,f2)) s = (O_SEM M f1 s = O_SEM M f2 s)``,
   RW_TAC list_ss [O_SEM_def,O_SEM_O_IMP,O_IFF_def]
    THEN PROVE_TAC[]);

(*****************************************************************************)
(* M |=ctl AG(b1 <-> b2)  ==>  M |=ctl AG b1 <-> AG b2                       *)
(*****************************************************************************)
val O_SEM_AG_B_IFF_IMP =
 store_thm
  ("O_SEM_AG_B_IFF_IMP",
   ``O_VALID M (O_AG(O_BOOL(B_IFF(b1, b2)))) ==>
      O_VALID M (O_IFF(O_AG(O_BOOL b1), O_AG(O_BOOL b2)))``,
   RW_TAC (list_ss++resq_SS) 
    [O_VALID_def,B_OR_def,B_IFF_def,B_IMP_def,B_SEM_def,B_SEM_def,
     O_SEM_O_AG,O_SEM_def,O_SEM_O_IFF]
    THEN PROVE_TAC[]);

(*
Ultimately want:

 M0 || A |= G b ==> !pi. pi in COMPUTATION M0 ==> pi || A |= G b

try to prove

 M0 || A |= f ==> !pi. pi in COMPUTATION M0 ==> pi || A |= f
*)

val UF_INFINITE_VALID_def =
 Define
  `UF_INFINITE_VALID M f =
   !pi. COMPUTATION M (INFINITE pi) 
        ==> 
        UF_SEM (MAP_PATH (\s. STATE (M.L s)) (INFINITE pi)) f`;

val UF_FINITE_VALID_def =
 Define
  `UF_FINITE_VALID M f =
   !pi. COMPUTATION M (FINITE pi) 
        ==> 
        UF_SEM (MAP_PATH (\s. STATE (M.L s)) (FINITE pi)) f`;


(*****************************************************************************)
(* mike,                                                                     *)
(*                                                                           *)
(* >If M (I assume I meant "M0") is the open model, would you expect:        *)
(* >                                                                         *)
(* > (M0 || A |=ltl f) and pi a computation of M0 implies (pi || A |=ltl f)  *)
(* >                                                                         *)
(* >to hold.                                                                 *)
(*                                                                           *)
(* yes.                                                                      *)
(*                                                                           *)
(* cindy.                                                                    *)
(*****************************************************************************)

val FST_LEMMA =
 prove
  (``!Q x. (\(s,t). Q s) x = Q(FST x)``,
   Cases_on `x`
    THEN RW_TAC std_ss []);

(* Probably won't need this *)
val OPEN_MODEL_PROD_INFINITE =
 store_thm
  ("OPEN_MODEL_PROD_INFINITE",
   ``(?p. ~(p IN P)) /\ AUTOMATON A /\ UF_VALID (MODEL_AUTOMATON_PROD (OPEN_MODEL P) A) f
     ==>
     !pi. COMPUTATION (OPEN_MODEL P) (INFINITE pi)
          ==>
          UF_INFINITE_VALID 
           (MODEL_AUTOMATON_PROD (COMPUTATION_TO_MODEL(INFINITE pi)) A)
           f``,
    RW_TAC (srw_ss()++resq_SS)
     [AUTOMATON_def,UF_VALID_def,UF_INFINITE_VALID_def,MODEL_AUTOMATON_PROD_def,
      OPEN_MODEL_def,COMPUTATION_def,IN_COMPUTATION,COMPUTATION_TO_MODEL_CASES,PATH_CASES]
     THEN FULL_SIMP_TAC list_ss 
           [FST_LEMMA,PROVE[]``(!v. (?s. P s v) ==> Q v) = !v s. P s v ==> Q v``,
            MAP_PATH_def]
     THEN `(!n. (?s t. (pi' n = (s,t)) /\ t IN A.Q)) /\
           (!n. ?s t t'.
                 ((pi' n = (s,t)) /\ (pi' (SUC n) = (s + 1,t'))) /\
                 (t,pi s,t') IN A.Delta)`
          by PROVE_TAC[]
     THEN POP_ASSUM(fn th => STRIP_ASSUME_TAC(CONV_RULE SKOLEM_CONV th))
     THEN POP_ASSUM(fn th => STRIP_ASSUME_TAC(CONV_RULE SKOLEM_CONV th))
     THEN POP_ASSUM(fn th => STRIP_ASSUME_TAC(CONV_RULE SKOLEM_CONV th))
     THEN ASSUM_LIST(fn thl => STRIP_ASSUME_TAC(CONV_RULE SKOLEM_CONV (el 2 thl)))
     THEN POP_ASSUM(fn th => STRIP_ASSUME_TAC(CONV_RULE SKOLEM_CONV th))
     THEN ASSUM_LIST
           (fn thl => ASSUME_TAC
                       (SPECL 
                         [``INFINITE(\n. (pi(FST(pi' n)), t''' n)):(('a -> bool) # 'b) path``,
                          ``(pi:num -> 'a -> bool 0,t):('a -> bool) # 'b``] 
                         (el 9 thl)))
     THEN `PATH
            <|S := {(s,t) | (s SUBSET P \/ (s = SINK P)) /\ t IN A.Q};
              S0 := {(s,t) | s SUBSET P /\ t IN A.Q0};
              R :=
                {((s,t),s',t') |
                 (s SUBSET P /\ (s' SUBSET P \/ (s' = SINK P))) /\
                 (t,(if s = SINK P then {} else s),t') IN A.Delta}; P := P;
              L := (\(s,t). (if s = SINK P then {} else s))|> (pi 0,t)
            (INFINITE (\n. (pi:num -> 'a -> bool (FST (pi':num -> num # 'b n)),t''' n)))
            ==>
           UF_SEM
            (MAP_PATH (\s'. STATE (if FST s' = SINK P then {} else FST s'))
               (INFINITE (\n. (pi (FST (pi' n)),t''' n)))) f`
          by PROVE_TAC[]
     THEN POP_ASSUM(ASSUME_TAC o SIMP_RULE (srw_ss()++resq_SS) [PATH_CASES,MAP_PATH_def])
     THEN POP_ASSUM(fn th => ASSUM_LIST(fn thl => ASSUME_TAC(SIMP_RULE std_ss thl th)))
     THEN ASM_REWRITE_TAC []
     THEN ASSUM_LIST(fn thl => POP_ASSUM(fn th => ASSUME_TAC(SIMP_RULE list_ss [SIMP_RULE list_ss [el 8 thl] (Q.SPEC `0` (el 3 thl))] th)))
     THEN ASSUM_LIST(fn thl => POP_ASSUM(fn th => ASSUME_TAC(SIMP_RULE list_ss [SIMP_RULE list_ss [el 3 thl] (Q.SPEC `n` (el 4 thl))] th)))
     THEN ASSUM_LIST(fn thl => REWRITE_TAC[SIMP_RULE list_ss [el 3 thl] (Q.SPEC `n` (el 4 thl))])
     THEN `!n. (pi:num -> 'a -> bool) n SUBSET P` by METIS_TAC[]
     THEN `!n. ~((pi:num -> 'a -> bool) n = SINK P)` by PROVE_TAC[SUBSET_SINK]
     THEN POP_ASSUM(fn th => FULL_SIMP_TAC list_ss [th]));

(*****************************************************************************)
(*     |- (COMPUTATION_TO_MODEL w || A).L =                                  *)
(*        (\(s,t). {p | s < LENGTH w /\ p IN ELEM w s}) : thm                *)
(*****************************************************************************)
val LEMMA4 =
 SIMP_CONV (srw_ss()++resq_SS) 
  [MODEL_AUTOMATON_PROD_def,OPEN_MODEL_def,IN_COMPUTATION,COMPUTATION_TO_MODEL_def,
   PATH_def,IN_LESS_LENGTH_SUB1,ELEM_FINITE,SUBSET_SINK,
   DECIDE ``~A \/ (~B \/ ~C /\ ~D) \/ E = A ==> B ==> (C \/ D) ==> E``,
   LEMMA1]
  ``(COMPUTATION_TO_MODEL w || A).L``;

val FST_SND_LEMMA =
 prove
  (``!p x y. (p = (x,y)) = (x = FST p) /\ (y = SND p)``,
   Cases_on `p`
    THEN ZAP_TAC std_ss []);

val SET_COND =
 store_thm
  ("SET_COND",
   ``{p | P /\ (p IN Q)} = if ~P then {} else Q``,
   RW_TAC (srw_ss()++resq_SS) [EXTENSION]
    THEN RW_TAC std_ss[]);

val SINGLETON_SUBSET_IN =
 store_thm
  ("SINGLETON_SUBSET_IN",
   ``(\x. x=a) SUBSET X = a IN X``,
   RW_TAC std_ss [SUBSET_DEF,IN_DEF]);


val _ = export_theory();
