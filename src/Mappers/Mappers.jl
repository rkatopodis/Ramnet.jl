module Mappers

using Random

abstract type Mapper end

include("RandomMapper.jl")
export RandomMapper, random_mapping

end