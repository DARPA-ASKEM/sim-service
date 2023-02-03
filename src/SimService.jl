module SimService 

using HTTP
using Oxygen

include("lib.jl");        import .Lib: solve_from_petri, fit
include("validation.jl"); import .Validation: make_responsive

# TODO(five): Document endpoints and use named routers
#using SwaggerMarkdown
#function document()
#       info = Dict("title" => "Simulation Service", "version" => "0.1.0")
#       swagger_header = build(OpenAPI("3.0", info))
#       mergeschema(swagger_header)
#end

function register!()
    @post "/solve" make_responsive(solve_from_petri)
    @post "/fit" make_responsive(fit)
    # TODO(five): Add more endpoints to expand the type of operations we can do
end

function run!()
    resetstate()
    register!()
    #document()
    # TODO(five)!: Stop SciML from slowing the server down. (Try `serveparallel`?)
    serve()
end

end # module Pipeline
