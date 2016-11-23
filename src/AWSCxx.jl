module AWSCxx

export AWSClient, AWSFeatures, AWSError, AWSOutcome

include("common.jl")
include("strings.jl")
include("client.jl")
include("features.jl")
include("outcomes.jl")

using .AWSFeatures

function __init__()
    AWSFeatures.load("core")
    AWSClient()
end

end # module
