module Pipeline

using Catlab
using Catlab.CategoricalAlgebra
using AlgebraicPetri
using AlgebraicPetri.BilayerNetworks
#using AlgebraicPetri.ModelingToolkitInterop 
import Catlab.CategoricalAlgebra: migrate!
using Catlab.WiringDiagrams
using Catlab.Programs.RelationalPrograms
using ASKEM
using EasyModelAnalysis

# TODO: Use other fields (only `path` is used)
struct SimRun
    path :: String
    timestep :: Tuple{Float64, Float64}
    initial_conditions
    parameters
end


# TODO: Figure out 'Is it idiomatic to stick make this a method of `convert`?'
function convert(::Type{ODEProblem}, sim_run::SimRun)
    petri = read_json_acset(LabelledPetriNet, sim_run.path)
    bilayer = LabelledBilayerNetwork()
    migrate!(bilayer, petri)
    ode = ODESystem(bilayer)

    # TODO: Generalize; This part only works for SIR models
    @variables t S(t)
    @variables t I(t)
    @variables t R(t)
    @parameters inf_uu rec_u
    return ODEProblem(ode, [S=>200, I=>10, R=>2], (0, 2), [inf_uu=>0.4, rec_u=>0.3])
end


gen_ode_problem(sim_run::SimRun) = convert(ODEProblem, sim_run)

gen_ode_problem(path::String)::ODEProblem = gen_ode_problem(SimRun(path, (0,0), 0, 0))

# TODO: Consider not including this as a method of `solve`
solve(path::String) = EasyModelAnalysis.solve(gen_ode_problem(path))

end # module Pipeline
