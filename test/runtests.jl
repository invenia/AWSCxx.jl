using AWSCxx
using Cxx
using ResultTypes
using Base.Test

@enum Scheme HTTP HTTPS

const PROXY_HOST = "127.0.0.1"
const PROXY_PORT = UInt(8080)
const PROXY_SCHEME = HTTP

function proxy_config(
    host::String=PROXY_HOST,
    port::UInt=PROXY_PORT,
    scheme::Scheme=PROXY_SCHEME
)
    clc = @cxx Aws::Client::ClientConfiguration()

    icxx"""
    $clc.proxyHost = $host;
    $clc.proxyPort = $port;
    """

    if scheme == HTTP
        icxx"""
        $clc.scheme = Aws::Http::Scheme::HTTP;
        """
    end

    return clc
end

type MotoServer
    proc::Base.Process
    perr::Pipe
end

function MotoServer(host::String=PROXY_HOST, port::UInt=PROXY_PORT)
    perr = Pipe()
    Base.link_pipe(perr, julia_only_read=true, julia_only_write=false)

    proc = spawn(pipeline(`moto_server --host $host --port $port`, stderr=perr))

    # we need this many bytes to know if the server is running or not based on output
    Base.wait_readnb(perr, 12)
    err_text = String(readavailable(perr))

    # checking two conditions because process_running might have a race condition?
    # it looked that way while testing
    if !process_running(proc) || !contains(err_text, "unning")
        # start reading async+blocking, then yield to the reading Task
        # this ensures we get everything when the pipe closes
        output = @async readstring(perr)
        close(perr)
        err_text *= wait(output)
        kill(proc)

        error("Failed to start a moto server:\n$err_text)")
    end

    m = MotoServer(proc, perr)
    finalizer(m, kill)

    return m
end

function Base.kill(m::MotoServer)
    if process_running(m.proc) && !process_exited(m.proc)
        close(m.perr)

        # without this check, there was an AssertionError: race condition?
        if m.proc.handle != C_NULL
            kill(m.proc, 2)  # SIGINT / CTRL+C
        end
    end

    nothing
end

# write your own tests here
@testset "error handling" begin
    AWSFeatures.load("s3")
    cl = AWSClient()

    s3_client = @cxxnew Aws::S3::S3Client()
    list_buckets_outcome = @cxx s3_client->ListBuckets()
    aws_raw_error = @cxx list_buckets_outcome->GetError()

    thetype = AWSCxx.CppAWSError{Symbol("Aws::S3::S3Errors"), Int32, (false, false, false)}

    @test typeof(aws_raw_error) <: thetype
    @test typeof(aws_raw_error) == thetype
    @test isa(aws_raw_error, thetype)
    # @test typeof(aws_raw_error) <: AWSCxx.CppAWSError
    # @test isa(aws_raw_error, AWSCxx.CppAWSError)
    @test AWSCxx.message(aws_raw_error) == ""
    aws_error = AWSError(aws_raw_error)
    @test AWSCxx.message(aws_error) == ""

    outcome = AWSOutcome(list_buckets_outcome)
    @test !iserror(outcome)
    result = unwrap(outcome)

    AWSCxx.shutdown(cl)
    nothing
end

@testset "mock" begin
    m = MotoServer()

    AWSFeatures.load("s3")

    cl = AWSClient()
    clc = proxy_config()
    s3_client = @cxxnew Aws::S3::S3Client(clc)

    outcome = AWSOutcome(@cxx s3_client->ListBuckets())
    @test !iserror(outcome)
    result = unwrap(outcome)
    buckets = @cxx result->GetBuckets()
    num_buckets = @cxx buckets->size()
    @test num_buckets == 0

    AWSCxx.shutdown(cl)
    kill(m)
end
