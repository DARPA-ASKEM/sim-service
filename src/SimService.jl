module SimService 

using HTTP
#using JSON3
using Oxygen
using StructTypes
#using SwaggerMarkdown

include("lib.jl");        import .Lib: solve_from_petri
include("validation.jl"); import .Validation: make_responsive

#  using Pkg; Pkg.activate(".");using SimService; SimService.run()
#info = Dict("title" => "Simulation Service", "version" => "0.1.0")
#swagger_header = build(OpenAPI("3.0", info))
#mergeschema(swagger_header)

function register()
    
    @post "/solve" make_responsive(solve_from_petri)

end

function run()
    resetstate()
    register()
    serve()
end

end # module Pipeline
