open HolKernel Parse bossLib boolLib gfgTheory listTheory optionTheory pred_setTheory

open alterATheory sptreeTheory ltlTheory generalHelpersTheory

val _ = new_theory "concrRep";

val _ = monadsyntax.temp_add_monadsyntax();
val _ = overload_on("monad_bind",``OPTION_BIND``);

val _ = Datatype`
  nodeLabelAA = <| frml : α ltl_frml ;
                   is_final : bool
                 |>`;

val _ = Datatype`
  edgeLabelAA = <| edge_grp : num ;
                   pos_lab : (α list) ;
                   neg_lab : (α list)
                 |>`;

val _ = Datatype`
  concrAA = <| graph : (α nodeLabelAA, α edgeLabelAA) gfg ;
               init : (num list) list ;
               atomicProp : α list
            |>`;

val concr2Abstr_states_def = Define`
  concr2Abstr_states graph =
     { x.frml | SOME x ∈
                (IMAGE (\n. lookup n graph.nodeInfo) (domain graph.nodeInfo))}`;

val concr2Abstr_init_def = Define`
  concr2Abstr_init concrInit graph =
     LIST_TO_SET
         (MAP
          (\l. {x.frml |
                MEM x (CAT_OPTIONS (MAP (\n. lookup n graph.nodeInfo) l)) })
          concrInit)`;

val concr2Abstr_final_def = Define`
  concr2Abstr_final graph =
     {x.frml | SOME x ∈
                 (IMAGE (\n. lookup n graph.nodeInfo) (domain graph.nodeInfo))
               ∧ x.is_final}`;

val concr2Abstr_edgeLabel_def = Define`
  concr2Abstr_edgeLabel (edgeLabelAA _ pos neg) aP =
     let  pos_part = FOLDL (\s a. s ∩ char (POW aP) a) {} pos
        in FOLDL (\s a. s ∩ char_neg (POW aP) a) pos_part neg`;

val concr2Abstr_trans_def = Define`
  concr2Abstr_trans graph aP s =
     let sucs = OPTION_TO_LIST
                     (OPTION_BIND (findNode (\label. (SND label).frml = s) graph)
                                  (\n. lookup n graph.followers))
     in { edge | ?i x label.
                 let iSucs = { (concr2Abstr_edgeLabel e aP,suc.frml)
                 | ?sucId. MEM (e,sucId) (FILTER ((\j. j = i) o FST) sucs)
                       ∧ SOME suc = lookup sucId graph.nodeInfo}
                 in (x ∈ iSucs) ∧ (label = FST x)
                  ∧ (edge = (label,IMAGE SND iSucs)) }`;

val concr2AbstrAA = Define`
  concr2AbstrAA (concrAA g init prop) =
    ALTER_A
        (concr2Abstr_states g)
        (concr2Abstr_init init g)
        (concr2Abstr_final g)
        (POW (LIST_TO_SET prop))
        (concr2Abstr_trans g (LIST_TO_SET prop))`;

val _ = Datatype`
  concrEdge = <| pos : (α list) ;
                 neg : (α list) ;
                 sucs : (α ltl_frml) list |>`;

val concr2AbstractEdge_def = Define`
  concr2AbstractEdge aP (concrEdge pos neg sucs) =
       (FOLDR (\a sofar. (char (POW aP) a) ∩ sofar)
          (FOLDR (\a sofar. (char_neg (POW aP) a) ∩ sofar) (POW aP) neg) pos
       , set sucs)`;

val autoStates_def = Define`
  autoStates (concrAA g i aP) =
    MAP ((\l. l.frml) o SND) (toAList g.nodeInfo)`;

val inAuto_def = Define`
  inAuto aut f = MEM f (autoStates aut)`;

val IN_AUTO_FINITE = store_thm
  ("IN_AUTO_FINITE",
   ``!aut. FINITE (LIST_TO_SET (autoStates aut))``,
   rpt strip_tac >> metis_tac[FINITE_LIST_TO_SET]
  );

val addFrmlToAut_def = Define`
   (addFrmlToAut (concrAA g i aP) (U f1 f2) =
       if inAuto (concrAA g i aP) (U f1 f2)
       then (concrAA g i aP)
       else concrAA (addNode <| frml := (U f1 f2); is_final := T |> g) i aP)
 ∧ (addFrmlToAut (concrAA g i aP) f =
       if inAuto (concrAA g i aP) f
       then (concrAA g i aP)
       else concrAA (addNode <| frml := f; is_final := F |> g) i aP)`;

val ADDFRML_LEMM = store_thm
  ("ADDFRML_LEMM",
   ``!aut f. inAuto (addFrmlToAut aut f) f``,
   rpt strip_tac >> Cases_on `inAuto aut f`
    >- (Cases_on `f` >> Cases_on `aut` >> simp[addFrmlToAut_def])
    >- (Cases_on `?f1 f2. f = U f1 f2` >> Cases_on `aut`
        >- (fs[] >> rw[]
            >> simp[addFrmlToAut_def,inAuto_def,autoStates_def,MEM_MAP]
            >> simp[addNode_def,MEM_toAList]
            >> qexists_tac `(g.next,<|frml := U f1 f2; is_final := T|>)`
            >> fs[MEM_toAList]
           )
        >- (qabbrev_tac `el = (g.next,<|frml := f; is_final := F|>)`
            >> Cases_on `f` >> fs[]
            >> simp[addFrmlToAut_def,inAuto_def,autoStates_def,MEM_MAP]
            >> simp[addNode_def,MEM_toAList]
            >> qexists_tac `el` >> qunabbrev_tac `el` >> fs[MEM_toAList]
           )
       )
  );

val addEdgeToAut_def = Define`
  addEdgeToAut f (concrEdge pos neg sucs) (concrAA g i aP) =
    let sucIds = CAT_OPTIONS (MAP (\s. findNode (λ(n,l). l.frml = s) g) sucs)
    in do nodeId <- findNode (λ(n,l). l.frml = f) g;
           oldSucPairs <- lookup nodeId g.followers ;
           oldSucs <- SOME (MAP FST oldSucPairs);
           lstGrpId <- SOME (if oldSucs = [] then 0 else (HD oldSucs).edge_grp) ;
           unfolded_edges <- SOME
             (MAP (\i. (<| edge_grp := lstGrpId + 1;
                          pos_lab := pos ;
                          neg_lab := neg ; |>,i)) sucIds);
           FOLDR (\e a_opt. do a <- a_opt ;
                               newGraph <- addEdge nodeId e a.graph;
                               SOME (concrAA newGraph i aP)
                            od)
                 (SOME (concrAA g i aP)) unfolded_edges
        od`;

val ADDFRML_LEMM2 = store_thm
  ("ADDFRML_LEMM2",
   ``!a f. wfg a.graph ==>
       (set (autoStates a) ⊆ set (autoStates (addFrmlToAut a f))
      ∧ wfg (addFrmlToAut a f).graph)``,
   simp[SUBSET_DEF] >> rpt strip_tac >> Cases_on `inAuto a f`
   >> Cases_on `a`
    >- (Cases_on `f` >> simp[addFrmlToAut_def])
    >- (Cases_on `f` >> simp[addFrmlToAut_def,addNode_def]
        >> `~(g.next ∈ domain g.nodeInfo)` by (
             fs[wfg_def] >> metis_tac[]
         )
        >> fs[autoStates_def,insert_def] >> POP_ASSUM mp_tac
        >> POP_ASSUM mp_tac >> POP_ASSUM mp_tac
        >> rw[MEM_MAP] >> qexists_tac `y` >> fs[]
        >> Cases_on `y` >> fs[]
        >> POP_ASSUM mp_tac >> POP_ASSUM mp_tac >> POP_ASSUM mp_tac
        >> rw[MEM_toAList] >> Cases_on `q = g.next`
        >> fs[lookup_insert]
        >> (`lookup q g.nodeInfo = NONE` by metis_tac[lookup_NONE_domain]
            >> rw[] >> fs[])
       )
    >- (Cases_on `f` >> simp[addFrmlToAut_def]
        >> fs[wfg_def])
    >- (Cases_on `f` >> simp[addFrmlToAut_def]
        >> fs[])
  );

val ADDFRML_FOLDR_LEMM = store_thm
  ("ADDFRML_FOLDR_LEMM",
   ``!a fs. wfg a.graph ==>
      (set (autoStates a) ⊆
         set (autoStates (FOLDR (\f a. addFrmlToAut a f) a fs))
         ∧ wfg (FOLDR (\f a. addFrmlToAut a f) a fs).graph)``,
   gen_tac >> HO_MATCH_MP_TAC list_induction >> rpt strip_tac
   >> fs[FOLDR]
     >- (`set (autoStates (FOLDR (λf a. addFrmlToAut a f) a fs))
           ⊆ set (autoStates (addFrmlToAut (FOLDR (λf a. addFrmlToAut a f) a fs) h))`
         by metis_tac[ADDFRML_LEMM2]
         >> metis_tac[SUBSET_TRANS])
     >- (metis_tac[ADDFRML_LEMM2])
  );

val ADDFRML_FOLDR_LEMM2 = store_thm
  ("ADDFRML_FOLDR_LEMM2",
   ``!a fs. wfg a.graph ==>
       set fs ⊆ set (autoStates (FOLDR (λp g. addFrmlToAut g p) a fs))``,
   Induct_on `fs` >> rpt strip_tac >> fs[] >> rpt strip_tac
    >- metis_tac[ADDFRML_LEMM,inAuto_def]
    >- (first_x_assum (qspec_then `a` mp_tac) >> simp[]
        >> `!ls. wfg (FOLDR (λp g. addFrmlToAut g p) a ls).graph` by (
             Induct_on `ls` >> fs[] >> rpt strip_tac
             >> metis_tac[ADDFRML_LEMM2]
         )
        >> metis_tac[ADDFRML_LEMM2,SUBSET_TRANS]
       )
  );

val ADDEDGE_LEMM = store_thm
  ("ADDEDGE_LEMM",
   ``!a f e. case addEdgeToAut f e a of
               | SOME newAut => (set (autoStates newAut) = set (autoStates a))
               | NONE => T ``,
   rpt strip_tac >> Cases_on `addEdgeToAut f e a`
   >> fs[] >> Cases_on `e` >> Cases_on `a` >> fs[addEdgeToAut_def]
   >> rename[`concrAA g init aP`]
   >> qabbrev_tac `M = (MAP
                           (λi.
                                (<|edge_grp :=
                                 (if oldSucPairs = [] then 0
                                  else (HD (MAP FST oldSucPairs)).edge_grp) + 1;
                                 pos_lab := l; neg_lab := l0|>,i))
                           (CAT_OPTIONS
                                (MAP (λs. findNode (λ(n,l). l.frml = s) g) l1)))`
   >> qabbrev_tac `doAddEdge =
                         (λe a_opt.
                             do
                             a <- a_opt;
                          newGraph <- addEdge nodeId e a.graph;
                          SOME (concrAA newGraph init aP)
                               od)`
   >> `!xs. case FOLDR doAddEdge (SOME (concrAA g init aP)) xs of
            | NONE => T
            | SOME a => (set (autoStates a)
                         = set (autoStates (concrAA g init aP)))`
      by (Induct_on `xs` >> rpt strip_tac >> fs[]
          >> Cases_on
               `doAddEdge h (FOLDR doAddEdge (SOME (concrAA g init aP)) xs)`
          >> fs[]
          >> `~(FOLDR doAddEdge (SOME (concrAA g init aP)) xs = NONE)` by (
               Cases_on `FOLDR doAddEdge (SOME (concrAA g init aP)) xs` >> fs[]
               >> qunabbrev_tac `doAddEdge` >> Cases_on `h` >> fs[]
           )
          >> fs[] >> Cases_on `FOLDR doAddEdge (SOME (concrAA g init aP)) xs`
          >> fs[] >> qunabbrev_tac `doAddEdge` >> Cases_on `h` >> fs[]
          >> fs[addEdge_def] >> Cases_on `x'` >> simp[autoStates_def]
          >> fs[] >> Cases_on `x''` >> fs[autoStates_def]
          >> `g''.nodeInfo = g'.nodeInfo` suffices_by metis_tac[]
          >> rw[]
         )
   >> first_x_assum (qspec_then `M` mp_tac) >> rpt strip_tac
   >> Cases_on `FOLDR doAddEdge (SOME (concrAA g init aP)) M`
   >> fs[] >> rw[]
  );

val ADDEDGE_LEMM2 = store_thm
  ("ADDEDGE_LEMM2",
   ``!a f e. wfg a.graph ∧ inAuto a f
        ==> (?a2. (addEdgeToAut f e a = SOME a2) ∧ wfg a2.graph
          ∧ (a.graph.nodeInfo = a2.graph.nodeInfo))``,
   rpt strip_tac >> Cases_on `e` >> Cases_on `a` >> fs[addEdgeToAut_def]
   >> rw[IS_SOME_EXISTS] >> fs[inAuto_def,autoStates_def,MEM_MAP]
   >> simp[findNode_def]
   >> Q.HO_MATCH_ABBREV_TAC
       `?x. (?nodeId. A nodeId ∧ ?oSP. P oSP x nodeId) ∧ Q x`
   >> `?nodeId. A nodeId ∧ ?oSP x. P oSP x nodeId ∧ Q x`
       suffices_by metis_tac[SWAP_EXISTS_THM]
   >> qunabbrev_tac `P` >> qunabbrev_tac `A` >> fs[]
   >> `?q. (FIND (λ(n,l). l.frml = (SND y).frml) (toAList g.nodeInfo) = SOME q)
         ∧ ((λ(n,l). l.frml = (SND y).frml) q)` by (
       qabbrev_tac `P = (λ(n:num,l). l.frml = (SND y).frml)`
       >> `P y` by (qunabbrev_tac `P` >> Cases_on `y` >> fs[])
       >> metis_tac[FIND_LEMM]
   )
   >> Cases_on `q` >> rename[`_ = SOME (nId,frml)`]
   >> qexists_tac `nId` >> rpt strip_tac
    >- (qexists_tac `(nId,frml)` >> fs[])
    >- (`nId ∈ domain g.followers` by (
         `nId ∈ domain g.nodeInfo` suffices_by metis_tac[wfg_def]
         >> `MEM (nId, frml) (toAList g.nodeInfo)` by metis_tac[FIND_LEMM2]
         >> fs[MEM_toAList] >> metis_tac[domain_lookup]
       )
       >> fs[domain_lookup]
       >> Q.HO_MATCH_ABBREV_TAC
           `?x. FOLDR addSingleEdge a_init ls = SOME x ∧ Q x`
       >> `!lab x. MEM (lab,x) ls ==> ?h. MEM (x,h) (toAList g.nodeInfo)` by (
         rpt strip_tac >> qunabbrev_tac `ls` >> fs[MEM_MAP]
         >> qabbrev_tac
             `func = λs.
                         OPTION_MAP FST
                         (FIND (λ(n,l). l.frml = s) (toAList g.nodeInfo))`
         >> `?a. MEM a l1 ∧ SOME x = func a` by metis_tac[CAT_OPTIONS_MAP_LEMM]
         >> qunabbrev_tac `func` >> fs[]
         >> `MEM z (toAList g.nodeInfo)` by metis_tac[FIND_LEMM2]
         >> qexists_tac `SND z` >> fs[]
       )
       >> `!qs. (!lab x. MEM (lab,x) qs ==> ?h. MEM (x,h) (toAList g.nodeInfo))
             ==> ?m. (FOLDR addSingleEdge a_init qs = SOME m)
                   ∧ (g.nodeInfo = m.graph.nodeInfo)
                   ∧ (wfg m.graph)` by (
           Induct_on `qs` >> fs[]
            >- (qunabbrev_tac `a_init` >> simp[])
            >- (rpt strip_tac
                >> `∀lab x. MEM (lab,x) qs ⇒ ∃h. MEM (x,h) (toAList g.nodeInfo)`
                    by metis_tac[]
                >> `∃m. (FOLDR addSingleEdge a_init qs = SOME m)
                      ∧ (g.nodeInfo = m.graph.nodeInfo)
                      ∧ (wfg m.graph)` by metis_tac[]
                >> `?m2. (addSingleEdge h (SOME m) = SOME m2)
                       ∧ (g.nodeInfo = m2.graph.nodeInfo)
                       ∧ (wfg m2.graph)` suffices_by fs[]
                >> qunabbrev_tac `addSingleEdge` >> Cases_on `h`
                >> simp[]
                >> `?nG. addEdge nId (q,r) m.graph = SOME nG` by (
                     simp[addEdge_def]
                     >> Q.HO_MATCH_ABBREV_TAC `?nG. P ∧ A nG`
                     >> `P ∧ (P ==> ?nG. A nG)` suffices_by fs[]
                     >> qunabbrev_tac `P` >> qunabbrev_tac `A`
                     >> rpt strip_tac
                      >- (`MEM (nId,frml) (toAList g.nodeInfo)`
                             by metis_tac[FIND_LEMM2]
                          >> fs[MEM_toAList,domain_lookup]
                          >> metis_tac[]
                         )
                      >- (`∃h. MEM (r,h) (toAList g.nodeInfo)` by metis_tac[]
                          >> fs[MEM_toAList,domain_lookup])
                      >- (`nId ∈ domain m.graph.followers` by metis_tac[wfg_def]
                          >> `?fol_o. lookup nId m.graph.followers = SOME fol_o`
                             by metis_tac[domain_lookup]
                          >> fs[]
                         )
                 )
                >> qexists_tac `concrAA nG l' l0'` >> simp[]
                >> `wfg nG` by metis_tac[addEdge_preserves_wfg]
                >> POP_ASSUM mp_tac >> POP_ASSUM mp_tac
                >> simp[addEdge_def] >> rpt strip_tac
                >> Cases_on `m.graph` >> fs[gfg_fn_updates]
                >> fs[gfg_component_equality]
               )
       )
       >> qunabbrev_tac `Q` >> metis_tac[]
       )
  );

val _ = export_theory ();
