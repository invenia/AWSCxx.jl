module AWSFeatures

import Base.Libdl: dlext

using Cxx


# includes `const AWS_LIBDIR::String` and `const AWS_INCLUDEDIR::String`
include(joinpath(dirname(dirname(@__FILE__)), "deps", "paths.jl"))

addHeaderDir(AWS_INCLUDEDIR, kind=C_System)
push!(Libdl.DL_LOAD_PATH, AWS_LIBDIR)

# includes `const FEATURE_HEADERS::Dict{String, Vector{String}}`
include(joinpath(dirname(@__FILE__), "..", "deps", "headers.jl"))

function aws_feature_lib(feature::AbstractString)
    return "libaws-cpp-sdk-$(lowercase(feature)).$dlext"
end

type Feature
    name::String
    libraries::Vector{String}
    headers::Vector{String}
    dependencies::Vector{Feature}
    loaded::Bool
end

function Feature(
    name::String;
    headers::Vector{String}=String[],
    dependencies::Vector{Feature}=Feature[]
)
    return Feature(
        name,
        [aws_feature_lib(name)],
        FEATURE_HEADERS[name],
        dependencies,
        false,
    )
end

function Base.show{T<:Feature}(io::IO, f::T)
    Base.print(io, T, "(\"", f.name, "\")")
end

const FEATURES = Dict{String, Feature}()

for feature in keys(FEATURE_HEADERS)
    FEATURES[feature] = Feature(feature)
end

function load(f::Feature)
    if !f.loaded
        for header in f.headers
            # println("Including <$header>")
            # cxxinclude(header; isAngled=true)
            eval(Cxx.process_cxx_string("#include <$header>", true, false))
        end

        for library in f.libraries
            Libdl.dlopen(joinpath(AWS_LIBDIR, library), Libdl.RTLD_LAZY | Libdl.RTLD_DEEPBIND | Libdl.RTLD_GLOBAL)
        end

        f.loaded = true
    end

    f
end

load(f::String) = load(FEATURES[f])

end
