module HTypes (HType(..), htype, ffiType) where

import Text.Parsec ((<|>), unexpected, try, skipMany)
import qualified Text.Parsec.Char as PC (string)
import Text.Parsec.String (Parser)

data HType
   = HUnit
   | HBool
   | HCBool
   | HChar
   | HSChar
   | HUChar
   | HShort
   | HUShort
   | HCInt
   | HCUInt
   | HLong
   | HULong
   | HLLong
   | HULLong
   | HFloat
   | HDouble
   | HInt
   | HInteger
   | HString
   | HCString
   | HIO HType
   | HList HType
   | HTuple [HType]
   | HFunc [HType]
   | HCTuple [HType]
   | HCFunc [HType]
   | HCArray HType
   | HCList HType
   | HCPtr HType -- TODO constrain HTypes available (only Storable ones)
   deriving (Show, Eq)

ffiType :: HType -> String
ffiType ht = case ht of
    HUnit   -> "()"
    HCBool  -> "CBool"
    HChar   -> "CChar"
    HSChar  -> "CSChar"
    HUChar  -> "CUChar"
    HShort  -> "CShort"
    HUShort -> "CUShort"
    HCInt   -> "CInt"
    HCUInt  -> "CUInt"
    HLong   -> "CLong"
    HULong  -> "CULong"
    HLLong  -> "CLLong"
    HULLong -> "CULLong"
    HFloat  -> "CFloat"
    HDouble -> "CDouble"
    HInt    -> "CInt"
    HInteger -> "CLLong"
    HCString -> "CWString"
    HIO ht'  -> "IO " ++ further ht'
    HCArray ht' -> "CArray " ++ further ht'
    HCList ht'  -> "CList " ++ further ht'
    where further = (\s -> "( " ++ s ++ " )") . ffiType

htype = foldr (<|>) (unexpected "invalid type") types
 where types = [char, schar, uchar, short, ushort, 
                int32, uint32, long, ulong, float, 
                double, bool
                ]

makeParser :: HType -> [String] -> Parser HType
makeParser t ss = foldr (<|>) (unexpected "invalid type") (map (try . PC.string) ss) 
               >> return t

mp = makeParser
bool = mp HBool ["Bool"]
char = mp HChar ["CChar","Int8"]
schar = mp HSChar ["CSChar","Int8"]
uchar = mp HUChar ["CUChar", "Word8"]
short = mp HShort ["CShort", "Int16"]
ushort = mp HUShort ["CUShort", "Word16"]
int32 = mp HCInt ["CInt","Int32"]
uint32 = mp HCUInt ["CUInt", "Word32"]
long = mp HLong ["CLong", "Int64"]
ulong = mp HULong ["CULong", "Word64"]
float = mp HFloat ["CFloat", "Float"]
double = mp HDouble ["CDouble","Double"]
string = mp HString ["[Char]","String"]
int = mp HInt ["Int"]
integer = mp HInteger ["Integer"]
cstring = mp HCString ["CString", "Ptr CChar"]

