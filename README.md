# Liquid Tensor Experiment

![](https://github.com/leanprover-community/lean-liquid/workflows/continuous%20integration/badge.svg?branch=master)

For the eponymous blogpost by Peter Scholze: see https://xenaproject.wordpress.com/2020/12/05/liquid-tensor-experiment/.
The aim of this project is to formalize Theorem 9.4 of Scholze--Clausen, [Analytic].

## The statement

The statement can be found in [`src/liquid.lean`](https://github.com/leanprover-community/lean-liquid/blob/master/src/liquid.lean#L29)

```lean
theorem first_target [BD.suitable c']
  (r r' : ℝ≥0) [fact (0 < r)] [fact (0 < r')] [fact (r < r')] [fact (r' ≤ 1)] :
  ∀ m : ℕ,
  ∃ (k : ℝ≥0) [fact (1 ≤ k)],
  ∃ c₀ : ℝ≥0,
  ∀ (S : Type) [fintype S],
  ∀ (V : NormedGroup) [normed_with_aut r V],​
    (Mbar_system V S r r' BD c').is_bdd_exact_for_bdd_degree_above_idx k m c₀ :=
sorry
```

See [`src/liquid.lean`](https://github.com/leanprover-community/lean-liquid/blob/master/src/liquid.lean#40)
for details on how to read this statement.

## How to browse this repository

### Blueprint

Below we explain how to engage with the Lean code directly.
We also provide a [blueprint](https://leanprover-community.github.io/liquid/)
including a [dependency graph](https://leanprover-community.github.io/liquid/dep_graph.html)
of the main ingredients in the repository.
This blueprint is developed in sync with the Lean formalization,
and will hence see frequent updates during the length of the project.

### Getting the project

At the moment, the recommended way of browsing this repository,
is by using a Lean development environment.
Crucially, this will allow you to introspect Lean's "Goal state" during proofs,
and easily jump to definitions or otherwise follow paths through the code.

We are looking into ways to setup an online interactive website
that will provide the same experience without the hassle of installing a complete
Lean development environment.

For the time being: please use the
[installation instructions](https://leanprover-community.github.io/get_started.html#regular-install)
to install Lean and a supporting toolchain.
After that, download and open a copy of the repository
by executing the following command in a terminal:
```
leanproject get lean-liquid
code lean-liquid
```
For detailed instructions on how to work with Lean projects,
see [this](https://leanprover-community.github.io/install/project.html).

### Reading the project

With the project opened in VScode,
you are all set to start exploring the code.
There are two pieces of functionality that help a lot when browsing through Lean code:

* "Go to definition": If you right-click on a name of a definition or lemma
  (such as `Mbar`, or `Tinv_continuous`), then you can choose "Go to definition" from the menu,
  and you will be taken to the relevant location in the source files.
  This also works by `Ctrl`-clicking on the name.
* "Goal view": in the event that you would like to read a *proof*,
  you can step through the proof line-by-line,
  and see the internals of Lean's "brain" in the Goal window.
  If the Goal window is not open,
  you can open it by clicking on one of the icons in the top right hand corner.

### Organization of the project

* All the Lean code (the juicy stuff) is contained in the directory `src/`.
* The file `liquid.lean` contains the statement of the theorem that we want to check.
* The ingredients that go into the theorem statement are defined in several other files.
  The most important pieces are:
  - `breen_deligne/basic.lean` contains an axiomatic definition
    of the data describing a Breen--Deligne resolution.
    It does *not* contain a formal proof of the Breen--Deligne resolution.
    At some point we may formalize Breen--Deligne resolutions,
    but this is not part of our first target.
  - `system_of_complexes/` contains the definition of a system of complexes
    of normed abelian groups indexed by nonnegative real numbers.
    It also contains the definition of `is_bdd_exact_for_bdd_degree_above_idx`,
    which is the exactness condition claimed in the main theorem.
  - `Mbar/*.lean` contains a definition of the spaces ![](svg/VhatMbar.svg)
    and how they fit together in the system of complexes
    that occurs in the statement of the theorem.

## Brief note on type theory

Lean is based on type theory,
which means that some things work slightly differently from set theory.
We highlight two syntactical differences.

* Firstly, the element-of relation (`∈`) plays no fundamental role.
  Instead, there is a typing judgment (`:`).

  This means that we write `x : X` to say that "`x` is a term of type `X`"
  instead of "`x` is an element of the set `X`".
  Conveniently, we can write `f : X → Y` to mean "`f` has type `X → Y`",
  in other words "`f` is a function from `X` to `Y`".

* Secondly, type theorists do not use the mapsto symbol (`↦`),
  but instead use lambda-notation.
  This means that we can define the square function on the integers via
  `λ x, x^2`, which translates to `x ↦ x^2` in set-theoretic notation.
  For more information about `λ`, see the Wikipedia page on
  [lambda calculus](https://en.wikipedia.org/wiki/Lambda_calculus).

For a more extensive discussion of type theory,
see the dedicated
[page](https://leanprover-community.github.io/lean-perfectoid-spaces/type_theory.html)
on the perfectoid project website.

## Source reference

`[Analytic]` : http://www.math.uni-bonn.de/people/scholze/Analytic.pdf

[Analytic]: http://www.math.uni-bonn.de/people/scholze/Analytic.pdf
