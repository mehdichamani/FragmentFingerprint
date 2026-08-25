Set WshShell = CreateObject("WScript.Shell")
WshShell.CurrentDirectory = "C:\Users\Mehdi\projects\FragmentFingerprint"
WshShell.Run """C:\Users\Mehdi\projects\FragmentFingerprint\xray.exe""", 0, False
