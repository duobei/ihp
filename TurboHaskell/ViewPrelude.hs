{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE UndecidableInstances  #-}

module TurboHaskell.ViewPrelude (
    module TurboHaskell.Prelude,
    module TurboHaskell.View.TimeAgo,
    stringValue,
    isActivePath,
    module TurboHaskell.View.Form,
    viewContext,
    hsx,
    toHtml,
    module Data.List.Split,
    isActivePathOrSub,
    preEscapedToHtml,
    module TurboHaskell.View.Modal,
    module TurboHaskell.ValidationSupport,
    addStyle,
    css,
    pathTo,
    module TurboHaskell.ViewSupport,
    module TurboHaskell.ModelSupport,
    (!),
    module Data.Data,
    param,
    fetch,
    query
) where

import TurboHaskell.Prelude
import           TurboHaskell.ViewErrorMessages
import           TurboHaskell.ViewSupport
import qualified Network.Wai
import           Text.Blaze                   (Attribute, dataAttribute, preEscapedText, stringValue, text)
import           Text.Blaze.Html5             (preEscapedToHtml, a, body, button, div, docTypeHtml, footer, form, h1, h2, h3, h4, h5, h6, head, hr, html, iframe, img, input,
                                               label, li, link, meta, nav, ol, p, script, small, span, table, tbody, td, th, thead, title, tr, ul, pre, code, select, option, (!))
import qualified Text.Blaze.Html5             as Html5
import           Text.Blaze.Html5.Attributes  (action, autocomplete, autofocus, charset, class_, selected, checked, content, href, httpEquiv, id, lang, method, name, onclick, onload,
                                               placeholder, rel, src, style, type_, value)
import qualified Text.Blaze.Html5.Attributes  as A
import TurboHaskell.View.Form
import TurboHaskell.HtmlSupport.QQ (hsx)
import TurboHaskell.HtmlSupport.ToHtml
import TurboHaskell.View.TimeAgo
import Data.List.Split (chunksOf)
import TurboHaskell.View.Modal
import TurboHaskell.ValidationSupport
import TurboHaskell.Controller.RequestContext
import TurboHaskell.RouterSupport
import TurboHaskell.ModelSupport
import Data.Data
import GHC.TypeLits as T
import qualified Data.ByteString as ByteString

css = plain

onClick = onclick
onLoad = onload

{-# INLINE theRequest #-}
theRequest :: (?viewContext :: viewContext, HasField "requestContext" viewContext RequestContext) => Network.Wai.Request
theRequest = 
    let
        requestContext = getField @"requestContext" ?viewContext
        request = getField @"request" requestContext
    in request

class PathString a where
    pathToString :: a -> Text

instance PathString Text where
    pathToString path = path

instance {-# OVERLAPPABLE #-} HasPath action => PathString action where
    pathToString = pathTo

isActivePath :: (?viewContext :: viewContext, HasField "requestContext" viewContext RequestContext, PathString controller) => controller -> Bool
isActivePath route =
    let 
        currentPath = Network.Wai.rawPathInfo theRequest
    in
        currentPath == cs (pathToString route)

isActivePathOrSub :: (?viewContext :: viewContext, HasField "requestContext" viewContext RequestContext, PathString controller) => controller -> Bool
isActivePathOrSub route =
    let
        currentPath = Network.Wai.rawPathInfo theRequest
    in
        cs (pathToString route) `ByteString.isPrefixOf` currentPath

{-# INLINE viewContext #-}
viewContext :: (?viewContext :: viewContext) => viewContext
viewContext = ?viewContext

{-# INLINE addStyle #-}
addStyle :: (ConvertibleStrings string Text) => string -> Html5.Markup
addStyle style = Html5.style $ preEscapedText (cs style)

class ViewParamHelpMessage where param :: a
instance (T.TypeError (T.Text "‘param‘ can only be used inside your controller actions.\nYou have to run the ‘param \"my_param\"‘ call inside your controller and then pass the resulting value to your view.\n\nController Example:\n\n    module Web.Controller.Projects\n\n    instance Controller ProjectsController where\n        action ProjectsAction = do\n            let showDetails = param \"showDetails\"\n            render ProjectsView { showDetails }\n\nView Example:\n\n    module Web.View.Projects.Index\n\n    data ProjectsView = ProjectsView { showDetails :: Bool }\n    instance View ProjectsView ViewContext where\n        html ProjectsView { .. } = [hsx|Show details: {showDetails}|]\n\n")) => ViewParamHelpMessage where

class ViewFetchHelpMessage where
    fetch :: a
    query :: a
instance (T.TypeError (T.Text "‘fetch‘ or ‘query‘ can only be used inside your controller actions. You have to call it from your controller action and then pass the result to the view.")) => ViewFetchHelpMessage where

instance (T.TypeError (T.Text "Looks like you forgot to pass a " :<>: (T.ShowType (GetModelByTableName record)) :<>: T.Text " id to this data constructor.")) => Eq (Id' (record :: T.Symbol) -> controller) where