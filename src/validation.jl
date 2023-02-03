module Validation

using HTTP
using Oxygen

# TODO(five): Splat JSON for the expected fields on the Julia objects instead of feding a single object to `func`
# ... Maybe StructTypes can help??
function make_responsive(func::Function)
    return (req::HTTP.Request) -> begin
        payload = nothing
        try
            payload = json(req)
        catch e
             if isa(error, ArgumentError)
                return HTTP.Response(422, "Valid JSON not given")
             else
                throw(e)
             end
        end
        return HTTP.Response(200, func(payload))
    end
end

end # module Validation
