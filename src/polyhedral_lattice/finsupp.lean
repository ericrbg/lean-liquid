import linear_algebra.finsupp_vector_space

import for_mathlib.finsupp

import polyhedral_lattice.basic
/-!

# Hom(ι, Λ) for Λ a polyhedral lattice

If Λ is a polyhedral lattice and ι is a finite type, then ι → Λ is a polyhedral lattice.

## Implementation issue

We use `ι →₀ Λ` rather than `ι → Λ` to make life easier with sums.

-/
noncomputable theory

open_locale big_operators classical

namespace finsupp

variables (ι Λ : Type*) [fintype ι]

section normed_group

variables [normed_group Λ]

instance : has_norm (ι →₀ Λ) := ⟨λ x, x.sum $ λ _, norm⟩

variables {ι Λ}

lemma norm_def (x : ι →₀ Λ) : ∥x∥ = x.sum (λ _, norm) := rfl

@[simp] lemma norm_single (i : ι) (l : Λ) : ∥single i l∥ = ∥l∥ :=
by simp only [norm_def, sum_single_index, norm_zero]

variables (ι Λ)

instance : normed_group (ι →₀ Λ) :=
normed_group.of_core _ $
{ norm_eq_zero_iff := λ x,
  begin
    simp only [norm_def, sum, ← coe_nnnorm, ← nnreal.coe_sum, nnreal.coe_eq_zero, coe_zero,
      finset.sum_eq_zero_iff, nnnorm_eq_zero, mem_support_iff, ext_iff, pi.zero_apply, not_imp_self]
  end,
  triangle :=
  begin
    intros x y,
    have aux := @sum_eq_sum_fintype ι Λ _ _ _ _ (λ i, norm) (λ i, norm_zero),
    simp only [norm_def, aux, ← finset.sum_add_distrib, add_apply],
    apply finset.sum_le_sum,
    rintro i -,
    apply norm_add_le,
  end,
  norm_neg := λ x,
  begin
    have aux := @sum_eq_sum_fintype ι Λ _ _ _ _ (λ i, norm) (λ i, norm_zero),
    simp only [norm_def, aux, norm_neg, neg_apply]
  end }

variables {ι Λ}

lemma nnnorm_def (x : ι →₀ Λ) : nnnorm x = x.sum (λ _, nnnorm) :=
begin
  ext,
  simpa only [coe_nnnorm, finsupp.sum, nnreal.coe_sum] using norm_def x,
end

end normed_group

variables [polyhedral_lattice Λ]

instance {ι : Type} [fintype ι] : polyhedral_lattice (ι →₀ Λ) :=
{ finite_free :=
  begin
    obtain ⟨J, _instJ, ⟨l⟩⟩ := polyhedral_lattice.finite_free Λ, resetI,
    exact ⟨_, infer_instance, ⟨finsupp.basis (λ i, l)⟩⟩
  end,
  polyhedral' :=
  begin
    obtain ⟨J, _instJ, x, hx⟩ := polyhedral_lattice.polyhedral' Λ, resetI,
    refine ⟨ι × J, infer_instance, λ j, single j.1 (x j.2), _⟩,
    intro l,
    have := λ i, hx (l i),
    choose c H1 H2 using this,
    have hl : l = ∑ i, single i (l i),
    { conv_lhs { rw [← sum_single l, sum] },
      apply finset.sum_subset (finset.subset_univ _),
      rintro i - hi,
      rw not_mem_support_iff at hi,
      rw [hi, single_zero] },
    refine ⟨λ j, c j.1 j.2, _, _⟩,
    { rw [hl, ← finset.univ_product_univ, finset.sum_product],
      apply fintype.sum_congr,
      intro i,
      rw [← single_add_hom_apply, H1, add_monoid_hom.map_sum],
      apply fintype.sum_congr,
      intro j,
      rw [add_monoid_hom.map_nsmul],
      refl },
    { have aux := @sum_eq_sum_fintype ι Λ _ _ _ _ (λ i, norm) (λ i, norm_zero),
      simp only [norm_def, aux, ← finset.univ_product_univ, finset.sum_product, H2, norm_single], }
  end }

end finsupp
