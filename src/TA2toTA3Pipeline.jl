module TA2toTA3Pipeline

using JSON
using Catlab
using Catlab.CategoricalAlgebra
using AlgebraicPetri
using AlgebraicPetri.BilayerNetworks
#using AlgebraicPetri.ModelingToolkitInterop 
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


function load_into_ode_prob(path::String)

    # TODO: Use IOBuffer instead of writing a temp file
    file = open(path, "r")
    request = JSON.parse(file)
    close(file)
    touch("temp.json")
    open("temp.json", "w") do file
        write(file, JSON.json(request["petri"]))
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

    return ODEProblem(ode, u0, (0,90), p)
end


gen_ode_problem(sim_run::SimRun) = convert(ODEProblem, sim_run)

gen_ode_problem(path::String)::ODEProblem = gen_ode_problem(SimRun(path, (0,0), (), ()))

# TODO: Consider not including this as a method of `solve`
solve(path::String) = EasyModelAnalysis.solve(gen_ode_problem(path))


end # module Pipeline
