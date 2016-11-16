# run `julia gen_headers.jl /usr/local/include/aws generate headers.jl`

import Base.Filesystem: pathsep

using ArgParse

function splitdirs(path)
    stem, leaf = splitdir(path)

    if leaf == ""
        if stem == ""
            return ()
        else
            return (stem,)
        end
    else
        return (splitdirs(stem)..., leaf)
    end
end

function aws_headers(aws_include_path, feature)
    feature_path = abspath(realpath(joinpath(aws_include_path, feature)))

    headers = String[]

    for (root, dirs, files) in walkdir(feature_path)
        for file in files
            if endswith(file, ".h") && !endswith(file, "_EXPORTS.h")
                relative = relpath(joinpath(root, file), feature_path)

                push!(headers, "aws/$feature/$(join(splitdirs(relative), "/"))")
            end
        end
    end

    return headers
end

function aws_headers(aws_include_path)
    features = filter(x->isdir(joinpath(aws_include_path, x)), readdir(aws_include_path))

    feature_headers = Dict{String, Vector{String}}()

    for feature in features
        feature_headers[feature] = aws_headers(aws_include_path, feature)
    end

    return feature_headers
end

function generate_headers_code(aws_include_path, output_file)
    file_or_stdout(output_file) do fp
        println(fp, "const FEATURE_HEADERS = Dict(")
        for (feature, header_list) in aws_headers(aws_include_path)
            println(fp, "    \"$feature\" => [", )
            for header in header_list
                println(fp, "        \"$header\",")
            end
            println(fp, "    ],", )
        end
        println(fp, ")")
    end
end

function print_headers(aws_include_path, output_file)
    file_or_stdout(output_file) do fp
        for header_list in values(aws_headers(aws_include_path))
            for header in header_list
                println(fp, "#include <$header>")
            end
        end
    end
end

function file_or_stdout(func::Function, filepath::AbstractString)
    open(func, filepath, "w")
end

function file_or_stdout(func::Function, filepath::Void)
    func(STDOUT)
end

function argmain()
    settings = ArgParseSettings(
        description="parse, group, and process the headers from the AWS SDK for C++",
        autofix_names=true,
    )

    add_arg_table(settings,
        "aws_include_path", Dict(:required=>true, :arg_type=>String),
        "print", Dict(:action=>:command),
        "generate", Dict(:action=>:command),
        "--output_file", Dict(:required=>false, :arg_type=>String),
    )

    args = parse_args(settings)
    command = args["%COMMAND%"]

    if command == "print"
        print_headers(args["aws_include_path"], args["output_file"])
    elseif command == "generate"
        generate_headers_code(args["aws_include_path"], args["output_file"])
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    argmain()
end
