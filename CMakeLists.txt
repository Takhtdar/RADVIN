cmake_minimum_required(VERSION 3.16)

project(Radvin_Qt VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS Widgets)

qt_standard_project_setup(REQUIRES 6.8)


set(SOURCES
    main.cpp
    src/clipboardListener.cpp
    src/databaseManager.cpp
    src/settingsManager.cpp
    src/networkManager.cpp
)

set(HEADERS
    src/clipboardListener.h
    src/databaseManager.h
    src/settingsManager.h
    src/networkManager.h
)

qt_add_executable(appRadvin_Qt
    ${SOURCES}
    ${HEADERS}
)

qt_add_qml_module(appRadvin_Qt
    URI Radvin_Qt
    VERSION 1.0

        SOURCES
        SOURCES
        QML_FILES UI/Desktop/Queue.qml
        QML_FILES UI/Desktop/Practice.qml
        QML_FILES UI/Desktop/Explorer.qml
        QML_FILES UI/Desktop/Settings.qml
        SOURCES src/ollamaProvider.h src/ollamaProvider.cpp
        QML_FILES UI/Desktop/ExploreProfile.qml

)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appRadvin_Qt PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appRadvin_Qt
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)


find_package(Qt6 REQUIRED COMPONENTS Widgets)
target_link_libraries(appRadvin_Qt PRIVATE Qt6::Widgets)

target_link_libraries(appRadvin_Qt PRIVATE Qt6::Quick)
target_link_libraries(appRadvin_Qt PRIVATE Qt6::Core)
find_package(Qt6 REQUIRED COMPONENTS Sql)
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS QuickControls2)
target_link_libraries(appRadvin_Qt PRIVATE Qt6::QuickControls2)


target_link_libraries(appRadvin_Qt PRIVATE Qt6::Sql)


target_link_libraries(appRadvin_Qt PRIVATE Qt6::Network)
target_link_libraries(appRadvin_Qt PRIVATE Qt6::Core)
target_link_libraries(appRadvin_Qt PRIVATE Qt6::Core)
target_link_libraries(appRadvin_Qt PRIVATE Qt6::Core)

include(GNUInstallDirs)
install(TARGETS appRadvin_Qt
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)


#       UI/Android/Home.qml
#       UI/Android/QueueReview.qml
#       UI/Android/Practice.qml
#       UI/Android/Settings.qml
#       UI/Android/WordProfile.qml

qt_add_resources(appRadvin_Qt
    PREFIX "/"
    FILES
        icons/book-green.svg
        icons/book-red.svg

        UI/Desktop/Home.qml
        UI/Desktop/Queue.qml
        UI/Desktop/Explorer.qml
        UI/Desktop/ExploreProfile.qml
        UI/Desktop/ExploreSentences.qml
        UI/Desktop/DropDownItem.qml
        UI/Desktop/ButtonItem.qml
        UI/Desktop/ExploreWords.qml
        UI/Desktop/Practice.qml
        UI/Desktop/Settings.qml
        UI/Desktop/CollapsibleSection.qml
        UI/Desktop/DynamicJsonViewer.qml

        UI/Shared/Main.qml
)


