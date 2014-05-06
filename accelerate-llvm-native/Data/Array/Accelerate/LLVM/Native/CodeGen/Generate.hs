{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE RankNTypes          #-}
{-# LANGUAGE QuasiQuotes         #-}
-- |
-- Module      : Data.Array.Accelerate.LLVM.Native.CodeGen.Generate
-- Copyright   : [2014] Trevor L. McDonell, Sean Lee, Vinod Grover, NVIDIA Corporation
-- License     : BSD3
--
-- Maintainer  : Trevor L. McDonell <tmcdonell@nvidia.com>
-- Stability   : experimental
-- Portability : non-portable (GHC extensions)
--

module Data.Array.Accelerate.LLVM.Native.CodeGen.Generate
  where

-- accelerate
import Data.Array.Accelerate.Array.Sugar                        ( Array, Shape, Elt )

import Data.Array.Accelerate.LLVM.CodeGen.Base
import Data.Array.Accelerate.LLVM.CodeGen.Environment
import Data.Array.Accelerate.LLVM.CodeGen.Exp
import Data.Array.Accelerate.LLVM.CodeGen.Module
import Data.Array.Accelerate.LLVM.CodeGen.Monad
import Data.Array.Accelerate.LLVM.CodeGen.Type

import Data.Array.Accelerate.LLVM.Native.CodeGen.Base
import Data.Array.Accelerate.LLVM.Native.CodeGen.Loop

import LLVM.General.AST

import LLVM.General.Quote.LLVM
import Data.Array.Accelerate.Type


-- Construct a new array by applying a function to each index. Each thread
-- processes multiple adjacent elements.
--
mkGenerate
    :: forall arch aenv sh e. (Shape sh, Elt e)
    => Gamma aenv
    -> IRFun1 aenv (sh -> e)
    -> CodeGen [Kernel arch aenv (Array sh e)]
mkGenerate aenv apply = do
  let
      arrOut                      = arrayData  (undefined::Array sh e) "out"
      shOut                       = arrayShape (undefined::Array sh e) "out"
      paramOut                    = arrayParam (undefined::Array sh e) "out"
      paramEnv                    = envParam aenv
      (start, end, paramGang)     = gangParam
      intType                     = (typeOf (integralType :: IntegralType Int))
  k <- [llgM|
  define void @generate (
    $params:(paramGang) ,
    $params:(paramOut) ,
    $params:(paramEnv)
    ) {
      for $type:(intType) %i in $opr:(start) to $opr:(end) {
        $bbsM:("ix" .=. indexOfInt (map local shOut) ("i" :: Operand))
        $bbsM:("r" .=. apply ("ix" :: Name))
        $bbsM:(exec (writeArray arrOut "i" ("r" :: Name)))
      }
      ret void
  }
  |]
  return $ [Kernel k]
