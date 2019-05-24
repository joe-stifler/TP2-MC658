# --------------------------------------------------------------------
###
# Problem: mn27
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
Cindex = 1:n

while !eof(f)
   line = readline(f)

   # Le as arestas do grafo
   u, v = (parse(Int, x) for x in split(line))

   push!(E, (u, v))
end

close(f) # => fecha arquivo de entrada

# # Preparando o modelo
MN27 = Model(solver=GurobiSolver(TimeLimit=time_limit, NodefileStart=6))

# Definindo as variáveis
@variable(MN27, c[j in Cindex], Bin)
@variable(MN27, x[i in Vindex, j in Cindex], Bin)

# função objetivo (FO)
@objective(MN27, Min, sum(c[j] for j in Cindex))

# restricoes:
# (a)  Cada vertice deve MN27ser colorido com exatamente uma cor
for i in Vindex
   @constraint(MN27, sum(x[i, j] for j in Cindex) == 1)
end

# (b)  Para cada aresta pertencente a E, no maximo um vertice do par pode receber a cor j
for e in E
   for j in Cindex
      @constraint(MN27, x[e[1], j] + x[e[2], j] <= 1)
   end
end

# (c)  A  cor j devera  ser  utilizada  caso  haja  no  minimo  um  verticecolorido com a cor j:
for i in Vindex
   for j in Cindex
      @constraint(MN27, x[i, j] <= c[j])
   end
end

# Solution
status = solve(MN27)
obj = getobjectivevalue(MN27)

open("mn27.out", "w") do f
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

println("Número de nós explorados: ", getnodecount(MN27::Model))

D = getobjbound(MN27::Model)
P = getobjectivevalue(MN27::Model)

@printf("Melhor limitante dual: %.2f\n", D)
@printf("Melhor limitante primal: %.2f\n", P)

Gap = (abs(D - P) / P) * 100

@printf("Gap de otimalidade: %.2f\n", Gap)
@printf("Tempo de execução: %.2f\n", getsolvetime(MN27::Model))

# ----------------------------------------

end  # => fim do bloco "let"
