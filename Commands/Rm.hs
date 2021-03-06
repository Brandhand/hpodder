{- hpodder component
Copyright (C) 2006-2007 John Goerzen <jgoerzen@complete.org>

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

module Commands.Rm(cmd, cmd_worker) where
import Utils
import System.Log.Logger
import DB
import Download
import FeedParser
import Types
import Text.Printf
import Config
import Database.HDBC
import Control.Monad
import Utils
import Data.String
import qualified Commands.Ls
import System.IO

i = infoM "rm"
w = warningM "rm"

cmd = simpleCmd "rm" 
      "Remove podcast(s) from hpodder" helptext 
      [] cmd_worker

cmd_worker gi ([], []) = 
    fail $ "rm requires a podcast ID to remove; please see hpodder rm --help"

cmd_worker gi ([], casts) = lock $
    do podcastlist <- getSelectedPodcasts (gdbh gi) casts
       i "Will remove the following podcasts:\n"
       Commands.Ls.lscasts_worker gi ([("l", "")], casts)
       i $ printf "\nAre you SURE you want to remove these %d podcast(s)?\n"
           (length podcastlist)
       i "Type YES exactly as shown, in all caps, to delete them."
       i "Remove podcasts? "
       hFlush stdout
       resp <- getLine
       if resp == "YES"
          then do mapM_ (removePodcast (gdbh gi)) podcastlist
                  commit (gdbh gi)
                  i $ "Remove completed."
          else do i "Remove aborted by user."

cmd_worker _ _ =
    fail $ "Invalid arguments to rm; please see hpodder rm --help"

helptext = "Usage: hpodder rm castid [castid...]\n\n" ++
 "\nRemoves the specified podcast(s) entirely from hpodder\n"
