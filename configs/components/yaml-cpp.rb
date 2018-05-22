component "yaml-cpp" do |pkg, settings, platform|
  pkg.url "git@github.com:jbeder/yaml-cpp.git"
  pkg.ref "refs/tags/yaml-cpp-0.6.2"

  # Build Requirements
  if platform.is_cross_compiled_linux?
    pkg.build_requires "pl-binutils-#{platform.architecture}"
    pkg.build_requires "pl-gcc-#{platform.architecture}"
    pkg.build_requires "pl-cmake"
  elsif platform.is_solaris?
    if platform.os_version == "10"
      pkg.build_requires "http://pl-build-tools.delivery.puppetlabs.net/solaris/10/pl-gcc-4.8.2-8.#{platform.architecture}.pkg.gz"
      pkg.build_requires "http://pl-build-tools.delivery.puppetlabs.net/solaris/10/pl-binutils-2.27-1.#{platform.architecture}.pkg.gz"
      pkg.build_requires "http://pl-build-tools.delivery.puppetlabs.net/solaris/10/pl-cmake-3.2.3-15.i386.pkg.gz"
    elsif platform.os_version == "11"
      pkg.build_requires "pl-binutils-#{platform.architecture}"
      pkg.build_requires "pl-gcc-#{platform.architecture}"
      pkg.build_requires "pl-cmake"
    end
  elsif platform.is_windows?
    pkg.build_requires "pl-toolchain-#{platform.architecture}"
    pkg.build_requires "cmake"
  elsif platform.is_macos?
    pkg.build_requires "cmake"
  elsif platform.is_aix?
    pkg.build_requires "http://pl-build-tools.delivery.puppetlabs.net/aix/#{platform.os_version}/ppc/pl-gcc-5.2.0-1.aix#{platform.os_version}.ppc.rpm"
    pkg.build_requires "http://pl-build-tools.delivery.puppetlabs.net/aix/#{platform.os_version}/ppc/pl-cmake-3.2.3-2.aix#{platform.os_version}.ppc.rpm"
  else
    pkg.build_requires "pl-gcc"
    pkg.build_requires "make"
    pkg.build_requires "pl-cmake"
  end

  # Build-time Configuration
  cmake = "#{settings[:tools_root]}/bin/cmake"
  cmake_toolchain_file = "-DCMAKE_TOOLCHAIN_FILE=#{settings[:tools_root]}/pl-build-toolchain.cmake"
  make = 'make'
  mkdir = 'mkdir'

  if platform.is_cross_compiled_linux?
    # We're using the x86_64 version of cmake
    cmake = "/opt/pl-build-tools/bin/cmake"
    cmake_toolchain_file = "-DCMAKE_TOOLCHAIN_FILE=#{settings[:tools_root]}/aarch64-redhat-linux/pl-build-toolchain.cmake"
  elsif platform.is_solaris?
    # We always use the i386 build of cmake, even on sparc
    cmake = "/opt/pl-build-tools/i386-pc-solaris2.#{platform.os_version}/bin/cmake"
    pkg.environment "PATH" => "$$PATH:/opt/csw/bin"
  elsif platform.is_macos?
    cmake_toolchain_file = ""
    cmake = "/usr/local/bin/cmake"
  elsif platform.is_windows?
    make = "#{settings[:gcc_bindir]}/mingw32-make"
    mkdir = '/usr/bin/mkdir'
    pkg.environment "PATH", "$(shell cygpath -u #{settings[:gcc_bindir]}):$(shell cygpath -u #{settings[:ruby_bindir]}):/cygdrive/c/Windows/system32:/cygdrive/c/Windows:/cygdrive/c/Windows/System32/WindowsPowerShell/v1.0"
    pkg.environment "CYGWIN", settings[:cygwin]
    cmake = "C:/ProgramData/chocolatey/bin/cmake.exe -G \"MinGW Makefiles\""
    cmake_toolchain_file = "-DCMAKE_TOOLCHAIN_FILE=#{settings[:tools_root]}/pl-build-toolchain.cmake"
  end

  # Build Commands
  pkg.build do
    [ "#{mkdir} build-shared",
      "cd build-shared",
      "#{cmake} \
      #{cmake_toolchain_file} \
      -DCMAKE_INSTALL_PREFIX=#{settings[:prefix]} \
      -DCMAKE_VERBOSE_MAKEFILE=ON \
      -DYAML_CPP_BUILD_TOOLS=0 \
      -DYAML_CPP_BUILD_TESTS=0 \
      -DBUILD_SHARED_LIBS=ON \
      .. ",
      "#{make} VERBOSE=1 -j$(shell expr $(shell #{platform[:num_cores]}) + 1)",
      "cd ../",
      "#{mkdir} build-static",
      "cd build-static",
      "#{cmake} \
      #{cmake_toolchain_file} \
      -DCMAKE_INSTALL_PREFIX=#{settings[:prefix]} \
      -DCMAKE_VERBOSE_MAKEFILE=ON \
      -DYAML_CPP_BUILD_TOOLS=0 \
      -DYAML_CPP_BUILD_TESTS=0 \
      -DBUILD_SHARED_LIBS=OFF \
      ..",
      "#{make} VERBOSE=1 -j$(shell expr $(shell #{platform[:num_cores]}) + 1)"
    ]
  end

  pkg.install do
    [ "cd build-shared",
      "#{make} install",
      "cd ../build-static",
      "#{make} install"
    ]
  end
end