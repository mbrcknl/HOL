open HolKernel Parse bossLib boolLib pairTheory pred_setTheory relationTheory set_relationTheory

open buechiATheory

val _ = new_theory "gbaSimpl"

(*
  Reducing the amount of transitions
*)

val trans_implies_def = Define`
  trans_implies accTrans q (a1,q1) (a2,q2)
      = (q1 = q2) ∧ a2 ⊆ a1
      ∧ !t. t ∈ accTrans ==> ((q,a2,q2) ∈ t ==> (q,a1,q1) ∈ t)`;

val TRANS_IMPLIES_PO = store_thm
  ("TRANS_IMPLIES_PO",
   ``!aT q d.
       partial_order (rrestrict (rel_to_reln (trans_implies aT q)) d) d``,
   fs[partial_order_def, rrestrict_def, rel_to_reln_def] >> rpt strip_tac
    >- (fs[domain_def,SUBSET_DEF] >> rpt strip_tac)
    >- (fs[range_def, SUBSET_DEF] >> rpt strip_tac)
    >- (fs[transitive_def,SUBSET_DEF] >> rpt strip_tac
        >> Cases_on `x` >> Cases_on `y` >> Cases_on `z` >> fs[trans_implies_def]
        >> metis_tac[SUBSET_TRANS])
    >- (fs[reflexive_def,SUBSET_DEF] >> rpt strip_tac >> Cases_on `x`
        >> fs[trans_implies_def])
    >- (fs[antisym_def,SUBSET_DEF] >> rpt strip_tac >> Cases_on `x`
        >> Cases_on `y` >> fs[trans_implies_def]
        >> metis_tac[SUBSET_ANTISYM]
       )
  );

val TRANS_IMPLIES_FINITE = store_thm
  ("TRANS_IMPLIES_FINITE",
  ``!aT q d. FINITE d ==>
     finite_prefixes (rrestrict (rel_to_reln (trans_implies aT q)) d) d``,
  fs[finite_prefixes_def, rrestrict_def, rel_to_reln_def] >> rpt strip_tac
  >> `FINITE {e' | e' ∈ (\x. trans_implies aT q x e) ∧ e' ∈ d }`
      suffices_by fs[IN_DEF]
  >> metis_tac[INTER_DEF,INTER_FINITE,INTER_COMM]
  );

val TRANS_IMPLIES_MIN = store_thm
  ("TRANS_IMPLIES_MIN",
  ``!aut q1 q2 w i a. FINITE aut.states ∧ FINITE aut.alphabet ∧ isValidGBA aut
          ∧ q1 ∈ aut.states ∧ (a,q2) ∈ aut.trans q1
          ==> let rel = rrestrict
                            (rel_to_reln (trans_implies aut.accTrans q1))
                            (aut.trans q1)
              in ?t. t ∈ minimal_elements (aut.trans q1) rel
                  ∧ (t,(a, q2)) ∈ rel``,
  rpt strip_tac >> simp[]
  >> qabbrev_tac `rel = rrestrict
                            (rel_to_reln (trans_implies aut.accTrans q1))
                            (aut.trans q1)`
  >> Cases_on `(a, q2) ∈ minimal_elements (aut.trans q1) rel`
   >- (qexists_tac `(a, q2)` >> fs[] >> qunabbrev_tac `rel`
       >> fs[rrestrict_def,rel_to_reln_def,trans_implies_def])
   >- (HO_MATCH_MP_TAC finite_prefix_po_has_minimal_path
       >> qexists_tac `aut.trans q1`
       >> `FINITE (aut.trans q1)` by (imp_res_tac GBA_FINITE_LEMM >> fs[])
       >> rpt strip_tac >> fs[] >> qunabbrev_tac `rel`
         >- metis_tac[TRANS_IMPLIES_PO]
         >- metis_tac[TRANS_IMPLIES_FINITE]
      )
  );

val removeImplied_def = Define`
  removeImplied accTrans trans q =
    (trans q) DIFF {t | ?t'. ~(t = t') ∧ t' ∈ (trans q)
                             ∧ trans_implies accTrans q t' t}`;

val reduceTransSimpl_def = Define`
  reduceTransSimpl (GBA s i t aT a) =
   GBA s i (removeImplied aT t) aT a`;

val REDUCE_IS_VALID = store_thm
 ("REDUCE_IS_VALID",
  ``!aut. isValidGBA aut ==> isValidGBA (reduceTransSimpl aut)``,
  fs[isValidGBA_def] >> rpt strip_tac >> Cases_on `aut`
  >> fs[reduceTransSimpl_def] >> fs[removeImplied_def] >> metis_tac[]
 );

val REDUCE_IS_CORRECT = store_thm
  ("REDUCE_IS_CORRECT",
   ``!aut. FINITE aut.states ∧ FINITE aut.alphabet ∧ isValidGBA aut
             ==> (GBA_lang aut = GBA_lang (reduceTransSimpl aut))``,
   fs[SET_EQ_SUBSET,SUBSET_DEF] >> rpt strip_tac
   >> fs[GBA_lang_def, reduceTransSimpl_def]
    >- (qexists_tac `r`
        >> `word_range x ⊆ (reduceTransSimpl aut).alphabet`
             by (Cases_on `aut` >> fs[reduceTransSimpl_def])
        >> fs[isGBARunFor_def] >> Cases_on `r`
        >> rename [`GBA_RUN f`]
        >> `!i. f i ∈ aut.states` by metis_tac[GBA_RUN_LEMM]
        >> rpt strip_tac
         >- (fs[isValidGBARunFor_def] >> rpt strip_tac
             >> Cases_on `aut` >> fs[reduceTransSimpl_def]
             >> rename [`GBA states init trans aT alph`]
             >> imp_res_tac TRANS_IMPLIES_MIN >> fs[]
             >> `∃a. (a,f (i + 1)) ∈ trans (f i) ∧ at x i ∈ a` by fs[]
             >> first_x_assum (qspec_then `f (i+1)` mp_tac) >> rpt strip_tac
             >> first_x_assum (qspec_then `f i` mp_tac) >> rpt strip_tac
             >> first_x_assum (qspec_then `a` mp_tac) >> rpt strip_tac
             >> POP_ASSUM mp_tac >> simp[] >> rpt strip_tac >> Cases_on `t`
             >> rename[`(a_new,_) ∈ minimal_elements (trans (f i)) _`]
             >> qexists_tac `a_new` >> simp[removeImplied_def]
             >> fs[minimal_elements_def,rrestrict_def,rel_to_reln_def]
             >> fs[trans_implies_def] >> rw[] >> metis_tac[SUBSET_DEF]
             )
         >- (`!T. T ∈ (reduceTransSimpl aut).accTrans
              ==> (!i. ?a j. i <= j ∧ (f j, a, f (j+1)) ∈ T
                ∧ (a, f (j+1)) ∈ (reduceTransSimpl aut).trans (f j)
                ∧ at x j ∈ a)` suffices_by metis_tac[GBA_ACC_LEMM]
             >> `!T. T ∈ aut.accTrans
                 ==> (!i. ?a j. i <= j ∧ (f j, a, f (j+1)) ∈ T
                    ∧ (a, f (j+1)) ∈ aut.trans (f j)
                    ∧ at x j ∈ a)` by metis_tac[GBA_ACC_LEMM]
             >> rpt strip_tac >> first_x_assum (qspec_then `T'` mp_tac)
             >> rpt strip_tac >> Cases_on `aut` >> fs[reduceTransSimpl_def]
             >> POP_ASSUM mp_tac >> simp[] >> rpt strip_tac
             >> first_x_assum (qspec_then `i` mp_tac) >> rpt strip_tac
             >> rename [`GBA states init trans aT alph`]
             >> imp_res_tac TRANS_IMPLIES_MIN >> fs[]
             >> first_x_assum (qspec_then `f (j+1)` mp_tac) >> rpt strip_tac
             >> first_x_assum (qspec_then `f j` mp_tac) >> rpt strip_tac
             >> first_x_assum (qspec_then `a` mp_tac) >> rpt strip_tac
             >> POP_ASSUM mp_tac >> simp[] >> rpt strip_tac
             >> Cases_on `t` >> rename[`(a_new,r) ∈ minimal_elements _ _`]
             >> qexists_tac `a_new` >> qexists_tac `j` >> fs[removeImplied_def]
             >> rpt strip_tac >> fs[minimal_elements_def,rrestrict_def]
             >> fs[rel_to_reln_def,trans_implies_def]
              >- (first_x_assum (qspec_then `(a,f(j+1))` mp_tac) >> fs[]
                  >> rpt strip_tac >> metis_tac[])
              >- metis_tac[]
              >- metis_tac[]
              >- metis_tac[SUBSET_DEF]
            )
       )
    >- (qexists_tac `r`
        >> `word_range x ⊆ aut.alphabet`
           by (Cases_on `aut` >> fs[reduceTransSimpl_def])
        >> fs[isGBARunFor_def] >> rpt strip_tac
         >- (Cases_on `r` >> simp[isValidGBARunFor_def] >> rpt strip_tac
             >> Cases_on `aut` >> fs[reduceTransSimpl_def,isValidGBARunFor_def]
             >> first_x_assum (qspec_then `i` mp_tac) >> rpt strip_tac
             >> fs[removeImplied_def] >> metis_tac[]
            )
         >- (Cases_on `r`
             >> `!T. T ∈ (reduceTransSimpl aut).accTrans
              ==> (!i. ?a j. i <= j ∧ (f j, a, f (j+1)) ∈ T
                     ∧ (a, f (j+1)) ∈ (reduceTransSimpl aut).trans (f j)
                     ∧ at x j ∈ a)` by metis_tac[GBA_ACC_LEMM]
             >> `!T. T ∈ aut.accTrans
                  ==> (!i. ?a j. i <= j ∧ (f j, a, f (j+1)) ∈ T
                        ∧ (a, f (j+1)) ∈ aut.trans (f j)
                        ∧ at x j ∈ a)` suffices_by metis_tac[GBA_ACC_LEMM]
             >> rpt strip_tac >> first_x_assum (qspec_then `T'` mp_tac)
             >> rpt strip_tac >> Cases_on `aut` >> fs[reduceTransSimpl_def]
             >> POP_ASSUM mp_tac >> simp[] >> rpt strip_tac
             >> first_x_assum (qspec_then `i` mp_tac) >> rpt strip_tac
             >> fs[removeImplied_def] >> metis_tac[]
            )
       )
  );

(*
  Remove unreachable states
*)

val removeStatesSimpl_def = Define`
  removeStatesSimpl (GBA s i t aT alph) =
  GBA (s ∩ reachableFromSetGBA (GBA s i t aT alph) i) i t aT alph`;

val REDUCE_STATE_VALID = store_thm
  ("REDUCE_STATE_VALID",
   ``!aut. isValidGBA aut ==> isValidGBA (removeStatesSimpl aut)``,
   fs[isValidGBA_def] >> rpt strip_tac >> Cases_on `aut`
   >> fs[removeStatesSimpl_def,reachableFromSetGBA_def]
   >> fs[SUBSET_DEF] >> rpt strip_tac
    >- (simp[reachableFromGBA_def] >> metis_tac[RTC_REFL])
    >- metis_tac[]
    >- (qexists_tac `x` >> fs[reachableFromGBA_def]
        >> `stepGBA (GBA f f0 f1 f2 f3) s d` suffices_by metis_tac[RTC_CASES2]
        >> simp[stepGBA_def] >> metis_tac[])
    >- metis_tac[]
  );

val REDUCE_STATE_CORRECT = store_thm
  ("REDUCE_STATE_CORRECT",
   ``!aut. isValidGBA aut ==>
              (GBA_lang aut = GBA_lang (removeStatesSimpl aut))``,
   fs[SET_EQ_SUBSET,SUBSET_DEF] >> rpt strip_tac
   >> fs[GBA_lang_def, removeStatesSimpl_def]
    >- (`word_range x ⊆ (removeStatesSimpl aut).alphabet`
           by (Cases_on `aut` >> fs[removeStatesSimpl_def])
        >> qexists_tac `r` >> fs[isGBARunFor_def] >> rpt strip_tac
       >- (Cases_on `r` >> fs[isValidGBARunFor_def] >> rpt strip_tac
           >> Cases_on `aut` >> fs[removeStatesSimpl_def])
       >- (Cases_on `r`
           >> `!T. T ∈ (removeStatesSimpl aut).accTrans
             ==> (!i. ?a j. i <= j ∧ (f j, a, f (j+1)) ∈ T
                  ∧ (a, f (j+1)) ∈ (removeStatesSimpl aut).trans (f j)
                  ∧ at x j ∈ a)` suffices_by metis_tac[GBA_ACC_LEMM]
           >> `!T. T ∈ aut.accTrans
             ==> (!i. ?a j. i <= j ∧ (f j, a, f (j+1)) ∈ T
                    ∧ (a, f (j+1)) ∈ aut.trans (f j)
                    ∧ at x j ∈ a)` by metis_tac[GBA_ACC_LEMM]
           >> rpt strip_tac >> fs[] >> first_x_assum (qspec_then `T'` mp_tac)
           >> Cases_on `aut` >> fs[removeStatesSimpl_def]
          )
       )
    >- (`word_range x ⊆ aut.alphabet`
           by (Cases_on `aut` >> fs[removeStatesSimpl_def])
        >> qexists_tac `r` >> fs[isGBARunFor_def] >> rpt strip_tac
         >- (Cases_on `r` >> fs[isValidGBARunFor_def] >> rpt strip_tac
             >> Cases_on `aut` >> fs[removeStatesSimpl_def])
         >- (Cases_on `r`
             >> `!T. T ∈ (removeStatesSimpl aut).accTrans
                  ==> (!i. ?a j. i <= j ∧ (f j, a, f (j+1)) ∈ T
                        ∧ (a, f (j+1)) ∈ (removeStatesSimpl aut).trans (f j)
                        ∧ at x j ∈ a)` by metis_tac[GBA_ACC_LEMM]
             >> `!T. T ∈ aut.accTrans
                  ==> (!i. ?a j. i <= j ∧ (f j, a, f (j+1)) ∈ T
                         ∧ (a, f (j+1)) ∈ aut.trans (f j)
                         ∧ at x j ∈ a)` suffices_by metis_tac[GBA_ACC_LEMM]
             >> rpt strip_tac >> fs[] >> first_x_assum (qspec_then `T'` mp_tac)
             >> Cases_on `aut` >> fs[removeStatesSimpl_def]
            )
       )
  );

(*
  Merge equivalent states
*)

val replaceState_def = Define`
  replaceState x_old x_new s =
    if s = x_old then x_new else s`;

val replaceStateSet_def = Define`
  replaceStateSet x_old x_new set =
    if x_old ∈ set
    then (set DIFF {x_old}) ∪ {x_new}
    else set`;

val replaceAccTrans_def = Define`
  replaceAccTrans x_old x_new aT =
    IMAGE (\s. {(replaceState x_old x_new q1, a, replaceState x_old x_new q2) |
                (q1,a,q2) ∈ s}) aT`;

val REPL_AT_LEMM = store_thm
  ("REPL_AT_LEMM",
   ``!aT t x y. t ∈ (replaceAccTrans x y aT)
  ==> ?t2. t2 ∈ aT
  ∧ !q1 a q2. (q1,a,q2) ∈ t2
                 ==> (replaceState x y q1, a, replaceState x y q2) ∈ t``,
   rpt strip_tac >> fs[replaceAccTrans_def] >> qexists_tac `s`
   >> rpt strip_tac >> rw[EQ_IMP_THM] >> metis_tac[]
  );

val equivalentStates_def = Define`
  equivalentStates aT trans q1 q2 =
     (trans q1 = trans q2)
   ∧ !a q3 T. ((a,q3) ∈ trans q1) ∧ T ∈ aT
                   ==> ((q1,a,q3) ∈ T = (q2,a,q3) ∈ T)`;

val mergeState_def = Define`
  mergeState x (GBA s i t aT alph) =
      if ?q. q ∈ s ∧ ~(q = x) ∧ equivalentStates aT t q x
      then let s_new = $@ (\p. p ∈ s ∧ ~(p = x)
                            ∧ equivalentStates aT t p x)
           in GBA
              (s DIFF {x})
              (replaceStateSet x s_new i)
              (\m. {(a,replaceState x s_new n) | (a,n) ∈ t m})
              (replaceAccTrans x s_new aT)
              alph
      else (GBA s i t aT alph)`;


(* val MERGE_IS_CORRECT = store_thm *)
(*   ("MERGE_IS_CORRECT", *)
(*    ``!aut q. isValidGBA aut ∧ q ∈ aut.states *)
(*            ==> (GBA_lang aut = GBA_lang (mergeState q aut))``, *)
(*    fs[SET_EQ_SUBSET,SUBSET_DEF] >> rpt strip_tac *)
(*    >> fs[GBA_lang_def,mergeState_def] *)
(*      >- (`word_range x ⊆ (mergeState q aut).alphabet` *)
(*            by (Cases_on `aut` >> fs[mergeState_def] *)
(*                >> Cases_on `∃q'. q' ∈ f ∧ q' ≠ q ∧ equivalentStates f2 f1 q' q` *)
(*                >> simp[]) *)
(*          >> Cases_on `∃q'. q' ∈ aut.states ∧ q' ≠ q *)
(*                          ∧ equivalentStates aut.accTrans aut.trans q' q` *)
(*          >- (Cases_on `aut` >> rename[`GBA states init t aT alph`] *)
(*              >> fs[] *)
(*              >> qabbrev_tac `s_new = *)
(*                    @p. p ∈ states ∧ ~(p = q) ∧ equivalentStates aT t p q` *)
(*              >> `s_new ∈ states ∧ ~(s_new = q) ∧ equivalentStates aT t s_new q` *)
(*                 by (qunabbrev_tac `s_new` >> metis_tac[]) *)
(*              >> Cases_on `r` *)
(*              >> qexists_tac `GBA_RUN (\i. replaceState q s_new (f i))` *)
(*              >> fs[isGBARunFor_def,mergeState_def] >> rpt strip_tac *)
(*              >> qabbrev_tac `newGBA = *)
(*                 GBA (states DIFF {q}) (replaceStateSet q s_new init) *)
(*                     (λm. {(a,replaceState q s_new n) | (a,n) ∈ t m}) *)
(*                     (replaceAccTrans q s_new aT) alph` *)
(*               >- (`isValidGBARunFor newGBA *)
(*                     (GBA_RUN (λi. replaceState q s_new (f i))) x` *)
(*                     suffices_by metis_tac[] *)
(*                   >> simp[isValidGBARunFor_def] >> rpt strip_tac *)
(*                    >- (qunabbrev_tac `newGBA` *)
(*                        >> simp[replaceState_def,replaceStateSet_def] *)
(*                        >> Cases_on `f 0 = q` >> simp[] *)
(*                         >- fs[isValidGBARunFor_def] *)
(*                         >- (Cases_on `q ∈ init` >> fs[isValidGBARunFor_def]) *)
(*                       ) *)
(*                    >- (fs[isValidGBARunFor_def] *)
(*                        >> `∃a. (a,f (i + 1)) ∈ t (f i) ∧ at x i ∈ a` *)
(*                            by metis_tac[] *)
(*                        >> qexists_tac `a` >> simp[replaceState_def] *)
(*                        >> qunabbrev_tac `newGBA` >> simp[replaceState_def] *)
(*                        >> qexists_tac `f (i + 1)` >> simp[] *)
(*                        >> Cases_on `f i = q` >> fs[equivalentStates_def] *)
(*                       ) *)
(*                  ) *)
(*               >- (qabbrev_tac `newRun = λi. replaceState q s_new (f i)` *)
(*                   >> `isAcceptingGBARunFor newGBA (GBA_RUN newRun) x` *)
(*                     suffices_by metis_tac[] *)
(*                   >> `!T. T ∈ newGBA.accTrans *)
(*                      ==> (!i. ?a j. i <= j ∧ (newRun j, a, newRun (j+1)) ∈ T *)
(*                           ∧ (a, newRun (j+1)) ∈ newGBA.trans (newRun j) *)
(*                           ∧ at x j ∈ a)` suffices_by metis_tac[GBA_ACC_LEMM] *)
(*                   >> qabbrev_tac `aut = GBA states init t aT alph` *)
(*                   >> `!T. T ∈ aut.accTrans *)
(*                      ==> (!i. ?a j. i <= j ∧ (f j, a, f (j+1)) ∈ T *)
(*                           ∧ (a, f (j+1)) ∈ aut.trans (f j) *)
(*                           ∧ at x j ∈ a)` by metis_tac[GBA_ACC_LEMM] *)
(*                   >> rpt strip_tac *)
(*                   >> `?t2. t2 ∈ aut.accTrans *)
(*                      ∧ !q1 a q2. (q1,a,q2) ∈ t2 ==> *)
(*                      (replaceState q s_new q1, a, replaceState q s_new q2) ∈ T'` *)
(*                      by (qunabbrev_tac `newGBA` >> fs[] *)
(*                          >> imp_res_tac REPL_AT_LEMM >> qunabbrev_tac `aut` *)
(*                          >> simp[] >> metis_tac[]) *)
(*                   >> first_x_assum (qspec_then `t2` mp_tac) *)
(*                   >> simp[] >> rpt strip_tac *)
(*                   >> first_x_assum (qspec_then `i` mp_tac) >> rpt strip_tac *)
(*                   >> qexists_tac `a` >> qexists_tac `j` >> fs[] *)
(*                   >> qunabbrev_tac `newRun` >> simp[replaceState_def] *)
(*                   >> Cases_on `f j = q` >> Cases_on `f (j + 1) = q` *)
(*                   >> qunabbrev_tac `aut` >> fs[equivalentStates_def] *)
(*                   >> rpt strip_tac >> qunabbrev_tac `newGBA` >> simp[] *)
(*                   >> metis_tac[replaceState_def] *)
(*                  ) *)
(*             ) *)
(*          >- (qexists_tac `r` >> simp[isGBARunFor_def] >> strip_tac *)
(*              >> Cases_on `aut` >> simp[mergeState_def] *)
(*               >- (qabbrev_tac `aut = GBA f f0 f1 f2 f3` *)
(*                   >> `isValidGBARunFor aut r x` suffices_by ( *)
(*                        qunabbrev_tac `aut` >> fs[] >> metis_tac[] *)
(*                    ) *)
(*                   >> fs[isGBARunFor_def] *)
(*                  ) *)
(*               >- (qabbrev_tac `aut = GBA f f0 f1 f2 f3` *)
(*                   >> `isAcceptingGBARunFor aut r x` suffices_by ( *)
(*                        qunabbrev_tac `aut` >> fs[] >> metis_tac[] *)
(*                    ) *)
(*                   >> fs[isGBARunFor_def] *)
(*                  ) *)
(*             ) *)
(*         ) *)
(*      >- (qexists_tac `r` >> simp[isGBARunFor_def] *)
(*          >> `word_range x ⊆ aut.alphabet` by ( *)
(*               Cases_on `aut` >> fs[mergeState_def] >> POP_ASSUM mp_tac *)
(*               >> Cases_on `∃q'. q' ∈ f ∧ q' ≠ q ∧ equivalentStates f2 f1 q' q` *)
(*               >> simp[]) *)
(*          >> Cases_on `∃q'. q' ∈ aut.states ∧ q' ≠ q *)
(*                  ∧ equivalentStates aut.accTrans aut.trans q' q` *)
(*          >> rpt strip_tac *)
(*           >- (fs[isGBARunFor_def,isValidGBARunFor_def] >> Cases_on `aut` *)
(*               >> POP_ASSUM mp_tac >> POP_ASSUM mp_tac >> POP_ASSUM mp_tac *)
(*               >> POP_ASSUM mp_tac >> POP_ASSUM mp_tac >> POP_ASSUM mp_tac *)
(*               >> RULE_ASSUM_TAC(SIMP_RULE (srw_ss())[mergeState_def]) *)
(*               >> rpt strip_tac *)
(*               >> qabbrev_tac *)
(*                   `s_new = @p. p ∈ f ∧ p ≠ q ∧ equivalentStates f2 f1 p q` *)
(*               >> fs[] *)
(*               >> qabbrev_tac *)
(*                   `newGBA = GBA (f DIFF {q}) (replaceStateSet q s_new f0) *)
(*                      (λm. {(a,replaceState q s_new n) | (a,n) ∈ f1 m}) *)
(*                        (replaceAccTrans q s_new f2) f3` *)
(*               >> `isValidGBARunFor newGBA r x` by metis_tac[] *)
(*               >> POP_ASSUM mp_tac >> Cases_on `r` >> simp[isValidGBARunFor_def] *)
(*               >> rpt strip_tac *)
(*                >- (qunabbrev_tac `newGBA` >> fs[replaceStateSet_def] *)
(*                    >> Cases_on `q ∈ f0` >> fs[equivalentStates_def]) *)
(* ) *)
