import data.polynomial.degree.lemmas
import algebra.module.ordered
import algebra.regular
import ring_theory.noetherian
import linear_algebra.finite_dimensional

/-- In the intended application, these are the players:
* `R₀ = ℕ`;
* `R = ℤ`;
* `M`and `N` are free finitely generated `ℤ`-modules that are dual to each other;
* `P = ℤ` is the target of the natural pairing `M ⊗ N → ℤ`.
-/
variables (R₀ R M N P : Type*)

namespace submodule

section comm_semiring

variables {R₀} {M}

variables [comm_semiring R₀] [add_comm_monoid M] [semimodule R₀ M]

/-- This definition does not assume that `R₀` injects into `R`.  If the map `R₀ → R` has a
non-trivial kernel, this might not be the definition you think. -/
def saturated (s : submodule R₀ M) : Prop :=
∀ (r : R₀) (hr : is_regular r) (m : M), r • m ∈ s → m ∈ s

/--  The saturation of a submodule `s ⊆ M` is the submodule obtained from `s` by adding all
elements of `M` that admit a multiple by a regular element of `R₀` lying in `s`. -/
def saturation (s : submodule R₀ M) : submodule R₀ M :=
{ carrier := { m : M | ∃ (r : R₀), is_regular r ∧ r • m ∈ s },
  zero_mem' := ⟨1, is_regular_one, by { rw smul_zero, exact s.zero_mem }⟩,
  add_mem' := begin
    rintros a b ⟨q, hqreg, hqa⟩ ⟨r, hrreg, hrb⟩,
    refine ⟨q * r, is_regular_mul_iff.mpr ⟨hqreg, hrreg⟩, _⟩,
    rw [smul_add],
    refine s.add_mem _ _,
    { rw [mul_comm, mul_smul],
      exact s.smul_mem _ hqa },
    { rw mul_smul,
      exact s.smul_mem _ hrb },
  end,
  smul_mem' := λ c m ⟨r, hrreg, hrm⟩,
    ⟨r, hrreg, by {rw smul_algebra_smul_comm, exact s.smul_mem _ hrm}⟩ }

/--  The saturation of `s` contains `s`. -/
lemma le_saturation (s : submodule R₀ M) : s ≤ saturation s :=
λ m hm, ⟨1, is_regular_one, by rwa one_smul⟩

/- I (DT) extracted this lemma from the proof of `dual_eq_dual_saturation`, since it seems a
lemma that we may use elsewhere as well. -/
lemma set_subset_saturation  {S : set M} :
  S ⊆ (submodule.saturation (submodule.span R₀ S)) :=
set.subset.trans (submodule.subset_span : S ⊆ submodule.span R₀ S)
  (submodule.le_saturation (submodule.span R₀ S))

/-
TODO: develop the API for the definitions
`is_cyclic`, `pointed`, `has_extremal_ray`, `extremal_rays`.
Prove(?) `sup_extremal_rays`, if it is true, even in the test case.
-/
/--  A cyclic submodule is a submodule generated by a single element. -/
def is_cyclic (s : submodule R₀ M) : Prop := ∃ m : M, submodule.span R₀ {m} = s

variables (R₀ M)

/--  A semimodule is cyclic if its top submodule is generated by a single element. -/
def semimodule.is_cyclic : Prop := is_cyclic (⊤ : submodule R₀ M)

variables {R₀ M}

/--  The zero submodule is cyclic. -/
lemma is_cyclic_bot : is_cyclic (⊥ : submodule R₀ M) :=
⟨_, span_zero_singleton⟩

/--  An extremal ray `r` is a cyclic submodule that can only be "reached" by vectors in `r`. -/
def has_extremal_ray (s r : submodule R₀ M) : Prop :=
r.is_cyclic ∧ ∀ {x y : M}, x ∈ s → y ∈ s → x + y ∈ r → (x ∈ r ∧ y ∈ r)

/--  The set of all extremal rays of a submodule.  Hopefully, these are a good replacement for
generators, in the case in which the cone is `pointed`. -/
def extremal_rays (s : submodule R₀ M) : set (submodule R₀ M) :=
{ r | s.has_extremal_ray r }

/-  The `is_scalar_tower R₀ R M` assumption is not needed to state `pointed`, but will likely play
a role in the proof of `sup_extremal_rays`. -/
variables [comm_semiring R] [semimodule R M]

/--  A pointed submodule is a submodule `s` that intersects the hyperplane `ker φ` just in the
origin.  Alternatively, the submodule `s` contains no `R` linear subspace. -/
def pointed (s : submodule R₀ M) : Prop := ∃ φ : M →ₗ[R] R, ∀ x : M, x ∈ s → φ x = 0 → x = 0

variables [algebra R₀ R] [is_scalar_tower R₀ R M]

/-- This lemma shows that any `R₀`-submodule of `R` is pointed, since the identity function is
a "separating hyperplane".  This should not happen if the module is not cyclic for `R`. -/
lemma pointed_of_sub_R {s : submodule R₀ R} : pointed R s :=
⟨1, λ _ _ h, h⟩

/--  Hopefully, this lemma will be easy to prove. -/
lemma sup_extremal_rays {s : submodule R₀ M} (sp : s.pointed R) :
  ⨆ r ∈ s.extremal_rays, r = s :=
sorry

end comm_semiring

section integral_domain

variables [integral_domain R₀] [add_comm_monoid M] [semimodule R₀ M]

/--  A sanity check that our definitions imply something not completely trivial
in an easy situation! -/
lemma sat {s t : submodule R₀ M}
  (s0 : s ≠ ⊥) (ss : s.saturated) (st : s ≤ t) (ct : is_cyclic t) :
  s = t :=
begin
  refine le_antisymm st _,
  rcases ct with ⟨t0, rfl⟩,
  refine (span_singleton_le_iff_mem t0 s).mpr _,
  rcases (submodule.ne_bot_iff _).mp s0 with ⟨m, hm, m0⟩,
  rcases (le_span_singleton_iff.mp st) _ hm with ⟨c, rfl⟩,
  refine ss _ (is_regular_of_cancel_monoid_with_zero _) _ hm,
  exact λ h, m0 (by rw [h, zero_smul]),
end

end integral_domain

end submodule


variables [comm_semiring R₀] [comm_semiring R] [algebra R₀ R]
  [add_comm_monoid M] [semimodule R₀ M] [semimodule R M] [is_scalar_tower R₀ R M]
  [add_comm_monoid N] [semimodule R₀ N] [semimodule R N] [is_scalar_tower R₀ R N]
  [add_comm_monoid P] [semimodule R₀ P] [semimodule R P] [is_scalar_tower R₀ R P]
  (P₀ : submodule R₀ P)

section pairing


/-- An R-pairing on the R-modules M, N, P is an R-linear map M -> Hom_R(N,P). -/
@[derive has_coe_to_fun] def pairing := M →ₗ[R] N →ₗ[R] P

instance pairing.inhabited : inhabited (pairing R M N P) :=
⟨{to_fun := 0, map_add' := by simp, map_smul' := by simp }⟩

variables {R M N P}

/--  Given a pairing between the `R`-modules `M` and `N`, we obtain a pairing between `N` and `M`
by exchanging the factors. -/
def pairing.flip : pairing R M N P → pairing R N M P := linear_map.flip

end pairing

variables {M}


namespace pairing

variables {R₀ R M N P} (f : pairing R M N P)

/--  For a subset `s ⊆ M`, the `dual_set s` is the submodule consisting of all elements of `N`
that have "positive pairing with all the elements of `s`.  "Positive" means that it lies in the
`R₀`-submodule `P₀` of `P`. -/
def dual_set (s : set M) : submodule R₀ N :=
{ carrier := { n : N | ∀ m ∈ s, f m n ∈ P₀ },
  zero_mem' := λ m hm, by simp only [linear_map.map_zero, P₀.zero_mem],
  add_mem' := λ n1 n2 hn1 hn2 m hm, begin
    rw linear_map.map_add,
    exact P₀.add_mem (hn1 m hm) (hn2 m hm),
  end,
  smul_mem' := λ r n h m hms, by simp [h m hms, P₀.smul_mem] }

lemma mem_dual_set (s : set M) (n : N) :
  n ∈ f.dual_set P₀ s ↔ ∀ m ∈ s, f m n ∈ P₀ := iff.rfl

section saturated

variables {P₀} (hP₀ : P₀.saturated)
include hP₀

lemma smul_regular_iff {r : R₀} (hr : is_regular r) (p : P) :
  r • p ∈ P₀ ↔ p ∈ P₀ :=
⟨hP₀ _ hr _, P₀.smul_mem _⟩

lemma dual_set_saturated (s : set M) (hP₀ : P₀.saturated) :
  (f.dual_set P₀ s).saturated :=
λ r hr n hn m hm, by simpa [smul_regular_iff hP₀ hr] using hn m hm

end saturated

-- this instance can be removed when #6331 is merged.
instance : is_scalar_tower R₀ R (N →ₗ[R] P) :=
{ smul_assoc := λ _ _ _, linear_map.ext $ by simp }

variable {P₀}

lemma dual_subset {s t : set M} (st : s ⊆ t) : f.dual_set P₀ t ≤ f.dual_set P₀ s :=
λ n hn m hm, hn m (st hm)

lemma mem_span_dual_set (s : set M) :
  f.dual_set P₀ (submodule.span R₀ s) = f.dual_set P₀ s :=
begin
  refine (dual_subset f submodule.subset_span).antisymm _,
  { refine λ n hn m hm, submodule.span_induction hm hn _ _ _,
    { simp only [linear_map.map_zero, submodule.zero_mem, linear_map.zero_apply] },
    { exact λ x y hx hy, by simp [P₀.add_mem hx hy] },
    { exact λ r m hm, by simp [P₀.smul_mem _ hm] } }
end

lemma subset_dual_dual {s : set M} : s ⊆ f.flip.dual_set P₀ (f.dual_set P₀ s) :=
λ m hm _ hm', hm' m hm

lemma subset_dual_set_of_subset_dual_set {S : set M} {T : set N}
  (ST : S ⊆ f.flip.dual_set P₀ T) :
  T ⊆ f.dual_set P₀ S :=
λ n hn m hm, ST hm _ hn

lemma le_dual_set_of_le_dual_set {S : submodule R₀ M} {T : submodule R₀ N}
  (ST : S ≤ f.flip.dual_set P₀ T) :
  T ≤ f.dual_set P₀ S :=
subset_dual_set_of_subset_dual_set _ ST

lemma dual_set_closure_eq {s : set M} :
  f.dual_set P₀ (submodule.span R₀ s) = f.dual_set P₀ s :=
begin
  refine (dual_subset _ submodule.subset_span).antisymm _,
  refine λ n hn m hm, submodule.span_induction hm hn _ _ _,
  { simp only [linear_map.map_zero, linear_map.zero_apply, P₀.zero_mem] },
  { exact λ x y hx hy, by simp only [linear_map.add_apply, linear_map.map_add, P₀.add_mem hx hy] },
  { exact λ r m hmn, by simp [P₀.smul_mem r hmn] },
end

lemma dual_eq_dual_saturation {S : set M} (hP₀ : P₀.saturated) :
  f.dual_set P₀ S = f.dual_set P₀ ((submodule.span R₀ S).saturation) :=
begin
  refine le_antisymm _ (dual_subset _ (submodule.set_subset_saturation)),
  rintro n hn m ⟨r, hr_reg, hrm⟩,
  refine (smul_regular_iff hP₀ hr_reg _).mp _,
  rw [← mem_span_dual_set, mem_dual_set] at hn,
  simpa using hn (r • m) hrm
end

/- flip the inequalities assuming saturatedness -/
lemma le_dual_set_of_le_dual_set_satu {S : submodule R₀ M} {T : submodule R₀ N}
  (ST : S ≤ f.flip.dual_set P₀ T) :
  T ≤ f.dual_set P₀ S :=
subset_dual_set_of_subset_dual_set _ ST

lemma subset_dual_set_iff {S : set M} {T : set N} :
  S ⊆ f.flip.dual_set P₀ T ↔ T ⊆ f.dual_set P₀ S :=
⟨subset_dual_set_of_subset_dual_set f, subset_dual_set_of_subset_dual_set f.flip⟩

lemma le_dual_set_iff {S : submodule R₀ M} {T : submodule R₀ N} :
  S ≤ f.flip.dual_set P₀ T ↔ T ≤ f.dual_set P₀ S :=
subset_dual_set_iff _

/- This lemma is a weakining of the next one.  It has the advantage that we can prove it in
this level of generality!  ;)
-/
lemma dual_dual_dual (S : set M) :
  f.dual_set P₀ (f.flip.dual_set P₀ (f.dual_set P₀ S)) = f.dual_set P₀ S :=
le_antisymm (λ m hm n hn, hm _ ((subset_dual_set_iff f).mpr set.subset.rfl hn))
  (λ m hm n hn, hn m hm)

variable (P₀)

/--  The rays of the dual of the set `s` are the duals of the subsets of `s` that happen to be
cyclic. -/
def dual_set_rays (s : set M) : set (submodule R₀ N) :=
{ r | r.is_cyclic ∧ ∃ s' ⊆ s, r = f.dual_set P₀ s' }

/-  We may need extra assumptions for this. -/
/--  The link between the rays of the dual and the extremal rays of the dual should be the
crucial finiteness step: if `s` is finite, there are only finitely many `dual_set_rays`, since
there are at most as many as there are subsets of `s`.  If the extremal rays generate
dual of `s`, then we are in a good position to prove Gordan's lemma! -/
lemma dual_set_rays_eq_extremal_rays (s : set M) :
  f.dual_set_rays P₀ s = (f.dual_set P₀ s).extremal_rays :=
sorry

lemma dual_set_pointed (s : set M) (hs : (submodule.span R₀ s).saturation) :
  (f.dual_set P₀ s).pointed R := sorry

--def dual_set_generators (s : set M) : set N := { n : N | }

lemma dual_fg_of_finite {s : set M} (fs : s.finite) : (f.dual_set P₀ s).fg :=
sorry

lemma dual_dual_of_saturated {S : submodule R₀ M} (Ss : S.saturated) :
  f.flip.dual_set P₀ (f.dual_set P₀ S) = S :=
begin
  refine le_antisymm _ (subset_dual_dual f),
  intros m hm,
--  rw mem_dual_set at hm,
  change ∀ (n : N), n ∈ (dual_set P₀ f ↑S) → f m n ∈ P₀ at hm,
  simp_rw mem_dual_set at hm,
  -- is this true? I (KMB) don't know and the guru (Damiano) has left!
  -- oh wait, no way is this true, we need some nondegeneracy condition
  -- on f, it's surely not true if f is just the zero map.
  -- I (DT) think that you are right, Kevin.  We may now start to make assumptions
  -- that are more specific to our situation.
  sorry,
end

end pairing
