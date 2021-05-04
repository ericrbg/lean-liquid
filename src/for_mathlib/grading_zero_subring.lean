import for_mathlib.grading
import ring_theory.noetherian -- for the lemma we need for Gordan
import ring_theory.finiteness
import linear_algebra.finsupp

/-!

# The `zero_component_subring` of a commutative graded ring

Some definitions and lemmas about commutative graded rings, graded by `add_subgroup`s which
are indexed by an `add_monoid`. We are mostly concerned with the relationship between the
ring `R` and the `zero_component_subring` `R₀`. All of this stuff will also pretty clearly work
for gradings indexed by `monoid`s. Most of it will probably work in the non-commutative case,
sometimes under the extra assumption that `R₀` is commutative. Most of it will work for `semirings`
graded by `add_submonoid`s but I find it difficult to reuse `semiring` results to get `ring`
results.

## Main definitions

If `R` is a commutative ring graded by `add_subgroup`s Gᵢ indexed by an `add_monoid` A,
then

* `zero_piece_subring R Gᵢ` := `Gᵢ 0` or `R₀` is a subring and `R` is an algebra for `R₀` and hence
    an `R₀`-module;
* If `a : A` then `Gᵢ a` is a submodule.

## Main theorems

* Given a `Gᵢ 0`-submodule of `Gᵢ a`, pushing forward to an ideal of `R` and then pulling back
    is the identity function.
* Hence if `R` is a Noetherian ring then `Gᵢ a` are all Noetherian `R₀`-modules.

-/

/-

## preparations

-/

-- move this, if it's not there already
def subring.incl (R : Type) [comm_ring R] (A B : subring R) (h : A ≤ B) : A →+* B :=
{ to_fun := λ a, ⟨a.1, h a.2⟩,
  map_zero' := rfl,
  map_add' := λ _ _, rfl,
  map_one' := rfl,
  map_mul' := λ _ _, rfl }

namespace direct_sum

namespace has_add_subgroup_decomposition

section ring

variables {A : Type*} [decidable_eq A] [add_monoid A]
  (R : Type*) [ring R]
  (Gᵢ : A → add_subgroup R) [has_add_subgroup_decomposition Gᵢ] [add_subgroup.is_gmonoid Gᵢ]

-- would love to deduce this from the obvious `subsemiring_of_add_submonoid` but it's all too much
-- for `convert` because an external direct sum of `Gᵢ i` is syntactically different to
-- an external direct sum of `(Gᵢ i).to_add_submonoid` and this caused me problems.
-- In the end I've just stuck to the case we need.
def subring_of_add_subgroup
    (S : add_submonoid A) : subring R :=
 { carrier := {r : R | ∀ ⦃a : A⦄, a ∉ S → add_subgroup_decomposition Gᵢ r a = 0 },
   zero_mem' := λ n _, by { rw (add_subgroup_decomposition Gᵢ).map_zero, refl },
   add_mem' := λ a b ha hb n hn, by
   { rw [(add_subgroup_decomposition Gᵢ).map_add, dfinsupp.add_apply, ha hn, hb hn, zero_add] },
   neg_mem' := λ a ha n hn, by
   { rw [(add_subgroup_decomposition Gᵢ).map_neg],
     convert dfinsupp.neg_apply _ n,
     rw ha hn,
     simp },
    one_mem' := λ n hn, (mem_piece_iff_single_support 1 0).1
     (add_subgroup.is_gmonoid.grading_one) (λ h, hn $ by { rw h, exact S.zero_mem }),
   mul_mem' := λ a b,
    let a' := add_subgroup_decomposition Gᵢ a in
    let b' := add_subgroup_decomposition Gᵢ b in
    λ (ha : ∀ ai ∉ S, a' ai = 0) (hb : ∀ bi ∉ S, b' bi = 0) n hn, begin
      change ((add_subgroup_decomposition_ring_equiv Gᵢ) (a * b)) n = 0,
      rw ring_equiv.map_mul,
      change (a' * b') n = 0,
      classical,
      rw mul_apply,
      apply dfinsupp.sum_eq_zero,
      intros ai hai,
      apply dfinsupp.sum_eq_zero,
      intros bi hbi,
      apply dif_neg,
      rintro rfl,
      obtain (hna | hnb) := S.not_mem_or_of_add_not_mem hn,
      exact hai (ha _ hna),
      exact hbi (hb _ hnb),
    end,
 }

-- has better definitional properties than `subring_of_add_subgroup A R Gᵢ ⊥
def zero_component_subring : subring R :=
{ one_mem' := add_subgroup.is_gmonoid.grading_one,
  mul_mem' := λ r s, begin
    suffices : r ∈ Gᵢ 0 → s ∈ Gᵢ 0 → r * s ∈ Gᵢ (0 + 0),
      simpa,
    exact add_subgroup.is_gmonoid.grading_mul,
  end,
  ..Gᵢ 0
}

instance : ring (Gᵢ 0) := subring.to_ring (zero_component_subring R Gᵢ)

end ring

-- in the commutative case we can go further because R is then an R₀-module

section comm_ring

variables {A : Type*} [decidable_eq A] [add_monoid A]
  (R : Type*) [comm_ring R]
  (Gᵢ : A → add_subgroup R) [has_add_subgroup_decomposition Gᵢ] [add_subgroup.is_gmonoid Gᵢ]

instance : comm_ring (Gᵢ 0) := subring.to_comm_ring (zero_component_subring R Gᵢ)
instance : algebra (Gᵢ 0) R := algebra.of_subring (zero_component_subring R Gᵢ)

/-- Rₐ considered as an R₀-submodule of R. -/
def component_submodule_for_zero_component_subring (a : A) :
  submodule (Gᵢ 0) R :=
{ carrier := Gᵢ a,
  zero_mem' := (Gᵢ a).zero_mem,
  add_mem' := λ _ _, (Gᵢ a).add_mem,
  smul_mem' := begin
    rintro ⟨c, (hc : c ∈ Gᵢ 0)⟩ x (hx : x ∈ Gᵢ a),
    change c * x ∈ Gᵢ a,
    convert add_subgroup.is_gmonoid.grading_mul hc hx,
    rw zero_add,
  end }

/-- Rₐ considered as an absract R₀-module -/
instance (a : A) : module (Gᵢ 0) (Gᵢ a) :=
submodule.module' (component_submodule_for_zero_component_subring R Gᵢ a)


--variables {A : Type*} [decidable_eq A] [add_monoid A] {R : Type*} [comm_ring R]
--  (Gᵢ : A → add_subgroup R) [has_add_subgroup_decomposition Gᵢ] [add_subgroup.is_gmonoid Gᵢ]

def projection_R₀_hom (a : A) : R →ₗ[Gᵢ 0] (Gᵢ a) :=
{ to_fun := (apply_add_monoid_hom (λ i, Gᵢ i) a).comp (add_subgroup_decomposition Gᵢ).to_add_monoid_hom,
  map_add' := ((apply_add_monoid_hom (λ i, Gᵢ i) a).comp (add_subgroup_decomposition Gᵢ).to_add_monoid_hom).map_add,
  map_smul' := λ r0 x, begin
    sorry,
  end
}

namespace component_submodule -- some technical lemmas

/-- Extension of an `R₀`-submodule of `Rₐ` to an `R`-submodule of `R`, sending `M` to `MR`. -/
def map (a : A) (M : submodule (Gᵢ 0) (Gᵢ a)) :
  submodule R R := submodule.span R {r : R | ∃ m : M, r = m.1}

/-- Construction of an `R₀`-submodule of `R` from an `R`-submodule of `R`. -/
def res (a : A) (I : submodule R R) : submodule (zero_component_subring R Gᵢ) R :=
{ carrier := I,
  zero_mem' := I.zero_mem,
  add_mem' := λ _ _, I.add_mem,
  smul_mem' := λ c _ hx, I.smul_mem c hx }

/-- Construction of an `R₀`-submodule of `Rₐ` from an `R`-submodule of `R`, given
  by intersection. -/
def comap (a : A) (I : submodule R R) : submodule (Gᵢ 0) (Gᵢ a) :=
submodule.comap (component_submodule_for_zero_component_subring R Gᵢ a).subtype (res R Gᵢ a I)

/-- Given an `R₀`-submodule `M` of `Rₐ`, pushing forward to `MR`, an ideal of `R`, and then
  intersecting with `Rₐ` gives back `M`.  -/
lemma comap_map_id (a : A)
  (M : submodule (Gᵢ 0) (Gᵢ a)) :
  comap R Gᵢ a (map R Gᵢ a M) = M :=
begin
  ext ⟨m, hm⟩,
  change m ∈ Gᵢ a at hm,
  -- goal: m ∈ R-span of M ↔ m ∈ M
  change m ∈ map R Gᵢ a M ↔ _,
  split,
  { rintro (h : m ∈ submodule.span R {r : R | ∃ (m : ↥M), r = ↑(m.val)}),
    -- M' is (the image of) M considered as a submodule of R
    let M' : submodule (Gᵢ 0) R :=
      submodule.map (component_submodule_for_zero_component_subring R Gᵢ a).subtype M,
    -- rewrite goal in terms of M'
    suffices : m ∈ M',
    { rcases this with ⟨t, ht, rfl⟩,
      cases M, simp only [set_like.eta, submodule.subtype_apply], exact ht },
    -- change hypothesis h to a form where we can rewrite finsupp.span_eq_map_total
    have h' : m ∈ submodule.span R (set.image (Gᵢ a).subtype (M : set (Gᵢ a))),
    { convert h,
      ext t,
      split,
      { rintro ⟨⟨s, hs⟩, hs2, rfl⟩,
        exact ⟨⟨⟨s, hs⟩, hs2⟩, rfl⟩ },
      { rintro ⟨⟨⟨s, hs⟩, hs2⟩, rfl⟩,
        exact ⟨⟨s, hs⟩, hs2, rfl⟩ } },
    clear h,
    rw finsupp.span_eq_map_total at h',
    rcases h' with ⟨f, hf, rfl⟩,
    -- hm says some element of r is in Rₐ
    -- so it's equal to its projection onto Rₐ
    have hm' := hm,
    rw mem_piece_iff_projection_eq' at hm',
    conv at hm' begin
      to_lhs,
      rw finsupp.total_apply,
    end,
    change ↑(((add_subgroup_decomposition_ring_equiv Gᵢ).to_add_monoid_hom _) a) =
      (finsupp.total ↥(Gᵢ a) R R ⇑((Gᵢ a).subtype)) f at hm',
    rw add_monoid_hom.map_finsupp_sum (add_subgroup_decomposition_ring_equiv Gᵢ).to_add_monoid_hom at hm',
    change ↑(projection _ a (f.sum (λ (m : ↥(Gᵢ a)) (b : R),
      (add_subgroup_decomposition_ring_equiv Gᵢ) (b * m.1)))) =
      (finsupp.total ↥(Gᵢ a) R R ⇑((Gᵢ a).subtype)) f at hm',
    rw add_monoid_hom.map_finsupp_sum (projection (λ i, Gᵢ i) a) at hm',
    simp_rw (add_subgroup_decomposition_ring_equiv Gᵢ).map_mul at hm',
    change (Gᵢ a).subtype _ = _ at hm',
    rw add_monoid_hom.map_finsupp_sum at hm',
    sorry },
  { -- easy way
    intro h,
    apply submodule.subset_span,
    refine ⟨⟨⟨m, hm⟩, h⟩, rfl⟩ }
end

end component_submodule

theorem component_submodule_noetherian {R : Type*} [comm_ring R] [is_noetherian_ring R]
  {A : Type*} [add_monoid A] [decidable_eq A]
  (Gᵢ : A → add_subgroup R) [has_add_subgroup_decomposition Gᵢ] [add_subgroup.is_gmonoid Gᵢ]
  (a : A) : is_noetherian (zero_component_subring R Gᵢ)
    (component_submodule_for_zero_component_subring R Gᵢ a) :=
begin
  sorry
end

end comm_ring

end has_add_subgroup_decomposition

end direct_sum
