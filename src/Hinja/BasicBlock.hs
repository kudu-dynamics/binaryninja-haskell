module Hinja.BasicBlock
  ( module Exports
  , BasicBlockFunction
  , getBasicBlocks
  , getBasicBlocksAtAddress
  , getBasicBlockForInstruction
  , getOutgoingEdges
  ) where

import Hinja.Prelude hiding (onException, handle)
import qualified Hinja.C.Main as BN
import Hinja.C.Pointers
import Hinja.Function ( Function
                      , LLILFunction
                      , MLILFunction
                      , MLILSSAFunction
                      , createFunction
                      )
import Hinja.Types.BasicBlock
import Hinja.Types.BasicBlock as Exports
import qualified Hinja.Function as Func
import Hinja.C.Types

class BasicBlockFunction fun where
  convertToBasicBlockFunction :: Function -> IO fun
  getBlockPtrList :: fun -> IO [BNBasicBlock]

instance BasicBlockFunction Function where
  convertToBasicBlockFunction = return
  getBlockPtrList = BN.getFunctionBasicBlockList . view Func.handle

instance BasicBlockFunction LLILFunction where
  convertToBasicBlockFunction = Func.getLLILFunction
  getBlockPtrList = BN.getLowLevelILBasicBlockList . view Func.handle

instance BasicBlockFunction MLILFunction where
  convertToBasicBlockFunction = Func.getMLILFunction
  getBlockPtrList = BN.getMediumLevelILBasicBlockList . view Func.handle

instance BasicBlockFunction MLILSSAFunction where
  convertToBasicBlockFunction = Func.getMLILSSAFunction
  getBlockPtrList = BN.getMediumLevelILBasicBlockList . view Func.handle

class BasicBlockInstructionFunction fun where
  getBasicBlockPtrForInstruction :: fun -> InstructionIndex fun -> IO (Maybe BNBasicBlock)

instance BasicBlockInstructionFunction LLILFunction where
  getBasicBlockPtrForInstruction fn idx =
    BN.getLowLevelILBasicBlockForInstruction (fn ^. Func.handle) idx

instance BasicBlockInstructionFunction MLILFunction where
  getBasicBlockPtrForInstruction fn idx =
    BN.getMediumLevelILBasicBlockForInstruction (fn ^. Func.handle) idx

instance BasicBlockInstructionFunction MLILSSAFunction where
  getBasicBlockPtrForInstruction fn idx =
    BN.getMediumLevelILBasicBlockForInstruction (fn ^. Func.handle) (coerceInstructionIndex idx)


createBasicBlock :: BasicBlockFunction t => BNBasicBlock -> IO (BasicBlock t)
createBasicBlock ptr = BasicBlock ptr
  <$> (BN.getBasicBlockFunction ptr >>= createFunction >>= convertToBasicBlockFunction)
  <*> (coerceInstructionIndex <$> BN.getBasicBlockStart ptr)
  <*> (coerceInstructionIndex <$> BN.getBasicBlockEnd ptr)

getBasicBlocks :: BasicBlockFunction t => t -> IO [BasicBlock t]
getBasicBlocks fn = getBlockPtrList fn >>= traverse createBasicBlock

getBasicBlocksAtAddress :: BNBinaryView -> Address -> IO [BasicBlock Function]
getBasicBlocksAtAddress bv addr = BN.getBasicBlocksForAddress bv addr
                                  >>= traverse createBasicBlock

getBasicBlockForInstruction :: (BasicBlockFunction fun, BasicBlockInstructionFunction fun)
                            => fun -> InstructionIndex fun -> IO (Maybe (BasicBlock fun))
getBasicBlockForInstruction fn idx = getBasicBlockPtrForInstruction fn idx >>=
  maybe (return Nothing) (fmap Just . createBasicBlock)

getOutgoingEdges :: BasicBlockFunction fun => BasicBlock fun -> IO [BlockEdge fun]
getOutgoingEdges bb = do
  BN.getBasicBlockOutgoingEdges (bb ^. handle) >>= traverse toBlockEdge
  where
    toBlockEdge bbe = do
      mTargetBlock <- maybe
                      (return Nothing)
                      (fmap Just . (createBasicBlock <=< BN.newBasicBlockReference))
                      $ bbe ^. target
      return $ BlockEdge
        { _src = bb
        , _target = mTargetBlock
        , _branchType = bbe ^. branchType
        , _isBackEdge = bbe ^. isBackEdge
        , _isFallThrough = bbe ^. isFallThrough
        }
