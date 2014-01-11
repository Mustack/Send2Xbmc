;send2XBMC v4.8.1027
;(c) 2007-2009 by Guillaume
;http://www.asymmetrics.nl/send2xbmc

Func Main()
	Init()
	$Path = ParseParameters()
		If IsArray($Path) Then
;If action is to queue multiple files
			If $Queue = 1 Then
				MultiFile($Path)
			Else
;If action is to play multiple files
				ClearPlaylist($Path)
				$Queue = 1
				MultiFile($Path)
				PlayFirst($Path)
			EndIf
		Else
;If action is to queue/play single file
			ParseCheck($Path)
		EndIf
EndFunc

Func Init()
;Get variables from INI-file
;Xbox IP-address:
	Global Const $XboxIP = IniRead(@ScriptDir & "\send2xbmc.ini","Config","XboxIP","xbox")
;Initial folder when opening without commandline:
	Global Const $InitFolder = IniRead(@ScriptDir & "\send2xbmc.ini","Config","InitFolder",@WorkingDir)
;File extensions for Audio playlist (first 16 used in Open File Dialog):
	Global Const $AudioExt = IniRead(@ScriptDir & "\send2xbmc.ini","Config","AudioExt","*.wav;*.mp3;*.mp4;*.m4a;*.wma;*.ogg;*.mpc;*.ac3;*.fla;*.flac;*.ape;*.aac;*.shn;*.wv;*.cue;*.m3u;*.pls;*.dts;*.strm;")
;File extensions for Video playlist(first 16 used in Open File Dialog):
	Global Const $VideoExt = IniRead(@ScriptDir & "\send2xbmc.ini","Config","VideoExt","*.avi;*.mpg;*.wmv;*.asf;*.mkv;*.ogm;*.mov;*.rm;*.ifo;*.vob;*.3gp;*.flv;")
;Shares to include in check:
	Global $SharesIncl = IniRead(@ScriptDir & "\send2xbmc.ini","Config","SharesIncl","#_ALL_#")
	If $SharesIncl <> "#_ALL_#" Then $SharesIncl = StringSplit($SharesIncl, ";")
;Shares to exclude in check:
	Global $SharesExcl = IniRead(@ScriptDir & "\send2xbmc.ini","Config","SharesExcl","#_NONE_#")
	If $SharesExcl <> "#_NONE_#" Then $SharesExcl = StringSplit($SharesExcl, ";")
;Include entries from playlist files when sending multiple files or folders to XBMC
	Global $IncludePlaylistFiles = IniRead(@ScriptDir & "\send2xbmc.ini","Config","IncludePlaylistFiles","Ask")
;Create variable to determine whether to add to playlist or play instantly
	Global $Queue = 0
;Create COM Event for error handling and error variable
	Global $oError = ObjEvent("AutoIt.Error","ErrorHandling")
	Global $ErrorOccurred = 0
;Create COM Extension for HTTP commands to XBMC
	Global $oHTTP = ObjCreate("winhttp.winhttprequest.5.1")
EndFunc

Func ParseParameters()
;Show File Dialog if no parameters were specified
	If $CmdLine[0] = 0 Then
		Return FileDialog()
;Check for integration function call
;Add/remove context menu handler
	ElseIf $CmdLine[1] = "/sendto" Then
		SendTo("")
		Exit
;Add/remove context menu handler
	ElseIf $CmdLine[1] = "/shellext" Then
		ShellExt()
		Exit
;Add/remove Opera context menu entries
	ElseIf $CmdLine[1] = "/opera" Then
		OperaContext()
		Exit
;Check for commandline parameter "/add"
	ElseIf $CmdLine[1] = "/add" Then
		$Queue = 1
		If $CmdLine[0] = 1 Then Return FileDialog()
	EndIf
;Return when Total Commander listfile
	If $Queue = 0 AND StringRight($CmdLine[1],4) = ".tmp" Then
		Return TotalCmd($CmdLine[1])
	ElseIf $Queue = 1 AND StringRight($CmdLine[2],4) = ".tmp" Then
		Return TotalCmd($CmdLine[2])
;Return when single parameter
	ElseIf $Queue = 0 AND $CmdLine[0] = 1 Then
;If parameter is directory, then return as array to invoke multifile
		If StringInStr(FileGetAttrib($CmdLine[1]),"D") Then
			Dim $Path[2] = [1, $CmdLine[1]]
			Return $Path
		EndIf
;Else return single file path
		Return $CmdLine[1]
	ElseIf $Queue = 1 AND $CmdLine[0] = 2 Then
;If parameter is directory, then return as array to invoke multifile
		If StringRight($CmdLine[2], 1) = "\" Then
			Dim $Path[2] = [1, $CmdLine[2]]
			Return $Path
		EndIf
;Else return single file path
		Return $CmdLine[2]
;Return when multiple parameters
	Else
		Return $CmdLine
	EndIf
EndFunc

Func FileDialog()
		$Filter = "All (*.*)|" & _
		"Audio (*.mp3;*.wma;*.ogg;*.mpc;*.wav;*.fla;*.flac;*.ape ;*.shn;*.wv;*.aac;*.ac3;*.dts;*.m4a;*.mp4;*.cue)|" & _
		"Video (*.avi;*.mpg;*.wmv;*.asf;*.mkv;*.ogm;*.mov;*.mp4;*.rm;*.ifo;*.vob;*.3gp)" & _
		"Playlists (*.m3u;*.pls;*.strm)|" & _
		"Disc Images (*.iso;*.img;*.bin)"
		$Dialog = FileOpenDialog("send2XBMC - Select file to to send...",$InitFolder,$Filter,5)
;If multiple files selected, add path folder to every filename
		If StringInStr($Dialog, "|") Then
			$DialogSplit = StringSplit($Dialog, "|")
			Dim $Path[$DialogSplit[0]]
;$DialogSplit[1] is the directory, so number of files is one less than in array
			$Path[0] = $DialogSplit[0] - 1
			For $i = 2 to $DialogSplit[0]
				$Path[$i-1] = $DialogSplit[1] & "\" & $DialogSplit[$i]
			Next
			Return $Path
		Else
;Return path when single file selected
			Return $Dialog
		EndIf
EndFunc

Func TotalCmd($List)
;Special handling when ?.tmp file is parsed (Total Commander listfile)
	$Path = StringSplit(FileRead($List),@LF)
;Fix for odd line-break handling
	For $i = 1 to $Path[0]
		$Path[$i] = StringTrimRight($Path[$i],1)
	Next
;AutoIt finds one item too many (again, line-break issue)
	$Path[0] = $Path[0] - 1
	Return $Path
EndFunc

Func MultiFile($Path)
;Discard first parameter if "/add"
	Dim $i = 1
	If $Path[1] = "/add" Then $i = 2
;Queue files in XBMC playlist(s)
	For $i = $i to $Path[0]
		If IncludeFile($Path[$i]) Then ParseCheck($Path[$i])
	Next
EndFunc

;----- Check operations -----

Func FileExist($Path)
;Check if the file exists (discard check when internet shortcut or share)
	If $Path = "" Then Exit
	If StringLeft($Path,4) = "http" OR StringLeft($Path,2) = "\\" OR StringIsDigit(StringLeft($Path,2)) OR FileExists($Path) Then
;To match shared paths saved in registry, return the long path
		Return FileGetLongName($Path)
	Else
		InputBox("send2XBMC","File not found!" & @LF & "Path: ",$Path)
		Exit		
	EndIf
EndFunc

Func IncludeFile($Path)
	$Ext = StringSplit($Path,".")
	$Ext = "*." & $Ext[$Ext[0]] & ";"
	If StringInStr("*.cue;*.m3u;*.pls;",$Ext) Then
		If $IncludePlaylistFiles = "No" Then Return 0
		If $IncludePlayListFiles = "Yes" Then Return 1
		$PlayListFile = FileGetLongName($Path,1)
		$PlayListFile = StringSplit($PlayListFile,"\")
		$PlayListFile = $PlayListFile[$PlayListFile[0]]
		$IgnoreFile = MsgBox(262180,"send2XBMC","You have selected multiple files including a playlist file." & @LF & "If you have selected an entire folder with a playlist inside, files will be added both through directory listing and the playlist entries (double)." & @LF & @LF & "Do you want to ignore the playlist " & $PlayListFile & "?")
		If $IgnoreFile = 6 Then Return 0
	EndIf
	Return 1
EndFunc

Func ParseCheck($Path)
;Send directly if commandline parameter is a network address
	If StringInStr($Path,"://") OR StringIsDigit(StringLeft($Path,2)) Then
;Opera sends "/add $URL  as one parameter
		If StringLeft($Path,4) = "/add" Then
			$Queue = 1
			$Path = StringTrimLeft($Path,5)
		EndIf
;If the URL is a YouTube page, parse YouTube video URL
;		If StringInStr($Path,"youtube.com") Then
;			YouTube($Path)
;If the URL is an Entensity.net page, parse Entensity.net video URL
;		If StringInStr($Path,"entensity.net") Then
;			Play(StringReplace($Path,"flash.php?media=",""))
;		Else
			MediaExtract($Path)
;		EndIf
;Convert to SMB address if parameter is share
	ElseIf StringLeft($Path,2) = "\\" Then
		Play("smb://" & StringTrimLeft($Path,2))
	Else
		Parse(FileExist($Path))
	EndIf
EndFunc

;----- URL operations -----

Func MediaExtract($Path)
;Media URL extraction from websites
	$entry = "#_NONE_#"
	For $i = 1 to 1024
		If IniRead(@ScriptDir & "\send2xbmc.ini","Patterns",$i,"#_NONE_#") = "#_NONE_#" Then ExitLoop
		If StringInStr($Path,IniRead(@ScriptDir & "\send2xbmc.ini","Patterns",$i,"#_ERROR_#")) Then
			$entry = $i
			ExitLoop
		EndIf
	Next
;If no extraction from page is necessary, pass through path unaltered
	If $entry = "#_NONE_#" Then
		Play($Path)
		Return
	EndIf	
;Extract video file location from HTML page
	$oHTTP.Open("GET",$Path)
	$oHTTP.Send()
;Abort current task if network error occurred
	If $ErrorOccurred Then
		$ErrorOccurred = 0
		Return
	EndIf
	$page = $oHTTP.Responsetext
;Parse retrieved HTML page (find variables in page by INI entries)
	$NumberOfVars = 0
	For $i = 1 to 1024
		If IniRead(@ScriptDir & "\send2xbmc.ini","Patterns", $entry & "-left" & $i, "#_NONE_#") = "#_NONE_#" Then ExitLoop
		Assign("media" & $i, StringTrimLeft($page, StringInStr($page, IniRead(@ScriptDir & "\send2xbmc.ini","Patterns", $entry & "-left" & $i, "#_ERROR_#")) + StringLen(IniRead(@ScriptDir & "\send2xbmc.ini","Patterns", $entry & "-left" & $i, "#_ERROR_#")) - 1))
		Assign("media" & $i, StringLeft(Eval("media" & $i), StringInStr(Eval("media" & $i), IniRead(@ScriptDir & "\send2xbmc.ini","Patterns", $entry & "-right" & $i, "#_ERROR_#")) - 1))
		$NumberOfVars = $i
	Next
;Bring extracted vars together to one URL
	If $NumberOfVars > 0 Then
		$media = StringReplace(IniRead(@ScriptDir & "\send2xbmc.ini","Patterns",$entry & "-url", "%1%"),"%1%",$media1)
		If $NumberOfVars > 1 Then
			For $i = 2 to $NumberOfVars
				$media = StringReplace($media,"%" & $i & "%", Eval("media" & $i))
			Next
		EndIf
;If the pattern uses (part of) the original URL
		If StringInStr($media,"%url%") Then
			$URLextract = StringLeft($Path, StringInStr($Path, IniRead(@ScriptDir & "\send2xbmc.ini", "Patterns", $entry & "-fromurl", "#_URLMISMATCH_#")) - 1)
			$media = StringReplace($media,"%url%",$URLextract)
		EndIf
;Pass through for playback
		If InetGetSize($media) Then
			Play($media)
		Else
				MsgBox(48,"send2XBMC - MediaExtract","Cannot find " & $media)
		EndIf
	Else
		MsgBox(48,"send2XBMC - MediaExtract","Cannot find the variables as specified in INI-file" & @LF & "Pattern: " & $entry)
	EndIf
EndFunc

;----- File operations -----

Func Parse($Path)	
;Get drive letter from commandline parameter
	Dim $DriveFolder[2]
	$DriveFolder[0] = StringLeft($Path,2)
	If DriveStatus($DriveFolder[0]) <> "READY" Then
		MsgBox(48,"send2XBMC - Parse","Drive" & $DriveFolder[0] & " not ready!")
		Exit
	EndIf
;Get path from commandline parameter
	$DriveFolder[1] = StringTrimLeft($Path,3)
;Split path into subfolder segments
	$SplitFolder = StringSplit($DriveFolder[1],"\")
	FindShares($Path, $DriveFolder, $SplitFolder)
EndFunc

Func FindShares($Path, $DriveFolder, $SplitFolder)
;Variable to determine whether a path is matched to a network share
	$Matched = 0
;Check if to search through shares in $SharesIncl only
	If $SharesIncl <> "#_ALL_#" Then
		For $i = 1 to $SharesIncl[0]
			If MatchShare($DriveFolder, $SplitFolder, $SharesIncl[$i]) Then
				$Matched = 1
				ExitLoop
			EndIf
		Next
	Else
;Find smb-shares from registry and check for matching share
		For $i = 1 to 1024
			$ShareName = RegEnumVal("HKLM\SYSTEM\CurrentControlSet\Services\lanmanserver\Shares", $i)
			If @error <> 0 Then ExitLoop
			If NotExcluded($ShareName) Then
				If MatchShare($DriveFolder, $SplitFolder, $ShareName) Then
					$Matched = 1
					ExitLoop
				EndIf
			EndIf
		Next
	EndIf
	If NOT $Matched Then MsgBox(48,"send2XBMC - FindShares","Path to the following file is not shared:" & @LF & $Path)
EndFunc

Func NotExcluded($ShareName)
;Check if sharename is not excluded by user through INI-file entry
	If $SharesExcl = "#_NONE_#" Then Return True
	For $i = 1 to $SharesExcl[0]
		If $ShareName = $SharesExcl[$i] OR $ShareName & ";" = $SharesExcl[$i] Then Return False
	Next
	Return True
EndFunc

Func MatchShare($DriveFolder, $SplitFolder, $ShareName)
		$Share = RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\lanmanserver\Shares", $ShareName)
		If @error <> 0 Then Return False
		If StringInStr($Share, "Path=" & $DriveFolder[0]) Then
;Extract the "Path=" line by splitting the data into an array
			$Share2Check = StringSplit($Share, @LF)
;Discard "Path=?:\" and split into subfolder segments
			$Share2Check = StringSplit(StringTrimLeft($Share2Check[3],8),"\")
;Now match the SplitFolder
			If MatchSplitFolder($ShareName, $Share2Check, $SplitFolder) Then Return True
		EndIf
EndFunc

Func MatchSplitFolder($ShareName, $Share2Check, $SplitFolder)
		For $i = 1 to $Share2Check[0]
;If the root of a drive is shared
			If $Share2Check[$i] = "" Then
				JoinPath($ShareName, $SplitFolder, $i)
				Return True
;If the share's subfolder doesn't match with the file location
			ElseIf $Share2Check[$i] <> $SplitFolder[$i] Then
				Return False
;If the last subfolder of the share is reached successfully
			ElseIf $i = $Share2Check[0] AND $Share2Check[$i] = $SplitFolder[$i] Then
				JoinPath($ShareName, $SplitFolder, $i+1)
				Return True
			EndIf
		Next
EndFunc

Func JoinPath($ShareName, $SplitFolder, $FromSubfolder)
;Determine full network path
	$NetworkPath = @ComputerName & "\" & $ShareName
	For $i = $FromSubFolder to $SplitFolder[0]
		$NetworkPath = $Networkpath & "\" & $SplitFolder[$i]
	Next
;Send the network path to XBMC
		Play("smb://" & $NetworkPath)
EndFunc

;----- Communication with XBMC -----

Func ClearPlaylist($Path)
;Set active playlist to media type of first file in $Path
	SendCommand("SetCurrentPlaylist",WhichPlaylist($Path[1]))
;Clear active playlist
	SendCommand("ClearPlaylist","")
EndFunc

Func Play($Parameter)
;Check whether to queue or play the file
	If $Queue = 1 Then
		$Command = "AddToPlayList"
		$Parameter = $Parameter & ";" & WhichPlaylist($Parameter)
	Else
		$Command = "PlayFile"
	EndIf
	SendCommand($Command, $Parameter)
EndFunc

Func WhichPlaylist($Parameter)
;Determine whether to use the XBMC audio or video playlist
	$Ext = StringSplit($Parameter,".")
	$Ext = "*." & $Ext[$Ext[0]] & ";"
	If StringInStr($AudioExt,$Ext) Then
		Return 0
	ElseIf StringInStr($VideoExt,$Ext) Then
		Return 1
	EndIf
EndFunc

Func PlayFirst($Path)
;Set media at playlist position 0 and play
	SendCommand("SetPlaylistSong","0")
EndFunc

Func SendCommand($Command, $Parameter)
;Construct full URL to send command to XBMC
	$URL = "http://" & $XboxIP & "/xbmcCmds/xbmcHttp?command=" & $Command & "&parameter=" & SyntaxURL($Parameter)
	$oHTTP.Open("GET",$URL)
	$oHTTP.Send()
;Abort current task if network error occurred
	If $ErrorOccurred Then
		$ErrorOccurred = 0
;If failed, present error message retrieved from XBMC
	ElseIf NOT StringInStr($oHTTP.Responsetext, "OK") Then
		$ResponseText = StringTrimRight(StringTrimLeft(StringReplace($oHTTP.Responsetext,"<li>",""),6),8)
		MsgBox(48,"send2XBMC - " & $Command,"Problem while sending command to XBMC(" & $XboxIP & ")" & @LF & _
		"URL: " & $Parameter & @LF & "As sent to XBMC: " & SyntaxURL($Parameter) & @LF & @LF & "Error message returned by XBMC:" & @LF & $ResponseText)
	EndIf
EndFunc

Func SyntaxURL($URL)
	Dim $NewURL
	For $i = 1 to StringLen($URL)
		$NewChar = StringMid($URL,$i,1)
;Substitute slashes for backslashes in SMB shares
		If $NewChar = "\" Then
			$NewChar = "/"
		ElseIf NOT StringIsAlNum($NewChar) Then
;Substitute hexadecimals for non-alphanumeric characters in URL
			$NewChar = "%" & Hex(Asc($NewChar),2)
		EndIf
		$NewURL = $NewURL & $NewChar
	Next
	Return $NewURL
EndFunc

Func ErrorHandling()
;If this function is called upon, the COM Object $oHTTP had some problems
	If MsgBox(52,"send2XBMC - " & $oError.source,"Cannot connect to your Xbox (" & $XboxIP & ") or network connection is lost." & @LF & _
	"Error message: " & $oError.description & @LF & "Do you want to abort further operations?") = 6 Then Exit
	$ErrorOccurred = 1
EndFunc

;----- Integration functions -----

Func SendTo($SendToDir)
;Place shortcuts in SendTo folder for  user
	If $SendToDir = "" Then $SendToDir = RegRead("HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders","SendTo")
	If Not FileExists($SendToDir) Then
		$SendToDir = FileSelectFolder("Can't find you SendTo Folder. Choose it below...","",6,@UserProfileDir)
		If @error = 1 Then Exit
		Return SendTo($SendToDir)
	Else
		$Result = MsgBox(36,"send2XBMC","Do you want to add send2XBMC items to the ""Send to"" Explorer context menu?")
		If $Result = 6 Then
			AddSendTo($SendToDir)
		Else
			DelSendTo($SendToDir)
		EndIf
	EndIf
EndFunc

Func AddSendTo($SendToDir)
	$Result = 0
	$Result += FileCreateShortcut(@ScriptFullPath,$SendToDir & "\send2XBMC - Play now.lnk")
	$Result += FileCreateShortcut(@ScriptFullPath,$SendToDir & "\send2XBMC - Add to playlist.lnk","","/add")
	If $Result = 2 Then
		MsgBox(64,"send2XBMC - ""Send to"" Shell Extension","Entries in ""Send to"" Explorer context menu have been added.")
	Else
		ShellExecute($SendToDir)
		MsgBox(262192,"send2XBMC - ""Send to"" Shell Extension","An error occurred while trying to create the shortcuts for the ""Send To"" context menu.")
	EndIf
EndFunc

Func DelSendTo($SendToDir)
	FileDelete($SendToDir & "\send2XBMC - Play now.lnk")
	FileDelete($SendToDir & "\send2XBMC - Add to playlist.lnk")
	$Result = 0
	$Result += FileExists($SendToDir & "\send2XBMC - Play now.lnk")
	$Result += FileExists($SendToDir & "\send2XBMC - Add to playlist.lnk")
	If $Result = 0 Then
		MsgBox(64,"send2XBMC - ""Send to"" Shell Extension","Entries have been removed from Explorer ""Send to"" context menu.")
	Else
		ShellExecute($SendToDir)
		MsgBox(262192,"send2XBMC - ""Send to"" Shell Extension","Could not remove the shortcuts from the ""SendTo"" folder." & @LF & "Please try to remove them manually.")
	EndIf
EndFunc

Func ShellExt()
	$Result = MsgBox(36,"send2XBMC","Do you want to add the send2XBMC Explorer context menu items?")
	If $Result = 6 Then
		AddShellExt()
	Else
		DelShellExt()
	EndIf
EndFunc

Func AddShellExt()
	$ExtType = MsgBox(35,"send2XBMC - Shell Extension","This will put send2XBMC in the Explorer context menu." & @LF & @LF & _
	"Do you want to install the shell extension for all users?" & @LF & "Yes = Shell extension for all users (you need Administrator privileges)" & _
	@LF & "No = Shell extension for current user only")
	If $ExtType = 6 Then
;Insert registry keys for all users
		$HKey = "HKLM\"
	ElseIf $ExtType = 7 Then
;Insert registry keys for current user
		$HKey = "HKCU\"
	Else
		Exit
	EndIf
;Registry values to be added
	Dim $Keys[8][2]
	$Keys[0][0] = "Software\Classes\*\shell\send2XBMC-Play"
	$Keys[0][1] = "send2XBMC - Play now"
	$Keys[1][0] = "Software\Classes\*\shell\send2XBMC-Play\command"
	$Keys[1][1] = """" & @ScriptFullPath & """ ""%1"""
	$Keys[2][0] = "Software\Classes\*\shell\send2XBMC-Queue"
	$Keys[2][1] = "send2XBMC - Add to playlist"
	$Keys[3][0] = "Software\Classes\*\shell\send2XBMC-Queue\command"
	$Keys[3][1] = """" & @ScriptFullPath & """ /add ""%1"""
	$Keys[4][0] = "Software\Classes\Directory\shell\send2XBMC-Play"
	$Keys[4][1] = "send2XBMC - Play now"
	$Keys[5][0] = "Software\Classes\Directory\shell\send2XBMC-Play\command"
	$Keys[5][1] = """" & @ScriptFullPath & """ ""%1"""
	$Keys[6][0] = "Software\Classes\Directory\shell\send2XBMC-Queue"
	$Keys[6][1] = "send2XBMC - Add to playlist"
	$Keys[7][0] = "Software\Classes\Directory\shell\send2XBMC-Queue\command"
	$Keys[7][1] = """" & @ScriptFullPath & """ /add ""%1"""
;Add the keys and values to registry
	$Error = ""
	For $i = 0 to UBound($Keys) - 1
		If NOT RegWrite($HKey & $Keys[$i][0],"","REG_SZ",$Keys[$i][1]) Then $Error = $Error & $Keys[$i][0] & @LF
	Next
	If $Error <> "" Then
		MsgBox(48,"send2XBMC - Shell Extension","Could not write to the following registry keys:" & @LF & @LF & $Error)
	Else
		MsgBox(64,"send2XBMC - Shell Extension","Entries in Explorer context menu have been added.")
	EndIf
EndFunc

Func DelShellExt()
;Registry keys to be deleted
	Dim $Keys[8]
	$Keys[0] = "HKLM\Software\Classes\*\shell\send2XBMC-Play"
	$Keys[1] = "HKLM\Software\Classes\*\shell\send2XBMC-Queue"
	$Keys[2] = "HKLM\Software\Classes\Directory\shell\send2XBMC-Play"
	$Keys[3] = "HKLM\Software\Classes\Directory\shell\send2XBMC-Queue"
	$Keys[4] = "HKCU\Software\Classes\*\shell\send2XBMC-Play"
	$Keys[5] = "HKCU\Software\Classes\*\shell\send2XBMC-Queue"
	$Keys[6] = "HKCU\Software\Classes\Directory\shell\send2XBMC-Play"
	$Keys[7] = "HKCU\Software\Classes\Directory\shell\send2XBMC-Queue"

;Delete the keys from registry
	$Error = ""
	For $i = 0 to UBound($Keys) - 1
		RegDelete($Keys[$i])
		If @error < 0 Then $Error = $Error & $Keys[$i] & @LF
	Next
	If $Error <> "" Then
		MsgBox(48,"send2XBMC - Shell Extension","Could not remove the following registry entries:" & @LF & @LF & $Error)
	Else
		MsgBox(64,"send2XBMC - Shell Extension","Entries have been removed from Explorer context menu.")
	EndIf
EndFunc

Func FindOperaIni($OperaDir)
	If $OperaDir = "#error#" Then $OperaDir = "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
	$OperaMenuFile = FileOpenDialog("send2XBMC - Select Opera (standard_menu).ini file...",$OperaDir,"Opera Menu (*.ini)",3,"standard_menu.ini")
	If NOT FileExists($OperaMenuFile) Then
		MsgBox(48,"send2XBMC - Opera Context Menu","No file selected or file cannot be opened.")
		Exit
	EndIf
	Return $OperaMenuFile
EndFunc

Func GetOperaPath()
;Determine initial directory for menu.ini
	$OperaDir = RegRead("HKCU\Software\Opera Software","Last CommandLine v2")
	If $OperaDir = "" Then FindOperaIni("#error#")
	$OperaDir = StringLeft($OperaDir,StringInStr($OperaDir,"\opera.exe"))
	If IniRead($OperaDir & "\operaprefs_default.ini","System","Multi User","1") = 0 Then
		$OperaMenuFile = IniRead($OperaDir & "\profile\operaprefs.ini","User Prefs","Menu Configuration","#error#")
	Else
		$OperaMenuFile = IniRead(@AppDataDir & "\Opera\Opera\operaprefs.ini","User Prefs","Menu Configuration","#error#")
	EndIf
	If $OperaMenuFile = "#error#" Then $OperaMenuFile = FindOperaIni(@AppDataDir)
	If StringInStr($OperaMenuFile,"{LargePrefs}") Then $OperaMenuFile = StringReplace($OperaMenuFile,"{LargePrefs}","")
	If StringInStr($OperaMenuFile,"{SmallPreferences}") Then $OperaMenuFile = StringReplace($OperaMenuFile,"{SmallPreferences}","")
	If Not StringInStr($OperaMenuFile,":\") Then $OperaMenuFile = $OperaDir & "Profile\" & $OperaMenuFile
	If Not FileExists($OperaMenuFile) Then
		If IniRead($OperaDir & "\operaprefs_default.ini","System","Multi User","1") = 0 Then
			$OperaMenuFile = FindOperaIni($OperaDir)
		Else
			$OperaMenuFile = FindOperaIni(@AppDataDir)
		EndIf
	EndIf
	Return $OperaMenuFile
EndFunc

Func OperaContext()
	$Result = MsgBox(36,"send2XBMC","Do you want to add the send2XBMC to Opera context menu?")
	If $Result = 6 Then
		AddOperaContext()
	Else
		DelOperaContext()
	EndIf
EndFunc

Func AddOperaContext()
$OperaMenuFile = GetOperaPath()
;Sections to which key will be added
	Dim $Sections[2][4]
	$Sections[0][0] = "Link Popup Menu"
	$Sections[0][1] = "Link Selection Popup Menu"
	$Sections[0][2] = "Image Link Popup Menu"
	$Sections[0][3] = "Hotclick Popup Menu"
	$Sections[1][0] = "Readonly Edit Widget Popup Menu"
	$Sections[1][1] = "Edit Widget Popup Menu"
	$Sections[1][2] = "Edit Go Widget Popup Menu"
	$Sections[1][3] = "Edit Widget Insert Menu"
;The two different types of values for the keys: [0] = link and [1] = highlighted text)
	Dim $Keys[2][2]
	$Keys[0][0] = "Execute program,""" & @ScriptFullPath & """,""%l"""
	$Keys[0][1] = "Execute program,""" & @ScriptFullPath & """,""/add %l"""
	$Keys[1][0] = "Copy & Execute program,""" & @ScriptFullPath & """,""%c"""
	$Keys[1][1] = "Copy & Execute program,""" & @ScriptFullPath & """,""/add %c"""
;Add keys to sections defined
	$Error = ""
	For $i = 0 to UBound($Sections) - 1
		For $j = 0 to UBound($Sections, 2) - 1
			If NOT IniWrite($OperaMenuFile,$Sections[$i][$j],"Item, ""send2XBMC - Play now""",$Keys[$i][0]) Then $Error = $Error & $Sections[$i][$j] & @LF
			If NOT IniWrite($OperaMenuFile,$Sections[$i][$j],"Item, ""send2XBMC - Add to playlist""",$Keys[$i][1]) Then $Error = $Error & $Sections[$i][$j] & @LF
		Next
	Next
	If $Error <> "" Then
		MsgBox(48,"send2XBMC - Opera Context Menu","Could not write to the following sections:" & @LF & @LF & _
		$Error & @LF & "File is probably read-only.")
	Else
		MsgBox(64,"send2XBMC - Opera Context Menu","Opera context menu entries have been added to"&@LF&$OperaMenuFile)
	EndIf
EndFunc

Func DelOperaContext()
$OperaMenuFile = GetOperaPath()
	Dim $Sections[8]
	$Sections[0] = "Link Popup Menu"
	$Sections[1] = "Link Selection Popup Menu"
	$Sections[2] = "Image Link Popup Menu"
	$Sections[3] = "Hotclick Popup Menu"
	$Sections[4] = "Readonly Edit Widget Popup Menu"
	$Sections[5] = "Edit Widget Popup Menu"
	$Sections[6] = "Edit Go Widget Popup Menu"
	$Sections[7] = "Edit Widget Insert Menu"
;Remove keys from sections defined
	$Error = ""
	For $i = 0 to UBound($Sections) - 1
		If NOT IniDelete($OperaMenuFile,$Sections[$i],"Item, ""send2XBMC - Play now""") Then $Error = $Error & $Sections[$i] & @LF
		If NOT IniDelete($OperaMenuFile,$Sections[$i],"Item, ""send2XBMC - Add to playlist""") Then $Error = $Error & $Sections[$i] & @LF
	Next
	If $Error <> "" Then
		MsgBox(48,"send2XBMC - Opera Context Menu","Could not remove the following sections:" & @LF & @LF & _
		$Error & @LF & "File is probably read-only.")
	Else
		MsgBox(64,"send2XBMC - Opera Context Menu","Opera context menu entries have been removed from"&@LF&$OperaMenuFile)
	EndIf
EndFunc

Main()