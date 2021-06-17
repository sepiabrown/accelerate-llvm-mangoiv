{-# LANGUAGE BangPatterns      #-}
{-# LANGUAGE OverloadedStrings #-}
-- |
-- Module      : Data.Array.Accelerate.LLVM.PTX.Array.Table
-- Copyright   : [2014..2020] The Accelerate Team
-- License     : BSD3
--
-- Maintainer  : Trevor L. McDonell <trevor.mcdonell@gmail.com>
-- Stability   : experimental
-- Portability : non-portable (GHC extensions)
--

module Data.Array.Accelerate.LLVM.PTX.Array.Table (

  MemoryTable,
  new,

) where

import Data.Array.Accelerate.LLVM.PTX.Context                       ( Context, withContext )
import qualified Data.Array.Accelerate.Array.Remote                 as Remote
import qualified Data.Array.Accelerate.LLVM.PTX.Debug               as Debug
import {-# SOURCE #-} Data.Array.Accelerate.LLVM.PTX.Execute.Event

import qualified Foreign.CUDA.Ptr                                   as CUDA
import qualified Foreign.CUDA.Driver                                as CUDA

import Data.Text.Lazy.Builder


-- Remote memory tables. This builds upon the LRU-cached memory tables provided
-- by the base Accelerate package.
--
type MemoryTable = Remote.MemoryTable CUDA.DevicePtr (Maybe Event)


-- | Create a new PTX memory table. This is specific to a given PTX target, as
-- devices arrays are unique to a CUDA context.
--
{-# INLINEABLE new #-}
new :: Context -> IO MemoryTable
new !ctx = Remote.new freeRemote
  where
    freeRemote :: CUDA.DevicePtr a -> IO ()
    freeRemote !ptr = do
      message ("freeRemote " <> fromString (show ptr))
      withContext ctx (CUDA.free ptr)


-- Debugging
-- ---------

{-# INLINE trace #-}
trace :: Builder -> IO a -> IO a
trace msg next = Debug.traceIO Debug.dump_gc ("gc: " <> msg) >> next

{-# INLINE message #-}
message :: Builder -> IO ()
message s = s `trace` return ()

