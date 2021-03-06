{-# LANGUAGE OverloadedStrings, FlexibleContexts #-}
module MkRelease where

import Prelude hiding (FilePath)
import Control.Arrow
import Data.Maybe
import Turtle
import Filesystem.Path.CurrentOS hiding (empty)
import qualified Data.Text as T
import qualified Data.Text.IO as T
import qualified Control.Foldl as Fold
import qualified Data.List as L
import Text.Printf
import Data.List hiding (find, stripPrefix)
import Data.Function

-- | guess project home directory
--   make sure to run this somewhere under the project home
guessProjectHome :: FilePath -> IO FilePath
guessProjectHome fPath = do
    guard $ fPath /= root fPath
    b <- testfile (fPath </> "bower.json")
    if b
      then return fPath
      else guessProjectHome (parent fPath)

toText' :: FilePath -> T.Text
toText' = either id id . toText

showEnv :: IO ()
showEnv = do
    xs <- env
    let ys = sortBy (compare `on` fst) xs
    mapM_ (\(k,v) -> Text.Printf.printf "%s=%s\n" (T.unpack k) (T.unpack v)) ys

main :: IO ()
main = do
    cwd <- pwd
    prjHome <- guessProjectHome cwd
    putStrLn $ "Project home in: " <> encodeString prjHome
    (ExitSuccess, npmBin) <- second T.strip <$> shellStrict "npm bin" empty
    let uglifyJsBin = fromText npmBin </> "uglifyjs"
--    True <- testfile uglifyJsBin
    putStrLn $ "Found uglifyjs in: " <> encodeString uglifyJsBin

    (ExitSuccess,pscLoc) <- shellStrict "which psc" empty
    (ExitSuccess,pscVer) <- shellStrict "psc --version" empty
    liftIO $ do
        putStrLn $ "psc location: " ++ T.unpack pscLoc
        putStrLn $ "psc version: " ++ T.unpack pscVer

    let buildDir = prjHome
        srcDir' = prjHome </> "src/" -- for stripping prefix
    cd buildDir
    -- search "purs" files
    pursFiles <- fold (find (suffix ".purs") srcDir') Fold.list
    let toRelativePursFileParts =
              map encodeString
            . splitDirectories
            . fromJust
            . stripPrefix srcDir'
        relativeFilePartsToModuleName xs = L.intercalate "." (modulePath ++ [moduleName])
          where
            -- drop last char ("/" in this case)
            modulePath = map init (init xs)
            moduleName = take (l-5) ys
              where
                ys = last xs
                l = length ys
    putStrLn "==== Detecting PureScript modules ===="
    let pursModules = L.sort $
            map ( relativeFilePartsToModuleName
                . toRelativePursFileParts) pursFiles
    mapM_ (putStrLn . ("* " ++)) pursModules
    putStrLn "=== End of list ===="
    -- build and optimize
    (ExitSuccess, _) <- shellStrict "pulp build -- --censor-codes=ImplicitImport,HidingImport --censor-lib " empty
    let pscBundleArgs = "output/*/*.js" : concatMap pmConvert pursModules
        pmConvert pm = ["-m", pm]
        bundleCmd = unwords ("psc-bundle" : pscBundleArgs)
    (ExitSuccess, jsContent) <- shellStrict (T.pack bundleCmd) empty
    let jsOptimized = jsContent
--    (ExitSuccess, jsOptimized) <- procStrict
--        (toText' uglifyJsBin)
--        ["-c", "-m"]
--        (select (textToLines jsContent))
    cd cwd
    let targetFile = "KanColleHelpers.js"
        targetFileNode = "KanColleHelpersN.js"
    -- write to file
    T.writeFile targetFile jsOptimized
    T.putStrLn $ "Saved to: " <> toText' (cwd </> decodeString targetFile)
    T.writeFile targetFileNode (jsOptimized <> "\nmodule.exports = PS;\n")
    T.putStrLn $ "Saved to: " <> toText' (cwd </> decodeString targetFileNode)
    return ()
