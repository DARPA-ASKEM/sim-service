module SimService 

using JSON
using CSV
using DataFrames
using Catlab
using Catlab.CategoricalAlgebra
using AlgebraicPetri
using AlgebraicPetri.BilayerNetworks
#using AlgebraicPetri.ModelingToolkitInterop 
using CSV
import Catlab.CategoricalAlgebra: migrate!
using Catlab.WiringDiagrams
using Catlab.Programs.RelationalPrograms
using EasyModelAnalysis

# TODO: Use other fields (only `path` is used)
struct SimRun
    path :: String
    timestep :: Tuple{Float64, Float64}
    initial_conditions :: Vector{Float64} 
    parameters :: Vector{Float64}
end


# TODO: Figure out 'Is it idiomatic to stick make this a method of `convert`?'
function convert(::Type{ODEProblem}, sim_run::SimRun)
    petri = read_json_acset(LabelledPetriNet, sim_run.path)
    bilayer = LabelledBilayerNetwork()
    migrate!(bilayer, petri)
    ode = ODESystem(bilayer)
    #print(petri[:, :tname])

    # TODO: Generalize; This part only works for SIR models
    #@variables t S(t)
    #@variables t I(t)
    #@variables t R(t)
    #@parameters Tuple(petri[:, :tname])
    return ODEProblem(ode, [200.0, 10.0, 2.0], sim_run.timestep, [0.4, 0.3])
end

gen_ode_problem(sim_run::SimRun) = convert(ODEProblem, sim_run)

gen_ode_problem(path::String)::ODEProblem = gen_ode_problem(SimRun(path, (0,0), (), ()))

# TODO: Consider not including this as a method of `solve`
solve(path::String) = EasyModelAnalysis.solve(gen_ode_problem(path))

function load_into_ode_prob(path::String, tspan::Tuple{Float64, Float64})

    # TODO: Use IOBuffer instead of writing a temp file
    file = open(path, "r")
    request = JSON.parse(file)
    close(file)
    touch("temp.json")
    open("temp.json", "w") do file
        write(file, JSON.json(request["petri"])) # ACSET READS REQUIRE FILE
    end

    # Get the actual ODE
    petri = read_json_acset(LabelledPetriNet, "temp.json")
    bilayer = LabelledBilayerNetwork()
    migrate!(bilayer, petri)
    ode = ODESystem(bilayer)

    # Get parameters and intitial values
    payload = request["payload"]
    (initial, params) = payload["initial_values"], payload["parameters"]

    getf(d, x) = d[x] # TODO: Do this idiomatically, maybe using composiiton: ∘
    get_initial(x) = getf(payload["initial_values"], string(x))
    get_params(x) = getf(payload["parameters"], string(x))

    u0 = get_initial.(petri[:, :sname])
    p = get_params.(petri[:, :tname])
    #u0 = Dict( for name in petri[:, :sname])
    #p = get_params.(petri[:, :tname])

    return ODEProblem(ode, u0, tspan, p)
end

function get_dataset_for_fit(dataset_path::String, sim_path::String, date_col::Symbol, name_map::Vector{Tuple{Symbol, Symbol}})
    df = CSV.read(dataset_path, DataFrame)
    sort!(df, date_col)
    entries = first(size(df))
    df[!, :steps] = 0: entries - 1

    prob = load_into_ode_prob(sim_path, (0.0, Float64(entries - 1)))

    rename!(df, Dict(name_map))

    #df[:, [:symbol1, symbol2]]
    data = Array(df[:, map(last, name_map)])

    return (data, prob)
end


end # module Pipeline
