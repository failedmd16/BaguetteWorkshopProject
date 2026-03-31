[Setup]
; Уникальный ID (двойная скобка в начале обязательна для экранирования в Inno Setup)
AppId={{3D3F0125-E137-4F43-9FAA-DBADD5BCBEE6}

; Название приложения и версия
AppName=BaguetteWorkShop
AppVersion=1.0
AppPublisher=Baguette Corp

; Папка установки по умолчанию
DefaultDirName={autopf}\BaguetteWorkShop
DefaultGroupName=BaguetteWorkShop

; -- КУДА СОХРАНИТЬ УСТАНОВЩИК --
OutputDir=Output
OutputBaseFilename=BaguetteSetup

; Иконка для самого файла установщика
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
; 1. Копируем сам EXE файл (теперь берем из папки build)
Source: "build\appproject.exe"; DestDir: "{app}"; Flags: ignoreversion

; 2. Копируем ВСЕ остальные файлы (dll, qml, папки images и т.д.)
Source: "build\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; Ярлык в меню Пуск
Name: "{group}\BaguetteWorkShop"; Filename: "{app}\appproject.exe"; IconFilename: "{app}\appproject.exe"
; Ярлык удаления
Name: "{group}\{cm:UninstallProgram,BaguetteWorkShop}"; Filename: "{uninstallexe}"
; Ярлык на рабочем столе
Name: "{autodesktop}\BaguetteWorkShop"; Filename: "{app}\appproject.exe"; IconFilename: "{app}\appproject.exe"; Tasks: desktopicon

[Run]
; Запуск после установки
Filename: "{app}\appproject.exe"; Description: "{cm:LaunchProgram,BaguetteWorkShop}"; Flags: nowait postinstall skipifsilent