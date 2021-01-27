module Binja.Types.MLIL.Op.CallParamSSAOp where

import Binja.Prelude

import Binja.Types.MLIL.Common (SSAVariable)

data CallParamSSAOp expr = CallParamSSAOp
    { _callParamSSAOpSrc_memory :: Int64
    , _callParamSSAOpSrc :: [SSAVariable]
    } deriving (Eq, Ord, Show, Functor, Foldable, Traversable, Generic)

instance Hashable a => Hashable (CallParamSSAOp a)
