signature finite_mapSyntax =
sig

  include Abbrev

  val dest_fmap_ty : hol_type -> hol_type * hol_type
  val mk_fmap_ty : hol_type * hol_type -> hol_type
  val is_fmap_ty : hol_type -> bool

  val fempty_t : term
  val fupdate_t : term
  val fapply_t : term

  val mk_fempty : hol_type * hol_type -> term
  val dest_fempty : term -> hol_type * hol_type
  val is_fempty : term -> bool

  val mk_fupdate : term * term -> term
  val dest_fupdate : term -> term * term
  val is_fupdate : term -> bool

  val mk_fapply : term * term -> term
  val dest_fapply : term -> term * term
  val is_fapply : term -> bool

end;