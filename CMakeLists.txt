cmake_minimum_required(VERSION 3.15)
project(Gh0s7H4x_Reconstructed LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(MSVC)
    add_compile_options(/W3 /O2 /GS- /GR-)
endif()

file(GLOB_RECURSE CPP_SOURCES "src/cpp/*.cpp")

add_library(gh0s7h4x SHARED ${CPP_SOURCES})

target_include_directories(gh0s7h4x PRIVATE "src/cpp")

target_link_libraries(gh0s7h4x PRIVATE opengl32 user32 gdi32)

set_target_properties(gh0s7h4x PROPERTIES
    PREFIX ""
    OUTPUT_NAME "gh0s7h4x"
)
