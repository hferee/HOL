(* ===================================================================== *)
(* FILE          : const_spec.sml                                        *)
(* DESCRIPTION   : Implements the principle of constant specification.   *)
(*                 Translated from hol88.                                *)
(*                                                                       *)
(* AUTHOR        : (c) Mike Gordon, University of Cambridge              *)
(* TRANSLATOR    : Konrad Slind, University of Calgary                   *)
(* DATE          : September 11, 1991                                    *)
(* ===================================================================== *)


structure Const_spec :> Const_spec =
struct

open Exception Lib Type Term Dsyntax Thm Theory;


val |-> = Lib.|->
infix 5 |->

fun CONST_SPEC_ERR s =
    HOL_ERR{origin_structure = "Const_spec",
	    origin_function = "check_specification",
	            message = s};

local val store_defnr = ref (fn ("",Lib.LEFT(""):(string,string list)Lib.sum,
                                 th,_:term) => th)
      val _ = Theory.expose_store_definition store_defnr
in
  val store_definition = !store_defnr
end;

(*---------------------------------------------------------------------------
 * Added on 25/11/1988 for HOL88:
 *  new_specification "flag" "name" "C" |- ?x. ... x ...
 *  declares C as a new constant and then does
 *  new_axiom("name", `... C ...`)  "flag" must be one of "constant",
 *  "infix" or "binder" and determines the syntactic status of C.
 *  To avoid Roger Jones type problems, it is required that there be
 *  no type variables in types of subterms of
 *
 *     `... C ...`
 *  that do not occur in the type of C. This rules out, for example,
 *
 *     new_specification(tok, "Wonk", |- ?b:bool. b = !x y:*. x=y)
 *
 *  The specification above was amended on 8/2/89 to the following:
 *
 *     new_specification
 *      name
 *      ["flag1","C1"; ... ; "flagn,Cn"]
 *      |- ?x1 ... xn. ... x1 ... xn ...
 *  declares C1, ... ,Cn as a new constants and then does
 *  new_axiom("name", `... C1 ... Cn ...`);  "flagi" must be one of "constant",
 *  "infix" or "binder" and determines the syntactic status of Ci.
 *  To avoid Roger Jones type problems, it is required that there be no
 *  type variables in types of subterms of  `... C1 ... Cn ...` that do not
 *  occ	ur in the types of any Ci (1 <= i <= n). This rules out, for example,
 *
 *     new_specification
 *      ("Wonk_DEF", ["constant","Wonk"], |- ?b:bool. b = !x y:*. x=y)
 *
 *  which would define a constant `Wonk` of type `:bool` by
 *  the inconsistent axiom:
 *
 *     |- Wonk = !x y:*. x=y
 *
 * (Actually, it doesn't do an "new_axiom", but a "store_definition" -KLS)
 *---------------------------------------------------------------------------*)

fun is_infix_type ty = Lib.can Type.dom_rng (Lib.snd (Type.dom_rng ty));
fun is_binder_type ty = Lib.can Type.dom_rng (Lib.fst (Type.dom_rng ty));

(*---------------------------------------------------------------------------*
 * Auxiliary function to strip off n quantifiers.                            *
 *---------------------------------------------------------------------------*)

fun n_strip_quant dest_fn 0 t = ([],t) |
    n_strip_quant dest_fn n t =
     let val {Bvar, Body} = dest_fn t
         val (l,t'') = n_strip_quant dest_fn (n-1) Body
     in
        (Bvar::l, t'')
     end;

fun no_assums th =
 case Thm.hyp th
  of (_::_) => raise CONST_SPEC_ERR
                       "no assumptions to theorem allowed in specifications"
   | [] => ();


fun no_free_vars th =
 case free_vars(concl th)
  of [] => ()
   | V  => raise CONST_SPEC_ERR (String.concat
            ("Unbound variable(s) in specification: "
             :: commafy (map (Lib.quote o #Name o dest_var) V)));


fun check_name const_name =
  if not(Lexis.allowed_term_constant const_name)
  then Lib.mesg true (String.concat
       [Lib.quote const_name, 
         " is not a standard constant name (continuing anyway)"])
  else ();


fun check_tyvars V var =
  case Lib.set_diff V (type_vars_in_term var)
   of [] => ()
    | W  => raise CONST_SPEC_ERR (String.concat
            (commafy (map (Lib.quote o dest_vartype) W)
             @ ["should occur in the type of ", #Name (dest_var var)]));



(*---------------------------------------------------------------------------*
 * Auxiliary function to check the arguments to new_specification;           *
 * fails (with useful message) or returns                                    *
 *  ([`x1`;...;`xn`], `... x1 ... xn ...`)                                   *
 *                                                                           *
 * deleted "defname" from arguments, as it is not used -- KLS                *
 *---------------------------------------------------------------------------*)

fun check_specification name_fixl th =
 let val _ = no_assums th
     val _ = no_free_vars th
     val _ = map check_name name_fixl
     val (vars,body) = n_strip_quant dest_exists (length name_fixl) (concl th)
                       handle HOL_ERR _
                       => raise CONST_SPEC_ERR
                             "too few existentially quantified variables"
     val body_tyvars = Term.type_vars_in_term body
     val _ = map (check_tyvars body_tyvars) vars
 in
   (vars, body)
 end;

fun const_intro const_name var = 
    Theory.new_constant{Name=const_name, Ty=Term.type_of var}

fun cnst s v = v |-> mk_const{Name=s,Ty=Term.type_of v};

fun new_specification{name, consts, sat_thm} =
   let val (vars,body) = check_specification consts sat_thm
       val _ = Lib.map2 const_intro consts vars
       val theta = Lib.map2 cnst consts vars
   in
     store_definition
        (name, Lib.RIGHT consts, sat_thm, Term.subst theta body)
   end;

end; (* CONST_SPEC *)
