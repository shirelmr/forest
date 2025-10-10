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
        
        if model.bigJumps
            perform_big_jump(tree, model)
        end
        
        tree.status = burnt
    end
end

function perform_big_jump(tree::TreeAgent, model)
    scale_factor = 15
    
    jump_distance_x = round(Int, model.westWind / scale_factor)
    jump_distance_y = round(Int, model.southWind / scale_factor)
    
    if abs(jump_distance_x) == 0 && abs(jump_distance_y) == 0
        return
    end
    
    target_pos = (
        tree.pos[1] + jump_distance_x,
        tree.pos[2] + jump_distance_y
    )
    
    space_dims = size(abmspace(model))
    max_x, max_y = space_dims[1], space_dims[2]
    if target_pos[1] >= 1 && target_pos[1] <= max_x &&
       target_pos[2] >= 1 && target_pos[2] <= max_y
        
        target_tree = nothing
        for agent in allagents(model)
            if agent.pos == target_pos && agent.status == green
                target_tree = agent
                break
            end
        end

        if target_tree !== nothing
            jump_probability = model.probabilityOfSpread * 0.2
            
            if rand(0:100) <= jump_probability
                target_tree.status = burning
                println("🌪️ Big jump! Chispa desde $(tree.pos) llegó a $target_pos (distancia: $(abs(jump_distance_x) + abs(jump_distance_y)))")
            end
        end
    end
end

function forest_fire(; density = 0.45, griddims = (5, 5), probabilityOfSpread = 100, southWind = 0, westWind = 0, bigJumps = false)
    space = GridSpace(griddims; periodic = false, metric = :chebyshev)
    forest = StandardABM(TreeAgent, space; agent_step! = forest_step, scheduler = Schedulers.ByID(), 
        properties = Dict(
            :probabilityOfSpread => probabilityOfSpread,
            :southWind => southWind,
            :westWind => westWind,
            :bigJumps => bigJumps
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
