# Install script for directory: /Users/mohamadelhajhassan/netcoredbg/src

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/Users/mohamadelhajhassan/netcoredbg/bin")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

# Set path to fallback-tool for dependency-resolution.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/opt/homebrew/bin/llvm-objdump")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/Users/mohamadelhajhassan/netcoredbg/bin/netcoredbg")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/Users/mohamadelhajhassan/netcoredbg/bin" TYPE EXECUTABLE FILES "/Users/mohamadelhajhassan/netcoredbg/build/src/netcoredbg")
  if(EXISTS "$ENV{DESTDIR}/Users/mohamadelhajhassan/netcoredbg/bin/netcoredbg" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}/Users/mohamadelhajhassan/netcoredbg/bin/netcoredbg")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/usr/bin/strip" -u -r "$ENV{DESTDIR}/Users/mohamadelhajhassan/netcoredbg/bin/netcoredbg")
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  include("/Users/mohamadelhajhassan/netcoredbg/build/src/CMakeFiles/netcoredbg.dir/install-cxx-module-bmi-Release.cmake" OPTIONAL)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/Users/mohamadelhajhassan/netcoredbg/bin/ManagedPart.dll;/Users/mohamadelhajhassan/netcoredbg/bin/Microsoft.CodeAnalysis.dll;/Users/mohamadelhajhassan/netcoredbg/bin/Microsoft.CodeAnalysis.CSharp.dll;/Users/mohamadelhajhassan/netcoredbg/bin/Microsoft.CodeAnalysis.Scripting.dll;/Users/mohamadelhajhassan/netcoredbg/bin/Microsoft.CodeAnalysis.CSharp.Scripting.dll")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/Users/mohamadelhajhassan/netcoredbg/bin" TYPE FILE FILES
    "/Users/mohamadelhajhassan/netcoredbg/build/src/ManagedPart.dll"
    "/Users/mohamadelhajhassan/netcoredbg/build/src/Microsoft.CodeAnalysis.dll"
    "/Users/mohamadelhajhassan/netcoredbg/build/src/Microsoft.CodeAnalysis.CSharp.dll"
    "/Users/mohamadelhajhassan/netcoredbg/build/src/Microsoft.CodeAnalysis.Scripting.dll"
    "/Users/mohamadelhajhassan/netcoredbg/build/src/Microsoft.CodeAnalysis.CSharp.Scripting.dll"
    )
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/Users/mohamadelhajhassan/netcoredbg/bin/libdbgshim.dylib")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/Users/mohamadelhajhassan/netcoredbg/bin" TYPE FILE FILES "/Users/mohamadelhajhassan/netcoredbg/build/src/libdbgshim.dylib")
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
if(CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/Users/mohamadelhajhassan/netcoredbg/build/src/install_local_manifest.txt"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
