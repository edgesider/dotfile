## `backup.py` A tiny script to manage backup of dotfile.
Usage:
1. Run `./backup.py genempty` to generate a empty backup_list file. Then 
add the files need to be backuped.
2. Run `./backup.py backup` to backup.
3. Run `./backup.py restore` to restore. restore action will attemp to 
restore permission bits, ownner, group and other metainfo, so it may
require root permission.
4. Run `./backup.py clean` will delete all backuped files, include its metainfo.

More options please check help text.
