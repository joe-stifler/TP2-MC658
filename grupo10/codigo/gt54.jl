# --------------------------------------------------------------------
###
# Problem: gt54
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

n = 0; c = 0; m = 0;

if !eof(f)
   line = readline(f)
   n, C_size, m = [parse(Int, x) for x in split(line)]
end

s = 0; t = 0;

if !eof(f)
   line = readline(f)
   s, t = [parse(Int, x) for x in split(line)]
end

C = []

for i in 1:C_size
   line = readline(f)

   a, b = (parse(Int, x) for x in split(line))

   push!(C, (a, b))
end

M = 1
E = []
Vindex = 1:n

for i in 1:m
   line = readline(f)

   u, v, w = (parse(Int, x) for x in split(line))

   M = M + w
   push!(E, (u, v, w))
end

close(f) # => fecha arquivo de entrada

a = zeros(Int64,(n,n)) .+ M

for e in E
   a[e[1], e[2]] = e[3]
end

# Preparando o modelo
GT54 = Model(solver=GurobiSolver(TimeLimit=time_limit, NodefileStart=6))

# Definindo as variáveis
@variable(GT54, y[i in Vindex], Bin)
@variable(GT54, x[i in Vindex, j in Vindex], Bin)

# função objetivo (FO)
@objective(GT54, Min, sum(a[i, j] * x[i, j] for i in Vindex for j in Vindex))

# Restricoes:

# (a) O número de arestas ativas que entram num vértice deve ser igual
# ao número de arestas que saem dele, para todo vértice diferente
# das extremidades (vértices s e t):
for i in Vindex
   if i != s && i != t
      @constraint(GT54, sum(x[i, j] - x[j, i] for j in Vindex) == 0)
   end
end

# (b) Deve ter uma única aresta ativa de saída no vértice s:
@constraint(GT54, sum(x[s, j] for j in Vindex) == 1)

# (c) Deve ter uma única aresta ativa de entrada no vértice t:
@constraint(GT54, sum(x[j, t] for j in Vindex) == 1)

# (d) Se pelo menos uma aresta incide no vértice i, então o mesmo deve estar no caminho:
for i in Vindex
   if i != s && i != t
      @constraint(GT54, sum(x[i, j] + x[j, i] for j in Vindex) == 2 * y[i])
   else
      @constraint(GT54, sum(x[i, j] + x[j, i] for j in Vindex) == y[i])
   end
end

# (e) Para todo par (i, j) pertencente a C, no maximo um único vértice do par pode estar no caminho
for p in C
   @constraint(GT54, y[p[1]] + y[p[2]] <= 1)
end

# println(GT54)

# Solution
status = solve(GT54)
obj = getobjectivevalue(GT54)

open("gt54.out", "w") do f
   write(f, "$obj\n")
end

# x_star = getvalue(x)
# y_star = getvalue(y)
#
# println(x_star)
# println(y_star)

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

println("Número de nós explorados: ", getnodecount(GT54::Model))

D = getobjbound(GT54::Model)
P = getobjectivevalue(GT54::Model)

@printf("Melhor limitante dual: %.2f\n", D)
@printf("Melhor limitante primal: %.2f\n", P)

Gap = (abs(D - P) / P) * 100

@printf("Gap de otimalidade: %.2f\n", Gap)
@printf("Tempo de execução: %.2f\n", getsolvetime(GT54::Model))

# ----------------------------------------

end  # => fim do bloco "let"
