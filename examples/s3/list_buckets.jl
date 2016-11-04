using AWSCxx
using Cxx

function main()
    AWSFeatures.load("s3")

    cl = AWSClient()

    s3_client = @cxxnew Aws::S3::S3Client()
    list_buckets_outcome = @cxx s3_client->ListBuckets()

    if @cxx list_buckets_outcome->IsSuccess()
        println("Your Amazon S3 buckets:")
        result = @cxx list_buckets_outcome->GetResult()
        buckets = @cxx result->GetBuckets()

        for i = 1:(@cxx buckets->size())
            bucket = @cxx buckets->at(i - 1)
            bucket_name = @cxx bucket->GetName()
            name_string = unsafe_string(@cxx bucket_name->c_str())
            println("$i: ", name_string)
        end
    else
        println("ListBuckets error: ")
    end

    finalize(cl)
end

main()
@time main()
