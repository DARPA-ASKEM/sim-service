module FileManager

using AWS.AWSServices: @service
using CSV
using DataFrames

@service S3

STORE="S3"
S3_BUCKET = get(ENV, "S3_BUCKET", nothing)
CREDENTIALS = env_var_credentials()

function get_file(::Type{String}, key::String)
    if STORE == "S3"
        return S3.get_object(S3_BUCKET, key)
    else:
        throw("Store is not configured!")
end

function get_file(::Type{DataFrame}, key::String)
    content = get_file(String, key)
    return CSV.read(IOBuffer(content), DataFrame)
end

function get_file(key::String)
    return get_file(String, key)
end

function write_file(key::String, content::String)
    if STORE == "S3"
        S3.put_object(S3_BUCKET, key, Dict("Body"=>content))
    else:
        throw("Store is not configured!")
end

function write_file(key::String, content::DataFrame) 
    io = IOBuffer()
    csv = string(take!(CSV.write(io, DataFrame(sol))))
    write_file(key, csv)
end

end # module FileManager
