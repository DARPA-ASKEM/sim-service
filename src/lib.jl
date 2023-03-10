module Lib

using CSV
using DataFrames
using JSON3 # TODO: Remove this dependency and use Dicts only in this lib

using Catlab.CategoricalAlgebra
using AlgebraicPetri
using EasyModelAnalysis
using ModelingToolkit
using Symbolics

include("filemanager.jl"); using .FileManager


# TODO(five): Break out creation of ODESystem into separate function so we can handle objects other than petris
function gen_prob(body::JSON3.Object)
    # TODO(five): Open issue in Catlab about reading directly from Dicts/Strings/File Objects
    mktemp() do path, file
        JSON3.write(path, body["petri"])
        petri = read_json_acset(LabelledPetriNet, path)
        ode = ODESystem(petri)

        # TODO(five): Don't use metaprogramming.  
        funcs_of_t = vcat(:t, map(x -> Expr(:call, x, :t), petri[:, :sname]))
        gen_vars = Symbolics._parse_vars(:variables, Real, funcs_of_t)
        state_funcs = eval(gen_vars)
        gen_params = Symbolics._parse_vars(:parameters, Real, petri[:, :tname], ModelingToolkit.toparam)
        parameters = eval(gen_params)

        get_val_from_payload(vals) = (x -> get(vals, x, nothing)) ∘ string
        function gen_mappings(names, vals, symbolics, offset=0)
            get_val = get_val_from_payload(vals)
            result = Dict()
            for (i, name) in enumerate(names)
                result[symbolics[i+offset]] = get_val(name)
            end

            return result
        end

        u0 = gen_mappings(petri[:, :sname], body["payload"]["initial_values"], state_funcs, 1)
        p = gen_mappings(petri[:, :tname], body["payload"]["parameters"], parameters)

        return tspan -> ODEProblem(ode, u0, tspan, p)
    end
end

function solve_from_petri(body::JSON3.Object, tspan::Tuple{Float64, Float64}=(0.0,90.0))
    prob = gen_prob(body)(tspan)
    sol = EasyModelAnalysis.solve(prob)
    
    # TODO(five): Handle filenames in a more systematic way (ENSURE NO COLLISION)
    # TODO(five)!!: FIX write_file
    #handle = FileManager.write_file(string(time()), sol)
    #return Dict("solution_id" => handle) 
    return "COMPLETED: NOT YET WRITING!"
end


# TODO(five)!: Finish the fitting and RETURN some data
function fit(body::JSON3.Object, sim_path::String, date_col::Symbol, name_map::Vector{Tuple{Symbol, Symbol}})
    # TODO(five)!!: Figure out where to get this dataset from??
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
