module DFOLS
using PyCall, Printf

const dfols = PyNULL()
function __init__()
    copy!(dfols, pyimport("dfols"))
end

# Key objects
struct DFOLSResults{TI <: Integer, TF <: AbstractFloat}
    x::Array{TF, 1}
    resid::Array{TF, 1}
    f::TF
    jacobian::Matrix{TF}
    nf::TI
    nx::TI # differs from nf if sample averaging is used
    nruns::TI # > 1 if multiple restarts
    flag::TI
    msg::String
    EXIT_SUCCESS::TI
    EXIT_MAXFUN_WARNING::TI
    EXIT_SLOW_WARNING::TI
    EXIT_FALSE_SUCCESS_WARNING::TI
    EXIT_INPUT_ERROR::TI
    EXIT_TR_INCREASE_ERROR::TI
    EXIT_LINALG_ERROR::TI
end

# see DFOLS documentation for kwargs
function solve(objfun, x0::Array{TF, 1};
                bounds = nothing,
                npt = nothing,
                rhobeg = nothing,
                rhoend = 1e-8,
                maxfun = nothing,
                nsamples = nothing,
                user_params = nothing, # see https://numericalalgorithmsgroup.github.io/dfols/build/html/advanced.html
                objfun_has_noise = false,
                scaling_within_bounds = false) where {TF <: AbstractFloat, TI <: Integer}

    # grab solution from Python
    soln = dfols[:solve](objfun, x0,
                        bounds = bounds,
                        npt = npt,
                        rhobeg = rhobeg,
                        rhoend = rhoend,
                        nsamples = nsamples,
                        user_params = user_params,
                        objfun_has_noise = objfun_has_noise,
                        scaling_within_bounds = scaling_within_bounds)

    # convergence check
    soln[:flag] == soln[:EXIT_SUCCESS] || error(soln[:msg])

    # return Julia object
    DFOLSResults(soln[:x],
                soln[:resid],
                soln[:f],
                soln[:jacobian],
                soln[:nf],
                soln[:nx],
                soln[:nruns],
                soln[:flag],
                soln[:msg],
                soln[:EXIT_SUCCESS],
                soln[:EXIT_MAXFUN_WARNING],
                soln[:EXIT_SLOW_WARNING],
                soln[:EXIT_FALSE_SUCCESS_WARNING],
                soln[:EXIT_INPUT_ERROR],
                soln[:EXIT_TR_INCREASE_ERROR],
                soln[:EXIT_LINALG_ERROR])
end

# Helper functions
converged(d::DFOLSResults) = (d.flag == d.EXIT_SUCCESS)
optimizer(d::DFOLSResults) = d.x
optimum(d::DFOLSResults) = d.f
residuals(d::DFOLSResults) = d.resid
jacobian(d::DFOLSResults) = d.jacobian
nf(d::DFOLSResults) = d.nf
nruns(d::DFOLSResults) = d.nruns
nx(d::DFOLSResults) = d.nx
flag(d::DFOLSResults) = d.flag
msg(d::DFOLSResults) = d.msg

# Exports
export solve, DFOLSResults, # key objects
        converged, optimizer, optimum, residuals, jacobian, nf, nruns, nx, flag, msg

end # module
