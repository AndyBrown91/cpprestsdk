# Extremely basic implementation to get things going on Unix systems without boost
# requires OpenSSL to have been found and added as a library named "openssl"

function(add_cpprest)
    
    set(cpprestsdk_src ${CMAKE_SOURCE_DIR}/Release/src)
    set(cpprestsdk_inc ${CMAKE_SOURCE_DIR}/Release/include)

    file(GLOB HEADERS_CPPREST "${cpprestsdk_inc}/cpprest/*.h" "${cpprestsdk_inc}/cpprest/*.hpp" "${cpprestsdk_inc}/cpprest/*.dat")
    file(GLOB HEADERS_PPLX "${cpprestsdk_inc}/pplx/*.h" "${cpprestsdk_inc}/pplx/*.hpp")
    file(GLOB HEADERS_DETAILS "${cpprestsdk_inc}/cpprest/details/*.h" "${cpprestsdk_inc}/cpprest/details/*.hpp" "${cpprestsdk_inc}/cpprest/details/*.dat" "${cpprestsdk_inc}/pplx/*.hpp" "${cpprestsdk_inc}/pplx/*.dat")

    file(GLOB HEADER_PPLX_THREADPOOL "${cpprestsdk_inc}/pplx/threadpool.h")
    list(REMOVE_ITEM HEADERS_PPLX ${HEADER_PPLX_THREADPOOL})

    set(SOURCES
        ${HEADERS_CPPREST}
        ${HEADERS_PPLX}
        ${HEADERS_DETAILS}
        ${cpprestsdk_src}/pch/stdafx.h
        ${cpprestsdk_src}/http/client/http_client.cpp
        ${cpprestsdk_src}/http/client/http_client_impl.h
        ${cpprestsdk_src}/http/client/http_client_msg.cpp
        ${cpprestsdk_src}/http/common/connection_pool_helpers.h
        ${cpprestsdk_src}/http/common/http_compression.cpp
        ${cpprestsdk_src}/http/common/http_helpers.cpp
        ${cpprestsdk_src}/http/common/http_msg.cpp
        ${cpprestsdk_src}/http/common/internal_http_helpers.h
        ${cpprestsdk_src}/http/listener/http_listener.cpp
        ${cpprestsdk_src}/http/listener/http_listener_msg.cpp
        ${cpprestsdk_src}/http/listener/http_server_api.cpp
        ${cpprestsdk_src}/http/listener/http_server_impl.h
        ${cpprestsdk_src}/http/oauth/oauth1.cpp
        ${cpprestsdk_src}/http/oauth/oauth2.cpp
        ${cpprestsdk_src}/json/json.cpp
        ${cpprestsdk_src}/json/json_parsing.cpp
        ${cpprestsdk_src}/json/json_serialization.cpp
        ${cpprestsdk_src}/uri/uri.cpp
        ${cpprestsdk_src}/uri/uri_builder.cpp
        ${cpprestsdk_src}/utilities/asyncrt_utils.cpp
        ${cpprestsdk_src}/utilities/base64.cpp
        ${cpprestsdk_src}/utilities/web_utilities.cpp
    )

    add_library(cpprest)
    target_sources(cpprest PRIVATE ${SOURCES})
    target_include_directories(cpprest
      SYSTEM
      PRIVATE
        $<INSTALL_INTERFACE:include> $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
      PRIVATE
        pch
    )

    target_compile_definitions(cpprest PRIVATE
        CPPREST_EXCLUDE_BROTLI=1
    )

    #add_library(cpprest PRIVATE)
    target_include_directories(cpprest SYSTEM PUBLIC ${cpprestsdk_inc})
    target_include_directories(cpprest SYSTEM PUBLIC ${cpprestsdk_src}/pch)

    # PPLX component
    target_sources(cpprest PRIVATE 
        ${cpprestsdk_src}/pplx/threadpool.cpp
        ${cpprestsdk_inc}/pplx/threadpool.h
    )
    if(APPLE)
        find_library(COREFOUNDATION CoreFoundation "/")
        find_library(SECURITY Security "/")
        target_link_libraries(cpprest PRIVATE ${COREFOUNDATION} ${SECURITY})
        target_sources(cpprest PRIVATE 
            ${cpprestsdk_src}/pplx/pplx.cpp
            ${cpprestsdk_src}/pplx/pplxapple.cpp
        )
    elseif(UNIX AND NOT APPLE)
        target_sources(cpprest PRIVATE
            ${cpprestsdk_src}/pplx/pplx.cpp
            ${cpprestsdk_src}/pplx/pplxlinux.cpp
        )
    elseif(WIN32)
        target_sources(cpprest PRIVATE ${cpprestsdk_src}/pplx/pplxwin.cpp)
    endif()

    # Http client component
    if(WIN32)
        target_link_libraries(cpprest PRIVATE
            Winhttp.lib
        )
        target_sources(cpprest PRIVATE ${cpprestsdk_src}/http/client/http_client_winhttp.cpp)
    else()
        target_compile_definitions(cpprest PRIVATE -DCPPREST_FORCE_HTTP_CLIENT_ASIO)
        target_sources(cpprest PRIVATE ${cpprestsdk_src}/http/client/http_client_asio.cpp ${cpprestsdk_src}/http/client/x509_cert_utilities.cpp)
        target_include_directories(cpprest ${CMAKE_SOURCE_DIR}/Release/libs/asio/asio/include)
        target_link_libraries(cpprest PRIVATE openssl)
    endif()

    # fileio streams component
    if(WIN32)
        target_sources(cpprest PRIVATE ${cpprestsdk_src}/streams/fileio_win32.cpp)
    else()
        target_sources(cpprest PRIVATE ${cpprestsdk_src}/streams/fileio_posix.cpp)
    endif()

    # http listener component
    if(WIN32)
        target_sources(cpprest PRIVATE
            ${cpprestsdk_src}/http/listener/http_server_httpsys.cpp
            ${cpprestsdk_src}/http/listener/http_server_httpsys.h
        )
        target_link_libraries(cpprest PRIVATE
            httpapi.lib
        )
    else()
        target_compile_definitions(cpprest PRIVATE -DCPPREST_FORCE_HTTP_LISTENER_ASIO)
        target_sources(cpprest PRIVATE ${cpprestsdk_src}/http/listener/http_server_asio.cpp)
        target_include_directories(cpprest ${CMAKE_SOURCE_DIR}/Release/libs/asio/asio/include)
        target_link_libraries(cpprest PRIVATE openssl zlib)
    endif()

    target_compile_options(cpprest PRIVATE -Wno-everything)

    set_target_properties(cpprest PROPERTIES
        CXX_STANDARD 20
    )

endfunction()