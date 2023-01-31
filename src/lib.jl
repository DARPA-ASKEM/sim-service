module Lib

using CSV
using DataFrames
using JSON3 # TODO: Remove this dependency and use Dicts only in this lib

using Catlab
using Catlab.CategoricalAlgebra
using AlgebraicPetri
using AlgebraicPetri.BilayerNetworks
import Catlab.CategoricalAlgebra: migrate!
using Catlab.WiringDiagrams
using Catlab.Programs.RelationalPrograms
using EasyModelAnalysis


function gen_prob(body::JSON3.Object)
    # TODO: Open issue in Catlab about reading directly from Dicts/Strings/File Objects
    mktemp() do path, file
        JSON3.write(path, body["petri"])
        petri = read_json_acset(LabelledPetriNet, path)
        bilayer = LabelledBilayerNetwork() # TODO: Remove step; petri should be able to convert to ODESystem
        migrate!(bilayer, petri)
        ode = ODESystem(bilayer)

        (initial, params) = body["payload"]["initial_values"], body["payload"]["parameters"]
        get_str(f) = (x -> get(f, x, nothing)) ∘ string

        # TODO!!!: Don't strip labels from u0 and p (using `@variables` and `@parameters`)
        
        # Examples
        #  @variables t S(t)
        #  @variables t I(t)
        #  @variables t R(t)
        #  @parameters Tuple(petri[:, :tname])
        # End Examples

        u0 = get_str(initial).(petri[:, :sname])
        p = get_str(params).(petri[:, :tname])

        return tspan -> ODEProblem(ode, u0, tspan, p)
    end
end

function solve_from_petri(body::JSON3.Object, tspan=(0,90))
    prob = gen_prob(body)(tspan)
    sol = EasyModelAnalysis.solve(prob)
    
    # TODO!!: Stream or save to S3?? RETURN SOMETHING! (Use https://github.com/JuliaCloud/AWS.jl *OR* HTTP.jl streams??)
    #io = IOBuffer()
    #csv = string(take!(CSV.write(io, DataFrame(sol))))
    return "SOLVED"
end


# TODO!: Finish the fitting and RETURN some data
function fit(body::JSON3.Object, sim_path::String, date_col::Symbol, name_map::Vector{Tuple{Symbol, Symbol}})
    # TODO!!: Figure out where to get this dataset from??
    df = CSV.read(body["dataset_path"], DataFrame)
    sort!(df, date_col)
    entries = first(size(df))
    df[!, :steps] = 0: entries - 1

    prob = gen_prob(body["sim"])((0.0, Float64(entries - 1)))

    rename!(df, Dict(body["name_map"]))
    data = Array(df[:, map(last, name_map)]) # Note: this reorders to match compartments (hopefully)

    material = (data, prob)
    return "READY TO FIT"
end


end # module Lib
