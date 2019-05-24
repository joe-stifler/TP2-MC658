# --------------------------------------------------------------------
###
# Problem: ss2
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

   n = 0; s_size = 0;

   if !eof(f)
      line = readline(f)
      n, s_size = [parse(Int, x) for x in split(line)]
   end

   M = 10
   S = []
   T = 1:n
   tasks = []

   for i in T
      line = readline(f)

      t, d = (parse(Int, x) for x in split(line))

      M = M + t
      push!(tasks, (t, d))
   end

   for k in 1:s_size
      line = readline(f)

      i, j = (parse(Int, x) for x in split(line))

      push!(S, (i, j))
   end

   # for t in tasks
   #    println("$t")
   # end
   #
   # println("Different sets")
   #
   # for t in S
   #    println("$t")
   # end
   #
   # println("Different sets")

   close(f) # => fecha arquivo de entrada

   SS2 = Model(solver=GurobiSolver(TimeLimit=time_limit, NodefileStart=6))

   # Definindo as variáveis
   @variable(SS2, s[i in T] >= 0, Int)
   @variable(SS2, y[i in T], Bin)
   @variable(SS2, x[i in T, j in T], Bin)

   # função objetivo (FO)
   @objective(SS2, Min, sum(y[i] for i in T))

   # (a) A tarefa i deve preceder a tarefa j, ou o contrário:
   for i in T
      for j in T
         if i != j
            @constraint(SS2, x[i, j] + x[j, i] == 1)
         end
      end
   end

   # (b) A tarefa j deve começar depois da tarefa i, caso i precede j. Caso
   # j preceda i, a expressão deve ser redundante:
   for i in T
      for j in T
         if i != j
            ti = tasks[i][1]
            @constraint(SS2, s[i] + ti - x[j, i] * M <= s[j])
         end
      end
   end

   # (c) A order de precedência das tarefas estabelecida pelo conjunto S
   # deve ser respeitada:
   for aux in S
      @constraint(SS2, x[aux[1], aux[2]] == 1)
   end

   # (d) Se a tarefa j terminar depois do prazo estipulado, então a mesma
   # estará atrasada:
   for j in T
      tj = tasks[j][1]
      dj = tasks[j][2]
      @constraint(SS2, s[j] + tj - dj - y[j] * M<= 0)
   end

   # # (e) Variável s deve ser positiva:
   # for j in T
   #    @constraint(SS2, s[j] >= 0)
   # end

   # Solution
   status = solve(SS2)
   obj = getobjectivevalue(SS2)

   # println(SS2)
   # x_star = getvalue(x)
   # println(x_star)
   #
   # y_star = getvalue(y)
   # println(y_star)
   #
   # s_star = getvalue(s)
   # println(s_star)

   open("ss2.out", "w") do f
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

   println("Número de nós explorados: ", getnodecount(SS2::Model))

   D = getobjbound(SS2::Model)
   P = getobjectivevalue(SS2::Model)

   @printf("Melhor limitante dual: %.2f\n", D)
   @printf("Melhor limitante primal: %.2f\n", P)

   Gap = (abs(D - P) / P) * 100

   @printf("Gap de otimalidade: %.2f\n", Gap)
   @printf("Tempo de execução: %.2f\n", getsolvetime(SS2::Model))

   # ----------------------------------------

end  # => fim do bloco "let"
