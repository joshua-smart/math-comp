(* (c) Copyright 2006-2016 Microsoft Corporation and Inria.                  *)
(* Distributed under the terms of CeCILL-B.                                  *)
From mathcomp Require Import ssreflect ssrfun ssrbool eqtype ssrnat seq choice.
From mathcomp Require Import fintype bigop ssralg poly.

(******************************************************************************)
(* This file provides a library for the basic theory of Euclidean and pseudo- *)
(* Euclidean division for polynomials over non trivial ring structures.       *)
(* The library defines two versions of the pseudo-euclidean division: one for *)
(* coefficients in a (not necessarily commutative) non-trivial ring structure *)
(* and one for coefficients equipped with a structure of integral domain.     *)
(* From the latter we derive the definition of the usual Euclidean division   *)
(* for coefficients in a field. Only the definition of the pseudo-division    *)
(* for coefficients in an integral domain is exported by default and benefits *)
(* from notations.                                                            *)
(* Also, the only theory exported by default is the one of division for       *)
(* polynomials with coefficients in a field.                                  *)
(* Other definitions and facts are qualified using name spaces indicating the *)
(* hypotheses made on the structure of coefficients and the properties of the *)
(* polynomial one divides with.                                               *)
(*                                                                            *)
(* Pdiv.Field (exported by the present library):                              *)
(*          edivp p q == pseudo-division of p by q with p q : {poly R} where  *)
(*                       R is an idomainType.                                 *)
(*                       Computes (k, quo, rem) : nat * {poly r} * {poly R},  *)
(*                       such that size rem < size q and:                     *)
(*                       + if lead_coef q is not a unit, then:                *)
(*                         (lead_coef q ^+ k) *: p = q * quo + rem            *)
(*                       + else if lead_coef q is a unit, then:               *)
(*                         p = q * quo + rem and k = 0                        *)
(*             p %/ q == quotient (second component) computed by (edivp p q). *)
(*             p %% q == remainder (third component) computed by (edivp p q). *)
(*          scalp p q == exponent (first component) computed by (edivp p q).  *)
(*             p %| q == tests the nullity of the remainder of the            *)
(*                       pseudo-division of p by q.                           *)
(*         rgcdp p q  == Pseudo-greater common divisor obtained by performing *)
(*                       the Euclidean algorithm on p and q using redivp as   *)
(*                       Euclidean division.                                  *)
(*             p %= q == p and q are associate polynomials, i.e., p %| q and  *)
(*                       q %| p, or equivalently, p = c *: q for some nonzero *)
(*                       constant c.                                          *)
(*           gcdp p q == Pseudo-greater common divisor obtained by performing *)
(*                       the Euclidean algorithm on p and q using  edivp as   *)
(*                       Euclidean division.                                  *)
(*          egcdp p q == The pair of Bezout coefficients: if e := egcdp p q,  *)
(*                       then size e.1 <= size q, size e.2 <= size p, and     *)
(*                       gcdp p q %= e.1 * p + e.2 * q                        *)
(*       coprimep p q == p and q are coprime, i.e., (gcdp p q) is a nonzero   *)
(*                       constant.                                            *)
(*          gdcop q p == greatest divisor of p which is coprime to q.         *)
(* irreducible_poly p <-> p has only trivial (constant) divisors.             *)
(*            mup x q == multplicity of x as a root of q                      *)
(*                                                                            *)
(* Pdiv.Idomain: theory available for edivp and the related operation under   *)
(*    the sole assumption that the ring of coefficients is canonically an     *)
(*    integral domain (R : idomainType).                                      *)
(*                                                                            *)
(* Pdiv.IdomainMonic:  theory available for edivp and the related operations  *)
(*    under the assumption that the ring of coefficients is canonically       *)
(*    and integral domain (R : idomainType) an the divisor is monic.          *)
(*                                                                            *)
(* Pdiv.IdomainUnit: theory available for edivp and the related operations    *)
(*    under the assumption that the ring of coefficients is canonically an    *)
(*    integral domain (R : idomainType) and the leading coefficient of the    *)
(*    divisor is a unit.                                                      *)
(*                                                                            *)
(* Pdiv.ClosedField: theory available for edivp and the related operation     *)
(*    under the sole assumption that the ring of coefficients is canonically  *)
(*    an algebraically closed field (R : closedField).                        *)
(*                                                                            *)
(*  Pdiv.Ring :                                                               *)
(*   redivp p q == pseudo-division of p by q with p q : {poly R} where R is   *)
(*                 a nzRingType.                                              *)
(*                 Computes (k, quo, rem) : nat * {poly r} * {poly R},        *)
(*                 such that if rem = 0 then quo * q = p * (lead_coef q ^+ k) *)
(*                                                                            *)
(*   rdivp p q  == quotient (second component) computed by (redivp p q).      *)
(*   rmodp p q  == remainder (third component) computed by (redivp p q).      *)
(*   rscalp p q == exponent (first component) computed by (redivp p q).       *)
(*   rdvdp p q  == tests the nullity of the remainder of the pseudo-division  *)
(*                 of p by q.                                                 *)
(*   rgcdp p q  == analogue of gcdp for coefficients in a nzRingType.         *)
(*   rgdcop p q == analogue of gdcop for coefficients in a nzRingType.        *)
(*rcoprimep p q == analogue of coprimep p q for coefficients in a nzRingType. *)
(*                                                                            *)
(* Pdiv.RingComRreg : theory of the operations defined in Pdiv.Ring, when the *)
(*   ring of coefficients is canonically commutative (R : comNzRingType) and  *)
(*   the leading coefficient of the divisor is both right regular and         *)
(*   commutes as a constant polynomial with the divisor itself                *)
(*                                                                            *)
(* Pdiv.RingMonic : theory of the operations defined in Pdiv.Ring, under the  *)
(*   assumption that the divisor is monic.                                    *)
(*                                                                            *)
(* Pdiv.UnitRing: theory of the operations defined in Pdiv.Ring, when the     *)
(*   ring R of coefficients is canonically with units (R : unitRingType).     *)
(*                                                                            *)
(******************************************************************************)

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Import GRing.Theory.
Local Open Scope ring_scope.

Reserved Notation "p %= q" (at level 70, no associativity).

Local Notation simp := Monoid.simpm.

Module Pdiv.

Module CommonRing.

Section RingPseudoDivision.

Variable R : nzRingType.
Implicit Types d p q r : {poly R}.

(* Pseudo division, defined on an arbitrary ring *)
Definition redivp_rec (q : {poly R}) :=
  let sq := size q in
  let cq := lead_coef q in
   fix loop (k : nat) (qq r : {poly R})(n : nat) {struct n} :=
    if size r < sq then (k, qq, r) else
    let m := (lead_coef r) *: 'X^(size r - sq) in
    let qq1 := qq * cq%:P + m in
    let r1 := r * cq%:P - m * q in
       if n is n1.+1 then loop k.+1 qq1 r1 n1 else (k.+1, qq1, r1).

Definition redivp_expanded_def p q :=
   if q == 0 then (0, 0, p) else redivp_rec q 0 0 p (size p).
Fact redivp_key : unit. Proof. by []. Qed.
Definition redivp : {poly R} -> {poly R} -> nat * {poly R} * {poly R} :=
  locked_with redivp_key redivp_expanded_def.
Canonical redivp_unlockable := [unlockable fun redivp].

Definition rdivp p q := ((redivp p q).1).2.
Definition rmodp p q := (redivp p q).2.
Definition rscalp p q := ((redivp p q).1).1.
Definition rdvdp p q := rmodp q p == 0.
(*Definition rmultp := [rel m d | rdvdp d m].*)
Lemma redivp_def p q : redivp p q = (rscalp p q, rdivp p q, rmodp p q).
Proof. by rewrite /rscalp /rdivp /rmodp; case: (redivp p q) => [[]] /=. Qed.

Lemma rdiv0p p : rdivp 0 p = 0.
Proof.
rewrite /rdivp unlock; case: ifP => // Hp; rewrite /redivp_rec !size_poly0.
by rewrite polySpred ?Hp.
Qed.

Lemma rdivp0 p : rdivp p 0 = 0. Proof. by rewrite /rdivp unlock eqxx. Qed.

Lemma rdivp_small p q : size p < size q -> rdivp p q = 0.
Proof.
rewrite /rdivp unlock; have [-> | _ ltpq] := eqP; first by rewrite size_poly0.
by case: (size p) => [|s]; rewrite /= ltpq.
Qed.

Lemma leq_rdivp p q : size (rdivp p q) <= size p.
Proof.
have [/rdivp_small->|] := ltnP (size p) (size q); first by rewrite size_poly0.
rewrite /rdivp /rmodp /rscalp unlock.
have [->|q0] //= := eqVneq q 0.
have: size (0 : {poly R}) <= size p by rewrite size_poly0.
move: {2 3 4 6}(size p) (leqnn (size p)) => A.
elim: (size p) 0%N (0 : {poly R}) {1 3 4}p (leqnn (size p)) => [|n ihn] k q1 r.
  by move/size_poly_leq0P->; rewrite /= size_poly0 size_poly_gt0 q0.
move=> /= hrn hr hq1 hq; case: ltnP => //= hqr.
have sq: 0 < size q by rewrite size_poly_gt0.
have sr: 0 < size r by apply: leq_trans sq hqr.
apply: ihn => //.
- apply/leq_sizeP => j hnj.
  rewrite coefB -scalerAl coefZ coefXnM ltn_subRL ltnNge.
  have hj : (size r).-1 <= j by apply: leq_trans hnj; rewrite -ltnS prednK.
  rewrite [leqLHS]polySpred -?size_poly_gt0 // coefMC.
  rewrite (leq_ltn_trans hj) /=; last by rewrite -add1n leq_add2r.
  move: hj; rewrite leq_eqVlt prednK // => /predU1P [<- | hj].
    by rewrite -subn1 subnAC subKn // !subn1 !lead_coefE subrr.
  have/leq_sizeP-> //: size q <= j - (size r - size q).
    by rewrite subnBA // leq_psubRL // leq_add2r.
  by move/leq_sizeP: (hj) => -> //; rewrite mul0r mulr0 subr0.
- apply: leq_trans (size_polyD _ _) _; rewrite geq_max; apply/andP; split.
    apply: leq_trans (size_polyMleq _ _) _.
    by rewrite size_polyC lead_coef_eq0 q0 /= addn1.
  rewrite size_polyN; apply: leq_trans (size_polyMleq _ _) _.
  apply: leq_trans hr; rewrite -subn1 leq_subLR -[in (1 + _)%N](subnK hqr).
  by rewrite addnA leq_add2r add1n -(@size_polyXn R) size_scale_leq.
apply: leq_trans (size_polyD _ _) _; rewrite geq_max; apply/andP; split.
  apply: leq_trans (size_polyMleq _ _) _.
  by rewrite size_polyC lead_coef_eq0 q0 /= addnS addn0.
apply: leq_trans (size_scale_leq _ _) _.
by rewrite size_polyXn -subSn // leq_subLR -add1n leq_add.
Qed.

Lemma rmod0p p : rmodp 0 p = 0.
Proof.
rewrite /rmodp unlock; case: ifP => // Hp; rewrite /redivp_rec !size_poly0.
by rewrite polySpred ?Hp.
Qed.

Lemma rmodp0 p : rmodp p 0 = p. Proof. by rewrite /rmodp unlock eqxx. Qed.

Lemma rscalp_small p q : size p < size q -> rscalp p q = 0.
Proof.
rewrite /rscalp unlock; case: eqP => _ // spq.
by case sp: (size p) => [| s] /=; rewrite spq.
Qed.

Lemma ltn_rmodp p q : (size (rmodp p q) < size q) = (q != 0).
Proof.
rewrite /rdivp /rmodp /rscalp unlock; have [->|q0] := eqVneq q 0.
  by rewrite /= size_poly0 ltn0.
elim: (size p) 0%N 0 {1 3}p (leqnn (size p)) => [|n ihn] k q1 r.
  move/size_poly_leq0P->.
  by rewrite /= size_poly0 size_poly_gt0 q0 size_poly0 size_poly_gt0.
move=> hr /=; case: (ltnP (size r)) => // hsrq; apply/ihn/leq_sizeP => j hnj.
rewrite coefB -scalerAl !coefZ coefXnM coefMC ltn_subRL ltnNge.
have sq: 0 < size q by rewrite size_poly_gt0.
have sr: 0 < size r by apply: leq_trans hsrq.
have hj: (size r).-1 <= j by apply: leq_trans hnj; rewrite -ltnS prednK.
move: (leq_add sq hj); rewrite add1n prednK // => -> /=.
move: hj; rewrite leq_eqVlt prednK // => /predU1P [<- | hj].
  by rewrite -predn_sub subKn // !lead_coefE subrr.
have/leq_sizeP -> //: size q <= j - (size r - size q).
  by rewrite subnBA // leq_subRL ?leq_add2r // (leq_trans hj) // leq_addr.
by move/leq_sizeP: hj => -> //; rewrite mul0r mulr0 subr0.
Qed.

Lemma ltn_rmodpN0 p q : q != 0 -> size (rmodp p q) < size q.
Proof. by rewrite ltn_rmodp. Qed.

Lemma rmodp1 p : rmodp p 1 = 0.
Proof.
apply/eqP; have := ltn_rmodp p 1.
by rewrite !oner_neq0 -size_poly_eq0 size_poly1 ltnS leqn0.
Qed.

Lemma rmodp_small p q : size p < size q -> rmodp p q = p.
Proof.
rewrite /rmodp unlock; have [->|_] := eqP; first by rewrite size_poly0.
by case sp: (size p) => [| s] Hs /=; rewrite sp Hs /=.
Qed.

Lemma leq_rmodp m d : size (rmodp m d) <= size m.
Proof.
have [/rmodp_small -> //|h] := ltnP (size m) (size d).
have [->|d0] := eqVneq d 0; first by rewrite rmodp0.
by apply: leq_trans h; apply: ltnW; rewrite ltn_rmodp.
Qed.

Lemma rmodpC p c : c != 0 -> rmodp p c%:P = 0.
Proof.
move=> Hc; apply/eqP; rewrite -size_poly_leq0 -ltnS.
have -> : 1%N = nat_of_bool (c != 0) by rewrite Hc.
by rewrite -size_polyC ltn_rmodp polyC_eq0.
Qed.

Lemma rdvdp0 d : rdvdp d 0. Proof. by rewrite /rdvdp rmod0p. Qed.

Lemma rdvd0p n : rdvdp 0 n = (n == 0). Proof. by rewrite /rdvdp rmodp0. Qed.

Lemma rdvd0pP n : reflect (n = 0) (rdvdp 0 n).
Proof. by apply: (iffP idP); rewrite rdvd0p; move/eqP. Qed.

Lemma rdvdpN0 p q : rdvdp p q -> q != 0 -> p != 0.
Proof. by move=> pq hq; apply: contraTneq pq => ->; rewrite rdvd0p. Qed.

Lemma rdvdp1 d : rdvdp d 1 = (size d == 1).
Proof.
rewrite /rdvdp; have [->|] := eqVneq d 0.
  by rewrite rmodp0 size_poly0 (negPf (oner_neq0 _)).
rewrite -size_poly_leq0 -ltnS; case: ltngtP => // [|/eqP] hd _.
  by rewrite rmodp_small ?size_poly1 // oner_eq0.
have [c cn0 ->] := size_poly1P _ hd.
rewrite /rmodp unlock -size_poly_eq0 size_poly1 /= size_poly1 size_polyC cn0 /=.
by rewrite polyC_eq0 (negPf cn0) !lead_coefC !scale1r subrr !size_poly0.
Qed.

Lemma rdvd1p m : rdvdp 1 m. Proof. by rewrite /rdvdp rmodp1. Qed.

Lemma Nrdvdp_small (n d : {poly R}) :
  n != 0 -> size n < size d -> rdvdp d n = false.
Proof. by move=> nn0 hs; rewrite /rdvdp (rmodp_small hs); apply: negPf. Qed.

Lemma rmodp_eq0P p q : reflect (rmodp p q = 0) (rdvdp q p).
Proof. exact: (iffP eqP). Qed.

Lemma rmodp_eq0 p q : rdvdp q p -> rmodp p q = 0. Proof. exact: rmodp_eq0P. Qed.

Lemma rdvdp_leq p q : rdvdp p q -> q != 0 -> size p <= size q.
Proof. by move=> dvd_pq; rewrite leqNgt; apply: contra => /rmodp_small <-. Qed.

Definition rgcdp p q :=
  let: (p1, q1) := if size p < size q then (q, p) else (p, q) in
  if p1 == 0 then q1 else
  let fix loop (n : nat) (pp qq : {poly R}) {struct n} :=
      let rr := rmodp pp qq in
      if rr == 0 then qq else
      if n is n1.+1 then loop n1 qq rr else rr in
  loop (size p1) p1 q1.

Lemma rgcd0p : left_id 0 rgcdp.
Proof.
move=> p; rewrite /rgcdp size_poly0 size_poly_gt0 if_neg.
case: ifP => /= [_ | nzp]; first by rewrite eqxx.
by rewrite polySpred !(rmodp0, nzp) //; case: _.-1 => [|m]; rewrite rmod0p eqxx.
Qed.

Lemma rgcdp0 : right_id 0 rgcdp.
Proof.
move=> p; have:= rgcd0p p; rewrite /rgcdp size_poly0 size_poly_gt0.
by case: eqVneq => p0; rewrite ?(eqxx, p0) //= eqxx.
Qed.

Lemma rgcdpE p q :
  rgcdp p q = if size p < size q
    then rgcdp (rmodp q p) p else rgcdp (rmodp p q) q.
Proof.
pose rgcdp_rec := fix rgcdp_rec (n : nat) (pp qq : {poly R}) {struct n} :=
   let rr := rmodp pp qq in
   if rr == 0 then qq else
   if n is n1.+1 then rgcdp_rec n1 qq rr else rr.
have Irec: forall m n p q, size q <= m -> size q <= n
      -> size q < size p -> rgcdp_rec m p q = rgcdp_rec n p q.
  + elim=> [|m Hrec] [|n] //= p1 q1.
    - move/size_poly_leq0P=> -> _; rewrite size_poly0 size_poly_gt0 rmodp0.
      by move/negPf->; case: n => [|n] /=; rewrite rmod0p eqxx.
    - move=> _ /size_poly_leq0P ->; rewrite size_poly0 size_poly_gt0 rmodp0.
      by move/negPf->; case: m {Hrec} => [|m] /=; rewrite rmod0p eqxx.
  case: eqVneq => Epq Sm Sn Sq //; have [->|nzq] := eqVneq q1 0.
    by case: n m {Sm Sn Hrec} => [|m] [|n] //=; rewrite rmod0p eqxx.
  apply: Hrec; last by rewrite ltn_rmodp.
    by rewrite -ltnS (leq_trans _ Sm) // ltn_rmodp.
  by rewrite -ltnS (leq_trans _ Sn) // ltn_rmodp.
have [->|nzp] := eqVneq p 0.
  by rewrite rmod0p rmodp0 rgcd0p rgcdp0 if_same.
have [->|nzq] := eqVneq q 0.
  by rewrite rmod0p rmodp0 rgcd0p rgcdp0 if_same.
rewrite /rgcdp -/rgcdp_rec !ltn_rmodp (negPf nzp) (negPf nzq) /=.
have [ltpq|leqp] := ltnP; rewrite !(negPf nzp, negPf nzq) //= polySpred //=.
  have [->|nzqp] := eqVneq.
    by case: (size p) => [|[|s]]; rewrite /= rmodp0 (negPf nzp) // rmod0p eqxx.
  apply: Irec => //; last by rewrite ltn_rmodp.
    by rewrite -ltnS -polySpred // (leq_trans _ ltpq) ?leqW // ltn_rmodp.
  by rewrite ltnW // ltn_rmodp.
have [->|nzpq] := eqVneq.
  by case: (size q) => [|[|s]]; rewrite /= rmodp0 (negPf nzq) // rmod0p eqxx.
apply: Irec => //; last by rewrite ltn_rmodp.
  by rewrite -ltnS -polySpred // (leq_trans _ leqp) // ltn_rmodp.
by rewrite ltnW // ltn_rmodp.
Qed.

Variant comm_redivp_spec m d : nat * {poly R} * {poly R} -> Type :=
  ComEdivnSpec k (q r : {poly R}) of
   (GRing.comm d (lead_coef d)%:P -> m * (lead_coef d ^+ k)%:P = q * d + r) &
   (d != 0 -> size r < size d) : comm_redivp_spec m d (k, q, r).

Lemma comm_redivpP m d : comm_redivp_spec m d (redivp m d).
Proof.
rewrite unlock; have [->|Hd] := eqVneq d 0.
  by constructor; rewrite !(simp, eqxx).
have: GRing.comm d (lead_coef d)%:P -> m * (lead_coef d ^+ 0)%:P = 0 * d + m.
  by rewrite !simp.
elim: (size m) 0%N 0 {1 4 6}m (leqnn (size m)) => [|n IHn] k q r Hr /=.
  move/size_poly_leq0P: Hr ->.
  suff hsd: size (0: {poly R}) < size d by rewrite hsd => /= ?; constructor.
  by rewrite size_poly0 size_poly_gt0.
case: ltnP => Hlt Heq; first by constructor.
apply/IHn=> [|Cda]; last first.
  rewrite mulrDl addrAC -addrA subrK exprSr polyCM mulrA Heq //.
  by rewrite mulrDl -mulrA Cda mulrA.
apply/leq_sizeP => j Hj; rewrite coefB coefMC -scalerAl coefZ coefXnM.
rewrite ltn_subRL ltnNge (leq_trans Hr) /=; last first.
  by apply: leq_ltn_trans Hj _; rewrite -add1n leq_add2r size_poly_gt0.
move: Hj; rewrite leq_eqVlt; case/predU1P => [<-{j} | Hj]; last first.
  rewrite !nth_default ?simp ?oppr0 ?(leq_trans Hr) //.
  by rewrite -{1}(subKn Hlt) leq_sub2r // (leq_trans Hr).
move: Hr; rewrite leq_eqVlt ltnS; case/predU1P=> Hqq; last first.
  by rewrite !nth_default ?simp ?oppr0 // -{1}(subKn Hlt) leq_sub2r.
rewrite /lead_coef Hqq polySpred // subSS subKn ?addrN //.
by rewrite -subn1 leq_subLR add1n -Hqq.
Qed.

Lemma rmodpp p : GRing.comm p (lead_coef p)%:P -> rmodp p p = 0.
Proof.
move=> hC; rewrite /rmodp unlock; have [-> //|] := eqVneq.
rewrite -size_poly_eq0 /redivp_rec; case sp: (size p)=> [|n] // _.
rewrite sp ltnn subnn expr0 hC alg_polyC !simp subrr.
by case: n sp => [|n] sp; rewrite size_polyC /= eqxx.
Qed.

Definition rcoprimep (p q : {poly R}) := size (rgcdp p q) == 1.

Fixpoint rgdcop_rec q p n :=
  if n is m.+1 then
      if rcoprimep p q then p
        else rgdcop_rec q (rdivp p (rgcdp p q)) m
    else (q == 0)%:R.

Definition rgdcop q p := rgdcop_rec q p (size p).

Lemma rgdcop0 q : rgdcop q 0 = (q == 0)%:R.
Proof. by rewrite /rgdcop size_poly0. Qed.

End RingPseudoDivision.

End CommonRing.

Module RingComRreg.

Import CommonRing.

Section ComRegDivisor.

Variable R : nzRingType.
Variable d : {poly R}.
Hypothesis Cdl : GRing.comm d (lead_coef d)%:P.
Hypothesis Rreg : GRing.rreg (lead_coef d).

Implicit Types p q r : {poly R}.

Lemma redivp_eq q r :
    size r < size d ->
    let k := (redivp (q * d + r) d).1.1 in
    let c := (lead_coef d ^+ k)%:P in
  redivp (q * d + r) d = (k, q * c, r * c).
Proof.
move=> lt_rd; case: comm_redivpP=> k q1 r1 /(_ Cdl) Heq.
have dn0: d != 0 by case: (size d) lt_rd (size_poly_eq0 d) => // n _ <-.
move=> /(_ dn0) Hs.
have eC : q * d * (lead_coef d ^+ k)%:P = q * (lead_coef d ^+ k)%:P * d.
  by rewrite -mulrA polyC_exp (commrX k Cdl) mulrA.
suff e1 : q1 = q * (lead_coef d ^+ k)%:P.
  congr (_, _, _) => //=; move/eqP: Heq.
  by rewrite [_ + r1]addrC -subr_eq e1 mulrDl addrAC eC subrr add0r; move/eqP.
have : (q1 - q * (lead_coef d ^+ k)%:P) * d = r * (lead_coef d ^+ k)%:P - r1.
  apply: (@addIr _ r1); rewrite subrK.
  apply: (@addrI _ ((q * (lead_coef d ^+ k)%:P) * d)).
  by rewrite mulrDl mulNr !addrA [_ + (q1 * d)]addrC addrK -eC -mulrDl.
move/eqP; rewrite -[_ == _ - _]subr_eq0 rreg_div0 //.
  by case/andP; rewrite subr_eq0; move/eqP.
rewrite size_polyN; apply: (leq_ltn_trans (size_polyD _ _)); rewrite size_polyN.
rewrite gtn_max Hs (leq_ltn_trans (size_polyMleq _ _)) //.
rewrite size_polyC; case: (_ == _); last by rewrite addnS addn0.
by rewrite addn0; apply: leq_ltn_trans lt_rd; case: size.
Qed.

(* this is a bad name *)
Lemma rdivp_eq p :
  p * (lead_coef d ^+ (rscalp p d))%:P = (rdivp p d) * d + (rmodp p d).
Proof.
by rewrite /rdivp /rmodp /rscalp; case: comm_redivpP=> k q1 r1 Hc _; apply: Hc.
Qed.

(* section variables impose an inconvenient order on parameters *)
Lemma eq_rdvdp k q1 p:
  p * ((lead_coef d)^+ k)%:P = q1 * d -> rdvdp d p.
Proof.
move=> he.
have Hnq0 := rreg_lead0 Rreg; set lq := lead_coef d.
pose v := rscalp p d; pose m := maxn v k.
rewrite /rdvdp -(rreg_polyMC_eq0 _ (@rregX _ _ (m - v) Rreg)).
suff:
 ((rdivp p d) * (lq ^+ (m - v))%:P - q1 * (lq ^+ (m - k))%:P) * d +
  (rmodp p d) * (lq ^+ (m - v))%:P == 0.
  rewrite rreg_div0 //; first by case/andP.
  by rewrite rreg_size ?ltn_rmodp //; exact: rregX.
rewrite mulrDl addrAC mulNr -!mulrA polyC_exp -(commrX (m-v) Cdl).
rewrite -polyC_exp mulrA -mulrDl -rdivp_eq // [(_ ^+ (m - k))%:P]polyC_exp.
rewrite -(commrX (m-k) Cdl) -polyC_exp mulrA -he -!mulrA -!polyCM -/v.
by rewrite -!exprD addnC subnK ?leq_maxl // addnC subnK ?subrr ?leq_maxr.
Qed.

Variant rdvdp_spec p q : {poly R} -> bool -> Type :=
  | Rdvdp k q1 & p * ((lead_coef q)^+ k)%:P = q1 * q : rdvdp_spec p q 0 true
  | RdvdpN & rmodp p q != 0 : rdvdp_spec p q (rmodp p q) false.

(* Is that version useable ? *)

Lemma rdvdp_eqP p : rdvdp_spec p d (rmodp p d) (rdvdp d p).
Proof.
case hdvd: (rdvdp d p); last by apply: RdvdpN; move/rmodp_eq0P/eqP: hdvd.
move/rmodp_eq0P: (hdvd)->; apply: (@Rdvdp _ _ (rscalp p d) (rdivp p d)).
by rewrite rdivp_eq //; move/rmodp_eq0P: (hdvd)->; rewrite addr0.
Qed.

Lemma rdvdp_mull p : rdvdp d (p * d).
Proof. by apply: (@eq_rdvdp 0 p); rewrite expr0 mulr1. Qed.

Lemma rmodp_mull p : rmodp (p * d) d = 0. Proof. exact/eqP/rdvdp_mull. Qed.

Lemma rmodpp : rmodp d d = 0.
Proof. by rewrite -[d in rmodp d _]mul1r rmodp_mull. Qed.

Lemma rdivpp : rdivp d d = (lead_coef d ^+ rscalp d d)%:P.
Proof.
have dn0 : d != 0 by rewrite -lead_coef_eq0 rreg_neq0.
move: (rdivp_eq d); rewrite rmodpp addr0.
suff ->: GRing.comm d (lead_coef d ^+ rscalp d d)%:P by move/(rreg_lead Rreg)->.
by rewrite polyC_exp; apply: commrX.
Qed.

Lemma rdvdpp : rdvdp d d. Proof. exact/eqP/rmodpp. Qed.

Lemma rdivpK p : rdvdp d p ->
  rdivp p d * d = p * (lead_coef d ^+ rscalp p d)%:P.
Proof. by rewrite rdivp_eq /rdvdp; move/eqP->; rewrite addr0. Qed.

End ComRegDivisor.

End RingComRreg.

Module RingMonic.

Import CommonRing.

Import RingComRreg.

Section RingMonic.

Variable R : nzRingType.
Implicit Types p q r : {poly R}.

Section MonicDivisor.

Variable d : {poly R}.
Hypothesis mond : d \is monic.

Lemma redivp_eq q r : size r < size d ->
  let k := (redivp (q * d + r) d).1.1 in
  redivp (q * d + r) d = (k, q, r).
Proof.
case: (monic_comreg mond)=> Hc Hr /(redivp_eq Hc Hr q).
by rewrite (eqP mond) => -> /=; rewrite expr1n !mulr1.
Qed.

Lemma rdivp_eq p : p = rdivp p d * d + rmodp p d.
Proof.
rewrite -rdivp_eq (eqP mond); last exact: commr1.
by rewrite expr1n mulr1.
Qed.

Lemma rdivpp : rdivp d d = 1.
Proof.
by case: (monic_comreg mond) => hc hr; rewrite rdivpp // (eqP mond) expr1n.
Qed.

Lemma rdivp_addl_mul_small q r : size r < size d -> rdivp (q * d + r) d = q.
Proof.
by move=> Hd; case: (monic_comreg mond)=> Hc Hr; rewrite /rdivp redivp_eq.
Qed.

Lemma rdivp_addl_mul q r : rdivp (q * d + r) d = q + rdivp r d.
Proof.
case: (monic_comreg mond)=> Hc Hr; rewrite [r in _ * _ + r]rdivp_eq addrA.
by rewrite -mulrDl rdivp_addl_mul_small // ltn_rmodp monic_neq0.
Qed.

Lemma rdivpDl q r : rdvdp d q -> rdivp (q + r) d = rdivp q d + rdivp r d.
Proof.
case: (monic_comreg mond)=> Hc Hr; rewrite [r in q + r]rdivp_eq addrA.
rewrite [q in q + _ + _]rdivp_eq; move/rmodp_eq0P->.
by rewrite addr0 -mulrDl rdivp_addl_mul_small // ltn_rmodp monic_neq0.
Qed.

Lemma rdivpDr q r : rdvdp d r -> rdivp (q + r) d = rdivp q d + rdivp r d.
Proof. by rewrite addrC; move/rdivpDl->; rewrite addrC. Qed.

Lemma rdivp_mull p : rdivp (p * d) d = p.
Proof. by rewrite -[p * d]addr0 rdivp_addl_mul rdiv0p addr0. Qed.

Lemma rmodp_mull p : rmodp (p * d) d = 0.
Proof.
by apply: rmodp_mull; rewrite (eqP mond); [apply: commr1 | apply: rreg1].
Qed.

Lemma rmodpp : rmodp d d = 0.
Proof.
by apply: rmodpp; rewrite (eqP mond); [apply: commr1 | apply: rreg1].
Qed.

Lemma rmodp_addl_mul_small q r : size r < size d -> rmodp (q * d + r) d = r.
Proof.
by move=> Hd; case: (monic_comreg mond)=> Hc Hr; rewrite /rmodp redivp_eq.
Qed.

Lemma rmodp_id (p : {poly R}) : rmodp (rmodp p d) d = rmodp p d.
Proof.
by rewrite rmodp_small // ltn_rmodpN0 // monic_neq0.
Qed.

Lemma rmodpD p q : rmodp (p + q) d = rmodp p d + rmodp q d.
Proof.
rewrite [p in LHS]rdivp_eq [q in LHS]rdivp_eq addrACA -mulrDl.
rewrite rmodp_addl_mul_small //; apply: (leq_ltn_trans (size_polyD _ _)).
by rewrite gtn_max !ltn_rmodp // monic_neq0.
Qed.

Lemma rmodpN p : rmodp (- p) d = - (rmodp p d).
Proof.
rewrite {1}(rdivp_eq p) opprD // -mulNr rmodp_addl_mul_small //.
by rewrite size_polyN ltn_rmodp // monic_neq0.
Qed.

Lemma rmodpB p q : rmodp (p - q) d = rmodp p d - rmodp q d.
Proof. by rewrite rmodpD rmodpN. Qed.

Lemma rmodpZ a p : rmodp (a *: p) d = a *: (rmodp p d).
Proof.
case: (altP (a =P 0%R)) => [-> | cn0]; first by rewrite !scale0r rmod0p.
have -> : ((a *: p) = (a *: (rdivp p d)) * d + a *: (rmodp p d))%R.
  by rewrite -scalerAl -scalerDr -rdivp_eq.
rewrite  rmodp_addl_mul_small //.
rewrite -mul_polyC; apply: leq_ltn_trans (size_polyMleq _ _) _.
  rewrite size_polyC cn0 addSn add0n /= ltn_rmodp.
exact: monic_neq0.
Qed.

Lemma rmodp_sum (I : Type) (r : seq I) (P : pred I) (F : I -> {poly R}) :
   rmodp (\sum_(i <- r | P i) F i) d = (\sum_(i <- r | P i) (rmodp (F i) d)).
Proof.
by elim/big_rec2: _ => [|i p q _ <-]; rewrite ?(rmod0p, rmodpD).
Qed.

Lemma rmodp_mulmr p q : rmodp (p * (rmodp q d)) d = rmodp (p * q) d.
Proof.
by rewrite [q in RHS]rdivp_eq mulrDr rmodpD mulrA rmodp_mull add0r.
Qed.

Lemma rdvdpp : rdvdp d d.
Proof.
by apply: rdvdpp; rewrite (eqP mond); [apply: commr1 | apply: rreg1].
Qed.

(* section variables impose an inconvenient order on parameters *)
Lemma eq_rdvdp q1 p : p = q1 * d -> rdvdp d p.
Proof.
(*  this probably means I need to specify impl args for comm_rref_rdvdp *)
move=> h; apply: (@eq_rdvdp _ _ _ _ 1 q1); rewrite (eqP mond).
- exact: commr1.
- exact: rreg1.
by rewrite expr1n mulr1.
Qed.

Lemma rdvdp_mull p : rdvdp d (p * d).
Proof.
by apply: rdvdp_mull; rewrite (eqP mond) //; [apply: commr1 | apply: rreg1].
Qed.

Lemma rdvdpP p : reflect (exists qq, p = qq * d) (rdvdp d p).
Proof.
case: (monic_comreg mond)=> Hc Hr; apply: (iffP idP) => [|[qq] /eq_rdvdp //].
by case: rdvdp_eqP=> // k qq; rewrite (eqP mond) expr1n mulr1 => ->; exists qq.
Qed.

Lemma rdivpK p : rdvdp d p -> (rdivp p d) * d = p.
Proof. by move=> dvddp; rewrite [RHS]rdivp_eq rmodp_eq0 ?addr0. Qed.

End MonicDivisor.

Lemma drop_poly_rdivp n p : drop_poly n p = rdivp p 'X^n.
Proof.
rewrite -[p in RHS](poly_take_drop n) addrC rdivp_addl_mul ?monicXn//.
by rewrite rdivp_small ?addr0// size_polyXn ltnS size_take_poly.
Qed.

Lemma take_poly_rmodp n p : take_poly n p = rmodp p 'X^n.
Proof.
have mX := monicXn R n; rewrite -[p in RHS](poly_take_drop n) rmodpD//.
by rewrite rmodp_small ?rmodp_mull ?addr0// size_polyXn ltnS size_take_poly.
Qed.

End RingMonic.

Section ComRingMonic.

Variable R : comNzRingType.
Implicit Types p q r : {poly R}.
Variable d : {poly R}.
Hypothesis mond : d \is monic.

Lemma rmodp_mulml p q : rmodp (rmodp p d * q) d = rmodp (p * q) d.
Proof. by rewrite [in LHS]mulrC [in RHS]mulrC rmodp_mulmr. Qed.

Lemma rmodpX p n : rmodp ((rmodp p d) ^+ n) d = rmodp (p ^+ n) d.
Proof.
elim: n => [|n IH]; first by rewrite !expr0.
rewrite !exprS -rmodp_mulmr // IH rmodp_mulmr //.
by rewrite mulrC rmodp_mulmr // mulrC.
Qed.

Lemma rmodp_compr p q : rmodp (p \Po (rmodp q d)) d = (rmodp (p \Po q) d).
Proof.
elim/poly_ind: p => [|p c IH]; first by rewrite !comp_polyC !rmod0p.
rewrite !comp_polyD !comp_polyM addrC rmodpD //.
  rewrite mulrC -rmodp_mulmr // IH rmodp_mulmr //.
  rewrite !comp_polyX !comp_polyC.
by rewrite mulrC rmodp_mulmr // -rmodpD // addrC.
Qed.

End ComRingMonic.

End RingMonic.

Module Ring.

Include CommonRing.
Import RingMonic.

Section ExtraMonicDivisor.

Variable R : nzRingType.

Implicit Types d p q r : {poly R}.

Lemma rdivp1 p : rdivp p 1 = p.
Proof. by rewrite -[p in LHS]mulr1 rdivp_mull // monic1. Qed.

Lemma rdvdp_XsubCl p x : rdvdp ('X - x%:P) p = root p x.
Proof.
have [HcX Hr] := monic_comreg (monicXsubC x).
apply/rmodp_eq0P/factor_theorem => [|[p1 ->]]; last exact/rmodp_mull/monicXsubC.
move=> e0; exists (rdivp p ('X - x%:P)).
by rewrite [LHS](rdivp_eq (monicXsubC x)) e0 addr0.
Qed.

Lemma polyXsubCP p x : reflect (p.[x] = 0) (rdvdp ('X - x%:P) p).
Proof. by apply: (iffP idP); rewrite rdvdp_XsubCl; move/rootP. Qed.

Lemma root_factor_theorem p x : root p x = (rdvdp ('X - x%:P) p).
Proof. by rewrite rdvdp_XsubCl. Qed.

End ExtraMonicDivisor.

End Ring.

Module ComRing.

Import Ring.

Import RingComRreg.

Section CommutativeRingPseudoDivision.

Variable R : comNzRingType.

Implicit Types d p q m n r : {poly R}.

Variant redivp_spec (m d : {poly R}) : nat * {poly R} * {poly R} -> Type :=
  EdivnSpec k (q r: {poly R}) of
    (lead_coef d ^+ k) *: m = q * d + r &
   (d != 0 -> size r < size d) : redivp_spec m d (k, q, r).

Lemma redivpP m d : redivp_spec m d (redivp m d).
Proof.
rewrite redivp_def; constructor; last by move=> dn0; rewrite ltn_rmodp.
by rewrite -mul_polyC mulrC rdivp_eq //= /GRing.comm mulrC.
Qed.

Lemma rdivp_eq d p :
  (lead_coef d ^+ rscalp p d) *: p = rdivp p d * d + rmodp p d.
Proof.
by rewrite /rdivp /rmodp /rscalp; case: redivpP=> k q1 r1 Hc _; apply: Hc.
Qed.

Lemma rdvdp_eqP d p : rdvdp_spec p d (rmodp p d) (rdvdp d p).
Proof.
case hdvd: (rdvdp d p); last by move/rmodp_eq0P/eqP/RdvdpN: hdvd.
move/rmodp_eq0P: (hdvd)->; apply: (@Rdvdp _ _ _ (rscalp p d) (rdivp p d)).
by rewrite mulrC mul_polyC rdivp_eq; move/rmodp_eq0P: (hdvd)->; rewrite addr0.
Qed.

Lemma rdvdp_eq q p :
  rdvdp q p = (lead_coef q ^+ rscalp p q *: p == rdivp p q * q).
Proof.
rewrite rdivp_eq; apply/rmodp_eq0P/eqP => [->|/eqP]; first by rewrite addr0.
by rewrite eq_sym addrC -subr_eq subrr; move/eqP<-.
Qed.

End CommutativeRingPseudoDivision.

End ComRing.

Module UnitRing.

Import Ring.

Section UnitRingPseudoDivision.

Variable R : unitRingType.
Implicit Type p q r d : {poly R}.

Lemma uniq_roots_rdvdp p rs :
  all (root p) rs -> uniq_roots rs -> rdvdp (\prod_(z <- rs) ('X - z%:P)) p.
Proof.
move=> rrs /(uniq_roots_prod_XsubC rrs) [q ->].
exact/RingMonic.rdvdp_mull/monic_prod_XsubC.
Qed.

End UnitRingPseudoDivision.

End UnitRing.

Module IdomainDefs.

Import Ring.

Section IDomainPseudoDivisionDefs.

Variable R : idomainType.
Implicit Type p q r d : {poly R}.

Definition edivp_expanded_def p q :=
  let: (k, d, r) as edvpq := redivp p q in
  if lead_coef q \in GRing.unit then
    (0, (lead_coef q)^-k *: d, (lead_coef q)^-k *: r)
  else edvpq.
Fact edivp_key : unit. Proof. by []. Qed.
Definition edivp := locked_with edivp_key edivp_expanded_def.
Canonical edivp_unlockable := [unlockable fun edivp].

Definition divp p q := ((edivp p q).1).2.
Definition modp p q := (edivp p q).2.
Definition scalp p q := ((edivp p q).1).1.
Definition dvdp p q := modp q p == 0.
Definition eqp p q := (dvdp p q) && (dvdp q p).

End IDomainPseudoDivisionDefs.

Notation "m %/ d" := (divp m d) : ring_scope.
Notation "m %% d" := (modp m d) : ring_scope.
Notation "p %| q" := (dvdp p q) : ring_scope.
Notation "p %= q" := (eqp p q) : ring_scope.
End IdomainDefs.

Module WeakIdomain.

Import Ring ComRing UnitRing IdomainDefs.

Section WeakTheoryForIDomainPseudoDivision.

Variable R : idomainType.
Implicit Type p q r d : {poly R}.

Lemma edivp_def p q : edivp p q = (scalp p q, divp p q, modp p q).
Proof. by rewrite /scalp /divp /modp; case: (edivp p q) => [[]] /=. Qed.

Lemma edivp_redivp p q : lead_coef q \in GRing.unit = false ->
  edivp p q = redivp p q.
Proof. by move=> hu; rewrite unlock hu; case: (redivp p q) => [[? ?] ?]. Qed.

Lemma divpE p q :
  p %/ q = if lead_coef q \in GRing.unit
    then lead_coef q ^- rscalp p q *: rdivp p q
    else rdivp p q.
Proof. by case: ifP; rewrite /divp unlock redivp_def => ->. Qed.

Lemma modpE p q :
  p %% q = if lead_coef q \in GRing.unit
    then lead_coef q ^- rscalp p q *: (rmodp p q)
    else rmodp p q.
Proof. by case: ifP; rewrite /modp unlock redivp_def => ->. Qed.

Lemma scalpE p q :
  scalp p q = if lead_coef q \in GRing.unit then 0 else rscalp p q.
Proof. by case: ifP; rewrite /scalp unlock redivp_def => ->. Qed.

Lemma dvdpE p q : p %| q = rdvdp p q.
Proof.
rewrite /dvdp modpE /rdvdp; case ulcq: (lead_coef p \in GRing.unit)=> //.
rewrite -[in LHS]size_poly_eq0 size_scale ?size_poly_eq0 //.
by rewrite invr_eq0 expf_neq0 //; apply: contraTneq ulcq => ->; rewrite unitr0.
Qed.

Lemma lc_expn_scalp_neq0 p q : lead_coef q ^+ scalp p q != 0.
Proof.
have [->|nzq] := eqVneq q 0; last by rewrite expf_neq0 ?lead_coef_eq0.
by rewrite /scalp 2!unlock /= eqxx lead_coef0 unitr0 /= oner_neq0.
Qed.

Hint Resolve lc_expn_scalp_neq0 : core.

Variant edivp_spec (m d : {poly R}) :
                                    nat * {poly R} * {poly R} -> bool -> Type :=
|Redivp_spec k (q r: {poly R}) of
  (lead_coef d ^+ k) *: m = q * d + r & lead_coef d \notin GRing.unit &
  (d != 0 -> size r < size d) : edivp_spec m d (k, q, r) false
|Fedivp_spec (q r: {poly R}) of m = q * d + r & (lead_coef d \in GRing.unit) &
  (d != 0 -> size r < size d) : edivp_spec m d (0, q, r) true.

(* There are several ways to state this fact. The most appropriate statement*)
(* might be polished in light of usage. *)
Lemma edivpP m d : edivp_spec m d (edivp m d) (lead_coef d \in GRing.unit).
Proof.
have hC : GRing.comm d (lead_coef d)%:P by rewrite /GRing.comm mulrC.
case ud: (lead_coef d \in GRing.unit); last first.
  rewrite edivp_redivp // redivp_def; constructor; rewrite ?ltn_rmodp // ?ud //.
  by rewrite rdivp_eq.
have cdn0: lead_coef d != 0 by apply: contraTneq ud => ->; rewrite unitr0.
rewrite unlock ud redivp_def; constructor => //.
  rewrite -scalerAl -scalerDr -mul_polyC.
  have hn0 : (lead_coef d ^+ rscalp m d)%:P != 0.
    by rewrite polyC_eq0; apply: expf_neq0.
  apply: (mulfI hn0); rewrite !mulrA -exprVn !polyC_exp -exprMn -polyCM.
  by rewrite divrr // expr1n mul1r -polyC_exp mul_polyC rdivp_eq.
move=> dn0; rewrite size_scale ?ltn_rmodp // -exprVn expf_eq0 negb_and.
by rewrite invr_eq0 cdn0 orbT.
Qed.

Lemma edivp_eq d q r : size r < size d -> lead_coef d \in GRing.unit ->
  edivp (q * d + r) d = (0, q, r).
Proof.
have hC : GRing.comm d (lead_coef d)%:P by apply: mulrC.
move=> hsrd hu; rewrite unlock hu; case et: (redivp _ _) => [[s qq] rr].
have cdn0 : lead_coef d != 0 by case: eqP hu => //= ->; rewrite unitr0.
move: (et); rewrite RingComRreg.redivp_eq //; last exact/rregP.
rewrite et /= mulrC (mulrC r) !mul_polyC; case=> <- <-.
by rewrite !scalerA mulVr ?scale1r // unitrX.
Qed.

Lemma divp_eq p q : (lead_coef q ^+ scalp p q) *: p = (p %/ q) * q + (p %% q).
Proof.
rewrite divpE modpE scalpE.
case uq: (lead_coef q \in GRing.unit); last by rewrite rdivp_eq.
rewrite expr0 scale1r; have [->|qn0] := eqVneq q 0.
  by rewrite lead_coef0 expr0n /rscalp unlock eqxx invr1 !scale1r rmodp0 !simp.
by rewrite -scalerAl -scalerDr -rdivp_eq scalerA mulVr (scale1r, unitrX).
Qed.

Lemma dvdp_eq q p : (q %| p) = (lead_coef q ^+ scalp p q *: p == (p %/ q) * q).
Proof.
rewrite dvdpE rdvdp_eq scalpE divpE; case: ifP => ulcq //.
rewrite expr0 scale1r -scalerAl; apply/eqP/eqP => [<- | {2}->].
  by rewrite scalerA mulVr ?scale1r // unitrX.
by rewrite scalerA mulrV ?scale1r // unitrX.
Qed.

Lemma divpK d p : d %| p -> p %/ d * d = (lead_coef d ^+ scalp p d) *: p.
Proof. by rewrite dvdp_eq; move/eqP->. Qed.

Lemma divpKC d p : d %| p -> d * (p %/ d) = (lead_coef d ^+ scalp p d) *: p.
Proof. by move=> ?; rewrite mulrC divpK. Qed.

Lemma dvdpP q p :
  reflect (exists2 cqq, cqq.1 != 0 & cqq.1 *: p = cqq.2 * q) (q %| p).
Proof.
rewrite dvdp_eq; apply: (iffP eqP) => [e | [[c qq] cn0 e]].
  by exists (lead_coef q ^+ scalp p q, p %/ q) => //=.
apply/eqP; rewrite -dvdp_eq dvdpE.
have Ecc: c%:P != 0 by rewrite polyC_eq0.
have [->|nz_p] := eqVneq p 0; first by rewrite rdvdp0.
pose p1 : {poly R} := lead_coef q ^+ rscalp p q *: qq - c *: (rdivp p q).
have E1: c *: rmodp p q = p1 * q.
  rewrite mulrDl mulNr -scalerAl -e scalerA mulrC -scalerA -scalerAl.
  by rewrite -scalerBr rdivp_eq addrC addKr.
suff: p1 * q == 0 by rewrite -E1 -mul_polyC mulf_eq0 (negPf Ecc).
rewrite mulf_eq0; apply/norP; case=> p1_nz q_nz; have:= ltn_rmodp p q.
by rewrite q_nz -(size_scale _ cn0) E1 size_mul // polySpred // ltnNge leq_addl.
Qed.

Lemma mulpK p q : q != 0 -> p * q %/ q = lead_coef q ^+ scalp (p * q) q *: p.
Proof.
move=> qn0; apply: (rregP qn0); rewrite -scalerAl divp_eq.
suff -> : (p * q) %% q = 0 by rewrite addr0.
rewrite modpE RingComRreg.rmodp_mull ?scaler0 ?if_same //.
  by red; rewrite mulrC.
by apply/rregP; rewrite lead_coef_eq0.
Qed.

Lemma mulKp p q : q != 0 -> q * p %/ q = lead_coef q ^+ scalp (p * q) q *: p.
Proof. by move=> nzq; rewrite mulrC; apply: mulpK. Qed.

Lemma divpp p : p != 0 -> p %/ p = (lead_coef p ^+ scalp p p)%:P.
Proof.
move=> np0; have := divp_eq p p.
suff -> : p %% p = 0 by rewrite addr0 -mul_polyC; move/(mulIf np0).
rewrite modpE Ring.rmodpp; last by red; rewrite mulrC.
by rewrite scaler0 if_same.
Qed.

End WeakTheoryForIDomainPseudoDivision.

#[global] Hint Resolve lc_expn_scalp_neq0 : core.

End WeakIdomain.

Module CommonIdomain.

Import Ring ComRing UnitRing IdomainDefs WeakIdomain.

Section IDomainPseudoDivision.

Variable R : idomainType.
Implicit Type p q r d m n : {poly R}.

Lemma scalp0 p : scalp p 0 = 0.
Proof. by rewrite /scalp unlock lead_coef0 unitr0 unlock eqxx. Qed.

Lemma divp_small p q : size p < size q -> p %/ q = 0.
Proof.
move=> spq; rewrite /divp unlock redivp_def /=.
by case: ifP; rewrite rdivp_small // scaler0.
Qed.

Lemma leq_divp p q : (size (p %/ q) <= size p).
Proof.
rewrite /divp unlock redivp_def /=; case: ifP => ulcq; rewrite ?leq_rdivp //=.
rewrite size_scale ?leq_rdivp // -exprVn expf_neq0 // invr_eq0.
by case: eqP ulcq => // ->; rewrite unitr0.
Qed.

Lemma div0p p : 0 %/ p = 0.
Proof.
by rewrite /divp unlock redivp_def /=; case: ifP; rewrite rdiv0p // scaler0.
Qed.

Lemma divp0 p : p %/ 0 = 0.
Proof.
by rewrite /divp unlock redivp_def /=; case: ifP; rewrite rdivp0 // scaler0.
Qed.

Lemma divp1 m : m %/ 1 = m.
Proof.
by rewrite divpE lead_coefC unitr1 Ring.rdivp1 expr1n invr1 scale1r.
Qed.

Lemma modp0 p : p %% 0 = p.
Proof.
rewrite /modp unlock redivp_def; case: ifP; rewrite rmodp0 //= lead_coef0.
by rewrite unitr0.
Qed.

Lemma mod0p p : 0 %% p = 0.
Proof.
by rewrite /modp unlock redivp_def /=; case: ifP; rewrite rmod0p // scaler0.
Qed.

Lemma modp1 p : p %% 1 = 0.
Proof.
by rewrite /modp unlock redivp_def /=; case: ifP; rewrite rmodp1 // scaler0.
Qed.

Hint Resolve divp0 divp1 mod0p modp0 modp1 : core.

Lemma modp_small p q : size p < size q -> p %% q = p.
Proof.
move=> spq; rewrite /modp unlock redivp_def; case: ifP; rewrite rmodp_small //.
by rewrite /= rscalp_small // expr0 /= invr1 scale1r.
Qed.

Lemma modpC p c : c != 0 -> p %% c%:P = 0.
Proof.
move=> cn0; rewrite /modp unlock redivp_def /=; case: ifP; rewrite ?rmodpC //.
by rewrite scaler0.
Qed.

Lemma modp_mull p q : (p * q) %% q = 0.
Proof.
have [-> | nq0] := eqVneq q 0; first by rewrite modp0 mulr0.
have rlcq : GRing.rreg (lead_coef q) by apply/rregP; rewrite lead_coef_eq0.
have hC : GRing.comm q (lead_coef q)%:P by red; rewrite mulrC.
rewrite modpE; case: ifP => ulcq; rewrite RingComRreg.rmodp_mull //.
exact: scaler0.
Qed.

Lemma modp_mulr d p : (d * p) %% d = 0. Proof. by rewrite mulrC modp_mull. Qed.

Lemma modpp d : d %% d = 0.
Proof. by rewrite -[d in d %% _]mul1r modp_mull. Qed.

Lemma ltn_modp p q : (size (p %% q) < size q) = (q != 0).
Proof.
rewrite /modp unlock redivp_def /=; case: ifP=> ulcq; rewrite ?ltn_rmodp //=.
rewrite size_scale ?ltn_rmodp // -exprVn expf_neq0 // invr_eq0.
by case: eqP ulcq => // ->; rewrite unitr0.
Qed.

Lemma ltn_divpl d q p : d != 0 ->
   (size (q %/ d) < size p) = (size q < size (p * d)).
Proof.
move=> dn0.
have: (lead_coef d) ^+ (scalp q d) != 0 by apply: lc_expn_scalp_neq0.
move/(size_scale q)<-; rewrite divp_eq; have [->|quo0] := eqVneq (q %/ d) 0.
  rewrite mul0r add0r size_poly0 size_poly_gt0.
  have [->|pn0] := eqVneq p 0; first by rewrite mul0r size_poly0 ltn0.
  by rewrite size_mul // (polySpred pn0) addSn ltn_addl // ltn_modp.
rewrite size_polyDl; last first.
  by rewrite size_mul // (polySpred quo0) addSn /= ltn_addl // ltn_modp.
have [->|pn0] := eqVneq p 0; first by rewrite mul0r size_poly0 !ltn0.
by rewrite !size_mul ?quo0 // (polySpred dn0) !addnS ltn_add2r.
Qed.

Lemma leq_divpr d p q : d != 0 ->
   (size p <= size (q %/ d)) = (size (p * d) <= size q).
Proof. by move=> dn0; rewrite leqNgt ltn_divpl // -leqNgt. Qed.

Lemma divpN0 d p : d != 0 -> (p %/ d != 0) = (size d <= size p).
Proof.
move=> dn0.
by rewrite -[d in RHS]mul1r -leq_divpr // size_polyC oner_eq0 size_poly_gt0.
Qed.

Lemma size_divp p q : q != 0 -> size (p %/ q) = (size p - (size q).-1)%N.
Proof.
move=> nq0; case: (leqP (size q) (size p)) => sqp; last first.
  move: (sqp); rewrite -{1}(ltn_predK sqp) ltnS -subn_eq0 divp_small //.
  by move/eqP->; rewrite size_poly0.
have np0 : p != 0.
  by rewrite -size_poly_gt0; apply: leq_trans sqp; rewrite size_poly_gt0.
have /= := congr1 (size \o @polyseq R) (divp_eq p q).
rewrite size_scale; last by rewrite expf_eq0 lead_coef_eq0 (negPf nq0) andbF.
have [->|qq0] := eqVneq (p %/ q) 0.
  by rewrite mul0r add0r=> es; move: nq0; rewrite -(ltn_modp p) -es ltnNge sqp.
rewrite size_polyDl.
  by move->; apply/eqP; rewrite size_mul // (polySpred nq0) addnS /= addnK.
rewrite size_mul ?qq0 //.
move: nq0; rewrite -(ltn_modp p); move/leq_trans; apply.
by rewrite (polySpred qq0) addSn /= leq_addl.
Qed.

Lemma ltn_modpN0 p q : q != 0 -> size (p %% q) < size q.
Proof. by rewrite ltn_modp. Qed.

Lemma modp_id p q : (p %% q) %% q = p %% q.
Proof.
by have [->|qn0] := eqVneq q 0; rewrite ?modp0 // modp_small ?ltn_modp.
Qed.

Lemma leq_modp m d : size (m %% d) <= size m.
Proof.
rewrite /modp unlock redivp_def /=; case: ifP; rewrite ?leq_rmodp //.
move=> ud; rewrite size_scale ?leq_rmodp // invr_eq0 expf_neq0 //.
by apply: contraTneq ud => ->; rewrite unitr0.
Qed.

Lemma dvdp0 d : d %| 0. Proof. by rewrite /dvdp mod0p. Qed.

Hint Resolve dvdp0 : core.

Lemma dvd0p p : (0 %| p) = (p == 0). Proof. by rewrite /dvdp modp0. Qed.

Lemma dvd0pP p : reflect (p = 0) (0 %| p).
Proof. by apply: (iffP idP); rewrite dvd0p; move/eqP. Qed.

Lemma dvdpN0 p q : p %| q -> q != 0 -> p != 0.
Proof. by move=> pq hq; apply: contraTneq pq => ->; rewrite dvd0p. Qed.

Lemma dvdp1 d : (d %| 1) = (size d == 1).
Proof.
rewrite /dvdp modpE; case ud: (lead_coef d \in GRing.unit); last exact: rdvdp1.
rewrite -size_poly_eq0 size_scale; first by rewrite size_poly_eq0 -rdvdp1.
by rewrite invr_eq0 expf_neq0 //; apply: contraTneq ud => ->; rewrite unitr0.
Qed.

Lemma dvd1p m : 1 %| m. Proof. by rewrite /dvdp modp1. Qed.

Lemma gtNdvdp p q : p != 0 -> size p < size q -> (q %| p) = false.
Proof.
by move=> nn0 hs; rewrite /dvdp; rewrite (modp_small hs); apply: negPf.
Qed.

Lemma modp_eq0P p q : reflect (p %% q = 0) (q %| p).
Proof. exact: (iffP eqP). Qed.

Lemma modp_eq0 p q : (q %| p) -> p %% q = 0. Proof. exact: modp_eq0P. Qed.

Lemma leq_divpl d p q :
  d %| p -> (size (p %/ d) <= size q) = (size p <= size (q * d)).
Proof.
case: (eqVneq d 0) => [-> /dvd0pP -> | nd0 hd].
  by rewrite divp0 size_poly0 !leq0n.
rewrite leq_eqVlt ltn_divpl // (leq_eqVlt (size p)).
case lhs: (size p < size (q * d)); rewrite ?orbT ?orbF //.
have: (lead_coef d) ^+ (scalp p d) != 0 by rewrite expf_neq0 // lead_coef_eq0.
move/(size_scale p)<-; rewrite divp_eq; move/modp_eq0P: hd->; rewrite addr0.
have [-> | quon0] := eqVneq (p %/ d) 0.
  rewrite mul0r size_poly0 2!(eq_sym 0) !size_poly_eq0.
  by rewrite mulf_eq0 (negPf nd0) orbF.
have [-> | nq0] := eqVneq q 0.
  by rewrite mul0r size_poly0 !size_poly_eq0 mulf_eq0 (negPf nd0) orbF.
by rewrite !size_mul // (polySpred nd0) !addnS /= eqn_add2r.
Qed.

Lemma dvdp_leq p q : q != 0 -> p %| q -> size p <= size q.
Proof.
move=> nq0 /modp_eq0P.
by case: leqP => // /modp_small -> /eqP; rewrite (negPf nq0).
Qed.

Lemma eq_dvdp c quo q p : c != 0 -> c *: p = quo * q -> q %| p.
Proof.
move=> cn0; case: (eqVneq p 0) => [->|nz_quo def_quo] //.
pose p1 : {poly R} := lead_coef q ^+ scalp p q *: quo - c *: (p %/ q).
have E1: c *: (p %% q) = p1 * q.
  rewrite mulrDl mulNr -scalerAl -def_quo scalerA mulrC -scalerA.
  by rewrite -scalerAl -scalerBr divp_eq addrAC subrr add0r.
rewrite /dvdp; apply/idPn=> m_nz.
have: p1 * q != 0 by rewrite -E1 -mul_polyC mulf_neq0 // polyC_eq0.
rewrite mulf_eq0; case/norP=> p1_nz q_nz.
have := ltn_modp p q; rewrite q_nz -(size_scale (p %% q) cn0) E1.
by rewrite size_mul // polySpred // ltnNge leq_addl.
Qed.

Lemma dvdpp d : d %| d. Proof. by rewrite /dvdp modpp. Qed.

Hint Resolve dvdpp : core.

Lemma divp_dvd p q : p %| q -> (q %/ p) %| q.
Proof.
have [-> | np0] := eqVneq p 0; first by rewrite divp0.
rewrite dvdp_eq => /eqP h.
apply: (@eq_dvdp ((lead_coef p)^+ (scalp q p)) p); last by rewrite mulrC.
by rewrite expf_neq0 // lead_coef_eq0.
Qed.

Lemma dvdp_mull m d n : d %| n -> d %| m * n.
Proof.
case: (eqVneq d 0) => [-> /dvd0pP -> | dn0]; first by rewrite mulr0 dvdpp.
rewrite dvdp_eq => /eqP e.
apply: (@eq_dvdp (lead_coef d ^+ scalp n d) (m * (n %/ d))).
  by rewrite expf_neq0 // lead_coef_eq0.
by rewrite scalerAr e mulrA.
Qed.

Lemma dvdp_mulr n d m : d %| m -> d %| m * n.
Proof. by move=> hdm; rewrite mulrC dvdp_mull. Qed.

Hint Resolve dvdp_mull dvdp_mulr : core.

Lemma dvdp_mul d1 d2 m1 m2 : d1 %| m1 -> d2 %| m2 -> d1 * d2 %| m1 * m2.
Proof.
case: (eqVneq d1 0) => [-> /dvd0pP -> | d1n0]; first by rewrite !mul0r dvdpp.
case: (eqVneq d2 0) => [-> _ /dvd0pP -> | d2n0]; first by rewrite !mulr0.
rewrite dvdp_eq; set c1 := _ ^+ _; set q1 := _ %/ _; move/eqP=> Hq1.
rewrite dvdp_eq; set c2 := _ ^+ _; set q2 := _ %/ _; move/eqP=> Hq2.
apply: (@eq_dvdp (c1 * c2) (q1 * q2)).
  by rewrite mulf_neq0 // expf_neq0 // lead_coef_eq0.
rewrite -scalerA scalerAr scalerAl Hq1 Hq2 -!mulrA.
by rewrite [d1 * (q2 * _)]mulrCA.
Qed.

Lemma dvdp_addr m d n : d %| m -> (d %| m + n) = (d %| n).
Proof.
case: (eqVneq d 0) => [-> /dvd0pP -> | dn0]; first by rewrite add0r.
rewrite dvdp_eq; set c1 := _ ^+ _; set q1 := _ %/ _; move/eqP=> Eq1.
apply/idP/idP; rewrite dvdp_eq; set c2 := _ ^+ _; set q2 := _ %/ _.
  have sn0 : c1 * c2 != 0.
    by rewrite !mulf_neq0 // expf_eq0 lead_coef_eq0 (negPf dn0) andbF.
  move/eqP=> Eq2; apply: (@eq_dvdp _ (c1 *: q2 - c2 *: q1) _ _ sn0).
  rewrite mulrDl -scaleNr -!scalerAl -Eq1 -Eq2 !scalerA.
  by rewrite mulNr mulrC scaleNr -scalerBr addrC addKr.
have sn0 : c1 * c2 != 0.
  by rewrite !mulf_neq0 // expf_eq0 lead_coef_eq0 (negPf dn0) andbF.
move/eqP=> Eq2; apply: (@eq_dvdp _ (c1 *: q2 + c2 *: q1) _ _ sn0).
by rewrite mulrDl -!scalerAl -Eq1 -Eq2 !scalerA mulrC addrC scalerDr.
Qed.

Lemma dvdp_addl n d m : d %| n -> (d %| m + n) = (d %| m).
Proof. by rewrite addrC; apply: dvdp_addr. Qed.

Lemma dvdp_add d m n : d %| m -> d %| n -> d %| m + n.
Proof. by move/dvdp_addr->. Qed.

Lemma dvdp_add_eq d m n : d %| m + n -> (d %| m) = (d %| n).
Proof. by move=> ?; apply/idP/idP; [move/dvdp_addr <-| move/dvdp_addl <-]. Qed.

Lemma dvdp_subr d m n : d %| m -> (d %| m - n) = (d %| n).
Proof. by move=> ?; apply: dvdp_add_eq; rewrite -addrA addNr simp. Qed.

Lemma dvdp_subl d m n : d %| n -> (d %| m - n) = (d %| m).
Proof. by move/dvdp_addl<-; rewrite subrK. Qed.

Lemma dvdp_sub d m n : d %| m -> d %| n -> d %| m - n.
Proof. by move=> *; rewrite dvdp_subl. Qed.

Lemma dvdp_mod d n m : d %| n -> (d %| m) = (d %| m %% n).
Proof.
have [-> | nn0] := eqVneq n 0; first by rewrite modp0.
case: (eqVneq d 0) => [-> /dvd0pP -> | dn0]; first by rewrite modp0.
rewrite dvdp_eq; set c1 := _ ^+ _; set q1 := _ %/ _; move/eqP=> Eq1.
apply/idP/idP; rewrite dvdp_eq; set c2 := _ ^+ _; set q2 := _ %/ _.
  have sn0 : c1 * c2 != 0.
   by rewrite !mulf_neq0 // expf_eq0 lead_coef_eq0 (negPf dn0) andbF.
  pose quo := (c1 * lead_coef n ^+ scalp m n) *: q2 - c2 *: (m %/ n) * q1.
  move/eqP=> Eq2; apply: (@eq_dvdp _ quo _ _ sn0).
  rewrite mulrDl mulNr -!scalerAl -!mulrA -Eq1 -Eq2 -scalerAr !scalerA.
  rewrite mulrC [_ * c2]mulrC mulrA -[((_ * _) * _) *: _]scalerA -scalerBr.
  by rewrite divp_eq addrC addKr.
have sn0 : c1 * c2 * lead_coef n ^+ scalp m n != 0.
  rewrite !mulf_neq0 // expf_eq0 lead_coef_eq0 ?(negPf dn0) ?andbF //.
  by rewrite (negPf nn0) andbF.
move/eqP=> Eq2; apply: (@eq_dvdp _ (c2 *: (m %/ n) * q1 + c1 *: q2) _ _ sn0).
rewrite -scalerA divp_eq scalerDr -!scalerA Eq2 scalerAl scalerAr Eq1.
by rewrite scalerAl mulrDl mulrA.
Qed.

Lemma dvdp_trans : transitive (@dvdp R).
Proof.
move=> n d m.
case: (eqVneq d 0) => [-> /dvd0pP -> // | dn0].
case: (eqVneq n 0) => [-> _ /dvd0pP -> // | nn0].
rewrite dvdp_eq; set c1 := _ ^+ _; set q1 := _ %/ _; move/eqP=> Hq1.
rewrite dvdp_eq; set c2 := _ ^+ _; set q2 := _ %/ _; move/eqP=> Hq2.
have sn0 : c1 * c2 != 0 by rewrite mulf_neq0 // expf_neq0 // lead_coef_eq0.
apply: (@eq_dvdp _ (q2 * q1) _ _ sn0).
by rewrite -scalerA Hq2 scalerAr Hq1 mulrA.
Qed.

Lemma dvdp_mulIl p q : p %| p * q. Proof. exact/dvdp_mulr/dvdpp. Qed.

Lemma dvdp_mulIr p q : q %| p * q. Proof. exact/dvdp_mull/dvdpp. Qed.

Lemma dvdp_mul2r r p q : r != 0 -> (p * r %| q * r) = (p %| q).
Proof.
move=> nzr.
have [-> | pn0] := eqVneq p 0.
  by rewrite mul0r !dvd0p mulf_eq0 (negPf nzr) orbF.
have [-> | qn0] := eqVneq q 0; first by rewrite mul0r !dvdp0.
apply/idP/idP; last by move=> ?; rewrite dvdp_mul ?dvdpp.
rewrite dvdp_eq; set c := _ ^+ _; set x := _ %/ _; move/eqP=> Hx.
apply: (@eq_dvdp c x); first by rewrite expf_neq0 // lead_coef_eq0 mulf_neq0.
by apply: (mulIf nzr); rewrite -mulrA -scalerAl.
Qed.

Lemma dvdp_mul2l r p q: r != 0 -> (r * p %| r * q) = (p %| q).
Proof. by rewrite ![r * _]mulrC; apply: dvdp_mul2r. Qed.

Lemma ltn_divpr d p q :
  d %| q -> (size p < size (q %/ d)) = (size (p * d) < size q).
Proof. by move=> dv_d_q; rewrite !ltnNge leq_divpl. Qed.

Lemma dvdp_exp d k p : 0 < k -> d %| p -> d %| (p ^+ k).
Proof. by case: k => // k _ d_dv_m; rewrite exprS dvdp_mulr. Qed.

Lemma dvdp_exp2l d k l : k <= l -> d ^+ k %| d ^+ l.
Proof. by move/subnK <-; rewrite exprD dvdp_mull // ?lead_coef_exp ?unitrX. Qed.

Lemma dvdp_Pexp2l d k l : 1 < size d -> (d ^+ k %| d ^+ l) = (k <= l).
Proof.
move=> sd; case: leqP => [|gt_n_m]; first exact: dvdp_exp2l.
have dn0 : d != 0 by rewrite -size_poly_gt0; apply: ltn_trans sd.
rewrite gtNdvdp ?expf_neq0 // polySpred ?expf_neq0 // size_exp /=.
rewrite [size (d ^+ k)]polySpred ?expf_neq0 // size_exp ltnS ltn_mul2l.
by move: sd; rewrite -subn_gt0 subn1; move->.
Qed.

Lemma dvdp_exp2r p q k : p %| q -> p ^+ k %| q ^+ k.
Proof.
case: (eqVneq p 0) => [-> /dvd0pP -> // | pn0].
rewrite dvdp_eq; set c := _ ^+ _; set t := _ %/ _; move/eqP=> e.
apply: (@eq_dvdp (c ^+ k) (t ^+ k)); first by rewrite !expf_neq0 ?lead_coef_eq0.
by rewrite -exprMn -exprZn; congr (_ ^+ k).
Qed.

Lemma dvdp_exp_sub p q k l: p != 0 ->
  (p ^+ k %| q * p ^+ l) = (p ^+ (k - l) %| q).
Proof.
move=> pn0; case: (leqP k l)=> [|/ltnW] hkl.
  move: (hkl); rewrite -subn_eq0; move/eqP->; rewrite expr0 dvd1p.
  exact/dvdp_mull/dvdp_exp2l.
by rewrite -[in LHS](subnK hkl) exprD dvdp_mul2r // expf_eq0 (negPf pn0) andbF.
Qed.

Lemma dvdp_XsubCl p x : ('X - x%:P) %| p = root p x.
Proof. by rewrite dvdpE; apply: Ring.rdvdp_XsubCl. Qed.

Lemma root_dvdp p q x : p %| q -> root p x -> root q x.
Proof. by rewrite -!dvdp_XsubCl => /[swap]; exact: dvdp_trans. Qed.

Lemma polyXsubCP p x : reflect (p.[x] = 0) (('X - x%:P) %| p).
Proof. by rewrite dvdpE; apply: Ring.polyXsubCP. Qed.

Lemma eqp_div_XsubC p c :
  (p == (p %/ ('X - c%:P)) * ('X - c%:P)) = ('X - c%:P %| p).
Proof. by rewrite dvdp_eq lead_coefXsubC expr1n scale1r. Qed.

Lemma root_factor_theorem p x : root p x = (('X - x%:P) %| p).
Proof. by rewrite dvdp_XsubCl. Qed.

Lemma uniq_roots_dvdp p rs : all (root p) rs -> uniq_roots rs ->
  (\prod_(z <- rs) ('X - z%:P)) %| p.
Proof.
move=> rrs; case/(uniq_roots_prod_XsubC rrs)=> q ->.
by apply: dvdp_mull; rewrite // (eqP (monic_prod_XsubC _)) unitr1.
Qed.

Lemma root_bigmul x (ps : seq {poly R}) :
  ~~root (\big[*%R/1]_(p <- ps) p) x = all (fun p => ~~ root p x) ps.
Proof.
elim: ps => [|p ps ihp]; first by rewrite big_nil root1.
by rewrite big_cons /= rootM negb_or ihp.
Qed.

Lemma eqpP m n :
  reflect (exists2 c12, (c12.1 != 0) && (c12.2 != 0) & c12.1 *: m = c12.2 *: n)
          (m %= n).
Proof.
apply: (iffP idP) => [| [[c1 c2]/andP[nz_c1 nz_c2 eq_cmn]]]; last first.
  rewrite /eqp (@eq_dvdp c2 c1%:P) -?eq_cmn ?mul_polyC // (@eq_dvdp c1 c2%:P)//.
  by rewrite eq_cmn mul_polyC.
case: (eqVneq m 0) => [-> /andP [/dvd0pP -> _] | m_nz].
  by exists (1, 1); rewrite ?scaler0 // oner_eq0.
case: (eqVneq n 0) => [-> /andP [_ /dvd0pP ->] | n_nz /andP []].
  by exists (1, 1); rewrite ?scaler0 // oner_eq0.
rewrite !dvdp_eq; set c1 := _ ^+ _; set c2 := _ ^+ _.
set q1 := _ %/ _; set q2 := _ %/ _; move/eqP => Hq1 /eqP Hq2;
have Hc1 : c1 != 0 by rewrite expf_eq0 lead_coef_eq0 negb_and m_nz orbT.
have Hc2 : c2 != 0 by rewrite expf_eq0 lead_coef_eq0 negb_and n_nz orbT.
have def_q12: q1 * q2 = (c1 * c2)%:P.
  apply: (mulIf m_nz); rewrite mulrAC mulrC -Hq1 -scalerAr -Hq2 scalerA.
  by rewrite -mul_polyC.
have: q1 * q2 != 0 by rewrite def_q12 -size_poly_eq0 size_polyC mulf_neq0.
rewrite mulf_eq0; case/norP=> nz_q1 nz_q2.
have: size q2 <= 1.
  have:= size_mul nz_q1 nz_q2; rewrite def_q12 size_polyC mulf_neq0 //=.
  by rewrite polySpred // => ->; rewrite leq_addl.
rewrite leq_eqVlt ltnS size_poly_leq0 (negPf nz_q2) orbF.
case/size_poly1P=> c cn0 cqe; exists (c2, c); first by rewrite Hc2.
by rewrite Hq2 -mul_polyC -cqe.
Qed.

Lemma eqp_eq p q: p %= q -> (lead_coef q) *: p = (lead_coef p) *: q.
Proof.
move=> /eqpP [[c1 c2] /= /andP [nz_c1 nz_c2]] eq.
have/(congr1 lead_coef) := eq; rewrite !lead_coefZ.
move=> eqC; apply/(@mulfI _ c2%:P); rewrite ?polyC_eq0 //.
by rewrite !mul_polyC scalerA -eqC mulrC -scalerA eq !scalerA mulrC.
Qed.

Lemma eqpxx : reflexive (@eqp R). Proof. by move=> p; rewrite /eqp dvdpp. Qed.

Hint Resolve eqpxx : core.

Lemma eqpW p q : p = q -> p %= q. Proof. by move->; rewrite eqpxx. Qed.

Lemma eqp_sym : symmetric (@eqp R).
Proof. by move=> p q; rewrite /eqp andbC. Qed.

Lemma eqp_trans : transitive (@eqp R).
Proof.
move=> p q r; case/andP=> Dp pD; case/andP=> Dq qD.
by rewrite /eqp (dvdp_trans Dp) // (dvdp_trans qD).
Qed.

Lemma eqp_ltrans : left_transitive (@eqp R).
Proof. exact: sym_left_transitive eqp_sym eqp_trans. Qed.

Lemma eqp_rtrans : right_transitive (@eqp R).
Proof. exact: sym_right_transitive eqp_sym eqp_trans. Qed.

Lemma eqp0 p : (p %= 0) = (p == 0).
Proof. by apply/idP/eqP => [/andP [_ /dvd0pP] | -> //]. Qed.

Lemma eqp01 : 0 %= (1 : {poly R}) = false.
Proof. by rewrite eqp_sym eqp0 oner_eq0. Qed.

Lemma eqp_scale p c : c != 0 -> c *: p %= p.
Proof.
move=> c0; apply/eqpP; exists (1, c); first by rewrite c0 oner_eq0.
by rewrite scale1r.
Qed.

Lemma eqp_size p q : p %= q -> size p = size q.
Proof.
have [->|Eq] := eqVneq q 0; first by rewrite eqp0; move/eqP->.
rewrite eqp_sym; have [->|Ep] := eqVneq p 0; first by rewrite eqp0; move/eqP->.
by case/andP => Dp Dq; apply: anti_leq; rewrite !dvdp_leq.
Qed.

Lemma size_poly_eq1 p : (size p == 1) = (p %= 1).
Proof.
apply/size_poly1P/idP=> [[c cn0 ep] |].
  by apply/eqpP; exists (1, c); rewrite ?oner_eq0 // alg_polyC scale1r.
by move/eqp_size; rewrite size_poly1; move/eqP/size_poly1P.
Qed.

Lemma polyXsubC_eqp1 (x : R) : ('X - x%:P %= 1) = false.
Proof. by rewrite -size_poly_eq1 size_XsubC. Qed.

Lemma dvdp_eqp1 p q : p %| q -> q %= 1 -> p %= 1.
Proof.
move=> dpq hq.
have sizeq : size q == 1 by rewrite size_poly_eq1.
have n0q : q != 0 by case: eqP hq => // ->; rewrite eqp01.
rewrite -size_poly_eq1 eqn_leq -{1}(eqP sizeq) dvdp_leq //= size_poly_gt0.
by apply/eqP => p0; move: dpq n0q; rewrite p0 dvd0p => ->.
Qed.

Lemma eqp_dvdr q p d: p %= q -> d %| p = (d %| q).
Proof.
suff Hmn m n: m %= n -> (d %| m) -> (d %| n).
  by move=> mn; apply/idP/idP; apply: Hmn=> //; rewrite eqp_sym.
by rewrite /eqp; case/andP=> pq qp dp; apply: (dvdp_trans dp).
Qed.

Lemma eqp_dvdl d2 d1 p : d1 %= d2 -> d1 %| p = (d2 %| p).
suff Hmn m n: m %= n -> (m %| p) -> (n %| p).
  by move=> ?; apply/idP/idP; apply: Hmn; rewrite // eqp_sym.
by rewrite /eqp; case/andP=> dd' d'd dp; apply: (dvdp_trans d'd).
Qed.

Lemma dvdpZr c m n : c != 0 -> m %| c *: n = (m %| n).
Proof. by move=> cn0; exact/eqp_dvdr/eqp_scale. Qed.

Lemma dvdpZl c m n : c != 0 -> (c *: m %| n) = (m %| n).
Proof. by move=> cn0; exact/eqp_dvdl/eqp_scale. Qed.

Lemma dvdpNl d p : (- d) %| p = (d %| p).
Proof.
by rewrite -scaleN1r; apply/eqp_dvdl/eqp_scale; rewrite oppr_eq0 oner_neq0.
Qed.

Lemma dvdpNr d p : d %| (- p) = (d %| p).
Proof. by apply: eqp_dvdr; rewrite -scaleN1r eqp_scale ?oppr_eq0 ?oner_eq0. Qed.

Lemma eqp_mul2r r p q : r != 0 -> (p * r %= q * r) = (p %= q).
Proof. by move=> nz_r; rewrite /eqp !dvdp_mul2r. Qed.

Lemma eqp_mul2l r p q: r != 0 -> (r * p %= r * q) = (p %= q).
Proof. by move=> nz_r; rewrite /eqp !dvdp_mul2l. Qed.

Lemma eqp_mull r p q: q %= r -> p * q %= p * r.
Proof.
case/eqpP=> [[c d]] /andP [c0 d0 e]; apply/eqpP; exists (c, d); rewrite ?c0 //.
by rewrite scalerAr e -scalerAr.
Qed.

Lemma eqp_mulr q p r : p %= q -> p * r %= q * r.
Proof. by move=> epq; rewrite ![_ * r]mulrC eqp_mull. Qed.

Lemma eqp_exp p q k : p %= q -> p ^+ k %= q ^+ k.
Proof.
move=> pq; elim: k=> [|k ihk]; first by rewrite !expr0 eqpxx.
by rewrite !exprS (@eqp_trans (q * p ^+ k)) // (eqp_mulr, eqp_mull).
Qed.

Lemma polyC_eqp1 (c : R) : (c%:P %= 1) = (c != 0).
Proof.
apply/eqpP/idP => [[[x y]] |nc0] /=.
  case: (eqVneq c) => [->|] //= /andP [_] /negPf <- /eqP.
  by rewrite alg_polyC scaler0 eq_sym polyC_eq0.
exists (1, c); first by rewrite nc0 /= oner_neq0.
by rewrite alg_polyC scale1r.
Qed.

Lemma dvdUp d p: d %= 1 -> d %| p.
Proof. by move/eqp_dvdl->; rewrite dvd1p. Qed.

Lemma dvdp_size_eqp p q : p %| q -> size p == size q = (p %= q).
Proof.
move=> pq; apply/idP/idP; last by move/eqp_size->.
have [->|Hq] := eqVneq q 0; first by rewrite size_poly0 size_poly_eq0 eqp0.
have [->|Hp] := eqVneq p 0.
  by rewrite size_poly0 eq_sym size_poly_eq0 eqp_sym eqp0.
move: pq; rewrite dvdp_eq; set c := _ ^+ _; set x := _ %/ _; move/eqP=> eqpq.
have /= := congr1 (size \o @polyseq R) eqpq.
have cn0 : c != 0 by rewrite expf_neq0 // lead_coef_eq0.
rewrite (@eqp_size _ q); last exact: eqp_scale.
rewrite size_mul ?p0 // => [-> HH|]; last first.
  apply/eqP=> HH; move: eqpq; rewrite HH mul0r.
  by move/eqP; rewrite scale_poly_eq0 (negPf Hq) (negPf cn0).
suff: size x == 1%N.
  case/size_poly1P=> y H1y H2y.
  by apply/eqpP; exists (y, c); rewrite ?H1y // eqpq H2y mul_polyC.
case: (size p) HH (size_poly_eq0 p)=> [|n]; first by case: eqP Hp.
by rewrite addnS -add1n eqn_add2r; move/eqP->.
Qed.

Lemma eqp_root p q : p %= q -> root p =1 root q.
Proof.
move/eqpP=> [[c d]] /andP [c0 d0 e] x; move/negPf:c0=>c0; move/negPf:d0=>d0.
by rewrite rootE -[_==_]orFb -c0 -mulf_eq0 -hornerZ e hornerZ mulf_eq0 d0.
Qed.

Lemma eqp_rmod_mod p q : rmodp p q %= modp p q.
Proof.
rewrite modpE eqp_sym; case: ifP => ulcq //.
apply: eqp_scale; rewrite invr_eq0 //.
by apply: expf_neq0; apply: contraTneq ulcq => ->; rewrite unitr0.
Qed.

Lemma eqp_rdiv_div p q : rdivp p q %= divp p q.
Proof.
rewrite divpE eqp_sym; case: ifP=> ulcq//; apply: eqp_scale; rewrite invr_eq0//.
by apply: expf_neq0; apply: contraTneq ulcq => ->; rewrite unitr0.
Qed.

Lemma dvd_eqp_divl d p q (dvd_dp : d %| q) (eq_pq : p %= q) :
  p %/ d %= q %/ d.
Proof.
case: (eqVneq q 0) eq_pq=> [->|q_neq0]; first by rewrite eqp0=> /eqP->.
have d_neq0: d != 0 by apply: contraTneq dvd_dp=> ->; rewrite dvd0p.
move=> eq_pq; rewrite -(@eqp_mul2r d) // !divpK // ?(eqp_dvdr _ eq_pq) //.
rewrite (eqp_ltrans (eqp_scale _ _)) ?lc_expn_scalp_neq0 //.
by rewrite (eqp_rtrans (eqp_scale _ _)) ?lc_expn_scalp_neq0.
Qed.

Definition gcdp p q :=
  let: (p1, q1) := if size p < size q then (q, p) else (p, q) in
  if p1 == 0 then q1 else
  let fix loop (n : nat) (pp qq : {poly R}) {struct n} :=
      let rr := modp pp qq in
      if rr == 0 then qq else
      if n is n1.+1 then loop n1 qq rr else rr in
  loop (size p1) p1 q1.
Arguments gcdp : simpl never.

Lemma gcd0p : left_id 0 gcdp.
Proof.
move=> p; rewrite /gcdp size_poly0 size_poly_gt0 if_neg.
case: ifP => /= [_ | nzp]; first by rewrite eqxx.
by rewrite polySpred !(modp0, nzp) //; case: _.-1 => [|m]; rewrite mod0p eqxx.
Qed.

Lemma gcdp0 : right_id 0 gcdp.
Proof.
move=> p; have:= gcd0p p; rewrite /gcdp size_poly0 size_poly_gt0.
by case: eqVneq => //= ->; rewrite eqxx.
Qed.

Lemma gcdpE p q :
  gcdp p q = if size p < size q
    then gcdp (modp q p) p else gcdp (modp p q) q.
Proof.
pose gcdpE_rec := fix gcdpE_rec (n : nat) (pp qq : {poly R}) {struct n} :=
   let rr := modp pp qq in
   if rr == 0 then qq else
   if n is n1.+1 then gcdpE_rec n1 qq rr else rr.
have Irec: forall k l p q, size q <= k -> size q <= l
      -> size q < size p -> gcdpE_rec k p q = gcdpE_rec l p q.
+ elim=> [|m Hrec] [|n] //= p1 q1.
  - move/size_poly_leq0P=> -> _; rewrite size_poly0 size_poly_gt0 modp0.
    by move/negPf ->; case: n => [|n] /=; rewrite mod0p eqxx.
  - move=> _ /size_poly_leq0P ->; rewrite size_poly0 size_poly_gt0 modp0.
    by move/negPf ->; case: m {Hrec} => [|m] /=; rewrite mod0p eqxx.
  case: eqP => Epq Sm Sn Sq //; have [->|nzq] := eqVneq q1 0.
    by case: n m {Sm Sn Hrec} => [|m] [|n] //=; rewrite mod0p eqxx.
  apply: Hrec; last by rewrite ltn_modp.
    by rewrite -ltnS (leq_trans _ Sm) // ltn_modp.
  by rewrite -ltnS (leq_trans _ Sn) // ltn_modp.
have [->|nzp] := eqVneq p 0; first by rewrite mod0p modp0 gcd0p gcdp0 if_same.
have [->|nzq] := eqVneq q 0; first by rewrite mod0p modp0 gcd0p gcdp0 if_same.
rewrite /gcdp !ltn_modp !(negPf nzp, negPf nzq) /=.
have [ltpq|leqp] := ltnP; rewrite !(negPf nzp, negPf nzq) /= polySpred //.
  have [->|nzqp] := eqVneq.
    by case: (size p) => [|[|s]]; rewrite /= modp0 (negPf nzp) // mod0p eqxx.
  apply: Irec => //; last by rewrite ltn_modp.
    by rewrite -ltnS -polySpred // (leq_trans _ ltpq) ?leqW // ltn_modp.
  by rewrite ltnW // ltn_modp.
case: eqVneq => [->|nzpq].
  by case: (size q) => [|[|s]]; rewrite /= modp0 (negPf nzq) // mod0p eqxx.
apply: Irec => //; rewrite ?ltn_modp //.
  by rewrite -ltnS -polySpred // (leq_trans _ leqp) // ltn_modp.
by rewrite ltnW // ltn_modp.
Qed.

Lemma size_gcd1p p : size (gcdp 1 p) = 1.
Proof.
rewrite gcdpE size_polyC oner_eq0 /= modp1; have [|/size1_polyC ->] := ltnP.
  by rewrite gcd0p size_polyC oner_eq0.
have [->|p00] := eqVneq p`_0 0; first by rewrite modp0 gcdp0 size_poly1.
by rewrite modpC // gcd0p size_polyC p00.
Qed.

Lemma size_gcdp1 p : size (gcdp p 1) = 1.
Proof.
rewrite gcdpE size_polyC oner_eq0 /= modp1 ltnS; case: leqP.
  by move/size_poly_leq0P->; rewrite gcdp0 modp0 size_polyC oner_eq0.
by rewrite gcd0p size_polyC oner_eq0.
Qed.

Lemma gcdpp : idempotent_op gcdp.
Proof. by move=> p; rewrite gcdpE ltnn modpp gcd0p. Qed.

Lemma dvdp_gcdlr p q : (gcdp p q %| p) && (gcdp p q %| q).
Proof.
have [r] := ubnP (minn (size q) (size p)); elim: r => // r IHr in p q *.
have [-> | nz_p] := eqVneq p 0; first by rewrite gcd0p dvdpp andbT.
have [-> | nz_q] := eqVneq q 0; first by rewrite gcdp0 dvdpp /=.
rewrite ltnS gcdpE; case: leqP => [le_pq | lt_pq] le_qr.
  suffices /IHr/andP[E1 E2]: minn (size q) (size (p %% q)) < r.
    by rewrite E2 andbT (dvdp_mod _ E2).
  by rewrite gtn_min orbC (leq_trans _ le_qr) ?ltn_modp.
suffices /IHr/andP[E1 E2]: minn (size p) (size (q %% p)) < r.
  by rewrite E2 (dvdp_mod _ E2).
by rewrite gtn_min orbC (leq_trans _ le_qr) ?ltn_modp.
Qed.

Lemma dvdp_gcdl p q : gcdp p q %| p. Proof. by case/andP: (dvdp_gcdlr p q). Qed.

Lemma dvdp_gcdr p q :gcdp p q %| q. Proof. by case/andP: (dvdp_gcdlr p q). Qed.

Lemma leq_gcdpl p q : p != 0 -> size (gcdp p q) <= size p.
Proof. by move=> pn0; move: (dvdp_gcdl p q); apply: dvdp_leq. Qed.

Lemma leq_gcdpr p q : q != 0 -> size (gcdp p q) <= size q.
Proof. by move=> qn0; move: (dvdp_gcdr p q); apply: dvdp_leq. Qed.

Lemma dvdp_gcd p m n : p %| gcdp m n = (p %| m) && (p %| n).
Proof.
apply/idP/andP=> [dv_pmn | []].
  by rewrite ?(dvdp_trans dv_pmn) ?dvdp_gcdl ?dvdp_gcdr.
have [r] := ubnP (minn (size n) (size m)); elim: r => // r IHr in m n *.
have [-> | nz_m] := eqVneq m 0; first by rewrite gcd0p.
have [-> | nz_n] := eqVneq n 0; first by rewrite gcdp0.
rewrite gcdpE ltnS; case: leqP => [le_nm | lt_mn] le_r dv_m dv_n.
  apply: IHr => //; last by rewrite -(dvdp_mod _ dv_n).
  by rewrite gtn_min orbC (leq_trans _ le_r) ?ltn_modp.
apply: IHr => //; last by rewrite -(dvdp_mod _ dv_m).
by rewrite gtn_min orbC (leq_trans _ le_r) ?ltn_modp.
Qed.

Lemma gcdpC p q : gcdp p q %= gcdp q p.
Proof. by rewrite /eqp !dvdp_gcd !dvdp_gcdl !dvdp_gcdr. Qed.

Lemma gcd1p p : gcdp 1 p %= 1.
Proof.
rewrite -size_poly_eq1 gcdpE size_poly1; case: ltnP.
  by rewrite modp1 gcd0p size_poly1 eqxx.
move/size1_polyC=> e; rewrite e.
have [->|p00] := eqVneq p`_0 0; first by rewrite modp0 gcdp0 size_poly1.
by rewrite modpC // gcd0p size_polyC p00.
Qed.

Lemma gcdp1 p : gcdp p 1 %= 1.
Proof. by rewrite (eqp_ltrans (gcdpC _ _)) gcd1p. Qed.

Lemma gcdp_addl_mul p q r: gcdp r (p * r + q) %= gcdp r q.
Proof.
suff h m n d : gcdp d n %| gcdp d (m * d + n).
  apply/andP; split => //.
  by rewrite {2}(_: q = (-p) * r + (p * r + q)) ?H // mulNr addKr.
by rewrite dvdp_gcd dvdp_gcdl /= dvdp_addr ?dvdp_gcdr ?dvdp_mull ?dvdp_gcdl.
Qed.

Lemma gcdp_addl m n : gcdp m (m + n) %= gcdp m n.
Proof. by rewrite -[m in m + _]mul1r gcdp_addl_mul. Qed.

Lemma gcdp_addr m n : gcdp m (n + m) %= gcdp m n.
Proof. by rewrite addrC gcdp_addl. Qed.

Lemma gcdp_mull m n : gcdp n (m * n) %= n.
Proof.
have [-> | nn0] := eqVneq n 0; first by rewrite gcd0p mulr0 eqpxx.
have [-> | mn0] := eqVneq m 0; first by rewrite mul0r gcdp0 eqpxx.
rewrite gcdpE modp_mull gcd0p size_mul //; case: leqP; last by rewrite eqpxx.
rewrite (polySpred mn0) addSn /= -[leqRHS]add0n leq_add2r -ltnS.
rewrite -polySpred //= leq_eqVlt ltnS size_poly_leq0 (negPf mn0) orbF.
case/size_poly1P=> c cn0 -> {mn0 m}; rewrite mul_polyC.
suff -> : n %% (c *: n) = 0 by rewrite gcd0p; apply: eqp_scale.
by apply/modp_eq0P; rewrite dvdpZl.
Qed.

Lemma gcdp_mulr m n : gcdp n (n * m) %= n.
Proof. by rewrite mulrC gcdp_mull. Qed.

Lemma gcdp_scalel c m n : c != 0 -> gcdp (c *: m) n %= gcdp m n.
Proof.
move=> cn0; rewrite /eqp dvdp_gcd [gcdp m n %| _]dvdp_gcd !dvdp_gcdr !andbT.
apply/andP; split; last first.
  by apply: dvdp_trans (dvdp_gcdl _ _) _; rewrite dvdpZr.
by apply: dvdp_trans (dvdp_gcdl _ _) _; rewrite dvdpZl.
Qed.

Lemma gcdp_scaler c m n : c != 0 -> gcdp m (c *: n) %= gcdp m n.
Proof.
move=> cn0; apply: eqp_trans (gcdpC _ _) _.
by apply: eqp_trans (gcdp_scalel _ _ _) _ => //; apply: gcdpC.
Qed.

Lemma dvdp_gcd_idl m n : m %| n -> gcdp m n %= m.
Proof.
have [-> | mn0] := eqVneq m 0.
  by rewrite dvd0p => /eqP ->; rewrite gcdp0 eqpxx.
rewrite dvdp_eq; move/eqP/(f_equal (gcdp m)) => h.
apply: eqp_trans (gcdp_mull (n %/ m) _).
by rewrite -h eqp_sym gcdp_scaler // expf_neq0 // lead_coef_eq0.
Qed.

Lemma dvdp_gcd_idr m n : n %| m -> gcdp m n %= n.
Proof. by move/dvdp_gcd_idl; exact/eqp_trans/gcdpC. Qed.

Lemma gcdp_exp p k l : gcdp (p ^+ k) (p ^+ l) %= p ^+ minn k l.
Proof.
case: leqP => [|/ltnW] /subnK <-; rewrite exprD; first exact: gcdp_mull.
exact/(eqp_trans (gcdpC _ _))/gcdp_mull.
Qed.

Lemma gcdp_eq0 p q : gcdp p q == 0 = (p == 0) && (q == 0).
Proof.
apply/idP/idP; last by case/andP => /eqP -> /eqP ->; rewrite gcdp0.
have h m n: gcdp m n == 0 -> (m == 0).
  by rewrite -(dvd0p m); move/eqP<-; rewrite dvdp_gcdl.
by move=> ?; rewrite (h _ q) // (h _ p) // -eqp0 (eqp_ltrans (gcdpC _ _)) eqp0.
Qed.

Lemma eqp_gcdr p q r : q %= r -> gcdp p q %= gcdp p r.
Proof.
move=> eqr; rewrite /eqp !(dvdp_gcd, dvdp_gcdl, andbT) /=.
by rewrite -(eqp_dvdr _ eqr) dvdp_gcdr (eqp_dvdr _ eqr) dvdp_gcdr.
Qed.

Lemma eqp_gcdl r p q : p %= q -> gcdp p r %= gcdp q r.
Proof.
move=> eqr; rewrite /eqp !(dvdp_gcd, dvdp_gcdr, andbT) /=.
by rewrite -(eqp_dvdr _ eqr) dvdp_gcdl (eqp_dvdr _ eqr) dvdp_gcdl.
Qed.

Lemma eqp_gcd p1 p2 q1 q2 : p1 %= p2 -> q1 %= q2 -> gcdp p1 q1 %= gcdp p2 q2.
Proof. move=> e1 e2; exact: eqp_trans (eqp_gcdr _ e2) (eqp_gcdl _ e1). Qed.

Lemma eqp_rgcd_gcd p q : rgcdp p q %= gcdp p q.
Proof.
move: {2}(minn (size p) (size q)) (leqnn (minn (size p) (size q))) => n.
elim: n p q => [p q|n ihn p q hs].
  rewrite leqn0; case: ltnP => _; rewrite size_poly_eq0; move/eqP->.
    by rewrite gcd0p rgcd0p eqpxx.
  by rewrite gcdp0 rgcdp0 eqpxx.
have [-> | pn0] := eqVneq p 0; first by rewrite gcd0p rgcd0p eqpxx.
have [-> | qn0] := eqVneq q 0; first by rewrite gcdp0 rgcdp0 eqpxx.
rewrite gcdpE rgcdpE; case: ltnP hs => sp hs.
  have e := eqp_rmod_mod q p; apply/eqp_trans/ihn: (eqp_gcdl p e).
  by rewrite (eqp_size e) geq_min -ltnS (leq_trans _ hs) ?ltn_modp.
have e := eqp_rmod_mod p q; apply/eqp_trans/ihn: (eqp_gcdl q e).
by rewrite (eqp_size e) geq_min -ltnS (leq_trans _ hs) ?ltn_modp.
Qed.

Lemma gcdp_modl m n : gcdp (m %% n) n %= gcdp m n.
Proof.
have [/modp_small -> // | lenm] := ltnP (size m) (size n).
by rewrite (gcdpE m n) ltnNge lenm.
Qed.

Lemma gcdp_modr m n : gcdp m (n %% m) %= gcdp m n.
Proof.
apply: eqp_trans (gcdpC _ _); apply: eqp_trans (gcdp_modl _ _); exact: gcdpC.
Qed.

Lemma gcdp_def d m n :
    d %| m -> d %| n -> (forall d', d' %| m -> d' %| n -> d' %| d) ->
  gcdp m n %= d.
Proof.
move=> dm dn h; rewrite /eqp dvdp_gcd dm dn !andbT.
by apply: h; rewrite (dvdp_gcdl, dvdp_gcdr).
Qed.

Definition coprimep p q := size (gcdp p q) == 1%N.

Lemma coprimep_size_gcd p q : coprimep p q -> size (gcdp p q) = 1.
Proof. by rewrite /coprimep=> /eqP. Qed.

Lemma coprimep_def p q : coprimep p q = (size (gcdp p q) == 1).
Proof. done. Qed.

Lemma coprimepZl c m n : c != 0 -> coprimep (c *: m) n = coprimep m n.
Proof. by move=> ?; rewrite !coprimep_def (eqp_size (gcdp_scalel _ _ _)). Qed.

Lemma coprimepZr c m n: c != 0 -> coprimep m (c *: n) = coprimep m n.
Proof. by move=> ?; rewrite !coprimep_def (eqp_size (gcdp_scaler _ _ _)). Qed.

Lemma coprimepp p : coprimep p p = (size p == 1).
Proof. by rewrite coprimep_def gcdpp. Qed.

Lemma gcdp_eqp1 p q : gcdp p q %= 1 = coprimep p q.
Proof. by rewrite coprimep_def size_poly_eq1. Qed.

Lemma coprimep_sym p q : coprimep p q = coprimep q p.
Proof. by rewrite -!gcdp_eqp1; apply: eqp_ltrans; rewrite gcdpC. Qed.

Lemma coprime1p p : coprimep 1 p.
Proof. by rewrite /coprimep -[1%N](size_poly1 R); exact/eqP/eqp_size/gcd1p. Qed.

Lemma coprimep1 p : coprimep p 1.
Proof. by rewrite coprimep_sym; apply: coprime1p. Qed.

Lemma coprimep0 p : coprimep p 0 = (p %= 1).
Proof. by rewrite /coprimep gcdp0 size_poly_eq1. Qed.

Lemma coprime0p p : coprimep 0 p = (p %= 1).
Proof. by rewrite coprimep_sym coprimep0. Qed.

(* This is different from coprimeP in div. shall we keep this? *)
Lemma coprimepP p q :
 reflect (forall d, d %| p -> d %| q -> d %= 1) (coprimep p q).
Proof.
rewrite /coprimep; apply: (iffP idP) => [/eqP hs d dvddp dvddq | h].
  have/dvdp_eqp1: d %| gcdp p q by rewrite dvdp_gcd dvddp dvddq.
  by rewrite -size_poly_eq1 hs; exact.
by rewrite size_poly_eq1; case/andP: (dvdp_gcdlr p q); apply: h.
Qed.

Lemma coprimepPn p q : p != 0 ->
  reflect (exists d, (d %| gcdp p q) && ~~ (d %= 1)) (~~ coprimep p q).
Proof.
move=> p0; apply: (iffP idP).
  by rewrite -gcdp_eqp1=> ng1; exists (gcdp p q); rewrite dvdpp /=.
case=> d /andP [dg]; apply: contra; rewrite -gcdp_eqp1=> g1.
by move: dg; rewrite (eqp_dvdr _ g1) dvdp1 size_poly_eq1.
Qed.

Lemma coprimep_dvdl q p r : r %| q -> coprimep p q -> coprimep p r.
Proof.
move=> rp /coprimepP cpq'; apply/coprimepP => d dp dr.
exact/cpq'/(dvdp_trans dr).
Qed.

Lemma coprimep_dvdr p q r : r %| p -> coprimep p q -> coprimep r q.
Proof.
by move=> rp; rewrite ![coprimep _ q]coprimep_sym; apply/coprimep_dvdl.
Qed.

Lemma coprimep_modl p q : coprimep (p %% q) q = coprimep p q.
Proof.
rewrite !coprimep_def [in RHS]gcdpE.
by case: ltnP => // hpq; rewrite modp_small // gcdpE hpq.
Qed.

Lemma coprimep_modr q p : coprimep q (p %% q) = coprimep q p.
Proof. by rewrite ![coprimep q _]coprimep_sym coprimep_modl. Qed.

Lemma rcoprimep_coprimep q p : rcoprimep q p = coprimep q p.
Proof. by rewrite /coprimep /rcoprimep (eqp_size (eqp_rgcd_gcd _ _)). Qed.

Lemma eqp_coprimepr p q r : q %= r -> coprimep p q = coprimep p r.
Proof. by rewrite -!gcdp_eqp1; move/(eqp_gcdr p)/eqp_ltrans. Qed.

Lemma eqp_coprimepl p q r : q %= r -> coprimep q p = coprimep r p.
Proof. by rewrite !(coprimep_sym _ p); apply: eqp_coprimepr. Qed.

(* This should be implemented with an extended remainder sequence *)
Fixpoint egcdp_rec p q k {struct k} : {poly R} * {poly R} :=
  if k is k'.+1 then
    if q == 0 then (1, 0) else
    let: (u, v) := egcdp_rec q (p %% q) k' in
      (lead_coef q ^+ scalp p q *: v, (u - v * (p %/ q)))
  else (1, 0).

Definition egcdp p q :=
  if size q <= size p then egcdp_rec p q (size q)
    else let e := egcdp_rec q p (size p) in (e.2, e.1).

(* No provable egcd0p *)
Lemma egcdp0 p : egcdp p 0 = (1, 0). Proof. by rewrite /egcdp size_poly0. Qed.

Lemma egcdp_recP : forall k p q, q != 0 -> size q <= k -> size q <= size p ->
  let e := (egcdp_rec p q k) in
    [/\ size e.1 <= size q, size e.2 <= size p & gcdp p q %= e.1 * p + e.2 * q].
Proof.
elim=> [|k ihk] p q /= qn0; first by rewrite size_poly_leq0 (negPf qn0).
move=> sqSn qsp; rewrite (negPf qn0).
have sp : size p > 0 by apply: leq_trans qsp; rewrite size_poly_gt0.
have [r0 | rn0] /= := eqVneq (p %%q) 0.
  rewrite r0 /egcdp_rec; case: k ihk sqSn => [|n] ihn sqSn /=.
    rewrite !scaler0 !mul0r subr0 add0r mul1r size_poly0 size_poly1.
    by rewrite dvdp_gcd_idr /dvdp ?r0.
  rewrite !eqxx mul0r scaler0 /= mul0r add0r subr0 mul1r size_poly0 size_poly1.
  by rewrite dvdp_gcd_idr /dvdp ?r0 //.
have h1 : size (p %% q) <= k.
  by rewrite -ltnS; apply: leq_trans sqSn; rewrite ltn_modp.
have h2 : size (p %% q) <= size q by rewrite ltnW // ltn_modp.
have := ihk q (p %% q) rn0 h1 h2.
case: (egcdp_rec _ _)=> u v /= => [[ihn'1 ihn'2 ihn'3]].
rewrite gcdpE ltnNge qsp //= (eqp_ltrans (gcdpC _ _)); split; last first.
- apply: (eqp_trans ihn'3).
  rewrite mulrBl addrCA -scalerAl scalerAr -mulrA -mulrBr.
  by rewrite divp_eq addrAC subrr add0r eqpxx.
- apply: (leq_trans (size_polyD _ _)).
  have [-> | vn0] := eqVneq v 0.
    rewrite mul0r size_polyN size_poly0 maxn0; apply: leq_trans ihn'1 _.
    exact: leq_modp.
  have [-> | qqn0] := eqVneq (p %/ q) 0.
    rewrite mulr0 size_polyN size_poly0 maxn0; apply: leq_trans ihn'1 _.
    exact: leq_modp.
  rewrite geq_max (leq_trans ihn'1) ?leq_modp //= size_polyN size_mul //.
  move: (ihn'2); rewrite (polySpred vn0) (polySpred qn0).
  rewrite -(ltn_add2r (size (p %/ q))) !addSn /= ltnS; move/leq_trans; apply.
  rewrite size_divp // addnBA ?addKn //.
  by apply: leq_trans qsp; apply: leq_pred.
- by rewrite size_scale // lc_expn_scalp_neq0.
Qed.

Lemma egcdpP p q : p != 0 -> q != 0 -> forall (e := egcdp p q),
  [/\ size e.1 <= size q, size e.2 <= size p & gcdp p q %= e.1 * p + e.2 * q].
Proof.
rewrite /egcdp => pn0 qn0; case: (leqP (size q) (size p)) => /= [|/ltnW] hp.
  exact: egcdp_recP.
case: (egcdp_recP pn0 (leqnn (size p)) hp) => h1 h2 h3; split => //.
by rewrite (eqp_ltrans (gcdpC _ _)) addrC.
Qed.

Lemma egcdpE p q (e := egcdp p q) : gcdp p q %= e.1 * p + e.2 * q.
Proof.
rewrite {}/e; have [-> /= | qn0] := eqVneq q 0.
  by rewrite gcdp0 egcdp0 mul1r mulr0 addr0.
have [-> | pn0] := eqVneq p 0; last by case: (egcdpP pn0 qn0).
by rewrite gcd0p /egcdp size_poly0 size_poly_leq0 (negPf qn0) /= !simp.
Qed.

Lemma Bezoutp p q : exists u, u.1 * p + u.2 * q %= (gcdp p q).
Proof.
have [-> | pn0] := eqVneq p 0.
  by rewrite gcd0p; exists (0, 1); rewrite mul0r mul1r add0r.
have [-> | qn0] := eqVneq q 0.
  by rewrite gcdp0; exists (1, 0); rewrite mul0r mul1r addr0.
pose e := egcdp p q; exists e; rewrite eqp_sym.
by case: (egcdpP pn0 qn0).
Qed.

Lemma Bezout_coprimepP p q :
  reflect (exists u, u.1 * p + u.2 * q %= 1) (coprimep p q).
Proof.
rewrite -gcdp_eqp1; apply: (iffP idP)=> [g1|].
  by case: (Bezoutp p q) => [[u v] Puv]; exists (u, v); apply: eqp_trans g1.
case=> [[u v]]; rewrite eqp_sym=> Puv; rewrite /eqp (eqp_dvdr _ Puv).
by rewrite dvdp_addr dvdp_mull ?dvdp_gcdl ?dvdp_gcdr //= dvd1p.
Qed.

Lemma coprimep_root p q x : coprimep p q -> root p x -> q.[x] != 0.
Proof.
case/Bezout_coprimepP=> [[u v] euv] px0.
move/eqpP: euv => [[c1 c2]] /andP /= [c1n0 c2n0 e].
suffices: c1 * (v.[x] * q.[x]) != 0.
  by rewrite !mulf_eq0 !negb_or c1n0 /=; case/andP.
have := f_equal (horner^~ x) e; rewrite /= !hornerZ hornerD.
by rewrite !hornerM (eqP px0) mulr0 add0r hornerC mulr1; move->.
Qed.

Lemma Gauss_dvdpl p q d: coprimep d q -> (d %| p * q) = (d %| p).
Proof.
move/Bezout_coprimepP=>[[u v] Puv]; apply/idP/idP; last exact: dvdp_mulr.
move/(eqp_mull p): Puv; rewrite mulr1 mulrDr eqp_sym=> peq dpq.
rewrite (eqp_dvdr _ peq) dvdp_addr; first by rewrite mulrA mulrAC dvdp_mulr.
by rewrite mulrA dvdp_mull ?dvdpp.
Qed.

Lemma Gauss_dvdpr p q d: coprimep d q -> (d %| q * p) = (d %| p).
Proof. by rewrite mulrC; apply: Gauss_dvdpl. Qed.

(* This could be simplified with the introduction of lcmp *)
Lemma Gauss_dvdp m n p : coprimep m n -> (m * n %| p) = (m %| p) && (n %| p).
Proof.
have [-> | mn0] := eqVneq m 0.
  by rewrite coprime0p => /eqp_dvdl->; rewrite !mul0r dvd0p dvd1p andbT.
have [-> | nn0] := eqVneq n 0.
  by rewrite coprimep0 => /eqp_dvdl->; rewrite !mulr0 dvd1p.
move=> hc; apply/idP/idP => [mnmp | /andP [dmp dnp]].
  move/Gauss_dvdpl: hc => <-; move: (dvdp_mull m mnmp); rewrite dvdp_mul2l //.
  move->; move: (dvdp_mulr n mnmp); rewrite dvdp_mul2r // andbT.
  exact: dvdp_mulr.
move: (dnp); rewrite dvdp_eq.
set c2 := _ ^+ _; set q2 := _ %/ _; move/eqP=> e2.
have/esym := Gauss_dvdpl q2 hc; rewrite -e2.
have -> : m %| c2 *: p by rewrite -mul_polyC dvdp_mull.
rewrite dvdp_eq; set c3 := _ ^+ _; set q3 := _ %/ _; move/eqP=> e3.
apply: (@eq_dvdp (c3 * c2) q3).
  by rewrite mulf_neq0 // expf_neq0 // lead_coef_eq0.
by rewrite mulrA -e3 -scalerAl -e2 scalerA.
Qed.

Lemma Gauss_gcdpr p m n : coprimep p m -> gcdp p (m * n) %= gcdp p n.
Proof.
move=> co_pm; apply/eqP; rewrite /eqp !dvdp_gcd !dvdp_gcdl /= andbC.
rewrite dvdp_mull ?dvdp_gcdr // -(@Gauss_dvdpl _ m).
  by rewrite mulrC dvdp_gcdr.
apply/coprimepP=> d; rewrite dvdp_gcd; case/andP=> hdp _ hdm.
by move/coprimepP: co_pm; apply.
Qed.

Lemma Gauss_gcdpl p m n : coprimep p n -> gcdp p (m * n) %= gcdp p m.
Proof. by move=> co_pn; rewrite mulrC Gauss_gcdpr. Qed.

Lemma coprimepMr p q r : coprimep p (q * r) = (coprimep p q && coprimep p r).
Proof.
apply/coprimepP/andP=> [hp | [/coprimepP-hq hr]].
  by split; apply/coprimepP=> d dp dq; rewrite hp //;
     [apply/dvdp_mulr | apply/dvdp_mull].
move=> d dp dqr; move/(_ _ dp) in hq.
rewrite Gauss_dvdpl in dqr; first exact: hq.
by move/coprimep_dvdr: hr; apply.
Qed.

Lemma coprimepMl p q r: coprimep (q * r) p = (coprimep q p && coprimep r p).
Proof. by rewrite ![coprimep _ p]coprimep_sym coprimepMr. Qed.

Lemma modp_coprime k u n : k != 0 -> (k * u) %% n %= 1 -> coprimep k n.
Proof.
move=> kn0 hmod; apply/Bezout_coprimepP.
exists (((lead_coef n)^+(scalp (k * u) n) *: u), (- (k * u %/ n))).
rewrite -scalerAl mulrC (divp_eq (u * k) n) mulNr -addrAC subrr add0r.
by rewrite mulrC.
Qed.

Lemma coprimep_pexpl k m n : 0 < k -> coprimep (m ^+ k) n = coprimep m n.
Proof.
case: k => // k _; elim: k => [|k IHk]; first by rewrite expr1.
by rewrite exprS coprimepMl -IHk andbb.
Qed.

Lemma coprimep_pexpr k m n : 0 < k -> coprimep m (n ^+ k) = coprimep m n.
Proof. by move=> k_gt0; rewrite !(coprimep_sym m) coprimep_pexpl. Qed.

Lemma coprimep_expl k m n : coprimep m n -> coprimep (m ^+ k) n.
Proof. by case: k => [|k] co_pm; rewrite ?coprime1p // coprimep_pexpl. Qed.

Lemma coprimep_expr k m n : coprimep m n -> coprimep m (n ^+ k).
Proof. by rewrite !(coprimep_sym m); apply: coprimep_expl. Qed.

Lemma gcdp_mul2l p q r : gcdp (p * q) (p * r) %= (p * gcdp q r).
Proof.
have [->|hp] := eqVneq p 0; first by rewrite !mul0r gcdp0 eqpxx.
rewrite /eqp !dvdp_gcd !dvdp_mul2l // dvdp_gcdr dvdp_gcdl !andbT.
move: (Bezoutp q r) => [[u v]] huv.
rewrite eqp_sym in huv; rewrite (eqp_dvdr _ (eqp_mull _ huv)).
rewrite mulrDr ![p * (_ * _)]mulrCA.
by apply: dvdp_add; rewrite dvdp_mull// (dvdp_gcdr, dvdp_gcdl).
Qed.

Lemma gcdp_mul2r q r p : gcdp (q * p) (r * p) %= gcdp q r * p.
Proof. by rewrite ![_ * p]mulrC gcdp_mul2l. Qed.

Lemma mulp_gcdr p q r : r * (gcdp p q) %= gcdp (r * p) (r * q).
Proof. by rewrite eqp_sym gcdp_mul2l. Qed.

Lemma mulp_gcdl p q r : (gcdp p q) * r %= gcdp (p * r) (q * r).
Proof. by rewrite eqp_sym gcdp_mul2r. Qed.

Lemma coprimep_div_gcd p q : (p != 0) || (q != 0) ->
  coprimep (p %/ (gcdp p q)) (q %/ gcdp p q).
Proof.
rewrite -negb_and -gcdp_eq0 -gcdp_eqp1 => gpq0.
rewrite -(@eqp_mul2r (gcdp p q)) // mul1r (eqp_ltrans (mulp_gcdl _ _ _)).
have: gcdp p q %| p by rewrite dvdp_gcdl.
have: gcdp p q %| q by rewrite dvdp_gcdr.
rewrite !dvdp_eq => /eqP <- /eqP <-.
have lcn0 k : (lead_coef (gcdp p q)) ^+ k != 0.
  by rewrite expf_neq0 ?lead_coef_eq0.
by apply: eqp_gcd; rewrite ?eqp_scale.
Qed.

Lemma divp_eq0 p q : (p %/ q == 0) = [|| p == 0, q ==0 | size p < size q].
Proof.
apply/eqP/idP=> [d0|]; last first.
  case/or3P; [by move/eqP->; rewrite div0p| by move/eqP->; rewrite divp0|].
  by move/divp_small.
case: eqVneq => // _; case: eqVneq => // qn0.
move: (divp_eq p q); rewrite d0 mul0r add0r.
move/(f_equal (fun x : {poly R} => size x)).
by rewrite size_scale ?lc_expn_scalp_neq0 // => ->; rewrite ltn_modp qn0 !orbT.
Qed.

Lemma dvdp_div_eq0 p q : q %| p -> (p %/ q == 0) = (p == 0).
Proof.
move=> dvdp_qp; have [->|p_neq0] := eqVneq p 0; first by rewrite div0p eqxx.
rewrite divp_eq0 ltnNge dvdp_leq // (negPf p_neq0) orbF /=.
by apply: contraTF dvdp_qp=> /eqP ->; rewrite dvd0p.
Qed.

Lemma Bezout_coprimepPn p q : p != 0 -> q != 0 ->
  reflect (exists2 uv : {poly R} * {poly R},
    (0 < size uv.1 < size q) && (0 < size uv.2 < size p) &
      uv.1 * p = uv.2 * q)
    (~~ (coprimep p q)).
Proof.
move=> pn0 qn0; apply: (iffP idP); last first.
  case=> [[u v] /= /andP [/andP [ps1 s1] /andP [ps2 s2]] e].
  have: ~~(size (q * p) <= size (u * p)).
    rewrite -ltnNge !size_mul // -?size_poly_gt0 // (polySpred pn0) !addnS.
    by rewrite ltn_add2r.
  apply: contra => ?; apply: dvdp_leq; rewrite ?mulf_neq0 // -?size_poly_gt0 //.
  by rewrite mulrC Gauss_dvdp // dvdp_mull // e dvdp_mull.
rewrite coprimep_def neq_ltn ltnS size_poly_leq0 gcdp_eq0.
rewrite (negPf pn0) (negPf qn0) /=.
case sg: (size (gcdp p q)) => [|n] //; case: n sg=> [|n] // sg _.
move: (dvdp_gcdl p q); rewrite dvdp_eq; set c1 := _ ^+ _; move/eqP=> hu1.
move: (dvdp_gcdr p q); rewrite dvdp_eq; set c2 := _ ^+ _; move/eqP=> hv1.
exists (c1 *: (q %/ gcdp p q), c2 *: (p %/ gcdp p q)); last first.
  by rewrite -!scalerAl !scalerAr hu1 hv1 mulrCA.
rewrite !size_scale ?lc_expn_scalp_neq0 //= !size_poly_gt0 !divp_eq0.
rewrite gcdp_eq0 !(negPf pn0) !(negPf qn0) /= -!leqNgt leq_gcdpl //.
rewrite leq_gcdpr //= !ltn_divpl -?size_poly_eq0 ?sg //.
rewrite !size_mul // -?size_poly_eq0 ?sg // ![(_ + n.+2)%N]addnS /=.
by rewrite -!(addn1 (size _)) !leq_add2l.
Qed.

Lemma dvdp_pexp2r m n k : k > 0 -> (m ^+ k %| n ^+ k) = (m %| n).
Proof.
move=> k_gt0; apply/idP/idP; last exact: dvdp_exp2r.
have [-> // | nn0] := eqVneq n 0; have [-> | mn0] := eqVneq m 0.
  move/prednK: k_gt0=> {1}<-; rewrite exprS mul0r //= !dvd0p expf_eq0.
  by case/andP=> _ ->.
set d := gcdp m n; have := dvdp_gcdr m n; rewrite -/d dvdp_eq.
set c1 := _ ^+ _; set n' := _ %/ _; move/eqP=> def_n.
have := dvdp_gcdl m n; rewrite -/d dvdp_eq.
set c2 := _ ^+ _; set m' := _ %/ _; move/eqP=> def_m.
have dn0 : d != 0 by rewrite gcdp_eq0 negb_and nn0 orbT.
have c1n0 : c1 != 0 by rewrite !expf_neq0 // lead_coef_eq0.
have c2n0 : c2 != 0 by rewrite !expf_neq0 // lead_coef_eq0.
have c2k_n0 : c2 ^+ k != 0 by rewrite !expf_neq0 // lead_coef_eq0.
rewrite -(@dvdpZr (c1 ^+ k)) ?expf_neq0 ?lead_coef_eq0 //.
rewrite -(@dvdpZl (c2 ^+ k)) // -!exprZn def_m def_n !exprMn.
rewrite dvdp_mul2r ?expf_neq0 //.
have: coprimep (m' ^+ k) (n' ^+ k).
  by rewrite coprimep_pexpl // coprimep_pexpr // coprimep_div_gcd ?mn0.
move/coprimepP=> hc hd.
have /size_poly1P [c cn0 em'] : size m' == 1.
  case: (eqVneq m' 0) def_m => [-> /eqP | m'_n0 def_m].
    by rewrite mul0r scale_poly_eq0 (negPf mn0) (negPf c2n0).
  have := hc _ (dvdpp _) hd; rewrite -size_poly_eq1.
  rewrite polySpred; last by rewrite expf_eq0 negb_and m'_n0 orbT.
  by rewrite size_exp eqSS muln_eq0 orbC eqn0Ngt k_gt0 /= -eqSS -polySpred.
rewrite -(@dvdpZl c2) // def_m em' mul_polyC dvdpZl //.
by rewrite -(@dvdpZr c1) // def_n dvdp_mull.
Qed.

Lemma root_gcd p q x : root (gcdp p q) x = root p x && root q x.
Proof.
rewrite /= !root_factor_theorem; apply/idP/andP=> [dg| [dp dq]].
  by split; apply: dvdp_trans dg _; rewrite ?(dvdp_gcdl, dvdp_gcdr).
have:= Bezoutp p q => [[[u v]]]; rewrite eqp_sym=> e.
by rewrite (eqp_dvdr _ e) dvdp_addl dvdp_mull.
Qed.

Lemma root_biggcd x (ps : seq {poly R}) :
  root (\big[gcdp/0]_(p <- ps) p) x = all (fun p => root p x) ps.
Proof.
elim: ps => [|p ps ihp]; first by rewrite big_nil root0.
by rewrite big_cons /= root_gcd ihp.
Qed.

(* "gdcop Q P" is the Greatest Divisor of P which is coprime to Q *)
(* if P null, we pose that gdcop returns 1 if Q null, 0 otherwise*)
Fixpoint gdcop_rec q p k :=
  if k is m.+1 then
      if coprimep p q then p
        else gdcop_rec q (divp p (gcdp p q)) m
    else (q == 0)%:R.

Definition gdcop q p := gdcop_rec q p (size p).

Variant gdcop_spec q p : {poly R} -> Type :=
  GdcopSpec r of (dvdp r p) & ((coprimep r q) || (p == 0))
  & (forall d, dvdp d p -> coprimep d q -> dvdp d r)
  : gdcop_spec q p r.

Lemma gdcop0 q : gdcop q 0 = (q == 0)%:R.
Proof. by rewrite /gdcop size_poly0. Qed.

Lemma gdcop_recP q p k : size p <= k -> gdcop_spec q p (gdcop_rec q p k).
Proof.
elim: k p => [p | k ihk p] /=.
  move/size_poly_leq0P->.
  have [->|q0] := eqVneq; split; rewrite ?coprime1p // ?eqxx ?orbT //.
  by move=> d _; rewrite coprimep0 dvdp1 size_poly_eq1.
move=> hs; case cop : (coprimep _ _); first by split; rewrite ?dvdpp ?cop.
have [-> | p0] := eqVneq p 0.
  by rewrite div0p; apply: ihk; rewrite size_poly0 leq0n.
have [-> | q0] := eqVneq q 0.
  rewrite gcdp0 divpp ?p0 //= => {hs ihk}; case: k=> /=.
    rewrite eqxx; split; rewrite ?dvd1p ?coprimep0 ?eqpxx //=.
    by move=> d _; rewrite coprimep0 dvdp1 size_poly_eq1.
  move=> n; rewrite coprimep0 polyC_eqp1 //; rewrite lc_expn_scalp_neq0.
  split; first by rewrite (@eqp_dvdl 1) ?dvd1p // polyC_eqp1 lc_expn_scalp_neq0.
    by rewrite coprimep0 polyC_eqp1 // ?lc_expn_scalp_neq0.
  by move=> d _; rewrite coprimep0; move/eqp_dvdl->; rewrite dvd1p.
move: (dvdp_gcdl p q); rewrite dvdp_eq; move/eqP=> e.
have sgp : size (gcdp p q) <= size p.
  by apply: dvdp_leq; rewrite ?gcdp_eq0 ?p0 ?q0 // dvdp_gcdl.
have : p %/ gcdp p q != 0; last move/negPf=>p'n0.
  apply: dvdpN0 (dvdp_mulIl (p %/ gcdp p q) (gcdp p q)) _.
  by rewrite -e scale_poly_eq0 negb_or lc_expn_scalp_neq0.
have gn0 : gcdp p q != 0.
  apply: dvdpN0 (dvdp_mulIr (p %/ gcdp p q) (gcdp p q)) _.
  by rewrite -e scale_poly_eq0 negb_or lc_expn_scalp_neq0.
have sp' : size (p %/ (gcdp p q)) <= k.
  rewrite size_divp ?sgp // leq_subLR (leq_trans hs) // -add1n leq_add2r -subn1.
  by rewrite ltn_subRL add1n ltn_neqAle eq_sym [_ == _]cop size_poly_gt0 gn0.
case (ihk _ sp')=> r' dr'p'; first rewrite p'n0 orbF=> cr'q maxr'.
constructor=> //=; rewrite ?(negPf p0) ?orbF //.
  exact/(dvdp_trans dr'p')/divp_dvd/dvdp_gcdl.
move=> d dp cdq; apply: maxr'; last by rewrite cdq.
case dpq: (d %| gcdp p q).
  move: (dpq); rewrite dvdp_gcd dp /= => dq; apply: dvdUp.
  apply: contraLR cdq => nd1; apply/coprimepPn; last first.
    by exists d; rewrite dvdp_gcd dvdpp dq nd1.
  by apply: contraNneq p0 => d0; move: dp; rewrite d0 dvd0p.
apply: contraLR dp => ndp'.
rewrite (@eqp_dvdr ((lead_coef (gcdp p q) ^+ scalp p (gcdp p q))*:p)).
  by rewrite e; rewrite Gauss_dvdpl //; apply: (coprimep_dvdl (dvdp_gcdr _ _)).
by rewrite eqp_sym eqp_scale // lc_expn_scalp_neq0.
Qed.

Lemma gdcopP q p : gdcop_spec q p (gdcop q p).
Proof. by rewrite /gdcop; apply: gdcop_recP. Qed.

Lemma coprimep_gdco p q : (q != 0)%B -> coprimep (gdcop p q) p.
Proof. by move=> q_neq0; case: gdcopP=> d; rewrite (negPf q_neq0) orbF. Qed.

Lemma size2_dvdp_gdco p q d : p != 0 -> size d = 2 ->
  (d %| (gdcop q p)) = (d %| p) && ~~(d %| q).
Proof.
have [-> | dn0] := eqVneq d 0; first by rewrite size_poly0.
move=> p0 sd; apply/idP/idP.
  case: gdcopP=> r rp crq maxr dr; move/negPf: (p0)=> p0f.
  rewrite (dvdp_trans dr) //=.
  apply: contraL crq => dq; rewrite p0f orbF; apply/coprimepPn.
    by apply: contraNneq p0 => r0; move: rp; rewrite r0 dvd0p.
  by exists d; rewrite dvdp_gcd dr dq -size_poly_eq1 sd.
case/andP=> dp dq; case: gdcopP=> r rp crq maxr; apply: maxr=> //.
apply/coprimepP=> x xd xq.
move: (dvdp_leq dn0 xd); rewrite leq_eqVlt sd; case/orP; last first.
  rewrite ltnS leq_eqVlt ltnS size_poly_leq0 orbC.
  case/predU1P => [x0|]; last by rewrite -size_poly_eq1.
  by move: xd; rewrite x0 dvd0p (negPf dn0).
by rewrite -sd dvdp_size_eqp //; move/(eqp_dvdl q); rewrite xq (negPf dq).
Qed.

Lemma dvdp_gdco p q : (gdcop p q) %| q. Proof. by case: gdcopP. Qed.

Lemma root_gdco p q x : p != 0 -> root (gdcop q p) x = root p x && ~~(root q x).
Proof.
move=> p0 /=; rewrite !root_factor_theorem.
apply: size2_dvdp_gdco; rewrite ?p0 //.
by rewrite size_polyDl size_polyX // size_polyN size_polyC ltnS; case: (x != 0).
Qed.

Lemma dvdp_comp_poly r p q : (p %| q) -> (p \Po r) %| (q \Po r).
Proof.
have [-> | pn0] := eqVneq p 0.
  by rewrite comp_poly0 !dvd0p; move/eqP->; rewrite comp_poly0.
rewrite dvdp_eq; set c := _ ^+ _; set s := _ %/ _; move/eqP=> Hq.
apply: (@eq_dvdp c (s \Po r)); first by rewrite expf_neq0 // lead_coef_eq0.
by rewrite -comp_polyZ Hq comp_polyM.
Qed.

Lemma gcdp_comp_poly r p q : gcdp p q \Po r %= gcdp (p \Po r) (q \Po r).
Proof.
apply/andP; split.
  by rewrite dvdp_gcd !dvdp_comp_poly ?dvdp_gcdl ?dvdp_gcdr.
case: (Bezoutp p q) => [[u v]] /andP [].
move/(dvdp_comp_poly r) => Huv _.
rewrite (dvdp_trans _ Huv) // comp_polyD !comp_polyM.
by rewrite dvdp_add // dvdp_mull //; [ exact: dvdp_gcdl | exact: dvdp_gcdr].
Qed.

Lemma coprimep_comp_poly r p q : coprimep p q -> coprimep (p \Po r) (q \Po r).
Proof.
rewrite -!gcdp_eqp1 -!size_poly_eq1 -!dvdp1; move/(dvdp_comp_poly r).
rewrite comp_polyC => Hgcd.
by apply: dvdp_trans Hgcd; case/andP: (gcdp_comp_poly r p q).
Qed.

Lemma coprimep_addl_mul p q r : coprimep r (p * r + q) = coprimep r q.
Proof. by rewrite !coprimep_def (eqp_size (gcdp_addl_mul _ _ _)). Qed.

Definition irreducible_poly p :=
  (size p > 1) * (forall q, size q != 1 -> q %| p -> q %= p) : Prop.

Lemma irredp_neq0 p : irreducible_poly p -> p != 0.
Proof. by rewrite -size_poly_gt0 => [[/ltnW]]. Qed.

Definition apply_irredp p (irr_p : irreducible_poly p) := irr_p.2.
Coercion apply_irredp : irreducible_poly >-> Funclass.

Lemma modp_XsubC p c : p %% ('X - c%:P) = p.[c]%:P.
Proof.
have/factor_theorem [q /(canRL (subrK _)) Dp]: root (p - p.[c]%:P) c.
  by rewrite /root !hornerE subrr.
rewrite modpE /= lead_coefXsubC unitr1 expr1n invr1 scale1r [in LHS]Dp.
rewrite RingMonic.rmodp_addl_mul_small // ?monicXsubC// size_XsubC size_polyC.
by case: (p.[c] == 0).
Qed.

Lemma coprimep_XsubC p c : coprimep p ('X - c%:P) = ~~ root p c.
Proof.
rewrite -coprimep_modl modp_XsubC /root -alg_polyC.
have [-> | /coprimepZl->] := eqVneq; last exact: coprime1p.
by rewrite scale0r /coprimep gcd0p size_XsubC.
Qed.

Lemma coprimep_XsubC2 (a b : R) : b - a != 0 ->
  coprimep ('X - a%:P) ('X - b%:P).
Proof. by move=> bBa_neq0; rewrite coprimep_XsubC rootE hornerXsubC. Qed.

Lemma coprimepX p : coprimep p 'X = ~~ root p 0.
Proof. by rewrite -['X]subr0 coprimep_XsubC. Qed.

Lemma eqp_monic : {in monic &, forall p q, (p %= q) = (p == q)}.
Proof.
move=> p q monic_p monic_q; apply/idP/eqP=> [|-> //].
case/eqpP=> [[a b] /= /andP[a_neq0 _] eq_pq].
apply: (@mulfI _ a%:P); first by rewrite polyC_eq0.
rewrite !mul_polyC eq_pq; congr (_ *: q); apply: (mulIf (oner_neq0 _)).
by rewrite -[in LHS](monicP monic_q) -(monicP monic_p) -!lead_coefZ eq_pq.
Qed.

Lemma dvdp_mul_XsubC p q c :
  (p %| ('X - c%:P) * q) = ((if root p c then p %/ ('X - c%:P) else p) %| q).
Proof.
case: ifPn => [| not_pc0]; last by rewrite Gauss_dvdpr ?coprimep_XsubC.
rewrite root_factor_theorem -eqp_div_XsubC mulrC => /eqP{1}->.
by rewrite dvdp_mul2l ?polyXsubC_eq0.
Qed.

Lemma dvdp_prod_XsubC (I : Type) (r : seq I) (F : I -> R) p :
    p %| \prod_(i <- r) ('X - (F i)%:P) ->
  {m | p %= \prod_(i <- mask m r) ('X - (F i)%:P)}.
Proof.
elim: r => [|i r IHr] in p *.
  by rewrite big_nil dvdp1; exists nil; rewrite // big_nil -size_poly_eq1.
rewrite big_cons dvdp_mul_XsubC root_factor_theorem -eqp_div_XsubC.
case: eqP => [{2}-> | _] /IHr[m Dp]; last by exists (false :: m).
by exists (true :: m); rewrite /= mulrC big_cons eqp_mul2l ?polyXsubC_eq0.
Qed.

Lemma irredp_XsubC (x : R) : irreducible_poly ('X - x%:P).
Proof.
split=> [|d size_d d_dv_Xx]; first by rewrite size_XsubC.
have: ~ d %= 1 by apply/negP; rewrite -size_poly_eq1.
have [|m /=] := @dvdp_prod_XsubC _ [:: x] id d; first by rewrite big_seq1.
by case: m => [|[] [|_ _] /=]; rewrite (big_nil, big_seq1).
Qed.

Lemma irredp_XaddC (x : R) : irreducible_poly ('X + x%:P).
Proof. by rewrite -[x]opprK rmorphN; apply: irredp_XsubC. Qed.

Lemma irredp_XsubCP d p :
  irreducible_poly p -> d %| p -> {d %= 1} + {d %= p}.
Proof.
move=> irred_p dvd_dp; have [] := boolP (_ %= 1); first by left.
by rewrite -size_poly_eq1=> /irred_p /(_ dvd_dp); right.
Qed.

Lemma dvdp_exp_XsubCP (p : {poly R}) (c : R) (n : nat) :
  reflect (exists2 k, (k <= n)%N & p %= ('X - c%:P) ^+ k)
          (p %| ('X - c%:P) ^+ n).
Proof.
apply: (iffP idP) => [|[k lkn /eqp_dvdl->]]; last by rewrite dvdp_exp2l.
move=> /Pdiv.WeakIdomain.dvdpP[[/= a q] a_neq0].
have [m [r]] := multiplicity_XsubC p c; have [->|pN0]/= := eqVneq p 0.
  rewrite mulr0 => _ _ /eqP;  rewrite scale_poly_eq0 (negPf a_neq0)/=.
  by rewrite expf_eq0/= andbC polyXsubC_eq0.
move=> rNc ->; rewrite mulrA => eq_qrm; exists m.
  have: ('X - c%:P) ^+ m %| a *: ('X - c%:P) ^+ n by rewrite eq_qrm dvdp_mull.
  by rewrite (eqp_dvdr _ (eqp_scale _ _))// dvdp_Pexp2l// size_XsubC.
suff /eqP : size r = 1%N.
  by rewrite size_poly_eq1 => /eqp_mulr/eqp_trans->//; rewrite mul1r eqpxx.
have : r %| a *: ('X - c%:P) ^+ n by rewrite eq_qrm mulrAC dvdp_mull.
rewrite (eqp_dvdr _ (eqp_scale _ _))//.
move: rNc; rewrite -coprimep_XsubC => /(coprimep_expr n) /coprimepP.
by move=> /(_ _ (dvdpp _)); rewrite -size_poly_eq1 => /(_ _)/eqP.
Qed.

End IDomainPseudoDivision.
Arguments gcdp : simpl never.

#[global] Hint Resolve eqpxx divp0 divp1 mod0p modp0 modp1 : core.
#[global] Hint Resolve dvdp_mull dvdp_mulr dvdpp dvdp0 : core.
Arguments dvdp_exp_XsubCP {R p c n}.

End CommonIdomain.

Module Idomain.

Include IdomainDefs.
Export IdomainDefs.
Include WeakIdomain.
Include CommonIdomain.

End Idomain.

Module IdomainMonic.

Import Ring ComRing UnitRing IdomainDefs Idomain.

Section IdomainMonic.

Variable R : idomainType.

Implicit Type p d r : {poly R}.

Section MonicDivisor.

Variable q : {poly R}.
Hypothesis monq : q \is monic.

Lemma divpE p : p %/ q = rdivp p q.
Proof. by rewrite divpE (eqP monq) unitr1 expr1n invr1 scale1r. Qed.

Lemma modpE p : p %% q = rmodp p q.
Proof. by rewrite modpE (eqP monq) unitr1 expr1n invr1 scale1r. Qed.

Lemma scalpE p : scalp p q = 0.
Proof. by rewrite scalpE (eqP monq) unitr1. Qed.

Lemma divp_eq p : p = (p %/ q) * q + (p %% q).
Proof. by rewrite -divp_eq (eqP monq) expr1n scale1r. Qed.

Lemma divpp p : q %/ q = 1.
Proof. by rewrite divpp ?monic_neq0 // (eqP monq) expr1n. Qed.

Lemma dvdp_eq p : (q %| p) = (p == (p %/ q) * q).
Proof. by rewrite dvdp_eq (eqP monq) expr1n scale1r. Qed.

Lemma dvdpP p : reflect (exists qq, p = qq * q) (q %| p).
Proof.
apply: (iffP idP); first by rewrite dvdp_eq; move/eqP=> e; exists (p %/ q).
by case=> qq ->; rewrite dvdp_mull // dvdpp.
Qed.

Lemma mulpK p : p * q %/ q = p.
Proof. by rewrite mulpK ?monic_neq0 // (eqP monq) expr1n scale1r. Qed.

Lemma mulKp p : q * p %/ q = p. Proof. by rewrite mulrC mulpK. Qed.

End MonicDivisor.

Lemma drop_poly_divp n p : drop_poly n p = p %/ 'X^n.
Proof. by rewrite RingMonic.drop_poly_rdivp divpE // monicXn. Qed.

Lemma take_poly_modp n p : take_poly n p = p %% 'X^n.
Proof. by rewrite RingMonic.take_poly_rmodp modpE // monicXn. Qed.

End IdomainMonic.

End IdomainMonic.

Module IdomainUnit.

Import Ring ComRing UnitRing IdomainDefs Idomain.

Section UnitDivisor.

Variable R : idomainType.
Variable d : {poly R}.

Hypothesis ulcd : lead_coef d \in GRing.unit.

Implicit Type p q r : {poly R}.

Lemma divp_eq p : p = (p %/ d) * d + (p %% d).
Proof. by have := divp_eq p d; rewrite scalpE ulcd expr0 scale1r. Qed.

Lemma edivpP p q r : p = q * d + r -> size r < size d ->
  q = (p %/ d) /\ r = p %% d.
Proof.
move=> ep srd; have := divp_eq p; rewrite [LHS]ep.
move/eqP; rewrite -subr_eq -addrA addrC eq_sym -subr_eq -mulrBl; move/eqP.
have lcdn0 : lead_coef d != 0 by apply: contraTneq ulcd => ->; rewrite unitr0.
have [-> /esym /eqP|abs] := eqVneq (p %/ d) q.
  by rewrite subrr mul0r subr_eq0 => /eqP<-.
have hleq : size d <= size ((p %/ d - q) * d).
  rewrite size_proper_mul; last first.
    by rewrite mulf_eq0 (negPf lcdn0) orbF lead_coef_eq0 subr_eq0.
  by move: abs; rewrite -subr_eq0; move/polySpred->; rewrite addSn /= leq_addl.
have hlt : size (r - p %% d) < size d.
  apply: leq_ltn_trans (size_polyD _ _) _.
  by rewrite gtn_max srd size_polyN ltn_modp -lead_coef_eq0.
by move=> e; have:= leq_trans hlt hleq; rewrite e ltnn.
Qed.

Lemma divpP p q r : p = q * d + r -> size r < size d -> q = (p %/ d).
Proof. by move/edivpP=> h; case/h. Qed.

Lemma modpP p q r : p = q * d + r -> size r < size d -> r = (p %% d).
Proof. by move/edivpP=> h; case/h. Qed.

Lemma ulc_eqpP p q : lead_coef q \is a GRing.unit ->
  reflect (exists2 c : R, c != 0 & p = c *: q) (p %= q).
Proof.
have [->|] := eqVneq (lead_coef q) 0; first by rewrite unitr0.
rewrite lead_coef_eq0 => nz_q ulcq; apply: (iffP idP).
  have [->|nz_p] := eqVneq p 0; first by rewrite eqp_sym eqp0 (negPf nz_q).
  move/eqp_eq=> eq; exists (lead_coef p / lead_coef q).
    by rewrite mulf_neq0 // ?invr_eq0 lead_coef_eq0.
  by apply/(scaler_injl ulcq); rewrite scalerA mulrCA divrr // mulr1.
by case=> c nz_c ->; apply/eqpP; exists (1, c); rewrite ?scale1r ?oner_eq0.
Qed.

Lemma dvdp_eq p : (d %| p) = (p == p %/ d * d).
Proof.
apply/eqP/eqP=> [modp0 | ->]; last exact: modp_mull.
by rewrite [p in LHS]divp_eq modp0 addr0.
Qed.

Lemma ucl_eqp_eq p q : lead_coef q \is a GRing.unit ->
  p %= q -> p = (lead_coef p / lead_coef q) *: q.
Proof.
move=> ulcq /eqp_eq; move/(congr1 ( *:%R (lead_coef q)^-1 )).
by rewrite !scalerA mulrC divrr // scale1r mulrC.
Qed.

Lemma modpZl c p : (c *: p) %% d = c *: (p %% d).
Proof.
have [-> | cn0] := eqVneq c 0; first by rewrite !scale0r mod0p.
have e : (c *: p) = (c *: (p %/ d)) * d + c *: (p %% d).
  by rewrite -scalerAl -scalerDr -divp_eq.
suff s: size (c *: (p %% d)) < size d by case: (edivpP e s) => _ ->.
rewrite -mul_polyC; apply: leq_ltn_trans (size_polyMleq _ _) _.
rewrite size_polyC cn0 addSn add0n /= ltn_modp -lead_coef_eq0.
by apply: contraTneq ulcd => ->; rewrite unitr0.
Qed.

Lemma divpZl c p : (c *: p) %/ d = c *: (p %/ d).
Proof.
have [-> | cn0] := eqVneq c 0; first by rewrite !scale0r div0p.
have e : (c *: p) = (c *: (p %/ d)) * d + c *: (p %% d).
  by rewrite -scalerAl -scalerDr -divp_eq.
suff s: size (c *: (p %% d)) < size d by case: (edivpP e s) => ->.
rewrite -mul_polyC; apply: leq_ltn_trans (size_polyMleq _ _) _.
rewrite size_polyC cn0 addSn add0n /= ltn_modp -lead_coef_eq0.
by apply: contraTneq ulcd => ->; rewrite unitr0.
Qed.

Lemma eqp_modpl p q : p %= q -> (p %% d) %= (q %% d).
Proof.
case/eqpP=> [[c1 c2]] /andP /= [c1n0 c2n0 e].
by apply/eqpP; exists (c1, c2); rewrite ?c1n0 //= -!modpZl e.
Qed.

Lemma eqp_divl p q : p %= q -> (p %/ d) %= (q %/ d).
Proof.
case/eqpP=> [[c1 c2]] /andP /= [c1n0 c2n0 e].
by apply/eqpP; exists (c1, c2); rewrite ?c1n0 // -!divpZl e.
Qed.

Lemma modpN p : (- p) %% d = - (p %% d).
Proof. by rewrite -mulN1r -[RHS]mulN1r -polyCN !mul_polyC modpZl. Qed.

Lemma divpN p : (- p) %/ d = - (p %/ d).
Proof. by rewrite -mulN1r -[RHS]mulN1r -polyCN !mul_polyC divpZl. Qed.

Lemma modpD p q : (p + q) %% d = p %% d + q %% d.
Proof.
have/edivpP [] // : (p + q) = (p %/ d + q %/ d) * d + (p %% d + q %% d).
  by rewrite mulrDl addrACA -!divp_eq.
apply: leq_ltn_trans (size_polyD _ _) _.
rewrite gtn_max !ltn_modp andbb -lead_coef_eq0.
by apply: contraTneq ulcd => ->; rewrite unitr0.
Qed.

Lemma divpD p q : (p + q) %/ d = p %/ d + q %/ d.
Proof.
have/edivpP [] // : (p + q) = (p %/ d + q %/ d) * d + (p %% d + q %% d).
  by rewrite mulrDl addrACA -!divp_eq.
apply: leq_ltn_trans (size_polyD _ _) _.
rewrite gtn_max !ltn_modp andbb -lead_coef_eq0.
by apply: contraTneq ulcd => ->; rewrite unitr0.
Qed.

Lemma mulpK q : (q * d) %/ d = q.
Proof.
case/esym/edivpP: (addr0 (q * d)); rewrite // size_poly0 size_poly_gt0.
by rewrite -lead_coef_eq0; apply: contraTneq ulcd => ->; rewrite unitr0.
Qed.

Lemma mulKp q : (d * q) %/ d = q. Proof. by rewrite mulrC; apply: mulpK. Qed.

Lemma divp_addl_mul_small q r : size r < size d -> (q * d + r) %/ d = q.
Proof. by move=> srd; rewrite divpD (divp_small srd) addr0 mulpK. Qed.

Lemma modp_addl_mul_small q r : size r < size d -> (q * d + r) %% d = r.
Proof. by move=> srd; rewrite modpD modp_mull add0r modp_small. Qed.

Lemma divp_addl_mul q r : (q * d + r) %/ d = q + r %/ d.
Proof. by rewrite divpD mulpK. Qed.

Lemma divpp : d %/ d = 1. Proof. by rewrite -[d in d %/ _]mul1r mulpK. Qed.

Lemma leq_divMp m : size (m %/ d * d) <= size m.
Proof.
case: (eqVneq d 0) ulcd => [->|dn0 _]; first by rewrite lead_coef0 unitr0.
have [->|q0] := eqVneq (m %/ d) 0; first by rewrite mul0r size_poly0 leq0n.
rewrite {2}(divp_eq m) size_polyDl // size_mul // (polySpred q0) addSn /=.
by rewrite ltn_addl // ltn_modp.
Qed.

Lemma dvdpP p : reflect (exists q, p = q * d) (d %| p).
Proof.
apply: (iffP idP) => [| [k ->]]; last by apply/eqP; rewrite modp_mull.
by rewrite dvdp_eq; move/eqP->; exists (p %/ d).
Qed.

Lemma divpK p : d %| p -> p %/ d * d = p.
Proof. by rewrite dvdp_eq; move/eqP. Qed.

Lemma divpKC p : d %| p -> d * (p %/ d) = p.
Proof. by move=> ?; rewrite mulrC divpK. Qed.

Lemma dvdp_eq_div p q : d %| p -> (q == p %/ d) = (q * d == p).
Proof.
move/divpK=> {2}<-; apply/eqP/eqP; first by move->.
apply/mulIf; rewrite -lead_coef_eq0; apply: contraTneq ulcd => ->.
by rewrite unitr0.
Qed.

Lemma dvdp_eq_mul p q : d %| p -> (p == q * d) = (p %/ d == q).
Proof. by move=> dv_d_p; rewrite eq_sym -dvdp_eq_div // eq_sym. Qed.

Lemma divp_mulA p q : d %| q -> p * (q %/ d) = p * q %/ d.
Proof.
move=> hdm; apply/eqP; rewrite eq_sym -dvdp_eq_mul.
  by rewrite -mulrA divpK.
by move/divpK: hdm<-; rewrite mulrA dvdp_mull // dvdpp.
Qed.

Lemma divp_mulAC m n : d %| m -> m %/ d * n = m * n %/ d.
Proof. by move=> hdm; rewrite mulrC (mulrC m); apply: divp_mulA. Qed.

Lemma divp_mulCA p q : d %| p -> d %| q -> p * (q %/ d) = q * (p %/ d).
Proof. by move=> hdp hdq; rewrite mulrC divp_mulAC // divp_mulA. Qed.

Lemma modp_mul p q : (p * (q %% d)) %% d = (p * q) %% d.
Proof. by rewrite [q in RHS]divp_eq mulrDr modpD mulrA modp_mull add0r. Qed.

End UnitDivisor.

#[deprecated(since="mathcomp 2.4.0", note="Renamed to leq_divMp.")]
Notation leq_trunc_divp := leq_divMp.

Section MoreUnitDivisor.

Variable R : idomainType.
Variable d : {poly R}.
Hypothesis ulcd : lead_coef d \in GRing.unit.

Implicit Types p q : {poly R}.

Lemma expp_sub m n : n <= m -> (d ^+ (m - n))%N = d ^+ m %/ d ^+ n.
Proof. by move/subnK=> {2}<-; rewrite exprD mulpK // lead_coef_exp unitrX. Qed.

Lemma divp_pmul2l p q : lead_coef q \in GRing.unit -> d * p %/ (d * q) = p %/ q.
Proof.
move=> uq; rewrite {1}(divp_eq uq p) mulrDr mulrCA divp_addl_mul //; last first.
  by rewrite lead_coefM unitrM_comm ?ulcd //; red; rewrite mulrC.
have dn0 : d != 0.
  by rewrite -lead_coef_eq0; apply: contraTneq ulcd => ->; rewrite unitr0.
have qn0 : q != 0.
  by rewrite -lead_coef_eq0; apply: contraTneq uq => ->; rewrite unitr0.
have dqn0 : d * q != 0 by rewrite mulf_eq0 negb_or dn0.
suff : size (d * (p %% q)) < size (d * q).
  by rewrite ltnNge -divpN0 // negbK => /eqP ->; rewrite addr0.
have [-> | rn0] := eqVneq (p %% q) 0.
  by rewrite mulr0 size_poly0 size_poly_gt0.
by rewrite !size_mul // (polySpred dn0) !addSn /= ltn_add2l ltn_modp.
Qed.

Lemma divp_pmul2r p q : lead_coef p \in GRing.unit -> q * d %/ (p * d) = q %/ p.
Proof. by move=> uq; rewrite -!(mulrC d) divp_pmul2l. Qed.

Lemma divp_divl r p q :
    lead_coef r \in GRing.unit -> lead_coef p \in GRing.unit ->
  q %/ p %/ r = q %/ (p * r).
Proof.
move=> ulcr ulcp.
have e : q = (q %/ p %/ r) * (p * r) + ((q %/ p) %% r * p + q %% p).
  by rewrite addrA (mulrC p) mulrA -mulrDl; rewrite -divp_eq //; apply: divp_eq.
have pn0 : p != 0.
  by rewrite -lead_coef_eq0; apply: contraTneq ulcp => ->; rewrite unitr0.
have rn0 : r != 0.
  by rewrite -lead_coef_eq0; apply: contraTneq ulcr => ->; rewrite unitr0.
have s : size ((q %/ p) %% r * p + q %% p) < size (p * r).
  have [-> | qn0] := eqVneq ((q %/ p) %% r) 0.
    rewrite mul0r add0r size_mul // (polySpred rn0) addnS /=.
    by apply: leq_trans (leq_addr _ _); rewrite ltn_modp.
  rewrite size_polyDl mulrC.
    by rewrite !size_mul // (polySpred pn0) !addSn /= ltn_add2l ltn_modp.
  rewrite size_mul // (polySpred qn0) addnS /=.
  by apply: leq_trans (leq_addr _ _); rewrite ltn_modp.
case: (edivpP _ e s) => //; rewrite lead_coefM unitrM_comm ?ulcp //.
by red; rewrite mulrC.
Qed.

Lemma divpAC p q : lead_coef p \in GRing.unit -> q %/ d %/ p = q %/ p %/ d.
Proof. by move=> ulcp; rewrite !divp_divl // mulrC. Qed.

Lemma modpZr c p : c \in GRing.unit -> p %% (c *: d) = (p %% d).
Proof.
case: (eqVneq d 0) => [-> | dn0 cn0]; first by rewrite scaler0 !modp0.
have e : p = (c^-1 *: (p %/ d)) * (c *: d) + (p %% d).
  by rewrite scalerCA scalerA mulVr // scale1r -(divp_eq ulcd).
suff s : size (p %% d) < size (c *: d).
  by rewrite (modpP _ e s) // -mul_polyC lead_coefM lead_coefC unitrM cn0.
by rewrite size_scale ?ltn_modp //; apply: contraTneq cn0 => ->; rewrite unitr0.
Qed.

Lemma divpZr c p : c \in GRing.unit -> p %/ (c *: d) = c^-1 *: (p %/ d).
Proof.
case: (eqVneq d 0) => [-> | dn0 cn0]; first by rewrite scaler0 !divp0 scaler0.
have e : p = (c^-1 *: (p %/ d)) * (c *: d) + (p %% d).
  by rewrite scalerCA scalerA mulVr // scale1r -(divp_eq ulcd).
suff s : size (p %% d) < size (c *: d).
  by rewrite (divpP _ e s) // -mul_polyC lead_coefM lead_coefC unitrM cn0.
by rewrite size_scale ?ltn_modp //; apply: contraTneq cn0 => ->; rewrite unitr0.
Qed.

End MoreUnitDivisor.

End IdomainUnit.

Module Field.

Import Ring ComRing UnitRing.
Include IdomainDefs.
Export IdomainDefs.
Include CommonIdomain.

Section FieldDivision.

Variable F : fieldType.

Implicit Type p q r d : {poly F}.

Lemma divp_eq p q : p = (p %/ q) * q + (p %% q).
Proof.
have [-> | qn0] := eqVneq q 0; first by rewrite modp0 mulr0 add0r.
by apply: IdomainUnit.divp_eq; rewrite unitfE lead_coef_eq0.
Qed.

Lemma divp_modpP p q d r : p = q * d + r -> size r < size d ->
  q = (p %/ d) /\ r = p %% d.
Proof.
move=> he hs; apply: IdomainUnit.edivpP => //; rewrite unitfE lead_coef_eq0.
by rewrite -size_poly_gt0; apply: leq_trans hs.
Qed.

Lemma divpP p q d r : p = q * d + r -> size r < size d ->
  q = (p %/ d).
Proof. by move/divp_modpP=> h; case/h. Qed.

Lemma modpP p q d r : p = q * d + r -> size r < size d -> r = (p %% d).
Proof. by move/divp_modpP=> h; case/h. Qed.

Lemma eqpfP p q : p %= q -> p = (lead_coef p / lead_coef q) *: q.
Proof.
have [->|nz_q] := eqVneq q 0; first by rewrite eqp0 scaler0 => /eqP ->.
by apply/IdomainUnit.ucl_eqp_eq; rewrite unitfE lead_coef_eq0.
Qed.

Lemma dvdp_eq q p : (q %| p) = (p == p %/ q * q).
Proof.
have [-> | qn0] := eqVneq q 0; first by rewrite dvd0p mulr0 eq_sym.
by apply: IdomainUnit.dvdp_eq; rewrite unitfE lead_coef_eq0.
Qed.

Lemma eqpf_eq p q : reflect (exists2 c, c != 0 & p = c *: q) (p %= q).
Proof.
apply: (iffP idP); last first.
  case=> c nz_c ->; apply/eqpP.
  by exists (1, c); rewrite ?scale1r ?oner_eq0.
have [->|nz_q] := eqVneq q 0.
  by rewrite eqp0=> /eqP ->; exists 1; rewrite ?scale1r ?oner_eq0.
case/IdomainUnit.ulc_eqpP; first by rewrite unitfE lead_coef_eq0.
by move=> c nz_c ->; exists c.
Qed.

Lemma modpZl c p q : (c *: p) %% q = c *: (p %% q).
Proof.
have [-> | qn0] := eqVneq q 0; first by rewrite !modp0.
by apply: IdomainUnit.modpZl; rewrite unitfE lead_coef_eq0.
Qed.

Lemma mulpK p q : q != 0 -> p * q %/ q = p.
Proof. by move=> qn0; rewrite IdomainUnit.mulpK // unitfE lead_coef_eq0. Qed.

Lemma mulKp p q : q != 0 -> q * p %/ q = p.
Proof. by rewrite mulrC; apply: mulpK. Qed.

Lemma divpZl c p q : (c *: p) %/ q = c *: (p %/ q).
Proof.
have [-> | qn0] := eqVneq q 0; first by rewrite !divp0 scaler0.
by apply: IdomainUnit.divpZl; rewrite unitfE lead_coef_eq0.
Qed.

Lemma modpZr c p d : c != 0 -> p %% (c *: d) = (p %% d).
Proof.
case: (eqVneq d 0) => [-> | dn0 cn0]; first by rewrite scaler0 !modp0.
have e : p = (c^-1 *: (p %/ d)) * (c *: d) + (p %% d).
  by rewrite scalerCA scalerA mulVf // scale1r -divp_eq.
suff s : size (p %% d) < size (c *: d) by rewrite (modpP e s).
by rewrite size_scale ?ltn_modp.
Qed.

Lemma divpZr c p d : c != 0 -> p %/ (c *: d) = c^-1 *: (p %/ d).
Proof.
case: (eqVneq d 0) => [-> | dn0 cn0]; first by rewrite scaler0 !divp0 scaler0.
have e : p = (c^-1 *: (p %/ d)) * (c *: d) + (p %% d).
  by rewrite scalerCA scalerA mulVf // scale1r -divp_eq.
suff s : size (p %% d) < size (c *: d) by rewrite (divpP e s).
by rewrite size_scale ?ltn_modp.
Qed.

Lemma eqp_modpl d p q : p %= q -> (p %% d) %= (q %% d).
Proof.
case/eqpP=> [[c1 c2]] /andP /= [c1n0 c2n0 e].
by apply/eqpP; exists (c1, c2); rewrite ?c1n0 // -!modpZl e.
Qed.

Lemma eqp_divl d p q : p %= q -> (p %/ d) %= (q %/ d).
Proof.
case/eqpP=> [[c1 c2]] /andP /= [c1n0 c2n0 e].
by apply/eqpP; exists (c1, c2); rewrite ?c1n0 // -!divpZl e.
Qed.

Lemma eqp_modpr d p q : p %= q -> (d %% p) %= (d %% q).
Proof.
case/eqpP=> [[c1 c2]] /andP [c1n0 c2n0 e].
have -> : p = (c1^-1 * c2) *: q by rewrite -scalerA -e scalerA mulVf // scale1r.
by rewrite modpZr ?eqpxx // mulf_eq0 negb_or invr_eq0 c1n0.
Qed.

Lemma eqp_mod p1 p2 q1 q2 : p1 %= p2 -> q1 %= q2 -> p1 %% q1 %= p2 %% q2.
Proof. move=> e1 e2; exact: eqp_trans (eqp_modpl _ e1) (eqp_modpr _ e2). Qed.

Lemma eqp_divr (d m n : {poly F}) : m %= n -> (d %/ m) %= (d %/ n).
Proof.
case/eqpP=> [[c1 c2]] /andP [c1n0 c2n0 e].
have -> : m = (c1^-1 * c2) *: n by rewrite -scalerA -e scalerA mulVf // scale1r.
by rewrite divpZr ?eqp_scale // ?invr_eq0 mulf_eq0 negb_or invr_eq0 c1n0.
Qed.

Lemma eqp_div p1 p2 q1 q2 : p1 %= p2 -> q1 %= q2 -> p1 %/ q1 %= p2 %/ q2.
Proof. move=> e1 e2; exact: eqp_trans (eqp_divl _ e1) (eqp_divr _ e2). Qed.

Lemma eqp_gdcor p q r : q %= r -> gdcop p q %= gdcop p r.
Proof.
move=> eqr; rewrite /gdcop (eqp_size eqr).
move: (size r)=> n; elim: n p q r eqr => [|n ihn] p q r; first by rewrite eqpxx.
move=> eqr /=; rewrite (eqp_coprimepl p eqr); case: ifP => _ //.
exact/ihn/eqp_div/eqp_gcdl.
Qed.

Lemma eqp_gdcol p q r : q %= r -> gdcop q p %= gdcop r p.
Proof.
move=> eqr; rewrite /gdcop; move: (size p)=> n.
elim: n p q r eqr {1 3}p (eqpxx p) => [|n ihn] p q r eqr s esp /=.
  case: (eqVneq q 0) eqr => [-> | nq0 eqr] /=.
    by rewrite eqp_sym eqp0 => ->; rewrite eqpxx.
  by case: (eqVneq r 0) eqr nq0 => [->|]; rewrite ?eqpxx // eqp0 => ->.
rewrite (eqp_coprimepr _ eqr) (eqp_coprimepl _ esp); case: ifP=> _ //.
exact/ihn/eqp_div/eqp_gcd.
Qed.

Lemma eqp_rgdco_gdco q p : rgdcop q p %= gdcop q p.
Proof.
rewrite /rgdcop /gdcop; move: (size p)=> n.
elim: n p q {1 3}p {1 3}q (eqpxx p) (eqpxx q) => [|n ihn] p q s t /= sp tq.
  case: (eqVneq t 0) tq => [-> | nt0 etq].
    by rewrite eqp_sym eqp0 => ->; rewrite eqpxx.
  by case: (eqVneq q 0) etq nt0 => [->|]; rewrite ?eqpxx // eqp0 => ->.
rewrite rcoprimep_coprimep (eqp_coprimepl t sp) (eqp_coprimepr p tq).
case: ifP=> // _; apply: ihn => //; apply: eqp_trans (eqp_rdiv_div _ _) _.
by apply: eqp_div => //; apply: eqp_trans (eqp_rgcd_gcd _ _) _; apply: eqp_gcd.
Qed.

Lemma modpD d p q : (p + q) %% d = p %% d + q %% d.
Proof.
have [-> | dn0] := eqVneq d 0; first by rewrite !modp0.
by apply: IdomainUnit.modpD; rewrite unitfE lead_coef_eq0.
Qed.

Lemma modpN p q : (- p) %% q = - (p %% q).
Proof. by apply/eqP; rewrite -addr_eq0 -modpD addNr mod0p. Qed.

Lemma modNp p q : (- p) %% q = - (p %% q). Proof. exact: modpN. Qed.

Lemma divpD d p q : (p + q) %/ d = p %/ d + q %/ d.
Proof.
have [-> | dn0] := eqVneq d 0; first by rewrite !divp0 addr0.
by apply: IdomainUnit.divpD; rewrite unitfE lead_coef_eq0.
Qed.

Lemma divpN p q : (- p) %/ q = - (p %/ q).
Proof. by apply/eqP; rewrite -addr_eq0 -divpD addNr div0p. Qed.

Lemma divp_addl_mul_small d q r : size r < size d -> (q * d + r) %/ d = q.
Proof.
move=> srd; rewrite divpD (divp_small srd) addr0 mulpK // -size_poly_gt0.
exact: leq_trans srd.
Qed.

Lemma modp_addl_mul_small d q r : size r < size d -> (q * d + r) %% d = r.
Proof. by move=> srd; rewrite modpD modp_mull add0r modp_small. Qed.

Lemma divp_addl_mul d q r : d != 0 -> (q * d + r) %/ d = q + r %/ d.
Proof. by move=> dn0; rewrite divpD mulpK. Qed.

Lemma divpp d : d != 0 -> d %/ d = 1.
Proof.
by move=> dn0; apply: IdomainUnit.divpp; rewrite unitfE lead_coef_eq0.
Qed.

Lemma leq_divMp d m : size (m %/ d * d) <= size m.
Proof.
have [-> | dn0] := eqVneq d 0; first by rewrite mulr0 size_poly0.
by apply: IdomainUnit.leq_divMp; rewrite unitfE lead_coef_eq0.
Qed.

Lemma divpK d p : d %| p -> p %/ d * d = p.
Proof.
case: (eqVneq d 0) => [-> /dvd0pP -> | dn0]; first by rewrite mulr0.
by apply: IdomainUnit.divpK; rewrite unitfE lead_coef_eq0.
Qed.

Lemma divpKC d p : d %| p -> d * (p %/ d) = p.
Proof. by move=> ?; rewrite mulrC divpK. Qed.

Lemma dvdp_eq_div d p q : d != 0 -> d %| p -> (q == p %/ d) = (q * d == p).
Proof.
by move=> dn0; apply: IdomainUnit.dvdp_eq_div; rewrite unitfE lead_coef_eq0.
Qed.

Lemma dvdp_eq_mul d p q : d != 0 -> d %| p -> (p == q * d) = (p %/ d == q).
Proof. by move=> dn0 dv_d_p; rewrite eq_sym -dvdp_eq_div // eq_sym. Qed.

Lemma divp_mulA d p q : d %| q -> p * (q %/ d) = p * q %/ d.
Proof.
case: (eqVneq d 0) => [-> /dvd0pP -> | dn0]; first by rewrite !divp0 mulr0.
by apply: IdomainUnit.divp_mulA; rewrite unitfE lead_coef_eq0.
Qed.

Lemma divp_mulAC d m n : d %| m -> m %/ d * n = m * n %/ d.
Proof. by move=> hdm; rewrite mulrC (mulrC m); apply: divp_mulA. Qed.

Lemma divp_mulCA d p q : d %| p -> d %| q -> p * (q %/ d) = q * (p %/ d).
Proof. by move=> hdp hdq; rewrite mulrC divp_mulAC // divp_mulA. Qed.

Lemma expp_sub d m n : d != 0 -> m >= n -> (d ^+ (m - n))%N = d ^+ m %/ d ^+ n.
Proof. by move=> dn0 /subnK=> {2}<-; rewrite exprD mulpK // expf_neq0. Qed.

Lemma divp_pmul2l d q p : d != 0 -> q != 0 -> d * p %/ (d * q) = p %/ q.
Proof.
by move=> dn0 qn0; apply: IdomainUnit.divp_pmul2l; rewrite unitfE lead_coef_eq0.
Qed.

Lemma divp_pmul2r d p q : d != 0 -> p != 0 -> q * d %/ (p * d) = q %/ p.
Proof. by move=> dn0 qn0; rewrite -!(mulrC d) divp_pmul2l. Qed.

Lemma divp_divl r p q : q %/ p %/ r = q %/ (p * r).
Proof.
have [-> | rn0] := eqVneq r 0; first by rewrite mulr0 !divp0.
have [-> | pn0] := eqVneq p 0; first by rewrite mul0r !divp0 div0p.
by apply: IdomainUnit.divp_divl; rewrite unitfE lead_coef_eq0.
Qed.

Lemma divpAC d p q : q %/ d %/ p = q %/ p %/ d.
Proof. by rewrite !divp_divl // mulrC. Qed.

Lemma edivp_def p q : edivp p q = (0, p %/ q, p %% q).
Proof.
rewrite Idomain.edivp_def; congr (_, _, _); rewrite /scalp 2!unlock /=.
have [-> | qn0] := eqVneq; first by rewrite lead_coef0 unitr0.
by rewrite unitfE lead_coef_eq0 qn0 /=; case: (redivp_rec _ _ _ _) => [[]].
Qed.

Lemma divpE p q : p %/ q = (lead_coef q)^-(rscalp p q) *: (rdivp p q).
Proof.
have [-> | qn0] := eqVneq q 0; first by rewrite rdivp0 divp0 scaler0.
by rewrite Idomain.divpE unitfE lead_coef_eq0 qn0.
Qed.

Lemma modpE p q : p %% q = (lead_coef q)^-(rscalp p q) *: (rmodp p q).
Proof.
have [-> | qn0] := eqVneq q 0.
  by rewrite rmodp0 modp0 /rscalp unlock eqxx lead_coef0 expr0 invr1 scale1r.
by rewrite Idomain.modpE unitfE lead_coef_eq0 qn0.
Qed.

Lemma scalpE p q : scalp p q = 0.
Proof.
have [-> | qn0] := eqVneq q 0; first by rewrite scalp0.
by rewrite Idomain.scalpE unitfE lead_coef_eq0 qn0.
Qed.

(* Just to have it without importing the weak theory *)
Lemma dvdpE p q : p %| q = rdvdp p q. Proof. exact: Idomain.dvdpE. Qed.

Variant edivp_spec m d : nat * {poly F} * {poly F} -> Type :=
  EdivpSpec n q r of
  m = q * d + r & (d != 0) ==> (size r < size d) : edivp_spec m d (n, q, r).

Lemma edivpP m d : edivp_spec m d (edivp m d).
Proof.
rewrite edivp_def; constructor; first exact: divp_eq.
by apply/implyP=> dn0; rewrite ltn_modp.
Qed.

Lemma edivp_eq d q r : size r < size d -> edivp (q * d + r) d = (0, q, r).
Proof.
move=> srd; apply: Idomain.edivp_eq; rewrite // unitfE lead_coef_eq0.
by rewrite -size_poly_gt0; apply: leq_trans srd.
Qed.

Lemma modp_mul p q m : (p * (q %% m)) %% m = (p * q) %% m.
Proof. by rewrite [in RHS](divp_eq q m) mulrDr modpD mulrA modp_mull add0r. Qed.

Lemma horner_mod p q x : root q x -> (p %% q).[x] = p.[x].
Proof.
by rewrite [in RHS](divp_eq p q) !hornerE => /eqP->; rewrite mulr0 add0r.
Qed.

Lemma dvdpP p q : reflect (exists qq, p = qq * q) (q %| p).
Proof.
have [-> | qn0] := eqVneq q 0; last first.
  by apply: IdomainUnit.dvdpP; rewrite unitfE lead_coef_eq0.
by rewrite dvd0p; apply: (iffP eqP) => [->| [? ->]]; [exists 1|]; rewrite mulr0.
Qed.

Lemma Bezout_eq1_coprimepP p q :
  reflect (exists u, u.1 * p + u.2 * q = 1) (coprimep p q).
Proof.
apply: (iffP idP)=> [hpq|]; last first.
  by case=> -[u v] /= e; apply/Bezout_coprimepP; exists (u, v); rewrite e eqpxx.
case/Bezout_coprimepP: hpq => [[u v]] /=.
case/eqpP=> [[c1 c2]] /andP /= [c1n0 c2n0] e.
exists (c2^-1 *: (c1 *: u), c2^-1 *: (c1 *: v)); rewrite /= -!scalerAl.
by rewrite -!scalerDr e scalerA mulVf // scale1r.
Qed.

Lemma dvdp_gdcor p q : q != 0 -> p %| (gdcop q p) * (q ^+ size p).
Proof.
rewrite /gdcop => nz_q; have [n hsp] := ubnPleq (size p).
elim: n => [|n IHn] /= in p hsp *; first by rewrite (negPf nz_q) mul0r dvdp0.
have [_ | ncop_pq] := ifPn; first by rewrite dvdp_mulr.
have g_gt1: 1 < size (gcdp p q).
  rewrite ltn_neqAle eq_sym ncop_pq size_poly_gt0 gcdp_eq0.
  by rewrite negb_and nz_q orbT.
have [-> | nz_p] := eqVneq p 0.
  by rewrite div0p exprSr mulrA dvdp_mulr // IHn // size_poly0.
have le_d_p: size (p %/ gcdp p q) < size p.
  rewrite size_divp -?size_poly_eq0 -(subnKC g_gt1) // add2n /=.
  by rewrite polySpred // ltnS subSS leq_subr.
rewrite -[p in p %| _](divpK (dvdp_gcdl p q)) exprSr mulrA.
by rewrite dvdp_mul ?IHn ?dvdp_gcdr // -ltnS (leq_trans le_d_p).
Qed.

Lemma reducible_cubic_root p q :
  size p <= 4 -> 1 < size q < size p -> q %| p -> {r | root p r}.
Proof.
move=> p_le4 /andP[]; rewrite leq_eqVlt eq_sym.
have [/poly2_root[x qx0] _ _ | _ /= q_gt2 p_gt_q] := size q =P 2.
  by exists x; rewrite -!dvdp_XsubCl in qx0 *; apply: (dvdp_trans qx0).
case/dvdpP/sig_eqW=> r def_p; rewrite def_p.
suffices /poly2_root[x rx0]: size r = 2 by exists x; rewrite rootM rx0.
have /norP[nz_r nz_q]: ~~ [|| r == 0 | q == 0].
  by rewrite -mulf_eq0 -def_p -size_poly_gt0 (leq_ltn_trans _ p_gt_q).
rewrite def_p size_mul // -subn1 leq_subLR ltn_subRL in p_gt_q p_le4.
by apply/eqP; rewrite -(eqn_add2r (size q)) eqn_leq (leq_trans p_le4).
Qed.

Lemma cubic_irreducible p :
  1 < size p <= 4 -> (forall x, ~~ root p x) -> irreducible_poly p.
Proof.
move=> /andP[p_gt1 p_le4] root'p; split=> // q sz_q_neq1 q_dv_p.
have nz_p: p != 0 by rewrite -size_poly_gt0 ltnW.
have nz_q: q != 0 by apply: contraTneq q_dv_p => ->; rewrite dvd0p.
have q_gt1: size q > 1 by rewrite ltn_neqAle eq_sym sz_q_neq1 size_poly_gt0.
rewrite -dvdp_size_eqp // eqn_leq dvdp_leq //= leqNgt; apply/negP=> p_gt_q.
by have [|x /idPn//] := reducible_cubic_root p_le4 _ q_dv_p; rewrite q_gt1.
Qed.

Section Multiplicity.

Definition mup x q :=
  [arg max_(n > (ord0 : 'I_(size q).+1) | ('X - x%:P) ^+ n %| q) n] : nat.

Lemma mup_geq x q n : q != 0 -> (n <= mup x q)%N = (('X - x%:P) ^+ n %| q).
Proof.
move=> q_neq0; rewrite /mup; symmetry.
case: arg_maxnP; rewrite ?expr0 ?dvd1p//= => i i_dvd gti.
case: ltnP => [|/dvdp_exp2l/dvdp_trans]; last exact.
apply: contraTF => dvdq; rewrite -leqNgt.
suff n_small : (n < (size q).+1)%N by exact: (gti (Ordinal n_small)).
by rewrite ltnS ltnW// -(size_exp_XsubC _ x) dvdp_leq.
Qed.

Lemma mup_leq x q n : q != 0 ->
  (mup x q <= n)%N = ~~ (('X - x%:P) ^+ n.+1 %| q).
Proof. by move=> qN0; rewrite leqNgt mup_geq. Qed.

Lemma mup_ltn x q n : q != 0 -> (mup x q < n)%N = ~~ (('X - x%:P) ^+ n %| q).
Proof. by move=> qN0; rewrite ltnNge mup_geq. Qed.

Lemma XsubC_dvd x q : q != 0 -> ('X - x%:P %| q) = (0 < mup x q)%N.
Proof. by move=> /mup_geq-/(_ _ 1%N)/esym; apply. Qed.

Lemma mup_XsubCX n x y :
  mup x (('X - y%:P) ^+ n) = (if (y == x) then n else 0)%N.
Proof.
have Xxn0 : ('X - y%:P) ^+ n != 0 by rewrite ?expf_neq0 ?polyXsubC_eq0.
apply/eqP; rewrite eqn_leq mup_leq ?mup_geq//.
have [->|Nxy] := eqVneq x y.
  by rewrite /= dvdpp ?dvdp_Pexp2l ?size_XsubC ?ltnn.
by rewrite dvd1p dvdp_XsubCl /root horner_exp !hornerE expf_neq0// subr_eq0.
Qed.

Lemma mupNroot x q : ~~ root q x -> mup x q = 0%N.
Proof.
move=> qNx; have qN0 : q != 0 by apply: contraNneq qNx => ->; rewrite root0.
by move: qNx; rewrite -dvdp_XsubCl XsubC_dvd// lt0n negbK => /eqP.
Qed.

Lemma mupMr x q1 q2 : ~~ root q1 x -> mup x (q1 * q2) = mup x q2.
Proof.
move=> q1Nx; have q1N0 : q1 != 0 by apply: contraNneq q1Nx => ->; rewrite root0.
have [->|q2N0] := eqVneq q2 0; first by rewrite mulr0.
apply/esym/eqP; rewrite eqn_leq mup_geq ?mulf_neq0// dvdp_mull -?mup_geq//=.
rewrite mup_leq ?mulf_neq0// Gauss_dvdpr -?mup_ltn//.
by rewrite coprimep_expl// coprimep_sym coprimep_XsubC.
Qed.

Lemma mupMl x q1 q2 : ~~ root q2 x -> mup x (q1 * q2) = mup x q1.
Proof. by rewrite mulrC; apply/mupMr. Qed.

Lemma mupM x q1 q2 : q1 != 0 -> q2 != 0 ->
  mup x (q1 * q2) = (mup x q1 + mup x q2)%N.
Proof.
move=> q1N0 q2N0; apply/eqP; rewrite eqn_leq mup_leq ?mulf_neq0//.
rewrite mup_geq ?mulf_neq0// exprD ?dvdp_mul; do ?by rewrite -mup_geq.
have [m1 [r1]] := multiplicity_XsubC q1 x; rewrite q1N0 /= => r1Nx ->.
have [m2 [r2]] := multiplicity_XsubC q2 x; rewrite q2N0 /= => r2Nx ->.
rewrite !mupMr// ?mup_XsubCX eqxx/= mulrACA exprS exprD.
rewrite dvdp_mul2r ?mulf_neq0 ?expf_neq0 ?polyXsubC_eq0//.
by rewrite dvdp_XsubCl rootM negb_or r1Nx r2Nx.
Qed.

Lemma mu_prod_XsubC x (s : seq F) :
  mup x (\prod_(y <- s) ('X - y%:P)) = count_mem x s.
Proof.
elim: s => [|y s IHs]; rewrite (big_cons, big_nil)/=.
  by rewrite mupNroot// root1.
rewrite mupM ?polyXsubC_eq0// ?monic_neq0 ?monic_prod_XsubC//.
by rewrite IHs (@mup_XsubCX 1).
Qed.

Lemma prod_XsubC_eq (s t : seq F) :
  \prod_(x <- s) ('X - x%:P) = \prod_(x <- t) ('X - x%:P) -> perm_eq s t.
Proof.
move=> eq_prod; apply/allP => x _ /=; apply/eqP.
by have /(congr1 (mup x)) := eq_prod; rewrite !mu_prod_XsubC.
Qed.

End Multiplicity.

Section FieldRingMap.

Variable rR : nzRingType.

Variable f : {rmorphism F -> rR}.
Local Notation "p ^f" := (map_poly f p) : ring_scope.

Implicit Type a b : {poly F}.

Lemma redivp_map a b :
  redivp a^f b^f = (rscalp a b, (rdivp a b)^f, (rmodp a b)^f).
Proof.
rewrite /rdivp /rscalp /rmodp !unlock map_poly_eq0 size_map_poly.
have [// | q_nz] := ifPn; rewrite -(rmorph0 (map_poly f)) //.
have [m _] := ubnPeq (size a); elim: m 0%N 0 a => [|m IHm] qq r a /=.
  rewrite -!mul_polyC !size_map_poly !lead_coef_map // -(map_polyXn f).
  by rewrite -!(map_polyC f) -!rmorphM -rmorphB -rmorphD; case: (_ < _).
rewrite -!mul_polyC !size_map_poly !lead_coef_map // -(map_polyXn f).
by rewrite -!(map_polyC f) -!rmorphM -rmorphB -rmorphD /= IHm; case: (_ < _).
Qed.

End FieldRingMap.

Section FieldMap.

Variable rR : idomainType.

Variable f : {rmorphism F -> rR}.
Local Notation "p ^f" := (map_poly f p) : ring_scope.

Implicit Type a b : {poly F}.

Lemma edivp_map a b :
  edivp a^f b^f = (0, (a %/ b)^f, (a %% b)^f).
Proof.
have [-> | bn0] := eqVneq b 0.
  rewrite (rmorph0 (map_poly f)) WeakIdomain.edivp_def !modp0 !divp0.
  by rewrite (rmorph0 (map_poly f)) scalp0.
rewrite unlock redivp_map lead_coef_map rmorph_unit; last first.
  by rewrite unitfE lead_coef_eq0.
rewrite modpE divpE !map_polyZ [in RHS]rmorphV ?rmorphXn // unitfE.
by rewrite expf_neq0 // lead_coef_eq0.
Qed.

Lemma scalp_map p q : scalp p^f q^f = scalp p q.
Proof. by rewrite /scalp edivp_map edivp_def. Qed.

Lemma map_divp p q : (p %/ q)^f = p^f %/ q^f.
Proof. by rewrite /divp edivp_map edivp_def. Qed.

Lemma map_modp p q : (p %% q)^f = p^f %% q^f.
Proof. by rewrite /modp edivp_map edivp_def. Qed.

Lemma egcdp_map p q :
  egcdp (map_poly f p) (map_poly f q)
     = (map_poly f (egcdp p q).1, map_poly f (egcdp p q).2).
Proof.
wlog le_qp: p q / size q <= size p.
  move=> IH; have [/IH// | lt_qp] := leqP (size q) (size p).
  have /IH := ltnW lt_qp; rewrite /egcdp !size_map_poly ltnW // leqNgt lt_qp /=.
  by case: (egcdp_rec _ _ _) => u v [-> ->].
rewrite /egcdp !size_map_poly {}le_qp; move: (size q) => n.
elim: n => /= [|n IHn] in p q *; first by rewrite rmorph1 rmorph0.
rewrite map_poly_eq0; have [_ | nz_q] := ifPn; first by rewrite rmorph1 rmorph0.
rewrite -map_modp (IHn q (p %% q)); case: (egcdp_rec _ _ n) => u v /=.
rewrite map_polyZ lead_coef_map -rmorphXn scalp_map rmorphB rmorphM.
by rewrite -map_divp.
Qed.

Lemma dvdp_map p q : (p^f %| q^f) = (p %| q).
Proof. by rewrite /dvdp -map_modp map_poly_eq0. Qed.

Lemma eqp_map p q : (p^f %= q^f) = (p %= q).
Proof. by rewrite /eqp !dvdp_map. Qed.

Lemma gcdp_map p q : (gcdp p q)^f = gcdp p^f q^f.
Proof.
wlog lt_p_q: p q / size p < size q.
  move=> IHpq; case: (ltnP (size p) (size q)) => [|le_q_p]; first exact: IHpq.
  rewrite gcdpE (gcdpE p^f) !size_map_poly ltnNge le_q_p /= -map_modp.
  have [-> | q_nz] := eqVneq q 0; first by rewrite rmorph0 !gcdp0.
  by rewrite IHpq ?ltn_modp.
have [m le_q_m] := ubnP (size q); elim: m => // m IHm in p q lt_p_q le_q_m *.
rewrite gcdpE (gcdpE p^f) !size_map_poly lt_p_q -map_modp.
have [-> | q_nz] := eqVneq p 0; first by rewrite rmorph0 !gcdp0.
by rewrite IHm ?(leq_trans lt_p_q) ?ltn_modp.
Qed.

Lemma coprimep_map p q : coprimep p^f q^f = coprimep p q.
Proof. by rewrite -!gcdp_eqp1 -eqp_map rmorph1 gcdp_map. Qed.

Lemma gdcop_rec_map p q n : (gdcop_rec p q n)^f = gdcop_rec p^f q^f n.
Proof.
elim: n p q => [|n IH] => /= p q.
  by rewrite map_poly_eq0; case: eqP; rewrite ?rmorph1 ?rmorph0.
rewrite /coprimep -gcdp_map size_map_poly.
by case: eqP => Hq0 //; rewrite -map_divp -IH.
Qed.

Lemma gdcop_map p q : (gdcop p q)^f = gdcop p^f q^f.
Proof. by rewrite /gdcop gdcop_rec_map !size_map_poly. Qed.

End FieldMap.

End FieldDivision.

#[deprecated(since="mathcomp 2.4.0", note="Renamed to leq_divMp.")]
Notation leq_trunc_divp := leq_divMp.

End Field.

Module ClosedField.

Import Field.

Section closed.

Variable F : closedFieldType.

Lemma root_coprimep (p q : {poly F}) :
  (forall x, root p x -> q.[x] != 0) -> coprimep p q.
Proof.
move=> Ncmn; rewrite -gcdp_eqp1 -size_poly_eq1; apply/closed_rootP.
by case=> r; rewrite root_gcd !rootE=> /andP [/Ncmn/negPf->].
Qed.

Lemma coprimepP (p q : {poly F}) :
  reflect (forall x, root p x -> q.[x] != 0) (coprimep p q).
Proof. by apply: (iffP idP)=> [/coprimep_root|/root_coprimep]. Qed.

End closed.

End ClosedField.

End Pdiv.

Export Pdiv.Field.
