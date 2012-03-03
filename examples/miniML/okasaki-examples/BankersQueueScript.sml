
open HolKernel Parse boolLib bossLib; val _ = new_theory "BankersQueue";

open listTheory arithmeticTheory;

(* implementation *)

val _ = Hol_datatype `queue = QUEUE of num => 'a list => num => 'a list`;

val empty_def = Define `empty = QUEUE 0 [] 0 []`;

val is_empty_def = Define `
  is_empty (QUEUE lenf _ _ _) = (lenf = 0)`;

val checkf_def = Define `
  checkf (QUEUE lenf f lenr r) =
    if lenr <= lenf then QUEUE lenf f lenr r
                    else QUEUE (lenf + lenr) (f ++ REVERSE r) 0 []`;

val snoc_def = Define `
  snoc (QUEUE lenf f lenr r) x = checkf (QUEUE lenf f (lenr+1) (x::r))`;

val head_def = Define `
  head (QUEUE lenf (x::xs) lenr r) = x`;

val tail_def = Define `
  tail (QUEUE lenf (x::xs) lenr r) = checkf (QUEUE (lenf-1) xs lenr r)`;

(* verification proof *)

val queue_inv_def = Define `
  queue_inv q (QUEUE lenf f lenr r) =
    (q = f ++ REVERSE r) /\ (lenr = LENGTH r) /\ (lenf = LENGTH f) /\ lenr <= lenf`;

val empty_thm = prove(
  ``!xs. queue_inv xs empty = (xs = [])``,
  EVAL_TAC THEN SIMP_TAC std_ss []);

val is_empty_thm = prove(
  ``!q xs. queue_inv xs q ==> (is_empty q = (xs = []))``,
  Cases THEN Cases_on `l` THEN EVAL_TAC THEN SRW_TAC [] []
  THEN FULL_SIMP_TAC std_ss [REVERSE_DEF,LENGTH_NIL]);

val snoc_thm = prove(
  ``!q xs x. queue_inv xs q ==> queue_inv (xs ++ [x]) (snoc q x)``,
  Cases THEN Cases_on `l` THEN EVAL_TAC
  THEN SRW_TAC [] [ADD1,queue_inv_def] THEN DECIDE_TAC);

val head_thm = prove(
  ``!q x xs. queue_inv (x::xs) q ==> (head q = x)``,
  Cases THEN Cases_on `l` THEN EVAL_TAC THEN SRW_TAC [] []
  THEN FULL_SIMP_TAC (srw_ss()) [REVERSE_DEF,LENGTH_NIL]);

val tail_thm = prove(
  ``!q x xs. queue_inv (x::xs) q ==> queue_inv xs (tail q)``,
  Cases THEN Cases_on `l` THEN EVAL_TAC THEN SRW_TAC [] []
  THEN TRY (Cases_on `t`) THEN EVAL_TAC
  THEN FULL_SIMP_TAC (srw_ss()) [REVERSE_DEF,LENGTH_NIL] THEN DECIDE_TAC);

val _ = export_theory();
