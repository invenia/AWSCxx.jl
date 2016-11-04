# run `julia gen_headers.jl /usr/local/include/aws generate headers.jl`

import Base.Filesystem: pathsep

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

function main()
    aws_include_path = ARGS[1]
    command = lowercase(ARGS[2])

    if command == "print"
        for header_list in values(aws_headers(aws_include_path))
            for header in header_list
                println("#include <$header>")
            end
        end
    elseif command == "generate"
        output_file = get(ARGS, 3, joinpath(dirname(@__FILE__), "headers.jl"))

        println("AWS: $aws_include_path")
        println("Action: $command")
        println("Output file: $output_file")
        println()

        open(output_file, "w") do fp

            println(fp, "const FEATURE_HEADERS = Dict(")
            for (feature, header_list) in aws_headers(aws_include_path)
                println(fp, "\t\"$feature\" => [", )
                for header in header_list
                    println(fp, "\t\t\"$header\",")
                end
                println(fp, "\t],", )
            end
            println(fp, ")")
        end

        println("Done")
    else
        error("Unknown command '$command'")
    end
end

main()
