@echo off
:: ============================================================
::  LaunchWork - opens everything for the start of shift
::  NOTE: inside a .bat file every % in a link must be written %%
::
::  The Bally / LNW apps (AlertGrid, SDS, CMP) are no longer here.
::  Watchlog opens them itself from [StartOfShift] in
::  settings.ini, and finds them whatever the version number is.
::
::  Ctrl+Alt+L passes the Chrome profile folder for ChromeAccount
::  (settings.ini) as %1, so the Chrome sites open in that Google account.
::  OLG iTrak (facial rec) opens in Microsoft Edge on purpose.
::  Double-clicking this file opens them in Chrome's last used one.
:: ============================================================

set "CHROME=chrome.exe"
if not "%~1"=="" set "CHROME=chrome.exe --profile-directory="%~1""

:: --- Facial rec: OLG iTrak, in Edge ---
start "" msedge.exe "https://itrakappprod.olgnetwork.ca/iTrak/login.aspx"

:: --- Websites, in Chrome ---
start "" %CHROME% "https://apps.gcgaming.com/Citrix/GCGCWeb/"
start "" %CHROME% "https://scheduling.shorelinescasinos.com/ess/Default.aspx?#/roster"
start "" %CHROME% "https://gcgaming-my.sharepoint.com/:x:/r/personal/thineman_greatcanadian_com/Documents/Names%%20and%%20Photos%%20by%%20Department%%20Live.xlsx?d=w5d3e130f0b32404fa3f0f33c12832852&csf=1&web=1&e=qpnczl"
start "" %CHROME% "https://gamingintegrityontario.ca/GIO/"
start "" %CHROME% "https://gcgaming.sharepoint.com/sites/GTASurveillanceGroup/Surveillance%%20Training/Forms/AllItems.aspx?id=%%2Fsites%%2FGTASurveillanceGroup%%2FSurveillance%%20Training%%2FSurveillance%%20Folder%%2F02%%20%%2D%%20Link%%20Template%%2FBS%%20Quiz%%2Epdf&parent=%%2Fsites%%2FGTASurveillanceGroup%%2FSurveillance%%20Training%%2FSurveillance%%20Folder%%2F02%%20%%2D%%20Link%%20Template"
start "" %CHROME% "https://elvk.fa.ca3.oraclecloud.com/fscmUI/redwood/learner/learn/learn-landing?tab=myLearnExperience&pagesUseSessionStoredFilters=learning-landing"
