module AWSCxx

export AWSClient, AWSFeatures, AWSError, AWSOutcome
export aws_string, aws_string_map

include("common.jl")
include("features.jl")
include("client.jl")

AWSFeatures.load("core")

include("strings.jl")
include("maps.jl")
include("outcomes.jl")
include("vectors.jl")

using .AWSFeatures

function __init__()
    AWSFeatures.load("core")
    AWSClient()
end

end # module
