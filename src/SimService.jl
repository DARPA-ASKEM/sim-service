module SimService 

using HTTP
using JSON3
using Oxygen
using StructTypes
using SwaggerMarkdown

using Catlab
using Catlab.CategoricalAlgebra
using AlgebraicPetri
using AlgebraicPetri.BilayerNetworks
import Catlab.CategoricalAlgebra: migrate!
using Catlab.WiringDiagrams
using Catlab.Programs.RelationalPrograms

function read_valid_json(req::HTTP.Request)
    try
         return json(req)
    catch e
         if isa(error, ArgumentError)
            return nothing
         else
            throw(e)
         end
    end
end

function gen_petri(serialization::JSON3.Object)
    # TODO: Open issue in Catlab about reading directly from Dicts/Strings/File Objects
    mktemp() do (path, file)
        println("HELLO")
        println(path)
        println(file)
        println("\n\n\n\n")
        write(file, JSON.json(serialization))
        print("MADE IT?")
        petri = read_json_acset(LabelledPetriNet, path)
        bilayer = LabelledBilayerNetwork() # TODO: Remove step; petri should be able to convert to ODESystem
        migrate!(bilayer, petri)
        return ODESystem(bilayer)
    end

end

function __init__()
    @post "/problem" (req::HTTP.Request) -> begin
        payload = nothing
        payload = read_valid_json(req)
        if payload == nothing
            return HTTP.Response(422, "Valid JSON not given")
        end
        return gen_petri(payload["petri"])
    end
end

#  using Pkg; Pkg.activate(".");using SimService; SimService.run()
#info = Dict("title" => "Simulation Service", "version" => "0.1.0")
#swagger_header = build(OpenAPI("3.0", info))
#mergeschema(swagger_header)

run = serve

end # module Pipeline
