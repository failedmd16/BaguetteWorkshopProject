; -- НАСТРОЙКИ ПУТЕЙ (Проверь эти строки!) --

; 1. Папка, где лежит готовый .exe и все DLL (результат windeployqt)
#define MyBuildFolder "C:\users\emil\desktop\Baguette"

; 2. Точное имя твоего .exe файла (проверь, как он называется в папке!)
#define MyAppExeName "appproject.exe"

; 3. Путь к иконке
#define MyIconPath "C:\college\projectQT\BaguetteWorkshopProject\project\images\icon.ico"

; -- Основные настройки приложения --
#define MyAppName "BaguetteWorkShop"
#define MyAppVersion "1.0"
#define MyAppPublisher "Baguette Corp"
#define MyAppId "{3D3F0125-E137-4F43-9FAA-DBADD5BCBEE6}"
#define MySetupName "BaguetteSetup"

[Setup]
; Уникальный ID (твой ключ)
AppId=#MyAppId

; Название приложения и версия
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}

; Папка установки по умолчанию (Program Files\BaguetteWorkShop)
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}

; -- КУДА СОХРАНИТЬ УСТАНОВЩИК --
; {userdesktop} означает твой Рабочий стол
OutputDir={userdesktop}
OutputBaseFilename={#MySetupName}

; Иконка для самого файла установщика
SetupIconFile={#MyIconPath}

; Сжатие
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; 1. Копируем сам EXE файл
Source: "{#MyBuildFolder}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

; 2. Копируем ВСЕ остальные файлы (dll, qml, папки images и т.д.)
; recursesubdirs - берет все подпапки
; createallsubdirs - создает такую же структуру папок
Source: "{#MyBuildFolder}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; Ярлык в меню Пуск
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
; Ярлык удаления
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
; Ярлык на рабочем столе
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; Запуск после установки
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
