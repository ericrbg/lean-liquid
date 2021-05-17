import algebraic_topology.simplicial_object
import linear_algebra.free_module
import ring_theory.int.basic

import polyhedral_lattice.finsupp
import polyhedral_lattice.category
import polyhedral_lattice.topology

import for_mathlib.free_abelian_group
import for_mathlib.normed_group_quotient
import for_mathlib.finsupp
import for_mathlib.normed_group


/-!
# The Čech conerve attached to `Λ → Λ'`

Let `f : Λ → Λ'` be a morphism of polyhedral lattices.
(We probably need to assume that the cokernel is torsion-free...)

In this file we construct the Čech conerve attached to `f`.

Concretely, but in pseudo-code:
it consists of the objects `Λ'^(m)` defined as `(Λ')^m/L`,
where `L` is the sublattice `Λ ⊗ {x : ℤ^m | ∑ x = 0}`.
-/

noncomputable theory

open_locale big_operators

section saturated

variables {G G₁ G₂ : Type*} [group G] [add_comm_group G₁] [add_comm_group G₂]

namespace subgroup -- move this section

@[to_additive]
def saturated (H : subgroup G) : Prop := ∀ ⦃n g⦄, gpow n g ∈ H → n = 0 ∨ g ∈ H

end subgroup

lemma add_subgroup.ker_saturated [no_zero_smul_divisors ℤ G₂] (f : G₁ →+ G₂) :
  (f.ker).saturated :=
begin
  intros n g hg,
  simpa only [f.mem_ker, gsmul_eq_smul, f.map_gsmul, smul_eq_zero] using hg
end

end saturated

namespace polyhedral_lattice

variables {Λ Λ' : Type*} [polyhedral_lattice Λ] [polyhedral_lattice Λ']
variables (f : polyhedral_lattice_hom Λ Λ') (f' : polyhedral_lattice_hom Λ' Λ)

namespace conerve

section objects

/-!
## The objects
-/

variables (m : ℕ)

def L : add_subgroup (fin m →₀ Λ') :=
{ carrier := { l' | ∑ i, l' i = 0 ∧ ∀ i, ∃ l, f l = l' i},
  zero_mem' := ⟨finset.sum_const_zero, λ i, ⟨0, f.map_zero⟩⟩,
  add_mem' :=
  begin
    rintro l'₁ l'₂ ⟨hl'₁, Hl'₁⟩ ⟨hl'₂, Hl'₂⟩,
    refine ⟨_, _⟩,
    { simp only [finsupp.add_apply, finset.sum_add_distrib, hl'₁, hl'₂, add_zero] },
    { intro i,
      obtain ⟨l₁, hl₁⟩ := Hl'₁ i,
      obtain ⟨l₂, hl₂⟩ := Hl'₂ i,
      refine ⟨l₁ + l₂, _⟩,
      rw [f.map_add, hl₁, hl₂, finsupp.add_apply] }
  end,
  neg_mem' :=
  begin
    rintro l' ⟨hl', Hl'⟩,
    refine ⟨_, _⟩,
    { simp only [finsupp.neg_apply, finset.sum_neg_distrib, hl', neg_zero] },
    { intro i,
      obtain ⟨l, hl⟩ := Hl' i,
      refine ⟨-l, _⟩,
      rw [f.map_neg, hl, finsupp.neg_apply] }
  end }

lemma L_saturated [hf : fact f.to_add_monoid_hom.range.saturated] :
  (L f m).saturated :=
begin
  rintro n l' ⟨hl', Hl'⟩,
  simp only [gsmul_eq_smul, finsupp.smul_apply, ← finset.smul_sum, smul_eq_zero] at hl' Hl',
  rw or_iff_not_imp_left,
  intro hn,
  refine ⟨hl'.resolve_left hn, λ i, _⟩,
  obtain ⟨li, hli⟩ := Hl' i,
  have hl'i : n • l' i ∈ f.to_add_monoid_hom.range,
  { rw [← hli, add_monoid_hom.mem_range], refine ⟨li, rfl⟩ },
  have Hf := hf.1,
  exact (Hf hl'i).resolve_left hn,
end

section open finsupp

lemma L_le_comap {n} (g : fin (n+1) → fin (m+1)) :
  (L f (n+1)) ≤ (L f (m+1)).comap (map_domain.add_monoid_hom g) :=
begin
  rintro l' ⟨hl', Hl'⟩,
  rw add_subgroup.mem_comap,
  refine ⟨_, _⟩,
  { have aux1 : l'.sum (λ _, add_monoid_hom.id _) = ∑ i, l' i,
    { exact finsupp.sum_eq_sum_fintype _ (λ _, rfl) _ },
    have aux2 := @sum_map_domain_index_add_monoid_hom _ _ _ _ _ _ g l' (λ _, add_monoid_hom.id _),
    dsimp only at aux2,
    rw [aux1, finsupp.sum_eq_sum_fintype, hl'] at aux2,
    { simpa only [add_monoid_hom.id_apply] using aux2 },
    { intro, refl } },
  { intro i,
    choose l hl using Hl',
    simp only [map_domain.add_monoid_hom_apply, map_domain],
    refine ⟨∑ j, if g j = i then (l j) else 0, _⟩,
    rw [finsupp.sum_apply, finsupp.sum_eq_sum_fintype],
    swap, { intro, simp only [coe_zero, pi.zero_apply, single_zero] },
    simp only [f.map_sum, single_apply, ← hl],
    apply fintype.sum_congr,
    intro j, split_ifs,
    { refl },
    { exact f.map_zero } }
end

@[simp] lemma L_one : L f 1 = ⊥ :=
begin
  rw eq_bot_iff,
  rintro l' ⟨hl', Hl'⟩,
  simp only [fin.default_eq_zero, univ_unique, finset.sum_singleton] at hl',
  simp only [add_subgroup.mem_bot, finsupp.ext_iff, coe_zero, pi.zero_apply],
  intro i, fin_cases i, exact hl'
end

end

lemma int.div_eq_zero (d n : ℤ) (h : d ∣ n) (H : n / d = 0) : n = 0 :=
begin
  rw [← int.mul_div_cancel' h, H, mul_zero]
end

def obj := quotient_add_group.quotient (L f m)

instance : is_closed (L f m : set (fin m →₀ Λ')) :=
is_closed_discrete _

instance : normed_group (obj f m) :=
add_subgroup.normed_group_quotient _

def π : (fin m →₀ Λ') →+ obj f m :=
by convert quotient_add_group.mk' (L f m)

lemma π_apply_eq_zero_iff (x : fin m →₀ Λ') : π f m x = 0 ↔ x ∈ L f m :=
quotient_add_group.eq_zero_iff _

lemma π_surjective : function.surjective (π f m) :=
quotient.surjective_quotient_mk'

lemma norm_π_one_eq (l : fin 1 →₀ Λ') : ∥(π f 1) l∥ = ∥l∥ :=
begin
  delta π, dsimp,
  rw quotient_norm_mk_eq (L f 1) l,
  simp only [L_one, set.image_singleton, add_zero, cInf_singleton, add_subgroup.coe_bot],
end

variables [fact f.to_add_monoid_hom.range.saturated]

instance : no_zero_smul_divisors ℤ (obj f m) :=
{ eq_zero_or_eq_zero_of_smul_eq_zero :=
  begin
    intros n x h,
    obtain ⟨x, rfl⟩ := π_surjective f m x,
    simp only [← add_monoid_hom.map_gsmul, π_apply_eq_zero_iff] at h ⊢,
    exact L_saturated _ _ h
  end }

lemma obj_finite_free : _root_.finite_free (obj f m) :=
begin
  obtain ⟨ι, _inst_ι, ⟨b⟩⟩ := polyhedral_lattice.finite_free (fin m →₀ Λ'), resetI,
  let φ := (π f m).to_int_linear_map,
  suffices : submodule.span ℤ (set.range (φ ∘ b)) = ⊤,
  { obtain ⟨n, b⟩ := module.free_of_finite_type_torsion_free this,
    exact ⟨fin n, infer_instance, ⟨b⟩⟩ },
  rw [set.range_comp, ← submodule.map_span, b.span_eq, submodule.map_top, linear_map.range_eq_top],
  exact π_surjective f m
end

instance : polyhedral_lattice (obj f m) :=
{ finite_free := obj_finite_free _ _,
  polyhedral' :=
  begin
    obtain ⟨ι, _inst_ι, l, hl, hl'⟩ := polyhedral_lattice.polyhedral (fin m →₀ Λ'),
    refine ⟨ι, _inst_ι, (λ i, quotient_add_group.mk' (L f m) (l i)), _⟩,
    intros x,
    apply quotient_add_group.induction_on x; clear x,
    intro x,
    obtain ⟨c, H1, H2⟩ := hl x,
    refine ⟨c, _, _⟩,
    { show quotient_add_group.mk' (L f m) x = _,
      simp only [H1, add_monoid_hom.map_sum, add_monoid_hom.map_nsmul] },
    { sorry },
  end }

end objects

section maps

/-!
## The simplicial maps
-/

open finsupp

variables {n m k : ℕ} (g : fin (n+1) → fin (m+1)) (g' : fin (m+1) → fin (k+1))

-- the underlying morphism of additive groups
def map_add_hom : obj f (n+1) →+ obj f (m+1) :=
quotient_add_group.map _ _ (map_domain.add_monoid_hom g) (L_le_comap f _ g)

lemma map_domain_add_monoid_hom_strict (x : fin (n+1) →₀ Λ) : ∥map_domain.add_monoid_hom g x∥ ≤ ∥x∥ :=
begin
  simp only [norm_def, map_domain.add_monoid_hom_apply],
  dsimp [map_domain],
  rw [sum_eq_sum_fintype], swap, { intro, exact norm_zero },
  simp only [sum_apply],
  rw [sum_eq_sum_fintype], swap, { intro, exact norm_zero },
  calc ∑ i, ∥x.sum (λ j l, single (g j) l i)∥
      ≤ ∑ i, ∑ j, ∥single (g j) (x j) i∥ : _
  ... ≤ ∑ j, ∥x j∥ : _,
  { apply finset.sum_le_sum,
    rintro i -,
    rw sum_eq_sum_fintype, swap, { intro, rw [single_zero, zero_apply] },
    exact norm_sum_le _ _ },
  { rw finset.sum_comm,
    apply finset.sum_le_sum,
    rintro j -,
    simp only [single_apply, norm_ite, norm_zero],
    apply le_of_eq,
    simp only [finset.sum_ite_eq, finset.mem_univ, if_true], }
end

lemma map_add_hom_strict (x : obj f (n+1)) : ∥map_add_hom f g x∥ ≤ ∥x∥ :=
begin
  apply le_of_forall_pos_le_add,
  intros ε hε,
  obtain ⟨x, rfl, h⟩ := norm_mk_lt x hε,
  calc _ ≤ ∥map_domain.add_monoid_hom g x∥ : quotient_norm_mk_le _ _
  ... ≤ ∥x∥ : map_domain_add_monoid_hom_strict _ _
  ... ≤ _ : h.le,
end

lemma map_add_hom_mk (x : fin (n+1) →₀ Λ') :
  (map_add_hom f g) (quotient_add_group.mk x) =
    quotient_add_group.mk (map_domain.add_monoid_hom g x) :=
rfl

@[simp] lemma map_add_hom_π (x : fin (n+1) →₀ Λ') :
  (map_add_hom f g) (π _ _ x) = π _ _ (map_domain.add_monoid_hom g x) :=
rfl

variables [fact f.to_add_monoid_hom.range.saturated]

@[simps]
def map : polyhedral_lattice_hom (obj f (n+1)) (obj f (m+1)) :=
{ strict' := map_add_hom_strict f g,
  .. map_add_hom f g }

lemma map_id : map f (id : fin (m+1) → fin (m+1)) = polyhedral_lattice_hom.id :=
begin
  ext x,
  apply quotient_add_group.induction_on x; clear x,
  intro x,
  simp only [add_monoid_hom.to_fun_eq_coe, map_apply, polyhedral_lattice_hom.id_apply,
    map_add_hom_mk, map_domain.add_monoid_hom_apply, map_domain_id],
end

lemma map_comp : map f (g' ∘ g) = (map f g').comp (map f g) :=
begin
  ext x,
  apply quotient_add_group.induction_on x; clear x,
  intro x,
  simp only [add_monoid_hom.to_fun_eq_coe, map_apply, polyhedral_lattice_hom.comp_apply,
    map_add_hom_mk, map_domain.add_monoid_hom_apply, ← map_domain_comp],
end

end maps

end conerve

end polyhedral_lattice

namespace PolyhedralLattice

universe variables u

open polyhedral_lattice simplex_category category_theory

variables {Λ Λ' : PolyhedralLattice.{u}} (f : Λ ⟶ Λ') [fact f.to_add_monoid_hom.range.saturated]

namespace Cech_conerve

def obj (m : ℕ) : PolyhedralLattice := of (conerve.obj f (m+1))

section open finsupp

def map_succ_zero_aux (m : ℕ) (g : fin (m+2) →ₘ fin 1) : obj f (m+1) →+ Λ' :=
(apply_add_hom (0 : fin 1)).comp $
begin
  -- TODO: this is very ugly
  let foo := quotient_add_group.lift (conerve.L f (m + 1 + 1)) (map_domain.add_monoid_hom g),
  refine foo _,
  rintro l' ⟨hl', Hl'⟩,
  ext i,
  simp only [map_domain.add_monoid_hom_apply, map_domain, sum_apply, single_apply, zero_apply],
  rw [finsupp.sum_eq_sum_fintype],
  swap, { simp only [forall_const, if_true, eq_iff_true_of_subsingleton] },
  convert hl',
  ext, rw if_pos, exact subsingleton.elim _ _
end

end

def map_succ_zero (m : ℕ) (g : fin (m+2) →ₘ fin 1) : obj f (m+1) ⟶ Λ' :=
{ strict' :=
  begin
    intro x,
    apply le_of_forall_pos_le_add,
    intros ε hε,
    obtain ⟨x, rfl, h⟩ := norm_mk_lt x hε,
    calc ∥finsupp.map_domain.add_monoid_hom g x 0∥
        ≤ ∥finsupp.map_domain.add_monoid_hom g x∥ : _
    ... ≤ ∥x∥ : conerve.map_domain_add_monoid_hom_strict g x
    ... ≤ _ : h.le,
    rw [finsupp.norm_def, finsupp.sum_eq_sum_fintype, fin.sum_univ_succ, fin.sum_univ_zero, add_zero],
    intro, exact norm_zero
  end,
  .. map_succ_zero_aux f m g }

-- move this, generalize to arbitrary subsingletons
@[simp] lemma preorder_hom_eq_id (g : fin 1 →ₘ fin 1) : g = preorder_hom.id :=
by { ext1, exact subsingleton.elim _ _ }

def finsupp_fin_one_iso : of (fin 1 →₀ Λ') ≅ Λ' :=
iso.symm $ PolyhedralLattice.iso_mk
  (finsupp.single_add_hom 0) (finsupp.apply_add_hom 0)
  (λ l, by { dsimp [finsupp.norm_def], simp only [norm_zero, finsupp.sum_single_index] })
  (by { ext l, dsimp, simp only [finsupp.single_eq_same] })
  (by { ext f x, fin_cases x, dsimp, simp only [finsupp.single_eq_same] })
.

@[simp] lemma finsupp_fin_one_iso_hom (l') :
  (@finsupp_fin_one_iso Λ').hom l' = finsupp.apply_add_hom (0 : fin 1) l':= rfl

@[simp] lemma finsupp_fin_one_iso_inv (l') :
  (@finsupp_fin_one_iso Λ').inv l' = finsupp.single_add_hom (0 : fin 1) l':= rfl

/-- the left hand side is by definition the quotient of the right hand side
by a subgroup that is provably trivial -/
def obj_zero_iso' : obj f 0 ≅ of (fin 1 →₀ Λ') :=
iso.symm $ PolyhedralLattice.iso_mk
  (polyhedral_lattice.conerve.π _ _)
  (quotient_add_group.lift _ (add_monoid_hom.id _)
    (by { intros x hx, rwa [polyhedral_lattice.conerve.L_one, add_subgroup.mem_bot] at hx }))
  (polyhedral_lattice.conerve.norm_π_one_eq _)
  (by ext; refl) (by ext ⟨x⟩; refl)

-- @[simp] lemma obj_zero_iso'_hom (l') :
--   (obj_zero_iso' f).hom l' = _ := rfl

@[simp] lemma obj_zero_iso'_inv (l') :
  (obj_zero_iso' f).inv l' = polyhedral_lattice.conerve.π _ _ l':= rfl

def obj_zero_iso : obj f 0 ≅ Λ' := obj_zero_iso' _ ≪≫ finsupp_fin_one_iso

end Cech_conerve

open Cech_conerve

variables [fact f.to_add_monoid_hom.range.saturated]

@[simps] def Cech_conerve : simplex_category ⥤ PolyhedralLattice :=
{ obj := λ n, obj f n.len,
  map := λ n m g, conerve.map f g.to_preorder_hom,
  map_id' := λ _, conerve.map_id f,
  map_comp' := λ _ _ _ _ _, conerve.map_comp f _ _ }

@[simps] def Cech_augmentation_map : Λ ⟶ (Cech_conerve f).obj (mk 0) :=
f ≫ (obj_zero_iso f).inv

lemma augmentation_map_equalizes :
  Cech_augmentation_map f ≫ (Cech_conerve f).map (δ 0) =
  Cech_augmentation_map f ≫ (Cech_conerve f).map (δ 1) :=
begin
  ext l,
  simp only [conerve.map_apply, add_monoid_hom.to_fun_eq_coe, Cech_augmentation_map_apply,
    Cech_conerve_map, comp_apply, finsupp.single_add_hom_apply, obj_zero_iso, iso.trans_inv,
    finsupp_fin_one_iso_inv, obj_zero_iso'_inv],
  have H1 := conerve.map_add_hom_π f (@hom.to_preorder_hom (mk 0) _ (δ 0)) (finsupp.single 0 (f l)),
  have H2 := conerve.map_add_hom_π f (@hom.to_preorder_hom (mk 0) _ (δ 1)) (finsupp.single 0 (f l)),
  refine H1.trans (eq.trans _ H2.symm), clear H1 H2,
  show (conerve.π f 2) _ = (conerve.π f 2) _,
  simp only [finsupp.map_domain_single, finsupp.map_domain.add_monoid_hom_apply],
  rw [← sub_eq_zero, ← add_monoid_hom.map_sub, conerve.π_apply_eq_zero_iff],
  have hδ0 : hom.to_preorder_hom (δ (0 : fin 2)) 0 = 1 := rfl,
  have hδ1 : hom.to_preorder_hom (δ (1 : fin 2)) 0 = 0 := rfl,
  erw [hδ0, hδ1],
  refine ⟨_, λ i, _⟩,
  { simp only [fin.sum_univ_succ, fin.sum_univ_zero, add_zero, finsupp.sub_apply,
      len_mk, finsupp.single_apply, fin.one_eq_zero_iff, if_true, zero_sub, fin.zero_eq_one_iff,
      eq_self_iff_true, sub_zero, fin.succ_zero_eq_one, add_left_neg, if_false, one_ne_zero] },
  fin_cases i;
  simp only [finsupp.sub_apply, len_mk, finsupp.single_apply, eq_self_iff_true, if_true, if_false,
    fin.one_eq_zero_iff, fin.zero_eq_one_iff, fin.succ_zero_eq_one, one_ne_zero,
    sub_zero, zero_sub, ← f.map_neg, exists_apply_eq_apply],
end

end PolyhedralLattice
