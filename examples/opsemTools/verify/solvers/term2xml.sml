(* Version of  term2xml.ml for compiling *)
(* Changes:
    numSyntax --> intSyntax
    is_numeral --> is_int_literal 
    is_greater --> is_great
    dest_greater --> dest_great
    is_exp --> is_exponential (defined below)
    dest_exp --> dest_exponential (defined below)
*)


open HolKernel Parse boolLib
     newOpsemTheory bossLib pairSyntax intLib
     computeLib finite_mapTheory relationTheory stringLib;

(* Path to ILOG executable *)
exception ILOG_EXECUndefinedError;
fun getILOG_EXEC () = 
 case Portable.getEnv "ILOG_EXEC" of
    SOME path_name => path_name
  | NONE           => (print "Environment variable ILOG_EXEC undefined.\n"; 
                       print "Add:\n setenv ILOG_EXEC \"<path to ILOG executable>\" \nto ~/.shrc\n";
                       raise ILOG_EXECUndefinedError);

(* Path to ILOG support directory
val ilogPath = Globals.HOLDIR ^ "/examples/opsemTools/verify/term2xml/xmlterm2csp/";
*)
val ilogPath = "/homes/mjcg/Helene/newOpsem/xmlterm2csp/";



(* Magnus switched to using integers
val _ = intLib.deprecate_int();
*)

fun is_exponential tm =
 is_comb tm 
  andalso is_comb(rator tm) 
  andalso is_const(rator(rator tm)) 
  andalso (fst(dest_const(rator(rator tm))) = "int_exp");

fun dest_exponential tm = 
 if is_exponential tm
  then (rand(rator tm), rand tm)
  else raise ERR "dest_exponential" "not an integer exponential";

(* ============================================= *)
(* To print a term built during symbolic execution
   as a xml file that follows the grammar defined into 
   term2xml.dtd
*)
(* ============================================= *)

(* ============================================= *)
(* inputs:
   - the name of the program, 
   - a term (logical expression)
   output: a xml file that follows the grammar in term2xml.dtd
*)
(* ============================================= *)

(*
map load ["intSyntax","pairSyntax","stringTheory","stringLib","finite_mapTheory"];
*)
open intSyntax   (* various functions on ints (e.g. is_plus) *)
     pairSyntax  (* various functions on pairs (e.g. strip_pair)    *)


(* ============================================= *)
(* functions for parsing Boolean and integer terms *)
(* ----------------------------------------------- *)


(* functions to identify the types of terms *)
(* ---------------------------------------- *)

fun is_comparator(t) = 
    is_less(t) orelse is_leq(t) orelse is_great(t)
    orelse is_geq(t) orelse is_eq(t) orelse is_var(t);

fun is_bool_term(t) =
    is_neg(t) orelse is_conj(t) orelse is_disj(t)
    orelse is_imp_only(t) orelse is_var(t) orelse 
    is_comparator(t);

fun is_int_term(t) =
    is_plus(t) orelse is_minus(t) orelse is_mult(t)
    orelse is_div(t) orelse is_exponential(t) 
    orelse is_var(t) orelse is_int_literal(t);

(* function to indent printing *)
fun  indent 0  =  ""
| indent n =  "  " ^ indent (n-1);


(* function for parsing a variable *)
(* ------------------------------- *)
fun get_var(tm) =
    "<ExprIdent name=\"" ^ fst(dest_var tm) ^"\"/>\n";

(* function for parsing an integer expression *)
fun parse_int(tm,i) =
  if is_var(tm) 
     then indent(i) ^ get_var(tm)
  else if is_int_literal(tm)
       then indent(i) ^ "<ExprIntegerLiteral value=\"" ^ term_to_string(tm) ^ "\"/>\n"
  else 
      if is_plus(tm)
      then
        let val c1 = parse_int(fst(dest_plus tm),i+1); 
          val c2 = parse_int(snd(dest_plus tm),i+1); 
          in
            indent(i) ^ "<ExprPlus>\n" ^ c1 ^  c2 ^ indent(i) ^ "</ExprPlus>\n"
          end
      else 
        if is_minus(tm)
        then
          let val c1 = parse_int(fst(dest_minus tm),i+1); 
            val c2 = parse_int(snd(dest_minus tm),i+1); 
            in
              indent(i) ^"<ExprMinus>\n" ^  c1 ^  c2 ^ indent(i) ^ "</ExprMinus>\n"
            end
        else 
          if is_mult(tm)
          then
            let val c1 = parse_int(fst(dest_mult tm),i+1); 
               val c2 = parse_int(snd(dest_mult tm),i+1); 
               in
                 indent(i) ^ "<ExprTimes>\n" ^  c1 ^  c2 ^ indent(i) ^ "</ExprTimes>\n"
               end
          else 
            if is_div(tm)
            then
              let val c1 = parse_int(fst(dest_div tm),i+1); 
                val c2 = parse_int(snd(dest_div tm),i+1); 
                in
                  indent(i) ^ "<ExprDiv>\n" ^  c1 ^  c2 ^ indent(i) ^ "</ExprDiv>\n"
                end
            else (* exponential *)
              (* n**2 is translated as n*n *)
              if snd(dest_exponential tm)=``2``
              then 
                let val c =  parse_int(fst(dest_exponential tm),i+1);
                   in
                    indent(i) ^ "<ExprTimes>\n" ^  c ^  c ^ indent(i) ^ "</ExprTimes>\n"
                   end
              else "";


(* function for parsing comparators *)
fun parse_comparator(tm,i) =
    if is_var(tm) 
       then  get_var(tm)
    else 
        if is_less(tm)
        then
            let val c1 = parse_int(fst(dest_less tm),i+1); 
              val c2 = parse_int(snd(dest_less tm),i+1); 
            in
               indent(i) ^ "<ExprLess>\n" ^ c1 ^ c2 ^ indent(i) ^ "</ExprLess>\n"
            end
        else
            if is_leq(tm)
            then
                let val c1 = parse_int(fst(dest_leq tm),i+1); 
                  val c2 = parse_int(snd(dest_leq tm),i+1); 
                in
                    indent(i) ^ "<ExprLessEq>\n" ^ c1  ^ c2 ^ indent(i) ^ "</ExprLessEq>\n"
                end
            else
                if is_eq(tm)
                then
                    let val c1 = parse_int(fst(dest_eq tm),i+1); 
                      val c2 = parse_int(snd(dest_eq tm),i+1); 
                    in
                       indent(i) ^ "<ExprEqual>\n"  ^ c1 ^ c2 ^ indent(i) ^ "</ExprEqual>\n"
                    end
                    else
                    if is_great(tm)
                    then
                        let val c1 = parse_int(fst(dest_great tm),i+1); 
                          val c2 = parse_int(snd(dest_great tm),i+1); 
                        in
                           indent(i) ^"<ExprGreat>\n"  ^  c1 ^  c2 ^ indent(i) ^ "</ExprGreat>\n"
                        end
                    else (* greater or equal *)
                             let val c1 = parse_int(fst(dest_geq tm),i+1); 
                               val c2 = parse_int(snd(dest_geq tm),i+1); 
                             in
                               indent(i) ^ "<ExprGreatEq>\n"   ^  c1 ^  c2 ^ indent(i) ^ "</ExprGreatEq>\n"
                             end;


(* function for parsing a Boolean term (without quantifiers) *)
fun parse_bool(tm,i) =
(* the boolean variable b is associated with constraint b==1 *)
  if is_var(tm) 
       then let val v = get_var(tm)
              in
               indent(i) ^ "<ExprEqual>\n" ^ indent(i+1) ^v ^
                indent(i+1) ^ "<ExprIntegerLiteral value=\"1\"/>\n"
               ^ indent(i) ^ "</ExprEqual>\n"
              end
    else 
        if is_comparator(tm)
        then parse_comparator(tm,i+1)
        else
            if is_neg(tm)
            then 
                let val c1 = parse_bool(dest_neg tm,i+1); 
                in 
                  indent(i) ^"<ExprLogicalNot>\n"   ^ c1 ^ indent(i) ^"</ExprLogicalNot>\n" 
                end
            else 
                (* binary operators *)
    if is_disj(tm)
    then
        let val c1 = parse_bool(fst(dest_disj tm),i+1); 
          val c2 = parse_bool(snd(dest_disj tm),i+1); 
        in
            indent(i) ^"<ExprLogicalOr>\n" ^  c1 ^  c2 ^ indent(i) ^ "</ExprLogicalOr>\n"
        end
    else 
        if is_imp_only(tm)
        then
             let val c1 = parse_bool(fst(dest_imp_only tm),i+1); 
              val c2 = parse_bool(snd(dest_imp_only tm),i+1); 
            in
                indent(i) ^"<ExprLogicalImplies>\n" ^  c1 ^  c2 ^ indent(i) ^ "</ExprLogicalImplies>\n"
            end
                (* conjunction *)
        else 
          if (fst(dest_conj tm)=``T``)
          then parse_bool(snd(dest_conj tm),i+1)
          else
            let val c1 = parse_bool(fst(dest_conj tm),i+1); 
              val c2 = parse_bool(snd(dest_conj tm),i+1); 
            in
                indent(i) ^ "<ExprLogicalAnd>\n" ^  c1 ^  c2 ^ indent(i) ^ "</ExprLogicalAnd>\n"
            end;


(* return the xml header *)
fun header()  =
    "<?xml version=\"1.0\" ?>\n" ^
    "<?xml-stylesheet type=\"text/css\" href=\"term.css\"?>\n"
;


(* ============================================== *)
(* functions to print tuples (pre,path,state,post)
   built by symbolic execution as a xml tree *)
(* ---------------------------------------------- *)


(* to  open the program tag *)
(* ------------------------ *)
fun open_term(n) =
 "\n\n<Term name=\"" ^ n ^ "\">\n";


(* to close the program tag *)
(* ------------------------ *)
fun close_term() = 
   "</Term>\n";

(* to print the specification and the path *)
(* terms can be empty                      *)
(* --------------------------------------- *)

fun get_term(t) = 
  if not(t = ``T``)
  then 
     parse_bool(t,2)
  else  "";




(* ------------------------------------------ *)
(* main function to print a term as xml tree          *)
(* ------------------------------------------ *)
fun print_opsemTerm(out,name,tm) =
   (out(header());
    out(open_term(name));
    out(get_term(tm));
    out(close_term())
   );

(* to print xml into a file *)
fun printXML_to_file(name,tm) =
 let val fileName = ilogPath ^ "xml/" ^ name ^ ".xml";
     val outstr = TextIO.openOut(fileName);
     fun out s = TextIO.output(outstr,s)
 in
  (print_opsemTerm(out,name,tm);
   TextIO.flushOut outstr;
   TextIO.closeOut outstr
   )
 end;

(* Old:
fun printXML_to_file(name,tm) =
 let val fileName = "xmlterm2csp/xml/" ^ name ^ ".xml";
    val outstr = TextIO.openOut(fileName);
    fun out s = TextIO.output(outstr,s)
 in
 (print_opsemTerm(out,name,tm);
  TextIO.flushOut outstr;
  TextIO.closeOut outstr
  )
 end;
*)

(* -----------------------------------------------------
   to launch the Java program that searches for solutions
   of the xml tree
The term is supposed to be a disjunction that corresponds
to the negation of the specification cases.
All the terms of the disjunction are successively proved.
*)
fun execute name =
  let val exec = ("java -cp .:" ^ getILOG_EXEC() ^ ":" ^ ilogPath ^ "java/classes"
                  ^ " validation.ValidationLauncher "   ^ name ^ " 16");
 in
   Portable.system(exec)
 end;

(* Old:
fun execute name = 
  let val exec = "java -cp .:xmlterm2csp/java/lib/jsolver.jar:xmlterm2csp/java/classes"
                  ^ " validation.ValidationLauncher " 
                  ^ name ^ " 16";
  in
    Portable.system(exec)
end;
*)


(* -----------------------------------------------------
   to launch the Java program that searches for solutions
   of the xml tree, and stops as soon as a first solution
   has been found
   Used to test if a path is feasible.
*)
fun execPath name =
 let val exec = ("java -cp .:" ^ getILOG_EXEC() ^ ":" ^ ilogPath ^ "java/classes"
                 ^ " validation.ValidationLauncher " ^ name
                 ^ " -path  16");
  in
    Portable.system(exec)
end;

(* Old:
fun execPath name = 
  let val exec = "java -cp .:xmlterm2csp/java/lib/jsolver.jar:xmlterm2csp/java/classes"
                  ^ " validation.ValidationLauncher " ^ name 
                  ^ " -path  16";
   in
     Portable.system(exec)
end;

*)




(* -----------------------------------------------------
   To compile the Java programs that symbolically executes
   the xml tree.
   Usefull only if Java sources have been modified
*)
fun compile() =
 let val compil = ("javac  -cp .:" ^ getILOG_EXEC() ^ ":" ^ ilogPath ^
                   "java/classes:" ^ ilogPath ^ "java/src " ^ ilogPath ^ "java/src/*/*.java "
                   ^ "java/src " ^ ilogPath ^ "java/src/*/*/*.java ");
  in
     Portable.system(compil)
 end;

(* Old:
fun compile() = 
  let val compil = "javac  -cp .:xmlterm2csp/java/lib/jsolver.jar:"
                   ^ "xmlterm2csp/java/classes:xmlterm2csp/java/src"
                   ^ " xmlterm2csp/java/src/*/*.java"
                   ^ " xmlterm2csp/java/src/*/*/*.java" ;
   in
     Portable.system(compil)
end;
*)



