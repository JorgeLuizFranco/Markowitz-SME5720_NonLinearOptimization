function solver(n, Q, e, r)
    model = Model(Ipopt.Optimizer)
    set_silent(model)
    @variable(model, x[1:n] >= 0)
    @objective(model, Min, .5*x' * Q * x - r'*x)
    @constraint(model, sum(x) == 1)
    optimize!(model)

    #println(solution_summary(model))
    #println(model)
    #println("Q:\n$Q\nr:\n$r")
    #println("\nSOLVER:")
    #println("\nx = $(value.(x))\n")
    #println("f(xk) = $(value(.5*(x' * Q * x) - e'*x))\n")
    return value(.5*(x' * Q * x) - r'*x), value(.5*(x' * Q * x)), value(- r'*x)
end

function make_dirs(n, caminho_inst)
    # Crindo os diretórios de teste
    diretorios = Dict("./$caminho_inst" => false, "./$caminho_inst/n=$n" => false)

	for (dir, valor) in diretorios
		if !isdir("./$dir")
			try
				mkdir("./$dir")
				diretorios[dir] = true
			catch
				logs_dir = open("logs_dir.txt","w")
				write(logs_dir, "Não foi possível criar o diretório $dir")
			end
		else
			diretorios[dir] = true
		end
	end
end

function make_inst(n, caminho_inst, dados_ficticios)
    # DataFrame aleátorio
    #df_Q = acoesRandomIBrx100(n)
    df_Q = DataFrame()
    if dados_ficticios == true
        df_Q = DataFrame(rand(Uniform(0,1), n, n), :auto)
    else
        df_Q = acoesRandomIBrx100(n)
        #df_Q = get_pricesAcoes(["ABEV3.SA","JBSS3.SA"])
    end

    caminho = joinpath(caminho_inst, "n=$(n)", "n=$(n)_Q.csv")
    writedlm(caminho, Iterators.flatten(([names(df_Q)], eachrow(df_Q))), ';')

    e = rand(Uniform(0,1), n)
    df_e = DataFrame(VetorE=e)
    caminho = joinpath(caminho_inst, "n=$(n)", "n=$(n)_e.csv")
    writedlm(caminho, Iterators.flatten(([names(df_e)], eachrow(df_e))), ';')

    b = [1]
    df_b = DataFrame(Vetorb = b)
    caminho = joinpath(caminho_inst, "n=$(n)", "n=$(n)_b.csv")
    CSV.write(caminho, df_b, delim=';')

    x = rand(Uniform(0, 1), n)
    df_x = DataFrame(Vetorx = x)
    caminho = joinpath(caminho_inst, "n=$(n)", "n=$(n)_x.csv")
    writedlm(caminho, Iterators.flatten(([names(df_x)], eachrow(df_x))), ';')
end

function read_inst(n, caminho_inst)
    # Leitura das instâncias
    caminho = joinpath(caminho_inst, "n=$(n)", "n=$(n)_Q.csv")
    df_Q = CSV.read(caminho, DataFrame)

    caminho = joinpath(caminho_inst, "n=$(n)", "n=$(n)_e.csv")
    df_e = CSV.read(caminho, DataFrame)

    caminho = joinpath(caminho_inst, "n=$(n)", "n=$(n)_b.csv")
    df_b = CSV.read(caminho, DataFrame)

    caminho = joinpath(caminho_inst, "n=$(n)", "n=$(n)_x.csv")
    df_x = CSV.read(caminho, DataFrame)

    return df_Q, df_e, df_b, df_x
end
