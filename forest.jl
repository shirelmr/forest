using Agents, Random, Distributions

@enum TreeStatus green burning burnt

@agent struct TreeAgent(GridAgent{2})
    status::TreeStatus = green
end

function calculate_wind_probability(tree_pos, neighbor_pos, base_probability, south_wind, west_wind)
    direction_x = neighbor_pos[1] - tree_pos[1]
    direction_y = neighbor_pos[2] - tree_pos[2]
    
    wind_factor = south_wind * direction_y + west_wind * direction_x
    
    final_probability = base_probability + wind_factor
    
    return max(0, min(100, final_probability))
end

function forest_step(tree::TreeAgent, model)
    if tree.status == burning
        for neighbor in nearby_agents(tree, model, 1)
            if neighbor.status == green
                wind_probability = calculate_wind_probability(
                    tree.pos, 
                    neighbor.pos, 
                    model.probabilityOfSpread,
                    model.southWind,
                    model.westWind
                )
                
                if rand(0:100) <= wind_probability
                    neighbor.status = burning
                end
            end
        end
        tree.status = burnt
    end
end

function forest_fire(; density = 0.45, griddims = (5, 5), probabilityOfSpread = 100, southWind = 0, westWind = 0)
    space = GridSpace(griddims; periodic = false, metric = :chebyshev)
    forest = StandardABM(TreeAgent, space; agent_step! = forest_step, scheduler = Schedulers.ByID(), 
        properties = Dict(
            :probabilityOfSpread => probabilityOfSpread,
            :southWind => southWind,
            :westWind => westWind
        ))

    for pos in positions(forest)
        if rand(Uniform(0,1)) < density
            tree = add_agent!(pos, TreeAgent, forest)
            if pos[1] == 1
                tree.status = burning
            end
        end
    end
    return forest
end
