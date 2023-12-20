using Plots, LinearAlgebra, ForwardDiff, DataFrames, Distributions, Statistics
gr(size=(600,400))
contour(1:10, 1:10, atan)
plotlyjs(size = (1100, 500))

# Importando o arquivo modelo_mark.jl
include("solver.jl")

# Dados inicias
n = 2

# DataFrame aleátorio
Q = rand(Uniform(0,1), 12,n)
df_Q = DataFrame(Q, :auto)

# Obtendo o retorno em relação a cada retorno do mês anterior
returns = diff(Matrix(df_Q); dims = 1) ./ Matrix(df_Q[1:end-1, :])

# Média dos retornos
r = vec(Statistics.mean(returns; dims = 1))

# Matriz de covariância
Q = Statistics.cov(returns)

# Definindo a função
b = 1
e = rand(Uniform(0,1), n)
f(x) = .5*x' * Q * x - e'*x
f(x,y) = f([x;y])
c(x) = [sum(r[i]*x[i] for i = 1:n) - b]



# Método (Lagrangiano aumentado)
# Baseado em https://youtu.be/EY0sXYe12-M?si=4Jn8ECPnUAED5OFO
m = 1 # N° de restrições
rho = 1.0
x = rand(Uniform(0, 1), n)
y = [0.0]

phi(x) = f(x) + rho*(sum(r[i]*x[i] for i = 1:n) - b)^2/2
phi(x,y) = phi([x;y])

FD = ForwardDiff
gf(x) = FD.gradient(f,x)
H(x) = FD.hessian(f,x)
J(x) = FD.jacobian(c,x)
Hc(x,i) = FD.hessian(x -> c(x)[i], x)

resultados_f = []
for k =1:20
    global cx = c(x)
    local gx = gf(x)
    local Ax = J(x)
    local Bx = H(x) + sum(Hc(x,i) * (y[i] + rho * cx[i]) for i = 1:m)

    local dk = -(Bx + rho*Ax'*Ax)\(gx + Ax'*(y + rho*cx))
    global x = x + dk
    global y += rho * c(x)
    push!(resultados_f, f(x))

    # Critério de parada
    if k>1 && abs(resultados_f[k-1] - resultados_f[k]) > 10^(-8)
        global rho = max(1, 10*rho)

        #println("$k | $(norm(c(x))) | $y | $(norm(gf(x) + J(x)'*y))")
    elseif k>1 && abs(resultados_f[k-1] - resultados_f[k]) <= 10^(-8)
        println("\nk = $k\n\nLAGRANGIANO\n")
        break
    end

    #println("$k | $(norm(c(x))) | $y | $(norm(gf(x) + J(x)'*y))")
end
#println("Final | $(norm(c(x)))\nxk = $x\n")
println("f(xk) = $(f(x))")
#println(resultados_f)

function impressao(n, f, xk, fxk)
    if n == 2
        function envelope(F)
            return (x, y) -> F([x, y])
        end

        X = range(xk[1] - 1000, xk[1] + 1000, length=100)
        Y = range(xk[2] - 1000, xk[2] + 1000, length=100)

        layout = @layout [a b c]
        p = plot(layout=layout)

        surface!(p[1], X, Y, envelope(f), xlabel="longer xlabel", ylabel="longer ylabel", zlabel="longer zlabel")
        contour!(p[3], X, Y, envelope(f))

        scatter!(p[1], [xk[1]], [xk[2]], [fxk], markersize=5, color=:red, label="Ponto ($(xk[1]), $(xk[2]), $fxk)")
        scatter!(p[3], [xk[1]], [xk[2]], markersize=5, color=:red, label="Ponto ($(xk[1]), $(xk[2]))")
        x_line = range(xk[1] - 1000, xk[1] + 1000, length=100)
        y_line = (-r[1] .* x_line .+ 1)/r[2]
        plot!(p[3], x_line, y_line, label="Restrição")
    end
end

tempo = @timed solver(n, Q, e, r)
println("Tempo (s): $(tempo.time)")
impressao(n, f, x, f(x))
