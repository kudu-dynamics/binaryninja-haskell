module Hinja.Types.MLIL.Op.TailcallUntypedSSAOp where

import Hinja.Prelude


data TailcallUntypedSSAOp expr = TailcallUntypedSSAOp
    { _tailcallUntypedSSAOpOutput :: expr
    , _tailcallUntypedSSAOpDest :: expr
    , _tailcallUntypedSSAOpParams :: expr
    , _tailcallUntypedSSAOpStack :: expr
    } deriving (Eq, Ord, Show, Functor, Foldable, Traversable, Generic)