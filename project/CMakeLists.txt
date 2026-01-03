cmake_minimum_required(VERSION 3.16)

project(project VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(Qt6 REQUIRED COMPONENTS Sql)
find_package(Qt6 REQUIRED COMPONENTS QuickControls2)
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS Concurrent)
find_package(Qt6 REQUIRED COMPONENTS Graphs)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appproject
    main.cpp
)

qt_add_qml_module(appproject
    URI project
    VERSION 1.0
    QML_FILES
        Main.qml
        pages/CustomersPage.qml
        pages/LoginPage.qml
        pages/AccountManagementPage.qml
        pages/MastersOrdersPage.qml
        pages/MastersProductsPage.qml
        pages/OrdersPage.qml
        pages/SalePage.qml
        pages/LogsPage.qml
        pages/CreateFirstAdminPage.qml
    RESOURCES
        SOURCES src/DatabaseManager.h SOURCES src/DatabaseManager.cpp
        SOURCES src/Logger.h SOURCES src/Logger.cpp
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appproject PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appproject
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appproject
    PRIVATE Qt6::Quick
    PRIVATE Qt6::Sql
    PRIVATE Qt6::QuickControls2
    PRIVATE Qt6::Core
    PRIVATE Qt6::Concurrent
    PRIVATE Qt6::Graphs
)

include(GNUInstallDirs)
install(TARGETS appproject
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
