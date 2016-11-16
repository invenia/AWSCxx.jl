using BinDeps

@BinDeps.setup

libaws = library_dependency("aws"; aliases=["libaws-cpp-sdk-core"])

if is_apple() && Pkg.installed("Homebrew") !== nothing
    using Homebrew
    provides(Homebrew.HB, "aws-sdk-cpp", libaws, os=:Darwin)
end

srcsubdir = "aws-sdk-cpp-master"

# provides(
#     Sources,
#     URI("https://github.com/aws/aws-sdk-cpp/archive/master.tar.gz"),
#     libaws,
#     unpacked_dir=srcsubdir,
# )

# CMAKE_OPTIONS = [
#     "-DCMAKE_BUILD_TYPE=Release",
#     "-DCMAKE_FIND_FRAMEWORK=LAST",
#     "-DCMAKE_INSTALL_PREFIX=$(BinDeps.usrdir(libaws))",
# ]
#
# provides(
#     BuildProcess,
#     (@build_steps begin
#         GetSources(libaws)
#         CreateDirectory(BinDeps.builddir(libaws))
#         @build_steps begin
#             ChangeDirectory(BinDeps.builddir(libaws))
#             FileRule(joinpath(BinDeps.libdir(libaws), "libaws-cpp-sdk-core.$(Libdl.dlext)"), @build_steps begin
#                 `cmake $CMAKE_OPTIONS $(joinpath(BinDeps.srcdir(libaws), srcsubdir))`
#                 `make -j$(Sys.CPU_CORES)`
#                 `make install`
#             end)
#         end
#     end),
#     libaws,
# )

# generate_headers_code()

@BinDeps.install Dict(:libaws=>:libaws)

installed_libaws = BinDeps._find_library(libaws)

include(joinpath(dirname(@__FILE__), "gen_headers.jl"))

# This used to be the first found installation and not the last.
# Due to libary search path weirdness, I switched to the last.
# The last will be the most system-y path, probably.
# Alternatively, we could error if there is more than one result from _find_library.
const AWS_LIBDIR = dirname(installed_libaws[end][2])
const AWS_INCLUDEDIR = joinpath(dirname(AWS_LIBDIR), "include")

generate_headers_code(joinpath(AWS_INCLUDEDIR, "aws"), joinpath(dirname(@__FILE__), "headers.jl"))

open(joinpath(dirname(@__FILE__), "paths.jl"), "w") do fp
    println(fp, "const AWS_LIBDIR = \"$AWS_LIBDIR\"")
    println(fp, "const AWS_INCLUDEDIR = \"$AWS_INCLUDEDIR\"")
end
