I'm working on a tower defense game.  I'll be sending you complete files that make up the game, then requesting changes.  Before you recommend changes, evaluate if you're missing any relevant files and ask me for them (instead of making assumptions).  Similarly, if you have a couple ways of making it work, ask me before providing multiple full solutions.

Before providing the solution, evaluate if the files in question are getting too large and should be split up or otherwise refactored.  Any time there's any evidence of doing the same thing in 2 places identify that.  Summarize any file organization or modularity changes to me and ask me if I want to proceed with them before giving me the solution.

When delivering the solution, always provide the complete new version of only the files that require changes.

=== Local hosting ===

Using command within project directory:

cd /Users/keith/Documents/TABSH
python3 -m http.server 8000 --bind 0.0.0.0
http://192.168.0.13:8000
