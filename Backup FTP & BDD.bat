@echo off
REM Il faut avoir wget et 7zip en variable d'environnement
REM wget : https://eternallybored.org/misc/wget/
REM 7z : https://www.7-zip.org/download.html

title Sauvegarde

REM Démarrage du PHP (À modifié !!)
cmd /C start http://localhost/sauvegarde/backup_bdd.php

timeout 1

REM Temps
set Annee=%DATE:~6,4%
set Mois=%DATE:~3,2%
set Jour=%DATE:~0,2%
set Heure=%TIME:~0,2%
set Minutes=%TIME:~3,2%
set Secondes=%TIME:~6,2%

if %Heure% LSS 10 set Heure=0%TIME:~1,1%

REM Nom du fichier de la sauvegarde
set fichier_name=save%Annee%%Mois%%Jour%%Heure%%Minutes%%Secondes%

REM Connexion FTP (À modifié !!)
SET FTP=127.0.0.1/
SET DossierARecupFTP=*
SET UTILISATEUR_FTP=test
SET MDP_FTP=test

REM Connexion SMTP (À modifié !!)
:: Si port=465 alors SSL=True
:: Si port=25 alors SSL=False
set Port=465
set SSL=True
set Par="envoie@test.com"
set A="recois@test.com"
set SMTPServer="smtp.test.test"
set User="envoie@test.com"
set Pass="votre_mot_de_passe"
set piecejointe=""

REM Chemin des sauvegardes (À modifié si nécessaire)
SET CHEMIN_BACKUP=C:\Sauv\%fichier_name%\
SET CHEMIN_ZIP_BACKUP=C:\Sauv\
SET DOSSIER_BACKUP_LOCAL="C:\Sauv"

REM Création et suppression des fichiers d'erreurs
IF NOT EXIST %CHEMIN_BACKUP% MKDIR %CHEMIN_BACKUP%
del /q %DOSSIER_BACKUP_LOCAL%\error_ftp.dat
del /q %DOSSIER_BACKUP_LOCAL%\error_zip.dat
del /q %DOSSIER_BACKUP_LOCAL%\error_bdd_export.dat

REM Connexion au FTP et récupére tout les dossiers du FTP
wget -r -P %CHEMIN_BACKUP% ftp://%UTILISATEUR_FTP%:%MDP_FTP%@%FTP%%DossierARecupFTP% 
if %ERRORLEVEL% NEQ 0 (
    title Sauvegarde - Erreur de connexion FTP
    color c
    echo Erreur : La connexion FTP a été refusé
    echo Erreur : La connexion FTP a été refusé > %DOSSIER_BACKUP_LOCAL%\error_ftp.dat
    rmdir /s /q %CHEMIN_BACKUP%
    del /s /q %DOSSIER_BACKUP_LOCAL%\%fichier_name%.zip
    goto ftpemail
)
REM Détecte si dans le FTP il y a un fichier nommé "error_bdd_export.dat"
wget -q --ftp-user=%UTILISATEUR_FTP% --ftp-password=%MDP_FTP% ftp://%FTP%/error_bdd_export.dat -O NUL 2>&1
if %ERRORLEVEL% EQU 0 (
    title Sauvegarde - Erreur d'exportation de base données
    color c
    echo Erreur : La base de données n'a pas pû s'exportée
    echo Erreur : La base de données n'a pas pû s'exportée > %DOSSIER_BACKUP_LOCAL%\error_bdd_export.dat
    rmdir /s /q %CHEMIN_BACKUP%
    del /s /q %DOSSIER_BACKUP_LOCAL%\%fichier_name%.zip
    goto bddemail
)

REM ZIP la totalité de la sauvegarde (Dossier FTP & Base de données)
7z a -tzip %CHEMIN_ZIP_BACKUP%\%fichier_name%.zip -r %CHEMIN_BACKUP%\*.*
if %ERRORLEVEL% NEQ 0 (
    title Sauvegarde - Erreur de zippage
    color c
    echo Erreur : La création du ZIP a été refusé
    echo Erreur : La création du ZIP a été refusé > %DOSSIER_BACKUP_LOCAL%\error_zip.dat
    rmdir /s /q %CHEMIN_BACKUP%
    del /s /q %DOSSIER_BACKUP_LOCAL%\%fichier_name%.zip
    goto zipemail
)

rmdir /s /q %CHEMIN_ZIP_BACKUP%\%fichier_name%

REM Le temps où les sauvegardes reste dans le disque (À modifié si nécessaire)
forfiles /p %DOSSIER_BACKUP_LOCAL% /s /d -7 /m *.* /c "cmd /c del @FILE" 
goto fin

REM Le sujet et l'objet du mail lors d'une erreur sur le FTP (À modifié si nécessaire)
:ftpemail
set Sujet="Sauvegarde refusée - FTP"
set Objet="Erreur : Accès FTP refusé"
goto sendemail

REM Le sujet et l'objet du mail lors d'une erreur sur la base de données (À modifié si nécessaire)
:bddemail
set Sujet="Sauvegarde refusée - BDD"
set Objet="Erreur : Exportation BDD refusé"
goto sendemail

REM Le sujet et l'objet du mail lors d'une erreur sur le ZIP (À modifié si nécessaire)
:zipemail
set Sujet="Sauvegarde refusée - ZIP"
set Objet="Erreur : Zippage refusé"
goto sendemail

REM Processus pour l'envoie de mail
:sendemail
if "%~7" NEQ "" (
set Par="%~1"
set A="%~2"
set Sujet="%~3"
set Objet="%~4"
set SMTPServer="%~5"
set User="%~6"
set Pass="%~7"
set piecejointe="%~8"
)
set "vbsfile=email-bat.vbs"
del "%vbsfile%" 2>nul
set cdoSchema=http://schemas.microsoft.com/cdo/configuration
echo >>"%vbsfile%" Set objArgs       = WScript.Arguments
echo >>"%vbsfile%" Set objEmail      = CreateObject("CDO.Message")
echo >>"%vbsfile%" objEmail.From     = %Par%
echo >>"%vbsfile%" objEmail.To       = %A%
echo >>"%vbsfile%" objEmail.Subject  = %Sujet%
echo >>"%vbsfile%" objEmail.Textbody = %Objet%
if exist %piecejointe% echo >>"%vbsfile%" objEmail.AddAttachment %piecejointe%
echo >>"%vbsfile%" with objEmail.Configuration.Fields
echo >>"%vbsfile%"  .Item ("%cdoSchema%/sendusing")        = 2 ' not local, smtp
echo >>"%vbsfile%"  .Item ("%cdoSchema%/smtpserver")       = %SMTPServer%
echo >>"%vbsfile%"  .Item ("%cdoSchema%/smtpserverport")   = %port%
echo >>"%vbsfile%"  .Item ("%cdoSchema%/smtpauthenticate") = 1 ' cdobasic
echo >>"%vbsfile%"  .Item ("%cdoSchema%/sendusername")     = %user%
echo >>"%vbsfile%"  .Item ("%cdoSchema%/sendpassword")     = %pass%
echo >>"%vbsfile%"  .Item ("%cdoSchema%/smtpusessl")       = %SSL%
echo >>"%vbsfile%"  .Item ("%cdoSchema%/smtpconnectiontimeout") = 30
echo >>"%vbsfile%"  .Update
echo >>"%vbsfile%" end with
echo >>"%vbsfile%" objEmail.Send
cscript.exe /nologo "%vbsfile%"
echo Email envoyé
del "%vbsfile%" 2>nul

:fin