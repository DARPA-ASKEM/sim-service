module FileManager

using AWS.AWSServices: @service, env_var_credentials
using CSV
using DataFrames
using EasyModelAnalysis: ODESolution

@service S3

STORE="S3"
S3_BUCKET = get(ENV, "S3_BUCKET", nothing)
CREDENTIALS = env_var_credentials()

function get_file(::Type{String}, key::String)
    if STORE == "S3"
        return S3.get_object(S3_BUCKET, key)
    else
        throw("Store is not configured!")
    end
end

function get_file(::Type{DataFrame}, key::String)
    content = get_file(String, key)
    return CSV.read(IOBuffer(content), DataFrame)
end

function get_file(key::String)
    return get_file(String, key)
end

function write_file(seed::String, content::String, content_type::String = "text/plain")
    if STORE == "S3"
        key = string(hash(seed))
        S3.put_object(S3_BUCKET, seed, )#Dict("Body"=>content, "Content-Type"=>content_type))
        return key
    else
        throw("Store is not configured!")
    end
end

function write_file(seed::String, content::ODESolution) 
    io = IOBuffer()
    csv = string(take!(CSV.write(io, DataFrame(content))))
    write_file(seed, csv, "text/csv")
end

end # module FileManager
