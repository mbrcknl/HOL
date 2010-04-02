signature Drule =
sig
  include Abbrev

  val ETA_CONV         : term -> thm
  val TY_ETA_CONV      : term -> thm
  val RIGHT_ETA        : thm -> thm
  val EXT              : thm -> thm
  val TY_EXT           : thm -> thm
  val MK_ABS           : thm -> thm
  val MK_TY_ABS        : thm -> thm
  val MK_EXISTS        : thm -> thm
  val MK_TY_EXISTS     : thm -> thm
  val MK_TY_TM_EXISTS  : thm -> thm
  val LIST_MK_EXISTS   : term list -> thm -> thm
  val LIST_MK_TY_EXISTS: hol_type list -> thm -> thm
  val LIST_MK_TY_TM_EXISTS: (hol_type,term) Lib.sum list -> thm -> thm
  val SIMPLE_EXISTS    : term -> thm -> thm
  val SIMPLE_TY_EXISTS : hol_type -> thm -> thm
  val SIMPLE_TY_TM_EXISTS : (hol_type,term) Lib.sum -> thm -> thm
  val SIMPLE_CHOOSE    : term -> thm -> thm
  val SIMPLE_TY_CHOOSE : hol_type -> thm -> thm
  val SIMPLE_TY_TM_CHOOSE : (hol_type,term) Lib.sum -> thm -> thm
  val EQT_INTRO        : thm -> thm
  val GSUBS            : ((term,term)subst -> term -> term)
                           -> thm list -> thm -> thm
  val SUBST_CONV       : (term,thm)subst -> term -> term -> thm
  val BETA_TY_RULE     : thm -> thm
  val ADD_ASSUM        : term -> thm -> thm
  val IMP_TRANS        : thm -> thm -> thm
  val IMP_ANTISYM_RULE : thm -> thm -> thm
  val CONTR            : term -> thm -> thm
  val UNDISCH          : thm -> thm
  val EQT_ELIM         : thm -> thm
  val SPECL            : term list -> thm -> thm
  val TY_GENL          : hol_type list -> thm -> thm
  val TY_SPECL         : hol_type list -> thm -> thm
  val TY_TM_GEN        : (hol_type,term)Lib.sum -> thm -> thm
  val TY_TM_SPEC       : (hol_type,term)Lib.sum -> thm -> thm
  val TY_TM_GENL       : (hol_type,term)Lib.sum list -> thm -> thm
  val TY_TM_SPECL      : (hol_type,term)Lib.sum list -> thm -> thm
  val SELECT_INTRO     : thm -> thm
  val SELECT_ELIM      : thm -> term * thm -> thm
  val SELECT_RULE      : thm -> thm
  val SPEC_VAR         : thm -> term * thm
  val TY_SPEC_VAR      : thm -> hol_type * thm
  val FORALL_EQ        : term -> thm -> thm
  val TY_FORALL_EQ     : hol_type -> thm -> thm
  val EXISTS_EQ        : term -> thm -> thm
  val TY_EXISTS_EQ     : hol_type -> thm -> thm
  val SELECT_EQ        : term -> thm -> thm
  val SUBS             : thm list -> thm -> thm
  val SUBS_OCCS        : (int list * thm) list -> thm -> thm
  val RIGHT_BETA       : thm -> thm
  val RIGHT_TY_BETA    : thm -> thm
  val RIGHT_TY_TM_BETA : thm -> thm
  val LIST_BETA_CONV   : term -> thm
  val LIST_TY_BETA_CONV : term -> thm
  val TY_TM_BETA_CONV  : term -> thm
  val LIST_TY_TM_BETA_CONV : term -> thm
  val RIGHT_LIST_BETA  : thm -> thm
  val RIGHT_LIST_TY_BETA : thm -> thm
  val RIGHT_LIST_TY_TM_BETA : thm -> thm
  val CONJUNCTS_AC     : term * term -> thm
  val DISJUNCTS_AC     : term * term -> thm
  val CONJ_DISCH       : term -> thm -> thm
  val CONJ_DISCHL      : term list -> thm -> thm
  val NEG_DISCH        : term -> thm -> thm
  val NOT_EQ_SYM       : thm -> thm
  val EQF_INTRO        : thm -> thm
  val EQF_ELIM         : thm -> thm
  val ISPEC            : term -> thm -> thm
  val ISPECL           : term list -> thm -> thm
  val GEN_ALL          : thm -> thm
  val TY_GEN_ALL       : thm -> thm
  val TY_TM_GEN_ALL    : thm -> thm
  val DISCH_ALL        : thm -> thm
  val UNDISCH_ALL      : thm -> thm
  val SPEC_ALL         : thm -> thm
  val TY_SPEC_ALL      : thm -> thm
  val TY_TM_SPEC_ALL   : thm -> thm
  val PROVE_HYP        : thm -> thm -> thm
  val CONJ_PAIR        : thm -> thm * thm
  val LIST_CONJ        : thm list -> thm
  val CONJ_LIST        : int -> thm -> thm list
  val CONJUNCTS        : thm -> thm list
  val BODY_CONJUNCTS   : thm -> thm list
  val IMP_CANON        : thm -> thm list
  val LIST_MP          : thm list -> thm -> thm
  val CONTRAPOS        : thm -> thm
  val DISJ_IMP         : thm -> thm
  val IMP_ELIM         : thm -> thm
  val DISJ_CASES_UNION : thm -> thm -> thm -> thm
  val DISJ_CASESL      : thm -> thm list -> thm
  val ALPHA_CONV       : term -> term -> thm
  val TY_ALPHA_CONV    : hol_type -> term -> thm
  val GEN_ALPHA_CONV   : term -> term -> thm
  val GEN_TY_ALPHA_CONV : hol_type -> term -> thm
  val GEN_TY_TM_ALPHA_CONV : (hol_type,term) Lib.sum -> term -> thm
  val IMP_CONJ         : thm -> thm -> thm
  val EXISTS_IMP       : term -> thm -> thm
  val TY_EXISTS_IMP    : hol_type -> thm -> thm
  val INST_TY_TERM     : (term,term)subst * (hol_type,hol_type)subst
                          -> thm -> thm
  val INST_ALL         : (term,term)subst * (hol_type,hol_type)subst
                           * (kind,kind)subst * int
                          -> thm -> thm
  val GSPEC            : thm -> thm
  val TY_GSPEC         : thm -> thm
  val TY_TM_GSPEC      : thm -> thm

  val strip_ty_tm_comb : term -> term * (hol_type,term) Lib.sum list
  val strip_ty_tm_abs  : term -> (hol_type,term) Lib.sum list * term

  val PART_MATCH       : (term -> term) -> thm -> term -> thm
  val MATCH_MP         : thm -> thm -> thm
  val BETA_VAR         : term -> term -> term -> thm
  val TY_BETA_VAR      : term -> term -> term -> thm
  val TY_TM_BETA_VAR   : term -> term -> term -> thm
  val HO_PART_MATCH    : (term -> term) -> thm -> term -> thm
  val HO_MATCH_MP      : thm -> thm -> thm
  val RES_CANON        : thm -> thm list

  val prove_rep_fn_one_one : thm -> thm
  val prove_rep_fn_onto    : thm -> thm
  val prove_abs_fn_onto    : thm -> thm
  val prove_abs_fn_one_one : thm -> thm

  val define_new_type_bijections
    : {name:string, ABS:string, REP:string, tyax:thm} -> thm

  val MK_AC_LCOMM    : thm * thm -> thm * thm * thm
end
