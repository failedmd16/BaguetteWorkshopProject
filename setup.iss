[Setup]
AppId={{3D3F0125-E137-4F43-9FAA-DBADD5BCBEE6}

AppName=BaguetteWorkShop
AppVersion=1.0
AppPublisher=Baguette Corp

DefaultDirName={autopf}\BaguetteWorkShop
DefaultGroupName=BaguetteWorkShop

OutputDir=Output
OutputBaseFilename=BaguetteSetup

SetupIconFile=project\images\icon.ico

; Сжатие
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "build\appproject.exe"; DestDir: "{app}"; Flags: ignoreversion

Source: "build\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\BaguetteWorkShop"; Filename: "{app}\appproject.exe"; IconFilename: "{app}\appproject.exe"
Name: "{group}\{cm:UninstallProgram,BaguetteWorkShop}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\BaguetteWorkShop"; Filename: "{app}\appproject.exe"; IconFilename: "{app}\appproject.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\appproject.exe"; Description: "{cm:LaunchProgram,BaguetteWorkShop}"; Flags: nowait postinstall skipifsilent

[INI]
Filename: "{app}\config.ini"; Section: "Database"; Key: "Host"; String: "pg4.sweb.ru"
Filename: "{app}\config.ini"; Section: "Database"; Key: "Port"; String: "5433"
Filename: "{app}\config.ini"; Section: "Database"; Key: "Name"; String: "failedmd16"
Filename: "{app}\config.ini"; Section: "Database"; Key: "User"; String: "failedmd16"
Filename: "{app}\config.ini"; Section: "Database"; Key: "Password"; String: "Bagetworkshop123"