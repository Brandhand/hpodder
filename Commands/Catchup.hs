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

module Commands.Catchup(cmd, cmd_worker) where
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
import System.Console.GetOpt
import System.Console.GetOpt.Utils

i = infoM "catchup"
w = warningM "catchup"

cmd = simpleCmd "catchup" 
      "Tell hpodder to ignore old undownloaded episodes" helptext
      [Option "n" ["number-eps"] (ReqArg (stdRequired "n") "NUM")
       "Number of episodes to allow to download (default 1)"] 
      cmd_worker

cmd_worker gi (args, casts) = lock $
    do podcastlist <- getSelectedPodcasts (gdbh gi) casts
       let n = case lookup "n" args of
                 Nothing -> 1
                 Just y -> read y
       i $ printf "%d podcast(s) to consider\n" (length podcastlist)
       mapM_ (catchupThePodcast gi n) podcastlist

catchupThePodcast gi n pc =
    do i $ printf " * Podcast %d: %s" (castid pc) (feedurl pc)
       eps <- getEpisodes (gdbh gi) pc
       let epstoproc = take (length eps - n) eps
       mapM procEp epstoproc
       commit (gdbh gi)
    where procEp ep = 
              updateEpisode (gdbh gi) (ep {epstatus = newstatus})
              where newstatus = 
                        case epstatus ep of
                          Pending -> Skipped
                          Error -> Skipped
                          x -> x


helptext = "Usage: hpodder catchup [-n x] [castid ...]\n\n" ++ 
           genericIdHelp ++
 "\nRunning catchup will cause hpodder to mark all but the n most recent\n\
 \episodes as Skipped.  This will prevent hpodder from automatically\n\
 \downloading such episodes.  You can specify the value for n with -n.\n"
