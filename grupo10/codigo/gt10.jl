# --------------------------------------------------------------------
###
# Problem: gt10
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
a = zeros(Int64,(n,n))
nodesAtivos = zeros(Int64, (1, n))

while !eof(f)
   line = readline(f)

   # Le as arestas do grafo
   u, v = (parse(Int, x) for x in split(line))

   a[u, v] = 1
   a[v, u] = 1

   nodesAtivos[u] = 1
   nodesAtivos[v] = 1

   push!(E, (u, v))
end

close(f) # => fecha arquivo de entrada

# # Preparando o modelo
GT10 = Model(solver=GurobiSolver(TimeLimit=time_limit, NodefileStart=6))

# Definindo as variáveis
@variable(GT10, y[i in Vindex], Bin)
@variable(GT10, x[i in Vindex, j in Vindex], Bin)

# função objetivo (FO)
@objective(GT10, Min, sum(x[e[1], e[2]] for e in E))

# restricoes:
# (a) Garante que no máximo uma aresta incidente no nodo i estará no emparelhamento:
for i in Vindex
   @constraint(GT10, sum(a[i, j] * x[i, j] for j in Vindex) == y[i])
end

# (b) Garante que em uma das extremidades da aresta (i, j) incide uma outra aresta
# que pertence ao emparelhamento. Caso isso não seja verdade, o conjunto de aresta
# não será maximal
for e in E
   @constraint(GT10, y[e[1]] + y[e[2]] >= 1)
end

# (c) Garante a simetria do problema (grafo simples)
for i in Vindex
   for j in Vindex
      if i != j
         @constraint(GT10, x[i, j] == x[j, i])
      end
   end
end

# Solution
status = solve(GT10)
obj = getobjectivevalue(GT10)

# x_star = getvalue(x)
# y_star = getvalue(y)
#
# println(x_star)
# println(y_star)

open("gt10.out", "w") do f
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

println("Número de nós explorados: ", getnodecount(GT10::Model))

D = getobjbound(GT10::Model)
P = getobjectivevalue(GT10::Model)

@printf("Melhor limitante dual: %.2f\n", D)
@printf("Melhor limitante primal: %.2f\n", P)

Gap = (abs(D - P) / P) * 100

@printf("Gap de otimalidade: %.2f\n", Gap)
@printf("Tempo de execução: %.2f\n", getsolvetime(GT10::Model))

# ----------------------------------------

end  # => fim do bloco "let"
