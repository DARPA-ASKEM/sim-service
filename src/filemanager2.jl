module FileManager2

using CSV
using DataFrames
using EasyModelAnalysis: ODESolution
using Serialization
using AWS
using AWSS3

STORE="S3"
region = "us-east-1"
bucket = "jataware-sim-service-test"
aws = global_aws_config(; region="us-east-1")


"""
Take a julia object, serialize it and write it to a 
location in S3 specified by key which is the path relative
to the master bucket.
"""
function write_file(data, key::String)
    b = IOBuffer()
    serialize(b, data)
    print(bucket, key)
    s3_put(aws, bucket, key)
end

"""
Assume a julia object has been serialized at location
specified by key.  Deserialize and return the object.
"""
function get_file(key::String)
    temp = s3_get(aws, bucket, key)
    data = deserialize(IOBuffer(temp)) #TODO handle errors
    return data
end

end