import data.real.nnreal
import topology.algebra.infinite_sum

open_locale nnreal big_operators

def mask_fun {α : Type*} (f : α → ℝ≥0) (mask : α → Prop) [∀ n, decidable (mask n)] : α → ℝ≥0 :=
λ n, if mask n then f n else 0

structure recursion_data (N : ℕ) (hN : 0 < N) (f : ℕ → ℝ≥0) (hf : ∀ n, f n ≤ 1) (k : ℕ) :=
(m : fin N → Prop)
(dec_inst : ∀ i, decidable (m i))
(hm :  ∃! i, m i)
(partial_sums : fin N → ℝ≥0)
(h₁ : ∑ i, partial_sums i = ∑ n : fin (k + 1), f n)
(h₂ : ∀ i, partial_sums i ≤ (∑ n : fin (k + 1), f n) / N + 1)

def recursion_data_zero (N : ℕ) (hN : 0 < N) (f : ℕ → ℝ≥0) (hf : ∀ n, f n ≤ 1) :
  recursion_data N hN f hf 0 :=
-- have _i : has_zero (fin N) := sorry, -- this follows from hN
{ m := λ j, j = ⟨0, hN⟩,
  dec_inst := by apply_instance,
  hm := ⟨_, rfl, by simp⟩,
  partial_sums := λ j, if j = ⟨0, hN⟩ then f 0 else 0,
  h₁ := by simp,
  h₂ :=
  begin
    intros i,
    split_ifs,
    { simp,
      refine (hf 0).trans _,
      exact self_le_add_left 1 (f 0 / ↑N) },
    { simp }
  end }

noncomputable def recursion_data_succ (N : ℕ) (hN : 0 < N) (f : ℕ → ℝ≥0) (hf : ∀ n, f n ≤ 1) (k : ℕ)
  (dat : recursion_data N hN f hf k) :
  recursion_data N hN f hf (k + 1) :=
let I := (finset.univ : finset (fin N)).exists_min_image
  dat.partial_sums ⟨⟨0, hN⟩, finset.mem_univ _⟩ in
{ m := λ j, j = I.some,
  dec_inst := by apply_instance,
  hm := ⟨I.some, by simp, by simp⟩,
  partial_sums := λ i, dat.partial_sums i + (if i = I.some then f (k + 1) else 0),
  h₁ := begin
    rw @fin.sum_univ_cast_succ _ _ (k + 1),
    simp [finset.sum_add_distrib, dat.h₁],
  end,
  h₂ := begin
    intros i,
    split_ifs,
    { rw h,
      have : dat.partial_sums I.some * N ≤ (∑ (n : fin (k + 1 + 1)), f ↑n),
      { calc dat.partial_sums I.some * N ≤ ∑ i, dat.partial_sums i : _ -- follows from I
        ... = ∑ n : fin (k + 1), f n : dat.h₁
        ... ≤ ∑ n : fin (k + 1 + 1), f n : _,
        { sorry },
        rw @fin.sum_univ_cast_succ _ _ (k + 1),
        simp },
      have : dat.partial_sums I.some ≤ (∑ (n : fin (k + 1 + 1)), f ↑n) / ↑N,
      { sorry }, -- algebra from previous
      exact add_le_add this (hf (k + 1)) },
    { transitivity (∑ n : fin (k + 1), f n) / N + 1,
      { simpa using dat.h₂ i },
      sorry } -- shouldn't be hard, but I wish `linarith` worked here!
  end }

noncomputable def partition (N : ℕ) (hN : 0 < N) (f : ℕ → ℝ≥0) (hf : ∀ n, f n ≤ 1) :
  Π i : ℕ, (recursion_data N hN f hf i)
| 0 := recursion_data_zero N hN f hf
| (k + 1) := recursion_data_succ N hN f hf k (partition k)

lemma partition_sums_aux (k : ℕ) (N : ℕ) (hN : 0 < N) (f : ℕ → ℝ≥0) (hf : ∀ n, f n ≤ 1)
  (i : fin N) :
  (partition N hN f hf (k + 1)).partial_sums i
  = (partition N hN f hf k).partial_sums i
  + (@ite _ ((partition N hN f hf (k + 1)).m i) ((partition N hN f hf (k + 1)).dec_inst i) (f (k + 1)) 0) :=
by simp [partition, recursion_data_succ]

lemma partition_sums (k : ℕ) (N : ℕ) (hN : 0 < N) (f : ℕ → ℝ≥0) (hf : ∀ n, f n ≤ 1)
  (i : fin N) :
  (partition N hN f hf k).partial_sums i
  = ∑ n : fin (k + 1), @mask_fun _ (f ∘ coe) (λ k, (partition N hN f hf k).m i)
    (λ k, (partition N hN f hf k).dec_inst i) n :=
begin
  induction k with k IH,
  { dsimp [partition, mask_fun], simp, dsimp [partition, recursion_data_zero], congr },
  rw [partition_sums_aux, IH, @fin.sum_univ_cast_succ _ _ k.succ],
  congr' 1,
  simp [mask_fun]
end

lemma exists_partition (N : ℕ) (hN : 0 < N) (f : ℕ → ℝ≥0) (hf : ∀ n, f n ≤ 1) :
  ∃ (mask : fin N → ℕ → Prop) [∀ i n, decidable (mask i n)], by exactI
    (∀ n, ∃! i, mask i n) ∧ (∀ i, ∑' n, mask_fun f (mask i) n ≤ (∑' n, f n) / N + 1) :=
begin
  let mask : fin N → ℕ → Prop := λ i, λ n, (partition N hN f hf n).m i,
  let partial_sums : fin N → ℕ → ℝ≥0 := λ i, λ n, (partition N hN f hf n).partial_sums i,
  haveI : ∀ i n, decidable (mask i n) := λ i, λ n, (partition N hN f hf n).dec_inst i,
  have h_sum : ∀ k, ∀ i, ∑ (n : fin k), mask_fun f (mask i) n ≤ (∑ (n : fin k), f n) / ↑N + 1,
  { intros k i,
    cases k,
    { simp [mask_fun, mask] },
    convert (partition N hN f hf k).h₂ i,
    convert (partition_sums k N hN f hf i).symm,
    ext n m,
    simp [mask, mask_fun] },
  refine ⟨mask, by apply_instance, _, _⟩,
  { intros n,
    exact (partition N hN f hf n).hm },
  { intros i,
    have := λ k, h_sum k i,
    -- now extend this inequality from partial sums to infinite sum
    sorry }
end
