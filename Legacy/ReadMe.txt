send2XBMC v4.8.1027
(c) 2007-2009 by Guillaume
http://www.addictivetips.com/windows-tips/send2xbmc-sends-file-or-url-to-xbmc-media-center/


Contents:
=========
1. Changelog
2. Description
3. Total Commander Support
4. Explorer Context Menu Handlers
5. Opera Context Menu Extension
6. INI-file settings
7. Todos (please help me out!)


1. Changelog
============

Changes since v4.8.0807:
------------------------
* Fixed a bug when operaprefs.ini uses {LargePrefs} or {SmallPreferences}
  to indicate path to .ini
* Removed the /del... parameters and introduced a dialog to add/remove the
  extensions for Explorer and Opera.

Changes since v4.8.0504:
------------------------
* Updated Opera context menu function for Opera 10

Changes since v4.8.0217:
------------------------
+ Added "Send to" Explorer context menu extension: this addresses both the
  issue of not being able to play multiple files from Explorer (this opens up
  multiple instances of send2XBMC causing trouble) and the 'Play from here'
  feature request: select the files, right-click on the file you want to play
  first and use 'send2XBMC - Play now' from 'Send to' menu
+ Added functionality to (ask to) ignore playlist files when multiple files or
  folders are selected to prevent files from being added twice to the playlist
* Although the shell extension is still available, it can be considered
  obsolete, as it causes problems when adding multiple files simultaneously:
  Explorer will open up an instance of send2XBMC for every file/folder selected
  causing 1) an unordered adding to the XBMC playlist and 2) possible problems
  when adding too many files/folders at once (XBMC returns errors)

Changes since v4.7.0106:
------------------------
+ Adds Explorer context menu items for folders
* Support for other protocols than http (e.g. rtsp://)
+ Custom webpage patterns for video URL extraction (see INI-file settings)

Changes since v4.6.1116:
------------------------
+ Added support for Entensity.net flash movies
* Added .flv to file extensions for Video playlist
* Quick fix for YouTube due to localization of the page
* Renamed Explorer and Opera context menu items ("send2XBMC - Play now" and
  "send2XBMC - Add to playlist")

Changes since v4.5.0707:
------------------------
* When function SyntaxURL was called (and "%E2" substitutes "."), the correct
  playlist (video or audio) could not be determined

Changes since v4.4.0615:
------------------------
+ Added Opera context menu item to enqueue URLs
* Renamed Explorer and Opera context menu items ("Play/Enqueue in XBMC")
* Fixed a dumb bug with not passing through the variable $Path when checking
  if the file was shared or not

Changes since v4.3.0612:
------------------------
+ Added commandline parameter "/dellshellext" to remove entries from Explorer
  context menu
+ Added commandline parameter "/opera" and "/delopera" to automatically add
  or remove Opera context menu items respectively
+ New INI-file entry YouTubeMP4 to choose for high quality H264 YouTube stream
  as the Xbox CPU might not be up for it, causing stuttery playback 
* Cleanup of ShellExt function
* Minor changes in Main, ParseParameters (formerly DeterminePath) and FileCheck
* Fixed issue with substituting "/" by syntaxURL

Changes since v4.2.0608:
------------------------
* [Big thanks to .zap!] SyntaxURL function is now more universal and used to
  change every non-alphanumeric character into its corresponding hexadecimal,
  avoiding problems with URL parsing by XBMC (should fix YouTube problems)

Changes since v4.1.0607:
------------------------
* Removed stupid ByRef(erence) residue
+ Added commandline parameter "/shellext" to add send2XBMC to Explorer
  context menu: right-click on file(s) and send to XBMC immediately
+ Proper error handling on network connection problems (finally!)
+ Some more code clearity by comments where appropriate
- Removed the debug code

Changes since v4.0.0607:
------------------------
* Code cleanup with regards to sending command to XBMC
* YouTube support: now doesn't need a temporary file
* YouTube support: no line-by-line variable seeking in HTML page
+ YouTube support: dialog if link could not be found or parsed correctly

Changes since v3.1.0517:
------------------------
* SharesIncl now has priority over SharesExcl
+ Preliminary support for YouTube URLs: tries to pass through the
  higher quality MP4 format videos first, if not found for the specific video,
  then FLV is passed to XBMC

Changes since v3.0.0508:
------------------------
* Removed checking routine of network path (for when current user has
  no permissions to read from the found share)
+ Two new options in INI-file to include only specified shares (SharesIncl)
  or exclude certain shares from being checked (SharesExcl), which is quite
  useful when XBMC has no permission to read from those shares

Changes since v2.1.0429:
------------------------
* Code restructuring
* Added audio playlist extensions to variable AudioExt
+ Ability to send/queue more files at once from commandline / file dialog
+ Ability to send files containing the following characters: & + ;#
+ Short paths to files allowed (C:\Progra~1\...)
+ Total Commander temporary list file compatibility (%L)

Changes since v2.0.0428:
------------------------
+ Added a routine to automatically choose the right (audio or video)
  playlist, instead of just using the currently active, which didn't
  work that well
+ INI-file entries AudioExt and VideoExt to manually configure which
  extensions are to be handled as audio/video files in order to add
  them correctly to the corresponding XBMC playlists

Changes since v1.0.0426:
------------------------
* Completely restructured code
* Removed UPX Compression (theoretically, since it has a very small
  file size already, it should initialize a bit faster)
+ Some more checks integrated
+ Added commandline parameter "/add" to add files to the XBMC playlist


2. Description:
===============
send2XBMC makes it easy to send either an URL or the address of a 
remotely shared (SMB) or local media file to your Xbox. This can be done
by opening the file through the dialog of send2XBMC or by providing
the path/URL by a commandline parameter. To use paths with spaces,
add quotation marks to the parameter. Be sure to have the Web Interface
enabled on your Xbox. Sending multiple files to XBMC at once is allowed.

send2XBMC will send URLs and remotely shared files directly to your
Xbox (after checking the existence of the file in case of a SMB-share).
If the supplied path is a local file, send2XBMC will automatically search
for an available SMB share that leads to the file. If found, it'll send
the network path to your Xbox.


3. Total Commander Support:
===========================
To use send2XBMC with Total Commander from its Start Menu, point to the
location of send2XBMC and use "%L" or "/add %L" (no quotes) as parameters.
This will send/add the file under the cursor to play on your Xbox or all
selected files.


4. Context Menu Handlers:
=========================
You can create context menu items in Explorer to send2XBMC in two ways.
Originally, registry items were added either for all users or the current user
only. This can still be done by running send2XBMC with the following command:
""[path]\send2xbmc.exe" /shellext"

Henceforth, you can easily send any file to XBMC by right-clicking on it
and choosing the command 'Send to XBMC' or 'Send to XBMC - Queue'.

This extension can be removed again by choosing 'No' in the dialog presented.

And you should, because problems arise with this solution when you select
multiple items and try to send them to XBMC: Explorer opens an instance for
send2XBMC for every selected file/folder simultaneously, causing a cascade of
requests to XBMC (and a mess in your notification/tray area) which eventually
leads to XBMC to return error messages and skipping several of the selected
items. Moreover, it is almost completely random in which order the items will
eventually be added to the playlist. In addressing this problem, I found it
easier to focus on the alternative already provided in the ReadMe files of all
previous send2XBMC versions:

This alternative option is to create shortcuts to send2xbmc.exe in the SendTo
folder of your user profile to use send2XBMC from the context menu.
This can now we done by send2XBMC automatically through the command:
"[path]\send2xbmc.exe" /sendto

You can easily remove the shortcuts again with the same command,
choosing 'No' in the dialog presented.

This method solves both the issue with multiple instances of send2XBMC running
simultaneously and the order in which the files/folders are added to the playlist,
as Explorer waits for send2XBMC to close before opening a new instance for the next
file (in alphabetical order).

Aditionally, a "Play from here" function springs from Explorer's behavior:
select the files you want to send to the XBMC playlist, then right-click on the
file you want to play first and use 'send2XBMC - Play now' from 'Send to' menu.
Explorer will call upon send2XBMC for the items in the following order:
1) the file/folder you hovered over upon right-clicking
2) all items after that specific file/folder
3) continuing from the top, all items above that specific file/folder


5. Opera Context Menu Extension
===============================
send2XBMC contains a handy command line parameter to add itself to the
Opera context menus. This way, you can directly send URL's of video or audio
to XBMC for instant playback, or a YouTube URL from the address bar or the
link to the video's page. Just right-click the link/selected text and choose
"Send to XBMC".

To add the entries to the Opera context menus, use the following command
(from the Windows Run dialog):
"send2xbmc.exe /opera"

Like the Explorer extension, you can remove the entries by choosing 'No'
in the dialog presented.


6. INI-file Settings:
==========================
send2XBMC can open up your download folder at start by using an optional
INI-file. Here you can also manually enter the IP-address of your Xbox
(by default, send2XBMC will try to connect using 'http://xbox').
Furthermore, you can manually configure the file extensions recognition
for audio and video files when adding multiple files at once from
commandline. Particular shares on your computer can be either explicitly
included or excluded using their settings SharesIncl and SharesExcl,
respectively.

If you have a particular website that provides either audio or video
content in a page like YouTube or Break.com do, you can specify a search
pattern for send2XBMC in order to extract the audio/video URL from the
source code of the page. This can either be a complete URL that resides
in the code, or an URL built up from multiple variables that can be
extracted from the page's source code.

Below you will find an example of an INI-file for send2XBMC. The values
below are what send2XBMC defaults to when the entry in the INI-file does
not exist (or the INI-file doesn't exist at all).

INI-file (filename = send2xbmc.ini):
--------------------------------------------------------------------------
[Config]
;Your Xbox IP-address:
XboxIP = xbox

;Initial folder when opening without commandline, e.g. F:\Downloads
InitFolder = (working directory)

;File extensions to add to Audio playlist
AudioExt = *.wav;*.mp3;*.mp4;*.m4a;*.wma;*.ogg;*.mpc;*.ac3;*.fla;*.flac;*.ape;*.aac;*.shn;*.wv;*.cue;*.m3u;*.pls;*.dts;*.strm;

;File extensions to add to Video playlist
VideoExt = *.avi;*.mpg;*.wmv;*.asf;*.mkv;*.ogm;*.mov;*.rm;*.ifo;*.vob;*.3gp;*.flv;

;Include shares with following names, e.g. Movies;Downloads
SharesIncl = ALL

;Exclude files with following names, e.g. Private;Documents
SharesExcl = NONE

;Include entries from playlist files when sending multiple files or folders to XBMC
IncludePlaylistFiles=No

;Search patterns to extract media URLs from the page's source code
[Patterns]

;Part of URL for which to use this pattern
1=youtube

;Start extraction of variable %1% when reaching... (left boundary)
1-left1=video_id=

;Stop extraction of variable %1% when reaching... (right boundary)
1-right1=&

;Start extraction of variable %2% when reaching... (left boundary)
1-left2=&t=

;Stop extraction of variable %2% when reaching... (right boundary)
1-right2=&

;Combine variables into following URL...
1-url=http://www.youtube.com/get_video?video_id=%1%&t=%2%

;Note:	You can add as many patterns as you want (up to 1024),
;	BUT only the FIRST pattern matching (part of) the URL,
;	as specified like 1=youtube, will be used. So best is to
;	order the patterns from most specific URL criterium to
;	least specific criterium.
;	You can use as many variables %?% as you want (up to 1024)
--------------------------------------------------------------------------


7. Todos:
=========
+ Include scripts or functions for context menu support for:
  1) Internet Explorer
  2) Firefox (in the mean time, use XBMC Fox: http://xbmchacks.blogspot.com/)
+ Let send2XBMC check inside folders for playlist files to prevent files from
  being added to the XBMC playlist twice (through directory listing and a
  playlist file)


Disclaimer:
===========
This program is tested on Windows XP (SP2 and SP3) and Windows 7,
but should work on all NT-based OS's.

For questions, bugs and/or suggestions, please visit
http://www.addictivetips.com/windows-tips/send2xbmc-sends-file-or-url-to-xbmc-media-center/

or visit the following topic on Xbox-Scene:
http://forums.xbox-scene.com/index.php?showtopic=600219

Icon created from "Xbox" by ~jackroberts (deviantART)