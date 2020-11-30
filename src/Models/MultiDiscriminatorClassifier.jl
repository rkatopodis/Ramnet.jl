# TODO: Allow the instantiation without the specification of width (Could be
#       determined from the training data)
# TODO: Check how other classification models handle the target type. Should I 
#       simply enforce it to be an integer? Furthermore, a may consider enforcing
#       targets to be in the range [1, nclasses]. These could be label encoded
#       by the user or the model could detect and perform the encoding. If I did
#       this, `discriminators` could simply be a list, with the discriminator's
#       indices being the target they are associated to. `predict_response` return
#       would also be simplified to a vector or matrix
struct MultiDiscriminatorClassifier{C, N <: Discriminator} <: AbstractModel
    mapper::RandomMapper
    discriminators::Dict{C,N}

    function MultiDiscriminatorClassifier{C,N}(width::Int, n::Int; seed::Union{Nothing,Int}=nothing) where {C,N<:Discriminator}
        mapper = RandomMapper(width, n; seed)

        new{C,N}(mapper, Dict{C,N}())
    end
end

# Default discriminator type is Discriminator
MultiDiscriminatorClassifier{C}(args...; kargs...) where C = 
    MultiDiscriminatorClassifier{C,Discriminator}(args...; kargs...)

function train!(model::MultiDiscriminatorClassifier{C,N}, X::T, y::C) where {T <: AbstractVector{Bool}, C, N <: Discriminator}
    train!(get!(model.discriminators, y) do
        N(model.mapper)
    end, X)
end

function train!(model::MultiDiscriminatorClassifier{C}, X::T, y::AbstractVector{C}) where {T <: AbstractMatrix{Bool}, C}
    size(X, 1) != size(y, 1) && throw(
        DimensionMismatch("Number of observations (rows in X) must match the number of targets (elements in y)"))
        
    # I could create all necessary discriminators upfront, which could lead to a gain in performance. On the other hand, 
    # the current design fits quite nicely with the repetitive training that is common in RL.
    
    for i in eachindex(y)
        train!(model, X[i, :], y[i])
    end
end

# TODO: Check if model was trained
function predict(model::MultiDiscriminatorClassifier{C}, X::T) where {T <: AbstractVector{Bool},C}
    largest_response = -1
    best_category = first(keys(model.discriminators))

    for (category, discriminator) in model.discriminators
        response = predict(discriminator, X)

        if response > largest_response
            largest_response = response
            best_category = category
        end
    end

    return best_category
end

function predict(model::MultiDiscriminatorClassifier{C}, X::AbstractMatrix{Bool}) where {C}
    return C[predict(model, row) for row in eachrow(X)]
end

function predict_response(model::MultiDiscriminatorClassifier{C}, X::T) where {T <: AbstractVecOrMat{Bool},C}
    Dict(k => predict(d, X) for (k,d) in model.discriminators)
end

# Once again, a should be able to avoid this replication
function predict(model::MultiDiscriminatorClassifier{C,BleachingDiscriminator}, X::T; b=0) where {T <: AbstractVector{Bool},C}
    largest_response = -1
    best_category = first(keys(model.discriminators))

    for (category, discriminator) in model.discriminators
        response = predict(discriminator, X; b)

        if response > largest_response
            largest_response = response
            best_category = category
        end
    end

    return best_category
end

function predict(model::MultiDiscriminatorClassifier{C,BleachingDiscriminator}, X::AbstractMatrix{Bool}; b=0) where {C}
    return C[predict(model, row; b) for row in eachrow(X)]
end

function predict_response(model::MultiDiscriminatorClassifier{C,BleachingDiscriminator}, X::T; b=0) where {T <: AbstractVecOrMat{Bool},C}
    Dict(k => predict(d, X; b) for (k,d) in model.discriminators)
end