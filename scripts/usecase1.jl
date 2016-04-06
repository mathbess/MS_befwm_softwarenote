using befwm
using Gadfly
using DataFrames
using ProgressMeter

# Generates a random network based on the null model
A = nichemodel(15, 45)

# We will use the `:ode45` solver
const solver = :ode45

# The scaling gradient will go from -3 to 3 (log scale)
Z = collect(logspace(-3, 2, 15))

# Initialize a DataFrame
replicates = 20
df = DataFrame([Float64, Float64, Float64], [:Z, :stability, :diversity], length(Z)*replicates)

df_index = 1
progbar = Progress(length(Z)*replicates, 1, "Simulating ", 50)
for i in eachindex(Z)
    p = make_initial_parameters(A)
    p[:Z] = Z[i]
    p = make_parameters(p)
    for s in 1:replicates
        initial_biomass = rand(size(A, 1))
        output = simulate(p, initial_biomass, start=0, stop=1000, steps=2500, use=solver)
        df[:Z][df_index] = Z[i]
        df[:stability][df_index] = population_stability(output, last=200, threshold=-0.01)
        df[:diversity][df_index] = foodweb_diversity(output, last=200)
        df_index += 1
        next!(progbar)
    end
end

plot(df, x=:Z, y=:d, ymin=:min, ymax=:max, Geom.point, Geom.errorbar, Scale.x_log10)

pl_stab = plot(df, x=:Z, y=:stability, Scale.x_log10, Geom.smooth, Geom.point)
pl_even = plot(df, x=:Z, y=:stability, Scale.x_log10, Geom.smooth, Geom.point)

draw(PDF("effect_scaling.pdf", 8cm, 12cm), hstack(pl_stab, pl_even))
