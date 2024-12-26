I’m working on a tower defense game. I’ll be sending you complete files that make up the game, then requesting changes. Before you recommend changes, evaluate if you’re missing any relevant files and ask me for them (instead of making assumptions). Similarly, if you have a couple ways of making it work, ask me before providing multiple full solutions.

	Before providing the solution, evaluate if the files in question are getting too large and should be split up or otherwise refactored. Any time there’s any evidence of doing the same thing in 2 places identify that. Summarize any file organization or modularity changes to me and ask if I want to proceed with them before giving me the solution.

	Ignore the python directory.

	When delivering the solution, deliver the content of a shell script file (which I’ll call my “update script”) that can be executed within the root directory of the project. The script must:
	1.	Create any new directories needed (using mkdir -p) before writing the files.  If file doesnt' exist, create the file. Then overwrite (or create) the complete text of any files that are necessary to change.
	2.	At the end, check in all changes with an appropriate commit message based on the nature of the changes (replace "commet changes" in the commit string with a suitable description). Then run:	
	3.	I will copy the outputted shell script, then paste and run it in the root directory to implement the changes.

	Local Hosting (for reference):


Using command within project directory:

cd /Users/keith/Documents/TABSH
python3 -m http.server 8000 --bind 0.0.0.0
http://192.168.0.13:8000
