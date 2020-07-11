module FFIWrapper where

import HTypes (HType(..))
import AST (AST(..), return', map', typeOf, add)
import FFIUtils (toC, fromC, isIO, toFFIType')

wrap :: String -> String -> [HType] -> String
wrap modname funcname functype = funcname ++ (concat $ map show args) ++ " = " ++ show body
    where body = wrapFunc (modname ++ '.':funcname) functype args
          args = zipWith (\c t -> Variable [c] t) ['a'..'z'] $ init functype

wrapFunc :: String -> [HType] -> [AST] -> AST
wrapFunc fn fts args = wrapAST func ft
    where func = wrapArgs fn fts args
          ft   = last fts

wrapAST :: AST -> HType -> AST
wrapAST func ft
    | bothIO    = if ft == (HIO HUnit)
                then func
                else Bind func (Lambda [res] $ convert res)
    | funcIO    = Bind func (Lambda [res] $ return' $ convert res)
    | outpIO    = Bind (return' func) (Lambda [res] $ convert res)
    | otherwise = convert func
    where res = Variable "res" ft
          convert = convertToC ft
          funcIO  = isIO $ typeOf func
          outpIO  = isIO $ toFFIType' ft
          bothIO  = funcIO && outpIO

wrapArgs :: String -> [HType] -> [AST] -> AST
wrapArgs fn ts args = foldr ($) (mkFunc fn ts) convfuncs
    where convfuncs = zipWith convertFromC ts args

mkFunc :: String -> [HType] -> AST
mkFunc fn ts = let
    ioIn  = any isIO $ map toFFIType' $ init ts
    ioOut = isIO $ last ts
    in if ioIn && not ioOut
    then return' norm
    else norm
    where norm = Function fn []  $ last ts

convertFromC :: HType -> AST -> AST -> AST
convertFromC ht arg f = case ht of
    HString -> Bind (fromC ht arg)
                    (Lambda [arg] $ adf arg)
    HList a -> Bind (fromArray a arg)
                    (Lambda [arg] $ adf arg)
    HTuple [a] -> undefined
    HFunc  [a] -> undefined
    _          -> adf $ fromC ht arg
    where adf = add f

convertToC :: HType -> AST -> AST
convertToC ht arg = case ht of
    HList a  -> toArray a arg
    _        -> toC ht arg

fromArray :: HType -> AST -> AST
fromArray ht arg = let
    converter = fromC ht arg
    inner     = case (ht, converter) of
        (HList a, _)        -> Just $ map' (fromArray a arg) arg
        (HString, _)        -> Just $ map' (fromC ht arg) arg
        (_, Function _ _ t) -> Just $ if isIO t
                                    then map' converter arg
                                    else map' (return' converter) arg
        _                   -> Nothing
    in case inner of
        Just inner -> Bind (fromC (HList ht) arg) $ Lambda [arg] inner
        Nothing    -> fromC (HList ht) arg

toArray :: HType -> AST -> AST
toArray ht arg = let
    inner = case (ht, toC ht arg) of
        (HList a, _)        -> Just $ map' (toArray a arg) arg
        (_, Function _ _ _) -> Just $ map' (toC ht arg) arg
        _                   -> Nothing
    in case inner of
        Just inner -> Bind (return' inner) (Lambda [arg] $ toC (HList ht) arg)
        Nothing    -> toC (HList ht) arg

