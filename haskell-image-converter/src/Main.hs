{-# language QuasiQuotes     #-}
{-# language TemplateHaskell #-}

module Main where

import Codec.Picture (decodeImage)
import Codec.Picture.Saving (imageToJpg)
import Control.Monad.IO.Class (liftIO)
import Data.ByteString qualified as BIO
import Data.ByteString.Lazy (toStrict)
import Data.Text (unpack)
import Data.UUID qualified as UUID
import Data.UUID.V4 qualified as V4
import GHC.Generics (Generic)
import Network.Wai (Application,)
import Network.Wai.Handler.Warp (run)
import Servant (err500, errBody, throwError, serveDirectoryWebApp, Raw, (:>), Post, Handler)
import Servant.API.Generic ((:-))
import Servant.HTML.Blaze (HTML)
import Servant.Multipart (Mem, MultipartData(..), fdPayload, fdFileName, MultipartForm)
import Servant.Server.Generic (AsServerT)
import Servant.Server.Generic (genericServe)
import Text.Hamlet (Html, shamlet)

main :: IO ()
main = run port app
  where
    port = 3001


data Routes mode = Routes
  { upload :: mode :- "upload" :> MultipartForm Mem (MultipartData Mem) :> Post '[HTML] Html
  , static :: mode :- Raw
  }
  deriving Generic


app :: Application
app = genericServe server
  where
    server :: Routes (AsServerT Handler)
    server = Routes
      { static = serveDirectoryWebApp "./public"
      , upload = uploadAndConvert
      }


uploadAndConvert :: MultipartData Mem -> Handler Html
uploadAndConvert form = do
  newPath <- case (files form) of
    [] -> oops "No files uploaded"
    f : [] -> liftIO $ do
      uuid <- V4.nextRandom
      let jpg = imageToJpg 100 . unsafeEither . decodeImage . toStrict . fdPayload $ f
          name = unpack (fdFileName f) ++ "-" ++ UUID.toString uuid ++ ".jpg"
          newPath = "images/" ++ name
      BIO.writeFile ("./public/" ++ newPath) (toStrict jpg)
      pure newPath
    _ -> oops "Too may files!"
  pure $ [shamlet| <img src=#{newPath} /> |]
    where
      oops m = throwError $ err500 { errBody = m }
      unsafeEither (Right x) = x
      unsafeEither _ = error "Bad parse"

