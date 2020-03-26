{-# LANGUAGE TemplateHaskell #-}

module Binja.Types.StringReference where

import Binja.Prelude

import Binja.C.Enums (BNStringType)

data BNStringReference
  = BNStringReference
      { _stringType :: BNStringType,
        _start :: Word64,
        _length :: Word64
      }
  deriving (Eq, Ord, Show)

$(makeFieldsNoPrefix ''BNStringReference)