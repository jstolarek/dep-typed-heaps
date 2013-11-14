----------------------------------------------------------------------
-- Copyright: 2013, Jan Stolarek, Lodz University of Technology     --
--                                                                  --
-- License: See LICENSE file in root of the repo                    --
-- Repo address: https://github.com/jstolarek/dep-typed-heaps       --
--                                                                  --
-- This module reinvents the dependently typed wheel.  We need that --
-- wheel to get rollin.                                             --
----------------------------------------------------------------------

module DepTypedBasics where

open import Basics public hiding (_≥_ ; min)

data _≥_ : Nat → Nat → Set where
  ge0 : {y : Nat} → y ≥ zero
  geS : {x : Nat} {y : Nat} → x ≥ y → suc x ≥ suc y

data Order : Nat → Nat → Set where
  ge : {x : Nat} {y : Nat} → x ≥ y → Order x y
  le : {x : Nat} {y : Nat} → y ≥ x → Order x y

order : (x : Nat) → (y : Nat) → Order x y
order x       zero    = ge ge0
order zero    (suc y) = le ge0
order (suc x) (suc y) with order x y
order (suc x) (suc y) | ge xgey = ge (geS xgey)
order (suc x) (suc y) | le ygex = le (geS ygex)

min : {m n : Nat} → Order m n → Nat
min {m} {n} (ge _) = n
min {m} {n} (le _) = m

infixl 4 _≥_


data _≡_ {S : Set} (s : S) : S → Set where
  refl : s ≡ s

infixl 1 _≡_


sym : {A : Set} → {a b : A} → a ≡ b → b ≡ a
sym refl = refl

trans : {A : Set}{a b c : A} → a ≡ b → b ≡ c → a ≡ c
trans refl refl = refl

cong : {A B : Set} (f : A → B) → ∀ {x y} → x ≡ y → f x ≡ f y
cong f refl = refl

subst : {A : Set}(P : A → Set) → {a b : A} → a ≡ b → P a → P b
subst prp refl p = p

subst2 : {A : Set}{P : A → Set} → {a b : A} → a ≡ b → P a → P b
subst2 refl p = p

+0 : (n : Nat) → n + zero ≡ n
+0 zero    = refl
+0 (suc n) = cong suc (+0 n)

+suc : (m n : Nat) → suc (m + n) ≡ m + (suc n)
+suc zero n = refl
+suc (suc m) n = cong suc (+suc m n)

≥suc : {m n : Nat} → m ≡ n → m ≥ n
≥suc {zero} {zero} refl        = ge0
≥suc {.(suc n)} {(suc n)} refl = geS (≥suc {n} {n} refl)

+comm : (m n : Nat) → m + n ≡ n + m
+comm m zero    = +0 m
+comm m (suc n) = trans (sym (+suc m n)) (cong suc (+comm m n))

+assoc : (m n l : Nat) → (m + n) + l ≡ m + (n + l)
+assoc zero n l    = refl
+assoc (suc m) n l = cong suc (+assoc m n l)

-- In the second case of +assoc I have to prove:
--
--   (suc m + n) + l ≡ suc m + (n + l)
--
-- Agda normalizes each side using definition of + :
--
--   (suc m + n) + l ≡ suc (m + n) + l ≡ suc ((m + n) + l)
--   suc m + (n + l) ≡ suc (m + (n + l))
--
-- This means I have to prove:
--
--   suc ((m + n) + l) ≡ suc (m + (n + l))
--
-- Parameters to suc are the inductive hypothesis, that's why I use cong

+ac : (m n l : Nat) → (n + l) + m ≡ (m + n) + l
+ac m n l = trans (+comm (n + l) m) (sym (+assoc m n l))

+x : (a b : Nat) → a + suc b ≡ b + suc a
+x a b = trans (sym (+suc a b)) (trans (cong suc (+comm a b)) (+suc b a))

+case3 : (m n l : Nat) → m + (n + suc l) ≡ l + suc (m + n)
+case3 m n l = trans (sym (+assoc m n (suc l))) (+x (m + n) l)

+n : {a b c : Nat} → a ≡ b → a + c ≡ b + c
+n refl = refl

+case4 : (a b c : Nat) → (a + suc b) + c ≡ b + suc (c + a)
+case4 a b c = trans (sym ((cong (λ n → n + c) (+suc a b))))
              (trans (cong suc
              (trans (cong (λ n → n + c) (+comm a b))
              (trans (+assoc b a c) (cong (λ n → b + n) (+comm a c))))) (+suc b (c + a)))

-- This:   sym ((cong (λ n → n + c) (+suc a b)))
-- proves: (a + suc b) + c ≡ suc ((a + b) + c)

-- This:   (three trans)
-- proves: suc (a + b) + c ≡ suc (b + (c + a))
-- where
--    this:   cong (λ n → n + c) (+comm a b)
--    proves: (a + b) + c ≡ (b + a) + c
--
--    this:   +assoc b a c
--    proves: (b + c) + a ≡ b + (c + a)
--
--    this:   cong (λ n → b + n) (+comm a c)
--    proves: b + (a + c) ≡ b + (c + a)

-- This:   +suc b (c + a)
-- proves: suc (b + (c + a)) ≡ b + suc (c + a)
