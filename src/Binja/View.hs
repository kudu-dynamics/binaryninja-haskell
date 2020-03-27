module Binja.View where

import Binja.C.Main
  ( BNBinaryReader,
    BNBinaryView
  )
import qualified Binja.C.Main as BN
import Binja.Types.StringReference (BNStringReference)
import qualified Binja.Types.StringReference as StrRef
import Binja.Prelude hiding (reader)
import Binja.C.Enums as BNEnums

import Data.Text.Encoding as TE
import Data.ByteString as BS

getDefaultReader :: BNBinaryView -> IO BNBinaryReader
getDefaultReader bv = do
  (Just reader) <- BN.createBinaryReader bv
  defaultEndianness <- BN.getDefaultEndianness bv
  BN.setBinaryReaderEndianness reader defaultEndianness
  return reader

readByte :: BNBinaryView -> Word64 -> IO Word8
readByte bv offset = do
  reader <- getDefaultReader bv
  BN.seekBinaryReader reader offset
  (Just val) <- BN.read8 reader
  return val

readBytes :: BNBinaryView -> Word64 -> Word64 -> IO [Word8]
readBytes bv offset numBytes = do
  reader <- getDefaultReader bv
  BN.seekBinaryReader reader offset
  (Just vals) <- BN.readData reader numBytes
  return vals

convertStringRef :: BNBinaryView -> BNStringReference -> IO Text
convertStringRef bv x =
  decode <$> bytes
  where
    decode :: ByteString -> Text
    decode bs =
      case x ^. StrRef.stringType of
        BNEnums.AsciiString -> TE.decodeUtf8 bs
        BNEnums.Utf8String -> TE.decodeUtf8 bs
        BNEnums.Utf16String -> TE.decodeUtf16LE bs
        BNEnums.Utf32String -> TE.decodeUtf32LE bs
    bytes :: IO ByteString
    bytes = BS.pack <$> readBytes bv (x ^. StrRef.start) (x ^. StrRef.length)

getStrings :: BNBinaryView -> IO [Text]
getStrings bv = do
  refs <- BN.getStringRefs bv
  traverse (convertStringRef bv) refs

-- TODO: Word64 should be Address, but don't want to leak that type from a Binja.C.* module
getStringAtAddress :: BNBinaryView -> Word64 -> IO (Maybe Text)
getStringAtAddress bv addr = do
  maybeRef <- BN.getStringRefAtAddress bv (fromIntegral addr)
  case maybeRef of
    (Just ref) -> Just <$> convertStringRef bv ref
    Nothing -> return Nothing