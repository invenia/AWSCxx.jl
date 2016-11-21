module AWSCxx

export AWSClient, AWSFeatures, AWSError, AWSOutcome

include("common.jl")
include("strings.jl")
include("client.jl")
include("features.jl")
include("outcomes.jl")

using .AWSFeatures

AWSFeatures.load("core")

end # module
