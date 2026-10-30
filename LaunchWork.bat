@echo off
:: ============================================================
::  LaunchWork - opens iTrak facial rec and the Citrix page in Edge
::  NOTE: inside a .bat file every % in a link must be written %%
::
::  Watchlog's Ctrl+Alt+L opens these two pages itself now
::  (FaceUrl and CitrixUrl in settings.ini) and no longer runs this
::  file. It is only here for double-clicking.
::  The Bally / LNW apps (AlertGrid, SDS, CMP) are opened by
::  Watchlog from [StartOfShift] in settings.ini.
:: ============================================================

start "" msedge.exe "https://itrakappprod.olgnetwork.ca/iTrak/login.aspx" "https://apps.gcgaming.com/Citrix/GCGCWeb/"
