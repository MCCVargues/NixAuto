cmake_minimum_required(VERSION 3.21)
project(nixauto-shell VERSION 0.1.0 LANGUAGES CXX)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick)
qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(nixauto-shell src/main.cpp)

set(QML_FILES
    Main.qml
    Theme.qml
    ClockPane.qml
    AppDrawer.qml
    AppTile.qml
)

# Alias qml/Foo.qml to the module root. Otherwise each file's implicit
# directory import (".../Shell/qml/") would see Theme.qml as a plain type and
# shadow the module's singleton, leaving every Theme.* undefined.
list(TRANSFORM QML_FILES PREPEND qml/ OUTPUT_VARIABLE QML_SOURCES)
foreach(file IN LISTS QML_FILES)
    set_source_files_properties(qml/${file} PROPERTIES QT_RESOURCE_ALIAS ${file})
endforeach()
set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(nixauto-shell
    URI NixAuto.Shell
    VERSION 1.0
    QML_FILES ${QML_SOURCES}
)

target_link_libraries(nixauto-shell PRIVATE Qt6::Quick)

install(TARGETS nixauto-shell RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
