using Plots, LinearAlgebra, ForwardDiff, DataFrames, Distributions, Statistics, DelimitedFiles, CSV, YFinance, Random, JuMP, Ipopt

gr(size=(600,400))
contour(1:10, 1:10, atan)
plotlyjs(size = (1100, 500))

# Importando o arquivo modelo_mark.jl
include("funcoes_aux.jl")
include("YFinance.jl")

function testes(n, caminho_inst = "instancias_ficticias", dados_ficticios = false)
    # Crindo os diretórios das instâncias, caso não existam0
    make_dirs(n, caminho_inst)

    # O relatório foi feito em cima das instâncias do diretório ./instancias
    # portanto descomentar a linhas make_inst(n) criará novas instâncias (dados != dos relatados)
    #make_inst(n, caminho_inst, dados_ficticios)

    # Lendo as instâncias
    df_Q, df_e, df_b, df_x = read_inst(n, caminho_inst)

    # Obtendo as taxas de retornos (preço atual da ação/preço imediatamente anterior)
    returns = diff(Matrix(df_Q); dims = 1) ./ Matrix(df_Q[1:end-1, :])

    # Média dos preços das ações
    r = vec(Statistics.mean(returns; dims = 1))

    # Matriz de covariância
    Q = Statistics.cov(Matrix(df_Q))

    # Definindo a função
    b = df_b.Vetorb[1]
    e = df_e.VetorE
    f(x) = .5*x' * Q * x - r'*x
    f(x,y) = f([x;y])
    c(x) = [sum(x[i] for i = 1:n) - b]

    # Método (Lagrangiano aumentado)
    m = 1 # N° de restrições
    global rho = 1.0
    global x = df_x.Vetorx
    global y = [0.0]

    phi(x) = f(x) + rho*(sum(x[i] for i = 1:n) - b)^2/2
    phi(x,y) = phi([x;y])

    FD = ForwardDiff
    gf(x) = FD.gradient(f,x)
    H(x) = FD.hessian(f,x)
    J(x) = FD.jacobian(c,x)
    Hc(x,i) = FD.hessian(x -> c(x)[i], x)

    resultados_f = []
    output = ""

    tempo_alg = @timed for k = 1:20
        global cx = c(x)
        local gx = gf(x)
        local Ax = J(x)
        local Bx = H(x) + sum(Hc(x,i) * (y[i] + rho * cx[i]) for i = 1:m)

        local dk = -(Bx + rho*Ax'*Ax)\(gx + Ax'*(y + rho*cx))
        global x = x + dk
        global y += rho * c(x)
        push!(resultados_f, f(x))

        # Critério de parada
        if k > 1 && abs(resultados_f[k-1] - resultados_f[k]) > 10^(-8)
            global rho = max(1, 10*rho)

            #println("$k | $(norm(c(x))) | $y | $(norm(gf(x) + J(x)'*y))")
        elseif k > 1 && abs(resultados_f[k-1] - resultados_f[k]) <= 10^(-8)
            output *= "\nk = $k\n\nLAGRANGIANO\n"
            break
        end

        #println("$k | $(norm(c(x))) | $y | $(norm(gf(x) + J(x)'*y))")
    end

    #println("Final | $(norm(c(x)))\nxk = $x\n")
    output *= "f(xk) = $(f(x))\n"
    #println(resultados_f)

    function impressao(n, f, xk, fxk)
        if n == 2
            function envelope(F)
                return (x, y) -> F([x, y])
            end

            X = range(xk[1] - 1000, xk[1] + 1000, length=100)
            Y = range(xk[2] - 1000, xk[2] + 1000, length=100)

            p_surface = plot(X, Y, envelope(f), st=:surface, xlabel="Eixo x", ylabel="Eixo y", zlabel="Eixo z")

            scatter!(
                p_surface, [xk[1]], [xk[2]], [fxk], markersize=5, color=:red,
                label="($(round(xk[1], digits=2)), $(round(xk[2], digits=2)), $(round(fxk, digits=2)))"
            )
            display(p_surface)

            p_contour = plot(X, Y, envelope(f), st=:contour)
            contour!(p_contour, X, Y, envelope(f))
            scatter!(p_contour, [xk[1]], [xk[2]], markersize=5, color=:red, label="Solução ($(round(xk[1], digits=2)), $(round(xk[2], digits=2)))   ")
            x_line = range(xk[1] - 1000, xk[1] + 1000, length=100)
            y_line = (-r[1] .* x_line .+ 1)/r[2]
            plot!(p_contour, x_line, y_line, label="Restrição", legend=:outerbottom)

            savefig("curvas_n$n.png")
            savefig("Curvas de níveis n=$n.svg")
        end
    end

    tempo = @timed solver(n, Q, e, r)
    output *= "\nx = \n$x\n"
    output *= "\nSOLVER\nf(xk) = $(tempo.value)\n\nTempos (s):\n Lagrangino aumentado: $(tempo_alg.time)\n Solver: $(tempo.time)\n"
    impressao(n, f, x, f(x))

    # Save results and output to a text file
    open("./outputs_plot/output_n_real_$n.txt", "w") do file
        println(file, output)
        println(file, "Resultados da f por iteracao:")
        writedlm(file, resultados_f)
    end
end

instancias = [2, 3, 4, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
#instancias = [2]
#instancias = [2,10,20]
for n in instancias
    println("Teste n = $n")
    println("*"^50)
    testes(n, "instancias_reais")
    println("*"^50)
end
