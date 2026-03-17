Option Explicit

Dim shell
Dim fso
Dim scriptDir
Dim cmdPath
Dim commitMessage
Dim command

Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
cmdPath = fso.BuildPath(scriptDir, "GitPushLatest.cmd")

If Not fso.FileExists(cmdPath) Then
  MsgBox "GitPushLatest.cmd wurde nicht gefunden:" & vbCrLf & cmdPath, vbCritical, "Git Push Latest"
  WScript.Quit 1
End If

commitMessage = InputBox("Commit-Message eingeben:", "Git Push Latest", "")

If Len(commitMessage) = 0 Then
  WScript.Quit 0
End If

command = "cmd.exe /k """ & cmdPath & """ """ & Replace(commitMessage, """", """""") & """"
shell.Run command, 1, False
