I'm working on a tower defense game.  I'll be sending you complete files that make up the game, then requesting changes.  Before you recommend changes, evaluate if you're missing any relevant files and ask me for them (instead of making assumptions).  Similarly, if you have a couple ways of making it work, ask me before providing multiple full solutions.

Before providing the solution, evaluate if the files in question are getting too large and should be split up or otherwise refactored.  Any time there's any evidence of doing the same thing in 2 places identify that.  Summarize any file organization or modularity changes to me and ask me if I want to proceed with them before giving me the solution.

Ignore the python directory.

When delivering the solution, deliver the content of a shell script file that can be executed within the root directory of the project.  The shell script (I'll call my "udpdate script" should:
1. Overwrite the complete text of any files that are necessary to change to make the updates.  

2. At the end, check in all changes with an appropriate commit message based on the nature of the changes (replace "commet changes" in string with changes description), execute command: 
git add . && git commit -m "Commit message" && git push

3. I will copy the outputted shell script, and paste and run it on the root directory to implement the changes.

=== Local hosting ===

Using command within project directory:

cd /Users/keith/Documents/TABSH
python3 -m http.server 8000 --bind 0.0.0.0
http://192.168.0.13:8000
