import algebra.homology.additive

open category_theory category_theory.limits

variables {V V₁ V₂ ι : Type*} {c : complex_shape ι} [category V] [category V₁] [category V₂]

namespace homological_complex

variables [has_zero_morphisms V] [has_zero_morphisms V₁] [has_zero_morphisms V₂]
variables {C₁ C₂ C₃ : homological_complex V c}

@[simps]
def iso_app (f : C₁ ≅ C₂) (i : ι) : C₁.X i ≅ C₂.X i :=
{ hom := f.hom.f i,
  inv := f.inv.f i,
  hom_inv_id' := by { erw [← comp_f, f.hom_inv_id, id_f] },
  inv_hom_id' := by { erw [← comp_f, f.inv_hom_id, id_f] } }

@[simps]
def iso_of_components (f : Π i, C₁.X i ≅ C₂.X i)
  (hf : ∀ i j, (f i).hom ≫ C₂.d i j = C₁.d i j ≫ (f j).hom) :
  C₁ ≅ C₂ :=
{ hom := { f := λ i, (f i).hom, comm' := hf },
  inv :=
  { f := λ i, (f i).inv,
    comm' := λ i j,
    calc (f i).inv ≫ C₁.d i j
        = (f i).inv ≫ (C₁.d i j ≫ (f j).hom) ≫ (f j).inv : by simp
    ... = (f i).inv ≫ ((f i).hom ≫ C₂.d i j) ≫ (f j).inv : by rw hf
    ... =  C₂.d i j ≫ (f j).inv : by simp },
  hom_inv_id' := by { ext i, exact (f i).hom_inv_id },
  inv_hom_id' := by { ext i, exact (f i).inv_hom_id } }

variables (V c)

@[simps] def forget : homological_complex V c ⥤ graded_object ι V :=
{ obj := λ C, C.X,
  map := λ _ _ f, f.f }

-- This ↓ is maybe not really "for_mathlib"

/-- A complex of functors gives a functor to complexes

jmc: This is functorial, but I'm getting timeouts, and I think this is all we need -/
def as_functor {T : Type*} [category V] [preadditive V] [category T]
  (C : homological_complex (T ⥤ V) c) :
  T ⥤ homological_complex V c :=
{ obj := λ t,
  { X := λ i, (C.X i).obj t,
    d := λ i j, (C.d i j).app t,
    d_comp_d' := λ i j k,
    begin
      have := C.d_comp_d i j k,
      rw [nat_trans.ext_iff, function.funext_iff] at this,
      exact this t
    end,
    shape' := λ i j h,
    begin
      have := C.shape _ _ h,
      rw [nat_trans.ext_iff, function.funext_iff] at this,
      exact this t
    end },
  map := λ t₁ t₂ h,
  { f := λ i, (C.X i).map h,
    comm' := λ i j, nat_trans.naturality _ _ },
  map_id' := λ t, by { ext i, dsimp, rw (C.X i).map_id, },
  map_comp' := λ t₁ t₂ t₃ h₁ h₂, by { ext i, dsimp, rw functor.map_comp, } }

end homological_complex

variable (c)

@[simps]
def functor.map_homological_complex_nat_trans [preadditive V₁] [preadditive V₂]
  (F G : V₁ ⥤ V₂) [F.additive] [G.additive] (α : F ⟶ G) :
  F.map_homological_complex c ⟶
  (G.map_homological_complex c : homological_complex V₁ c ⥤ homological_complex V₂ c) :=
{ app := λ C,
  { f := λ i, α.app _,
    comm' := λ i j, (α.naturality _).symm },
  naturality' := λ C₁ C₂ f, by { ext i, exact α.naturality _ } }
