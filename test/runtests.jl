using AWSCxx
using Cxx
using ResultTypes
using MotoServer
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

function stringio(func::Function)
    io = IOBuffer()
    func(io)
    takebuf_string(io)
end

@testset "AWSCxx" begin
    @testset "two clients" begin
        cl = AWSClient()
        @test_throws AWSCxx.AWSCxxConcurrencyError AWSClient()
        AWSCxx.shutdown(cl)
    end

    @testset "error handling" begin
        @testset "success" begin
            MockAWSServer(; host=PROXY_HOST, port=PROXY_PORT, service="s3") do ms
                AWSFeatures.load("s3")

                cl = AWSClient()
                clc = proxy_config()
                s3_client = @cxxnew Aws::S3::S3Client(clc)

                list_buckets_outcome = @cxx s3_client->ListBuckets()
                aws_raw_error = @cxx list_buckets_outcome->GetError()

                thetype = AWSCxx.CppAWSError{Symbol("Aws::S3::S3Errors"), Int32, (false, false, false)}

                @test typeof(aws_raw_error) <: thetype
                @test typeof(aws_raw_error) == thetype
                @test isa(aws_raw_error, thetype)

                @test AWSCxx.message(aws_raw_error) == ""
                aws_error = AWSError(aws_raw_error)
                @test AWSCxx.message(aws_error) == ""

                outcome = AWSOutcome(list_buckets_outcome)
                @test !iserror(outcome)
                result = unwrap(outcome)

                AWSCxx.shutdown(cl)
            end
        end

        @testset "failure" begin
            MockAWSServer(; host=PROXY_HOST, port=PROXY_PORT, service="s3") do ms
                AWSFeatures.load("s3")

                cl = AWSClient()
                clc = proxy_config()
                s3_client = @cxxnew Aws::S3::S3Client(clc)

                request = @cxx Aws::S3::Model::GetObjectRequest()
                @cxx request->SetBucket(pointer("not_a_bucket"))
                @cxx request->SetKey(pointer("not_an_object"))

                get_object_outcome = @cxx s3_client->GetObject(request)
                @test !(@cxx get_object_outcome->IsSuccess())
                aws_raw_error = @cxx get_object_outcome->GetError()

                @test length(AWSCxx.name(aws_raw_error)) > 0
                @test length(AWSCxx.message(aws_raw_error)) > 0

                outcome = AWSOutcome(get_object_outcome)
                @test iserror(outcome)
                @test_throws AWSError unwrap(outcome)
                error_text = stringio() do io
                    Base.showerror(io, unwrap_error(outcome))
                end
                @test contains(error_text, "AWSError")
                @test contains(error_text, "NoSuchBucket")

                AWSCxx.shutdown(cl)
            end
        end
    end

    @testset "mock" begin
        @testset "number of buckets" begin
            MockAWSServer(; host=PROXY_HOST, port=PROXY_PORT, service="s3") do ms
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
            end
        end

        @testset "S3 Object I/O" begin
            MockAWSServer(; host=PROXY_HOST, port=PROXY_PORT, service="s3") do ms
                BUCKET_NAME = "definitely_a_bucket"
                OBJECT_KEY = "certainly_a_key"
                OBJECT_BODY = "undoubtedly_an_object"

                AWSFeatures.load("s3")

                cl = AWSClient()
                clc = proxy_config()
                s3_client = @cxxnew Aws::S3::S3Client(clc)

                cbr = @cxx Aws::S3::Model::CreateBucketRequest()
                @cxx cbr->SetBucket(pointer(BUCKET_NAME))
                cbo = AWSOutcome(@cxx s3_client->CreateBucket(cbr))
                @test !iserror(cbo)

                por = @cxx Aws::S3::Model::PutObjectRequest()
                @cxx por->SetBucket(pointer(BUCKET_NAME))
                @test (@cxx por->GetBucket()) == BUCKET_NAME
                @test BUCKET_NAME == (@cxx por->GetBucket())
                @cxx por->SetKey(pointer(OBJECT_KEY))
                @test (@cxx por->GetKey()) == OBJECT_KEY
                @test OBJECT_KEY == (@cxx por->GetKey())
                icxx"""
                    std::shared_ptr<Aws::StringStream> ss = Aws::MakeShared<Aws::StringStream>("JULIA", $(pointer(OBJECT_BODY)));
                    $por.SetBody(ss);
                """
                poo = AWSOutcome(@cxx s3_client->PutObject(por))
                @test !iserror(poo)

                gor = @cxx Aws::S3::Model::GetObjectRequest()
                @cxx gor->SetBucket(pointer(BUCKET_NAME))
                @cxx gor->SetKey(pointer(OBJECT_KEY))
                goo = AWSOutcome(@cxx s3_client->GetObject(gor))
                @test !iserror(goo)
                result = unwrap(goo)

                stream = @cxx result->GetBody()
                length = @cxx result->GetContentLength()
                byte_buf = Vector{UInt8}(length)
                @cxx stream->read(pointer(byte_buf), length)
                contents = String(byte_buf)
                @test contents == OBJECT_BODY

                AWSCxx.shutdown(cl)
            end
        end
    end
end
