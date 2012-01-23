{-
Copyright (C) 2012 John MacFarlane <jgm@berkeley.edu>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
-}

{- |
   Module      : Text.Pandoc.Slides
   Copyright   : Copyright (C) 2012 John MacFarlane
   License     : GNU GPL, version 2 or above

   Maintainer  : John MacFarlane <jgm@berkeley.edu>
   Stability   : alpha
   Portability : portable

Utility functions for splitting documents into slides for slide
show formats (dzslides, s5, slidy, beamer).
-}
module Text.Pandoc.Slides ( ) where
import Text.Pandoc.Definition
import Text.ParserCombinators.Parsec
import Text.Parsec.Pos (initialPos)

data SlideElement = Outside Block
                  | Slide [Inline] [Inline] [Block]  -- title - subtitle - contents
                  deriving (Read, Show)

toSlideElements :: [Block] -> [SlideElement]
toSlideElements bs =
  case parse (pElements $ getSlideLevel bs) "blocks" bs of
       Left err   -> map Outside bs
       Right res  -> res

anyTok :: GenParser Block () Block
anyTok = token show (const $ initialPos "blocks") Just

satisfies :: (Block -> Bool) -> GenParser Block () Block
satisfies f = token show (const $ initialPos "blocks")
                   (\x -> if f x then Just x else Nothing)

pElements :: Int -> GenParser Block () [SlideElement]
pElements slideLevel = do
  res <- many (pSlide slideLevel <|> pOutside)
  eof
  return res

pSlide :: Int -> GenParser Block () SlideElement
pSlide slideLevel = try $ do
  

pOutside :: GenParser Block () SlideElement
pOutside = Outside `fmap` anyTok

-- | Find level of header that starts slides (defined as the least header
-- level that occurs before a non-header/non-hrule in the blocks).
getSlideLevel :: [Block] -> Int
getSlideLevel = go 6
  where go least (Header n _ : x : xs)
                 | n < least && nonHOrHR x = go n xs
                 | otherwise               = go least (x:xs)
        go least (x : xs) = go least xs
        go least [] = least
        nonHOrHR (Header _ _) = False
        nonHOrHR (HorizontalRule) = False
        nonHOrHR _ = True
