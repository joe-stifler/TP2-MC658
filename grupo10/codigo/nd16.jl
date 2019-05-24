# --------------------------------------------------------------------
###
# Problem: nd16
# University: UNICAMP
# Discipline: MC658
# Professor: Cid C. de Souza
# PED: Natanael Ramos
# Author (RA 176665): Jose Ribeiro Neto <j176665@dac.unicamp.br>
###

# Importando os pacotes para fazer a otimização
using JuMP, Gurobi, Printf

file_path = ARGS[1]
time_limit = parse(Int, ARGS[2])

f = open(file_path, "r")

# ----------------------------------------------------------------------------------------
# IMPORTANTE: sem este "let", as variáveis de fora do loop não ficam definidas dentro dele
# ----------------------------------------------------------------------------------------
let

n=0; m=0;

if !eof(f)
   line = readline(f)
   n, m = [parse(Int, x) for x in split(line)]
end

E = []
Vindex = 1:n
Eindex = 1:m

while !eof(f)
   line = readline(f)

   # Le as arestas do grafo
   u, v, w = (parse(Int, x) for x in split(line))

   push!(E, (u, v, w))
end

close(f) # => fecha arquivo de entrada

# Preparando o modelo
ND16 = Model(solver=GurobiSolver(TimeLimit=time_limit, NodefileStart=6))

# Definindo as variáveis
@variable(ND16, y[i in Eindex], Bin)
@variable(ND16, x[i in Vindex, j in 1:2], Bin)

# função objetivo (FO)
@objective(ND16, Max, sum(E[i][3] * y[i] for i in Eindex))

# restricoes:
# (a) Todo nodo i deve pertencer a exatamente uma das partições:
for i in Vindex
   @constraint(ND16, x[i, 1] + x[i, 2] == 1)
end

# (b) Uma aresta (u, v) terá extremos em V1 e V2 somente se os dois nodos não estiverem na mesma partição:
for i in Eindex
   @constraint(ND16, x[E[i][1], 1] + x[E[i][2], 1] + y[i] <= 2)
   @constraint(ND16, x[E[i][1], 2] + x[E[i][2], 2] + y[i] <= 2)
end

# Solution
status = solve(ND16)
obj = getobjectivevalue(ND16)

# x_star = getvalue(x)
# y_star = getvalue(y)
#
# println(x_star)
# println(y_star)

open("nd16.out", "w") do f
   write(f, "$obj\n")
end

# ----------------------------------------
# Relatório
println("===============================")

if status == :Optimal
   println("Solução ótima encontrada.")
elseif status == :Unbounded
   println("Problema é ilimitado.")
elseif status == :Infeasible
   println("Problema é inviável.")
elseif status == :UserLimit
   println("Parado por limite de tempo ou iterações.")
elseif status == :Error
   println("Erro do resolvedor.")
else
   println("Não resolvido.")
end

println("Número de nós explorados: ", getnodecount(ND16::Model))

D = getobjbound(ND16::Model)
P = getobjectivevalue(ND16::Model)

@printf("Melhor limitante dual: %.2f\n", D)
@printf("Melhor limitante primal: %.2f\n", P)

Gap = (abs(D - P) / P) * 100

@printf("Gap de otimalidade: %.2f\n", Gap)
@printf("Tempo de execução: %.2f\n", getsolvetime(ND16::Model))

# ----------------------------------------

end  # => fim do bloco "let"
