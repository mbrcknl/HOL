signature file_readerLib =
sig

  datatype arch = ARM | M0 | RISCV

  val arch_name : arch ref
  val num_to_hex : num -> string
  val get_tools : unit -> helperLib.decompiler_tools
  val arm_spec : string -> helperLib.instruction
  val m0_spec : string -> helperLib.instruction
  val riscv_spec : string -> helperLib.instruction
  val read_files : string -> string list -> unit
  val section_body : string -> (Arbnum.num * string * string) list
  val section_io : string -> int list * int * bool
  val section_location : string -> string
  val section_names : unit -> string list
  val show_annotated_code : (Arbnum.num -> string) -> string -> unit
  val show_code : string -> unit

  val tysize : unit -> Type.hol_type
  val wsize  : unit -> Type.hol_type

end
