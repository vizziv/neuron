{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE NoImplicitPrelude #-}

-- | Special Zettel links in Markdown
module Neuron.Zettelkasten.Link.View where

import Lucid
import Neuron.Zettelkasten.ID
import Neuron.Zettelkasten.Link.Action
import qualified Neuron.Zettelkasten.Meta as Meta
import Neuron.Zettelkasten.Route (Route (..))
import Neuron.Zettelkasten.Store
import Neuron.Zettelkasten.Type
import Relude
import qualified Rib

linkActionRender :: Monad m => ZettelStore -> MarkdownLink -> LinkAction -> HtmlT m ()
linkActionRender store MarkdownLink {..} = \case
  LinkAction_ConnectZettel _conn -> do
    -- The inner link text is supposed to be the zettel ID
    let zid = parseZettelID markdownLinkText
    renderZettelLink LinkTheme_Default store zid
  LinkAction_QueryZettels _conn linkTheme q -> do
    p_ $ toHtml @Text $ show q
    ul_ $ do
      forM_ (runQuery store q) $ \zid -> do
        li_ $ renderZettelLink linkTheme store zid

renderZettelLink :: Monad m => LinkTheme -> ZettelStore -> ZettelID -> HtmlT m ()
renderZettelLink ltheme store zid = do
  let Zettel {..} = lookupStore zid store
      zurl = Rib.routeUrlRel $ Route_Zettel zid
      ztagsM = Meta.tags =<< Meta.getMeta zettelContent
  case ltheme of
    LinkTheme_Default -> do
      -- Special consistent styling for Zettel links
      -- Uses ZettelID as link text. Title is displayed aside.
      span_ [class_ "zettel-link"] $ do
        span_ [class_ "zettel-link-idlink"] $ do
          a_ [href_ zurl] $ toHtml zid
        span_ [class_ "zettel-link-title"] $ do
          toHtml $ zettelTitle
        whenJust ztagsM $ \ztags ->
          forM_ ztags $ \ztag ->
            span_ [class_ "ui label"] $ toHtml ztag
    LinkTheme_Menu ignoreZid -> do
      -- A normal looking link.
      -- Zettel's title is the link text.
      if Just zid == ignoreZid
        then div_ [class_ "zettel-link item active", title_ $ unZettelID zid] $ do
          span_ [class_ "zettel-link-title"] $ do
            b_ $ toHtml zettelTitle
        else a_ [class_ "zettel-link item", href_ zurl, title_ $ unZettelID zid] $ do
          span_ [class_ "zettel-link-title"] $ do
            toHtml zettelTitle
    LinkTheme_WithDate -> do
      span_ [class_ "zettel-link", title_ $ unZettelID zid] $ do
        code_ $ toHtml @Text $ show $ zettelIDDate zid
        a_ [href_ zurl] $ do
          span_ [class_ "zettel-link-title"] $ do
            toHtml zettelTitle