----------------------------------------------------------------------
-- Copyright: 2013, Jan Stolarek, Lodz University of Technology     --
--                                                                  --
-- License: See LICENSE file in root of the repo                    --
-- Repo address: https://github.com/jstolarek/dep-typed-wbl-heaps   --
--                                                                  --
-- Weight biased leftist heap that proves rank invariant: size of   --
-- left subtree of a node is not smaller than size of right         --
-- subtree.                                                         --
----------------------------------------------------------------------

{-# OPTIONS --sized-types #-}
module MakeT.RankProof where

open import Basics
open import Sized

-- We prove the rank invariant we will index each Heap by its size, (remember
-- that size of a heap is its rank). Therefore index of value n says that a
-- Heap stores n elements.
--
-- Again, Heap has two constructor:
--
--  1) empty constructs a heap containing no elements. Therefore the index is 0.
--
--  2) node takes two subtrees: one containing l elements, the other containing
--     r elements. The size of resulting heap is the sum of l and r plus one for
--     the element stored by the node itself. To enforce the rank invariant node
--     constructor expects a proof that invariant holds: a value of type l ≥ r.
--     If we can construct value of this type then it proves the invariant.
--
-- We also use sized types in this case, to aid the termination checker in the
-- merge function.
data Heap : {i : Size} → Rank → Set where
  empty : {i : Size} → Heap {↑ i} zero
  node  : {i : Size} {l r : Rank} → Priority → l ≥ r →
          Heap {i} l → Heap {i} r → Heap {↑ i} (suc (l + r))

-- Singleton heap stores only one element. Therefore it has size of one. To
-- prove the rank invariant we must show that 0 ≥ 0. We can proove this with ge0
-- constructor.
singleton : Priority → Heap one
singleton p = node p ge0 empty empty

-- Note [Proving rank invariant (merge using makeT)]
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- We need to prove that the size of merged heap is equal to the sum of sizes of
-- heaps being merged. Recall that our merging algorithm is two pass: we use
-- merge to actually do the merging and makeT to restore the rank invariant if
-- necessary (see [Merging algorithm]). This means our proof will be
-- two-stage. We need to prove that:
--
--  1) makeT creates a node of required size, even if it swaps left
--     and right children.
--
--  2) recursive calls to merge produce heaps of required size.

-- Note [Proving makeT]
-- ~~~~~~~~~~~~~~~~~~~~
--
-- makeT has two cases:
--
--  1) size of l is ≥ than size of r in which case no extra
--     proof is necessary.
--
--  2) size of r is ≥ than size of l in which case we swap left and
--     right subtrees. This requires us to prove that:
--
--       suc (r + l) ≡ suc (l + r)
--
--     That proof is done using congruence on suc function and
--     commutativity of addition.

makeT : {l r : Rank} → Priority → Heap l → Heap r → Heap (suc (l + r))
makeT {l-rank} {r-rank} p l r with order l-rank r-rank
makeT {l-rank} {r-rank} p l r | ge l≥r
  = node p l≥r l r
makeT {l-rank} {r-rank} p l r | le r≥l
  = subst Heap (cong suc (+comm r-rank l-rank)) (node p r≥l r l)

-- Note [Notation for proving heap merge]
-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- In the proofs of heap merge we will use following notation:
--
--  h1, h2 - rank of heaps being merged
--  p1, p2 - priority of root element
--  l1     - rank of left  subtree in the first  heap
--  r1     - rank of right subtree in the first  heap
--  l2     - rank of left  subtree in the second heap
--  r2     - rank of right subtree in the second heap
--
-- Note that:
--
--    h1 = suc (l1 + r1)
--    h2 = suc (l2 + r2)
--
--     h1         h2
--
--     p1         p2
--    /  \       /  \
--   /    \     /    \
--  l1    r1   l2    r2


-- Note [Proving merge]
-- ~~~~~~~~~~~~~~~~~~~~
--
-- We need to prove that all four cases of merge (see [Merging
-- algorithm]) produce heap of required size, which is h1 + h2. Since in
-- the proofs we will always operate on l1, r1, l2 and r2 we have:
--
--   h1 + h2 ̄≡ suc (l1 + r1) + suc (l2 + r2)
--           ≡ suc ((l1 + r1) + suc (l2 + r2))
--
-- (Second transformation comes from definition of _+_). This is the expected
-- size and therefore the final result we must prove in every case that we
-- analyze.

-- It is best to study the implementation of merge now and then read the
-- explanation of proofs.

-- Note [merge, proof 0a]
-- ~~~~~~~~~~~~~~~~~~~~~~
--
-- h1 ≡ 0, therefore: h1 + h2 ≡ 0 + h2 ≡ h2 ∎
--
-- This is definitional equality based on _+_
--
-- ∎

-- Note [merge, proof 0b]
-- ~~~~~~~~~~~~~~~~~~~~~~
--
-- h2 ≡ 0, therefore expected size is h1 + h2 ≡ h1 + 0. We need to
-- show that:
--
--    h1 ≡ h1 + 0
--
-- This is a simple statement that 0 is right identity of addition. We proved
-- that as one of basic properties of addition in Basics.Reasoning module,
-- except our proof had the sides of equality reversed, ie. we proved a + 0 ≡ a,
-- not a ≡ a + 0). We use symmetry to construct a proof of latter from the
-- former.
--
-- ∎

-- Note [merge, proof 1]
-- ~~~~~~~~~~~~~~~~~~~~~
--
-- We have p1 < p2. We keep p1 as the root and need to prove that merging r1
-- with h2 gives correct size.  Here's how the term that performs the merge
-- corresponds to its type (for the sake of readability I elided implict
-- parameters):
--
--   makeT p1 x1 l1 (merge r1 (node p2 l2≥r2 l2 r2))
--    |          |         |   \__________________/
--    |   +------+         |            |
--    |   |     +----------+            |
--    |   |     |             +---------+
--    |   |     |     ________|__
--    |   |     |    /           \
--   suc (l1 + (r1 + suc (l2 + r2)))
--
-- Formally:
--
--   suc (l1 + (r1 + suc (l2 + r2))) ≡ suc ((l1 + r1) + suc (l2 + r2))
--
-- Recall that RHS of this equality comes from [Proving merge]. We begin proof
-- with congruence on suc:
--
--   cong suc X
--
-- where X proves
--
--   l1 + (r1 + suc (l2 + r2)) ≡ (l1 + r1) + suc (l2 + r2)
--
-- Substituting a = l1, b = r1 and c = suc (l2 + r2) we have
--
--   a + (b + c) ≡ (a + b) + c
--
-- Which is associativity of addition that we have already proved in
-- Basics.Reasoning.
--
-- ∎

proof-1 : (l1 r1 l2 r2 : Nat) → suc ( l1 + (r1 + suc (l2 + r2)))
                              ≡ suc ((l1 + r1) + suc (l2 + r2))
proof-1 l1 r1 l2 r2 = cong suc (+assoc l1 r1 (suc (l2 + r2)))

-- Note [merge, proof 2]
-- ~~~~~~~~~~~~~~~~~~~~~
--
-- We have p2 < p1. We keep p2 as the root and need to prove that merging r2
-- with h1 gives correct size. Again, here's the corespondence between the term
-- and its type:
--
--   makeT p2 x2 l2 (merge r2 (node p1 l1≥r1 l1 r1))
--    |          |         |   \_________________/
--    |   +------+         |            |
--    |   |     +----------+  +---------+
--    |   |     |     ________|__
--    |   |     |    /           \
--   suc (l2 + (r2 + suc (l1 + r1)))
--
-- Formally:
--
--   suc (l2 + (r2 + suc (l1 + r1))) ≡ suc ((l1 + r1) + suc (l2 + r2))
--
-- Again we use cong to deal with the outer calls to suc and substitute
-- a = l2, b = r2 and c = l1 + r1). This leaves us with a proof
-- of lemma A:
--
--   a + (b + suc c) ≡ c + suc (a + b)
--
-- From associativity we know that:
--
--   a + (b + suc c) ≡ (a + b) + suc c
--
-- If we prove lemma B:
--
--  (a + b) + suc c = c + suc (a + b)
--
-- we can combine it using transitivity to get the final proof. We can
-- rewrite lemma B as:
--
--    n + suc m ≡ m + suc n
--
-- where n = a + b and m = c. From symmetry of +suc we have:
---
--   n + (suc m) ≡ suc (n + m)
--
-- Using transitivity we combine it with congruence on commutativity
-- of addition to prove:
--
--   suc (n + m) ≡ suc (m + n)
--
-- Again, using transitivity we combine it with +suc:
--
--   suc (m + n) ≡ m + suc n
--
-- Which proves lemma B and therefore the whole proof is complete.
--
-- ∎

lemma-B : (n m : Nat) → n + suc m ≡ m + suc n
lemma-B n m = trans (sym (+suc n m)) (trans (cong suc (+comm n m)) (+suc m n))

lemma-A : (a b c : Nat) → a + (b + suc c) ≡ c + suc (a + b)
lemma-A a b c = trans (+assoc a b (suc c)) (lemma-B (a + b) c)

proof-2 : (l1 r1 l2 r2 : Nat) → suc (l2 + (r2  + suc (l1 + r1)))
                              ≡ suc ((l1 + r1) + suc (l2 + r2))
proof-2 l1 r1 l2 r2 = cong suc (lemma-A l2 r2 (l1 + r1))

-- Let's rewrite that proof in a different fassion to see closely what is
-- happening at each step. Inlining lemmas A and B into proof-2 gives:
--
--   proof-2a : (l1 r1 l2 r2 : Nat) → suc (l2 + (r2  + suc (l1 + r1)))
--                                  ≡ suc ((l1 + r1) + suc (l2 + r2))
--   proof-2a l1 r1 l2 r2 =
--     cong suc (trans (+assoc l2 r2 (suc (l1 + r1)))
--              (trans (sym (+suc (l2 + r2) (l1 + r1)))
--              (trans (cong suc (+comm (l2 + r2) (l1 + r1)))
--                     (+suc (l1 + r1) (l2 + r2))))
--
-- We have a lot of properties combined using transitivity. In general, if we
-- have to prove:
--
--   a ≡ e
--
-- and we can prove:
--
--   a ≡ b, b ≡ c, c ≡ d, d ≡ e
--
-- then we can combine these proofs using transitivity:
--
--   trans (a ≡ b) (trans (b ≡ c) (trans (c ≡ d) (d ≡ e)))
--
-- We used this pattern here and we will be using it in the proofs to
-- come. While simple to use, combining proofs with transitivity can be not so
-- obvious at first. Let's rewrite the proof we have conducted using this
-- notation:
--
--  a ≡[ proof 1 ]
--  b ≡[ proof 2 ]
--  c ≡[ proof 3 ]
--  d ≡[ proof 4 ]
--  e ∎
--
-- Where proof 1 proves a ≡ b, proof 2 proves b ≡ c and so on. In our particular
-- case this will be:
--
--  suc  (l2 + (r2 + suc (l1 + r1))) ≡[ cong suc ]
-- [suc]  l2 + (r2 + suc (l1 + r1))  ≡[+assoc l2 r2 (suc (l1 + r1))]
-- [suc] (l2 + r2) + suc (l1 + r1)   ≡[ sym (+suc (l2 + r2) (l1 + r1))]
-- [suc] suc ((l2 + r2) + (l1 + r1)) ≡[ cong suc (+comm (l2 + r2) (l1 + r1)) ]
-- [suc] suc ((l1 + r1) + (l2 + r2)) ≡[+suc (l1 + r1) (l2 + r2) ]
-- [suc] (l1 + r1) + suc (l2 + r2) ∎
--
-- We use [suc] to denote that everything happens under a call to suc (thanks to
-- using congruence). Compare this notation with code of proof-2a.


-- Note [Notation in merge]
-- ~~~~~~~~~~~~~~~~~~~~~~~~
--
-- merge uses different notation than the proofs. We use l1, r1, l2
-- and r2 to denote the respective subtrees and l1-rank, r1-rank,
-- l2-rank and r2-rank to denote their ranks. We use h1 and h2 to
-- denote heaps.
merge : {i j : Size} {l r : Rank} → Heap {i} l → Heap {j} r → Heap (l + r)
merge empty h2 = h2 -- See [merge, proof 0a]
merge {_} .{_} {suc l} {zero} h1 empty
      = subst Heap (sym (+0 (suc l))) h1 -- See [merge, proof 0b]
merge .{↑ i} .{↑ j} {suc .(l1-rank + r1-rank)} {suc .(l2-rank + r2-rank)}
      (node {i} {l1-rank} {r1-rank} p1 l1≥r1 l1 r1)
      (node {j} {l2-rank} {r2-rank} p2 l2≥r2 l2 r2)
      with p1 < p2
merge .{↑ i} .{↑ j} {suc .(l1-rank + r1-rank)} {suc .(l2-rank + r2-rank)}
      (node {i} {l1-rank} {r1-rank} p1 l1≥r1 l1 r1)
      (node {j} {l2-rank} {r2-rank} p2 l2≥r2 l2 r2)
      | true
      = subst Heap
              (proof-1 l1-rank r1-rank l2-rank r2-rank) -- See [merge, proof 1]
              (makeT p1 l1 (merge {i} {↑ j} r1
                            (node {j} {l2-rank} {r2-rank} p2 l2≥r2 l2 r2)))
merge .{↑ i} .{↑ j} {suc .(l1-rank + r1-rank)} {suc .(l2-rank + r2-rank)}
      (node {i} {l1-rank} {r1-rank} p1 l1≥r1 l1 r1)
      (node {j} {l2-rank} {r2-rank} p2 l2≥r2 l2 r2)
      | false
      = subst Heap
              (proof-2 l1-rank r1-rank l2-rank r2-rank) -- See [merge, proof 2]
              (makeT p2 l2 (merge {j} {↑ i} r2
                            (node {i} {l1-rank} {r1-rank} p1 l1≥r1 l1 r1)))

-- We require that inserting an element into the heap increases its size by
-- one. As previously we define insert as merge and a singleton heap. Size of
-- singleton heap is (suc zero), while already existing heap has size
-- n. According to definition of merge the resulting heap will therefore have
-- size:
--
--   (suc zero) + n
--
-- by definition of +this can be normalized to:
--
--  suc (zero + n)
--
-- and finally to
--
--  suc n
--
-- Which is size we require in the type signature. This means we don't need any
-- additional proof because expected result follows from definitions.
insert : {n : Rank} → Priority → Heap n → Heap (suc n)
insert p h = merge (singleton p) h

-- By indexing heap with its size we can finally have means to ensure that heap
-- passed to findMin or deleteMin is not empty.
findMin : {n : Rank} → Heap (suc n) → Priority
findMin (node p _ _ _) = p

deleteMin : {n : Rank} → Heap (suc n) → Heap n
deleteMin (node _ _ l r) = merge l r
