function acoesRandomIBrx100(num_acoes = 3,acoes = [])
    #gera ações aleatórias do Ibxr100, as 100 ações mais expressivas da B3.

    ibxr100 = ["RRRP3.SA","ALOS3.SA","ALPA4.SA","ABEV3.SA","ARZZ3.SA","ASAI3.SA","AURE3.SA",
    "AZUL4.SA","B3SA3.SA","BBSE3.SA","BBDC3.SA","BBDC4.SA","BRAP4.SA","BBAS3.SA","BRKM5.SA",
    "BRFS3.SA","BPAC11.SA","CRFB3.SA","BHIA3.SA","CBAV3.SA","CCRO3.SA","CMIG4.SA","CIEL3.SA",
    "COGN3.SA","CSMG3.SA","CPLE6.SA","CSAN3.SA","CPFE3.SA","CMIN3.SA","CVCB3.SA","CYRE3.SA","DXCO3.SA",
    "DIRR3.SA","ECOR3.SA","ELET3.SA","ELET6.SA","EMBR3.SA","ENGI11.SA","ENEV3.SA","EGIE3.SA","EQTL3.SA",
    "EZTC3.SA","FLRY3.SA","GGBR4.SA","GOAU4.SA","GOLL4.SA","GMAT3.SA","NTCO3.SA","SOMA3.SA","HAPV3.SA",
    "HYPE3.SA","IGTI11.SA","IRBR3.SA","ITSA4.SA","ITUB4.SA","JBSS3.SA","KLBN11.SA","RENT3.SA","LWSA3.SA",
    "LREN3.SA","MDIA3.SA","MGLU3.SA","MRFG3.SA","CASH3.SA","BEEF3.SA","MOVI3.SA","MRVE3.SA","MULT3.SA",
    "PCAR3.SA","PETR3.SA","PETR4.SA","RECV3.SA","PRIO3.SA","PETZ3.SA","PSSA3.SA","RADL3.SA","RAIZ4.SA",
    "RDOR3.SA","RAIL3.SA","SBSP3.SA","SANB11.SA","STBP3.SA","SMTO3.SA","CSNA3.SA","SIMH3.SA","SLCE3.SA",
    "SUZB3.SA","TAEE11.SA","VIVT3.SA","TIMS3.SA","TOTS3.SA","TRPL4.SA","UGPA3.SA","USIM5.SA","VALE3.SA",
    "VAMO3.SA","VBBR3.SA","VIVA3.SA","WEGE3.SA","YDUQ3.SA"
    ];

    if isempty(acoes)
        acoes = ibxr100[randperm(100)]
    end
    #reshape(acoes, num_acoes)

    data = []
    aux = 0;
    size_cnt = size(get_prices.("ABEV3.SA",range="1y",interval="1d")["close"],1);
    vetor_data=[]

    cont = 1
    println("$cont, $(size_cnt)")
    names = []
    while cont <= num_acoes
        println("$cont, $(size(get_prices.(acoes[cont + aux],range="1y",interval="1d")["close"],1))")
        if size(get_prices.(acoes[cont + aux],range="1y",interval="1d")["close"],1) == size_cnt
            data = get_prices.(acoes[cont + aux],range="1y",interval="1d");
            println("Entrou!")
            push!(names, acoes[cont+aux])
            cont+=1
        else
            aux +=1;
        end
        push!(vetor_data, data)
    end
    data = vcat([DataFrame(i) for i in vetor_data]...);
    data = data[:,:close];
    data = reshape(data,(Int(size(data,1)/num_acoes),num_acoes));

    # data = get_prices.(acoes,range="1y",interval="1d");
    # data = vcat([DataFrame(i) for i in data]...);
    # data = data[:,:close];
    # data = reshape(data,(Int(size(data,1)/num_acoes),num_acoes));

    # # Convertendo para DataFrame
    data = DataFrame(data, names)

    return data
end


function get_pricesAcoes(acoes = [])
    num_acoes = length(acoes);
    #gera devolve preços de ações especificas.
    data = get_prices.(acoes,range="1y",interval="1d");
    data = vcat([DataFrame(i) for i in data]...);
    data = data[:,:close];
    data = reshape(data,(Int(size(data,1)/num_acoes),num_acoes));

    # Convertendo para DataFrame
    data = DataFrame(data, acoes)

    return data
end

#=
using Statistics
Q,nome_acoes = acoesRandomIBrx100(10)
df_Q = DataFrame(Q, :auto)


returns = diff(Matrix(df_Q); dims = 1) ./ Matrix(df_Q[1:end-1, :])

matriz_cov = cov(Matrix(returns))
=#
