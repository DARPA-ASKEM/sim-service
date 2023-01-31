module Lib

using JSON3 # TODO: Remove this dependency and use Dicts only in this lib

using Catlab
using Catlab.CategoricalAlgebra
using AlgebraicPetri
using AlgebraicPetri.BilayerNetworks
import Catlab.CategoricalAlgebra: migrate!
using Catlab.WiringDiagrams
using Catlab.Programs.RelationalPrograms
using EasyModelAnalysis


function gen_prob(payload::JSON3.Object)
    # TODO: Open issue in Catlab about reading directly from Dicts/Strings/File Objects
    mktemp() do path, file
        JSON3.write(path, payload["petri"])
        petri = read_json_acset(LabelledPetriNet, path)
        bilayer = LabelledBilayerNetwork() # TODO: Remove step; petri should be able to convert to ODESystem
        migrate!(bilayer, petri)
        ode = ODESystem(bilayer)

        (initial, params) = payload["payload"]["initial_values"], payload["payload"]["parameters"]

        getf(d, x) = d[x] # TODO: Do this idiomatically, maybe using composiiton: ∘
        get_initial(x) = getf(initial, string(x))
        get_params(x) = getf(params, string(x))

        # Use labels
        u0 = get_initial.(petri[:, :sname])
        p = get_params.(petri[:, :tname])

        return (tspan) -> ODEProblem(ode, u0, tspan, p)
    end
end

function solve_from_petri(payload::JSON3.Object)
    prob_creator = gen_prob(payload)
    sol = EasyModelAnalysis.solve(prob_creator((0,90)))
    return "COMPLETE"
end

end # module Lib
