using JuMP
import Ipopt

function solver(n, Q, e, r)
    model = Model(Ipopt.Optimizer)
    set_silent(model)
    @variable(model, x[1:n] >= 0)
    @objective(model, Min, .5*x' * Q * x + e'*x)
    @constraint(model, r' * x == 1)
    optimize!(model)

    #println(solution_summary(model))
    #println(model)
    #println("Q:\n$Q\nr:\n$r")
    println("\nSOLVER:")
    #println("\nx = $(value.(x))\n")
    println("f(xk) = $(value(.5*(x' * Q * x) + e'*x))")
end
