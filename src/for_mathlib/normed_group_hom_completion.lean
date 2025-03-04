import analysis.normed_space.normed_group_hom

import for_mathlib.normed_group

noncomputable theory

open set normed_group_hom uniform_space

variables {G : Type*} [semi_normed_group G]
variables {H : Type*} [semi_normed_group H]
variables {K : Type*} [semi_normed_group K]

def normed_group_hom.completion (f : normed_group_hom G H) :
  normed_group_hom (completion G) (completion H) :=
{ to_fun := completion.map f,
  map_add' := by { intros x y,
                   apply completion.induction_on₂ x y,
                   apply is_closed_eq,
                   exact completion.continuous_map.comp continuous_add,
                   exact (completion.continuous_map.comp  continuous_fst).add (completion.continuous_map.comp continuous_snd),
                   intros a b,
                   norm_cast,
                   simp [completion.map_coe f.uniform_continuous],
                   norm_cast },
  bound' := begin
    use ∥f∥,
    intro y,
    apply completion.induction_on y,
    exact is_closed_le (continuous_norm.comp completion.continuous_map) (continuous_const.mul continuous_norm),
    intro x,
    rw completion.map_coe f.uniform_continuous,
    simp only [f.le_op_norm x, completion.norm_coe]
  end }

lemma normed_group_hom.completion_def (f : normed_group_hom G H) (x : completion G) :
  f.completion x = completion.map f x := rfl

lemma normed_group_hom.completion_coe_to_fun (f : normed_group_hom G H) :
  (f.completion : (completion G) → (completion H)) = completion.map f :=
by { ext x, exact normed_group_hom.completion_def f x }

@[simp]
lemma normed_group_hom.completion_coe (f : normed_group_hom G H) (g : G) : f.completion g = f g :=
completion.map_coe f.uniform_continuous _

@[simp]
lemma normed_group_hom.completion_id : (normed_group_hom.id G).completion =
  normed_group_hom.id (completion G) :=
begin
  ext x,
  rw [normed_group_hom.completion_def, normed_group_hom.coe_id, completion.map_id],
  refl
end

lemma normed_group_hom.completion_comp (f : normed_group_hom G H) (g : normed_group_hom H K) :
  g.completion.comp f.completion = (g.comp f).completion :=
begin
  ext x,
  rw [normed_group_hom.coe_comp, normed_group_hom.completion_def,
    normed_group_hom.completion_coe_to_fun, normed_group_hom.completion_coe_to_fun,
    completion.map_comp (normed_group_hom.uniform_continuous _)
    (normed_group_hom.uniform_continuous _)],
  refl
end

lemma normed_group_hom.completion_add (f g : normed_group_hom G H) :
  (f + g).completion = f.completion + g.completion :=
begin
  ext x,
  apply uniform_space.completion.induction_on x,
  { refine is_closed_eq (normed_group_hom.continuous _) _,
    apply continuous.add; apply normed_group_hom.continuous },
  { clear x, intro x,
    simp only [add_apply, normed_group_hom.completion_coe],
    exact is_add_hom.map_add coe (f x) (g x) }
end

def normed_group.to_compl : normed_group_hom G (completion G) :=
{ to_fun := coe,
  map_add' := by { intros x y,
                   exact is_add_hom.map_add coe x y },
  bound' := ⟨1, by simp [le_refl]⟩ }

abbreviation j := (normed_group.to_compl : normed_group_hom G $ completion G)

lemma normed_group.norm_to_compl (x : G) : ∥j x∥ = ∥x∥ :=
completion.norm_coe x

@[simp]
lemma normed_group_hom.zero_completion : (0 : normed_group_hom G H).completion = 0 :=
begin
  ext,
  apply completion.induction_on x,
  { apply is_closed_eq,
    continuity },
  { simp [normed_group_hom.mem_ker, completion.coe_zero] }
end

lemma normed_group.dense_range_to_compl : dense_range (j : G → completion G) :=
completion.dense_inducing_coe.dense

@[simp]
lemma normed_group_hom.completion_to_compl (f : normed_group_hom G H) : f.completion.comp j = j.comp f :=
begin
  ext x,
  change f.completion x = _,
  simpa
end

lemma normed_group_hom.norm_completion_le (f : normed_group_hom G H) : ∥f.completion∥ ≤ ∥f∥ :=
begin
  apply f.completion.op_norm_le_bound (norm_nonneg _),
  intro x,
  apply completion.induction_on x,
  { apply is_closed_le,
    continuity },
  { intro g,
    simp [f.le_op_norm  g] },
end

lemma normed_group_hom.ker_le_ker_completion (f : normed_group_hom G H) :
  (j.comp $ incl f.ker).range ≤ f.completion.ker  :=
begin
  intros a h,
  replace h : ∃ y : f.ker, j (y : G) = a, by simpa using h,
  rcases h with ⟨⟨g, g_in : g ∈ f.ker⟩, rfl⟩,
  rw f.mem_ker at g_in,
  change f.completion (g : completion G) = 0,
  simp [normed_group_hom.mem_ker, f.completion_coe g, g_in, completion.coe_zero],
end

lemma normed_group_hom.ker_completion {f : normed_group_hom G H} {C : ℝ}
  (h : ∀ h ∈ f.range, ∃ g, f g = h ∧ ∥g∥ ≤ C*∥h∥) :
  (f.completion.ker : set $ completion G) = closure (j.comp $ incl f.ker).range :=
begin
  by_cases Hf : ∀ x, ∥f x∥ = 0, -- This is a bit silly, we simply avoid assuming C ≥ 0
  { apply le_antisymm,
    { intros hatg hatg_in,
      rw semi_normed_group.mem_closure_iff,
      intros ε ε_pos,
      obtain ⟨_, ⟨g : G, rfl⟩, hg : ∥hatg - g∥ < ε⟩ :=
      semi_normed_group.mem_closure_iff.mp (completion.dense_inducing_coe.dense hatg) ε ε_pos,
      obtain ⟨g' : G, hgg' : f g' = f g, hfg : ∥g'∥ ≤ C * ∥f g∥⟩ :=
      h (f g) (mem_range_self g),
      rw [Hf g, mul_zero] at hfg,
      refine ⟨g - g', _, _⟩,
      { norm_cast,
        rw normed_group_hom.comp_range,
        apply add_subgroup.mem_map_of_mem,
        simp only [incl_range, mem_ker, map_sub, hgg', sub_self], },
      { calc ∥hatg - (g - g')∥ = ∥hatg - g + g'∥ : by abel
      ... ≤ ∥hatg - g∥ + ∥(g' : completion G)∥ : norm_add_le _ _
      ... = ∥hatg - g∥ + ∥g'∥ : by rw [completion.norm_coe]
      ... ≤ ∥hatg - g∥ : (add_le_iff_nonpos_right _).2 hfg
      ... < ε : hg } },
    { rw ← f.completion.is_closed_ker.closure_eq,
      exact closure_mono f.ker_le_ker_completion } },
  have hC : 0 ≤ C,
  { push_neg at Hf,
    cases Hf with x hx,
    rcases h (f x) (mem_range_self x) with ⟨y, hy, hy'⟩,
    rw ← hy at hy' hx,
    exact nonneg_of_mul_nonneg_right ((norm_nonneg y).trans hy')
      (lt_of_le_of_ne (norm_nonneg (f y)) hx.symm) },
  apply le_antisymm, -- Now start the actual proof
  { intros hatg hatg_in,
    rw semi_normed_group.mem_closure_iff,
    intros ε ε_pos,
    have hCf : 0 ≤ C*∥f∥ := mul_nonneg hC (norm_nonneg _),
    have ineq : 0 < 1 + C*∥f∥, by linarith,
    set δ := ε/(1 + C*∥f∥),
    have δ_pos : δ > 0, from div_pos ε_pos ineq,
    obtain ⟨_, ⟨g : G, rfl⟩, hg : ∥hatg - g∥ < δ⟩ :=
      semi_normed_group.mem_closure_iff.mp (completion.dense_inducing_coe.dense hatg) δ δ_pos,
    obtain ⟨g' : G, hgg' : f g' = f g, hfg : ∥g'∥ ≤ C * ∥f g∥⟩ :=
      h (f g) (mem_range_self g),
    have mem_ker : g - g' ∈ f.ker,
      by rw [f.mem_ker, f.map_sub, sub_eq_zero.mpr hgg'.symm],
    have : ∥f g∥ ≤ ∥f∥*∥hatg - g∥,
    calc
      ∥f g∥ = ∥f.completion g∥ : by rw [f.completion_coe, completion.norm_coe]
        ... = ∥f.completion g - 0∥ : by rw [sub_zero _]
        ... = ∥f.completion g - (f.completion hatg)∥ : by rw [(f.completion.mem_ker _).mp hatg_in]
        ... = ∥f.completion (g - hatg)∥ : by rw [f.completion.map_sub]
        ... ≤ ∥f.completion∥ * ∥(g :completion G) - hatg∥ : f.completion.le_op_norm _
        ... = ∥f.completion∥ * ∥hatg - g∥ : by rw norm_sub_rev
        ... ≤ ∥f∥ * ∥hatg - g∥ : mul_le_mul_of_nonneg_right
          (normed_group_hom.norm_completion_le f) (norm_nonneg _),
    have : ∥(g' : completion G)∥ ≤ C*∥f∥*∥hatg - g∥,
    calc
    ∥(g' : completion G)∥ = ∥g'∥ : completion.norm_coe _
                      ... ≤ C * ∥f g∥ : hfg
                      ... ≤ C * ∥f∥ * ∥hatg - g∥ : by { rw mul_assoc,
                                                        exact mul_le_mul_of_nonneg_left this hC},


    refine ⟨g - g', _, _⟩,
    { norm_cast,
      rw normed_group_hom.comp_range,
      apply add_subgroup.mem_map_of_mem,
      simp only [incl_range, mem_ker] },
    { calc ∥hatg - (g - g')∥ = ∥hatg - g + g'∥ : by abel
      ... ≤ ∥hatg - g∥ + ∥(g' : completion G)∥ : norm_add_le _ _
      ... < δ + C*∥f∥*∥hatg - g∥ : by linarith
      ... ≤ δ + C*∥f∥*δ : add_le_add_left (mul_le_mul_of_nonneg_left hg.le hCf) δ
      ... = (1 + C*∥f∥)*δ : by ring
      ... = ε : mul_div_cancel' _ ineq.ne.symm } },
  { rw ← f.completion.is_closed_ker.closure_eq,
    exact closure_mono f.ker_le_ker_completion }
end
