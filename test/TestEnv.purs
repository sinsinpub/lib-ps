module TestEnv
  ( module Prelude
  , module Data.Foreign
  , module Data.Maybe
  , module KanColle.KCAPI.Battle
  , module KanColle.DamageAnalysis
  , module KanColle.DamageAnalysis.DamageVector
  , module KanColle.Util
  , module BattleData
  , module KanColle.Expedition.Plan
  , module KanColle.Expedition.Minimal
  , module KanColle.SType
  , module KanColle.Generated.SType
  , module KanColle.RepairTime
  , module Control.Monad.Eff.Console
  , module TestEnv
  )
where

-- this module is just for the purpose of
-- manually testing in psci
-- which exports as many modules as possible.

import Prelude

import Data.Foreign
import Data.Maybe
import Data.Monoid
import Data.Array.ST
import Control.Monad.Eff.Console

import KanColle.KCAPI.Battle
import KanColle.DamageAnalysis
import KanColle.DamageAnalysis.DamageVector
import KanColle.DamageAnalysis.Stages
import KanColle.Expedition.Plan
import KanColle.Expedition.Minimal
import KanColle.SType
import KanColle.RepairTime

import BattleData
import DamageVectorTests


import Control.Monad.Eff
import KanColle.Util

testArr :: Array Int
testArr = heapSort compare [1,9,2,8,3,7,4,6,5]
