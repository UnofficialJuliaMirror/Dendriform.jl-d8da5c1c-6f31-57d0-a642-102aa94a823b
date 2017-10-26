# This file is part of Dendriform.jl. It is licensed under the GPL license
# Dendriform Copyright (C) 2017 Michael Reed

export ∪, ∨, graft, left, right, over, under, ↗, ↖, dashv, vdash, ⊣, ⊢, +, *

# union

"""
    ∪(g...)

Returns union of AbstractGrove objects
"""
function ∪(x::Grove,y::Vararg{Grove})
    L = 1:length(y)
    out = Grove(.|(grovebit(x),[grovebit(y[i]) for i ∈ L]...))
    s = x.size
    for i ∈ L
        s += y[i].size
    end
    s = s - out.size
    s ≠ 0 && info("$s duplicate$(s>1?'s':"") in grove union")
    return out
end

∪(x::NotGrove,y::Vararg{Grove}) = ∪(convert(Grove,x),y...)
∪{T<:Union{NotGrove,Grove}}(x::Grove,y::Vararg{T}) = ∪(promote(x,y...)...)
∪{T<:NotGrove}(x::NotGrove,y::Vararg{T}) = ∪(promote(convert(Grove,x),y...)...)
∪(x::NotGrove) = Grove(x); ∪(x::Grove) = x

# grafting

"""
    ∨(left::AbstractPBTree, right::AbstractPBTree)

Grafts the left and right AbstractPBTree objects
"""
function ∨(L::PBTree,R::PBTree) # graft()
    Ld = L.degr
    Rd = R.degr
    n = Ld + Rd
    G = PBTree(n+1,Array{UInt8,1}(n+1))
    G.Y[Ld+1] = n+1
    G.Y[1:Ld] = L.Y[:]
    G.Y[Ld+2:Ld+Rd+1] = R.Y[:]
    return G
end

∨(L::Ar1UI8I,R::PBTree) = PBTree(L) ∨ R; ∨(L::PBTree,R::Ar1UI8I) = L ∨ PBTree(R)
∨(L::Ar1UI8I,R::Ar1UI8I) = PBTree(L) ∨ PBTree(R)

"""
    graft(left::AbstractPBTree, right::AbstractPBTree)

Grafts the left and right PBTree with root vertex
"""
graft(x::AbstractPBTree,y::AbstractPBTree) = x ∨ y

# branching

"""
    left(::AbstractPBTree)

Returns the left branch of an AbstractPBTree
"""
function left(t::PBTree)
    fx = findfirst(ξ->(ξ==t.degr),t.Y)
    fx>1 && (return PBTree(fx-1,t.Y[1:fx-1]))
    return PBTree(0x00,Array{UInt8,1}(0))
end

left(t::Ar1UI8I) = left(convert(PBTree,t))

"""
    right(::AbstractPBTree)

Returns the right branch of an AbstractPBTree
"""
function right(t::PBTree)
    fx = findfirst(ξ->(ξ==t.degr),t.Y)
    fx<t.degr && (return PBTree(t.Y[fx+1:end]))
    return PBTree(0x00,Array{UInt8,1}(0))
end

right(t::Ar1UI8I) = right(convert(PBTree,t))

# partial ordering

"""
    Dendriform.posetnext(::PBTree)

Returns an Array{PBTree,1} of trees that are greater than it
"""
function posetnext(t::PBTree)
    g = Array{PBTree,1}()
    λ = left(t)
    ρ = right(t)
    x = left(λ) ∨ (right(λ) ∨ ρ)
    x.degr == t.degr && push!(g,x)
    if λ.degr ≠ 0x00
        gλ = posetnext(λ)
        for i ∈ 1:length(gλ)
            gλ[i] = gλ[i] ∨ ρ
        end
        push!(g,gλ...)
    end
    if ρ.degr ≠ 0x00
        gρ= posetnext(ρ)
        for i ∈ 1:length(gρ)
            gρ[i] = λ ∨ gρ[i]
        end
        push!(g,gρ...)
    end
    return g
end

"""
    Dendriform.posetprev(::PBTree)

Returns an Array{PBTree,1} of trees that are less than it
"""
function posetprev(t::PBTree)
    g = Array{PBTree,1}()
    λ = left(t)
    ρ = right(t)
    x = (λ ∨ left(ρ)) ∨ right(ρ)
    x.degr == t.degr && push!(g,x)
    if λ.degr ≠ 0x00
        gλ = posetprev(λ)
        for i ∈ 1:length(gλ)
            gλ[i] = gλ[i] ∨ ρ
        end
        push!(g,gλ...)
    end
    if ρ.degr ≠ 0x00
        gρ = posetprev(ρ)
        for i ∈ 1:length(gρ)
            gρ[i] = λ ∨ gρ[i]
        end
        push!(g,gρ...)
    end
    return g
end

"""
    <(a::AbstractPBTree, b::AbstractPBTree)

Returns Bool that tells if a < b in Tamari partial order
"""
<(a::PBTree,b::PBTree) = b ∈ posetnext(a)
<(a::AbstractPBTree,b::AbstractPBTree) = PBTree(a) < PBTree(b)

"""
    >(a::AbstractPBTree, b::AbstractPBTree)

Returns Bool that tells if a > b in Tamari partial order
"""
>(a::PBTree,b::PBTree) = b ∈ posetprev(a)
>(a::AbstractPBTree,b::AbstractPBTree) = PBTree(a) > PBTree(b)

"""
    ≤(a::AbstractPBTree, b::AbstractPBTree)

Returns Bool that tells if a ≤ b in Tamari partial order
"""
≤(a::PBTree,b::PBTree) = (a == b) || (a < b)
≤(a::AbstractPBTree,b::AbstractPBTree) = PBTree(a) ≤ PBTree(b)

"""
    ≥(a::AbstractPBTree, b::AbstractPBTree)

Returns Bool that tells if a ≥ b in Tamari partial order
"""
≥(a::PBTree,b::PBTree) = (a == b) || (a > b)
≥(a::AbstractPBTree,b::AbstractPBTree) = PBTree(a) ≥ PBTree(b)

# over / under

"""
    ↗(a::AbstractPBTree, b::AbstractPBTree)

Returns PBTRee obtained from a over b operation
"""
↗(x::AbstractPBTree,y::AbstractPBTree) = over(x,y)

"""
    over(a::AbstractPBTree, b::AbstractPBTree)

Returns PBTRee obtained from a over b operation
"""
over(x::PBTree,y::PBTree) = y.degr > 1 ? over(x,left(y)) ∨ right(y) : x ∨ PBTree(0,1)
over(x::AbstractPBTree,y::AbstractPBTree) = over(PBTree(x),PBTree(y))

"""
    ↖(a::AbstractPBTree, b::AbstractPBTree)

Returns PBTRee obtained from a under b operation
"""
↖(x::PBTree,y::PBTree) = under(x,y)

"""
    under(a::AbstractPBTree, b::AbstractPBTree)

Returns PBTRee obtained from a under b operation
"""
under(x::PBTree,y::PBTree) = x.degr > 1 ? left(x) ∨ under(right(x),y) : PBTree(0,1) ∨ y
under(x::AbstractPBTree,y::AbstractPBTree) = under(PBTree(x),PBTree(y))

# arithmetic (left)

"""
    ⊣(a::AbstractGrove, b::AbstractGrove)

Returns Grove obtained from a ⊣ b operation
"""
function ⊣(x::PBTree,y::PBTree)
    x.degr == 0 && (return Grove(0))
    y.degr == 0 && (return Grove(x))
    sm = right(x)+y
    blx = left(x)
    isempty(sm.Y) && (return Grove(blx ∨ Array{UInt8,1}(0)))
    ls = sm.size
    addl = Grove(Array{UInt8,2}(ls,sm.degr + blx.degr + 1))
    for i ∈ 1:ls
        addl.Y[i,:] = (blx ∨ sm.Y[i,:]).Y
    end
    return addl
end

function ⊣(x::Grove,y::PBTree)
    x.degr == 0 && (return Grove(0))
    y.degr == 0 && (return Grove(x))
    γ = x.size
    gr = Array{Array,1}(γ)
    for i ∈ 1:γ
        gr[i] = (PBTree(x.Y[i,:]) ⊣ y).Y
    end
    return Grove(vcat(gr...))
end

function ⊣(x::PBTree,y::Grove)
    x.degr == 0 && (return Grove(0))
    y.degr == 0 && (return Grove(x))
    γ = y.size
    gr = Array{Array,1}(γ)
    for i ∈ 1:γ
        gr[i] = (x ⊣ PBTree(y.Y[i,:])).Y
    end
    return Grove(vcat(gr...))
end

function ⊣(x::Grove,y::Grove)
    x.degr == 0 && (return Grove(0))
    y.degr == 0 && (return Grove(x))
    γ = x.size
    gr = Array{Array,1}(γ)
    for i ∈ 1:γ
        gr[i] = (PBTree(x.Y[i,:]) ⊣ y).Y
    end
    return Grove(vcat(gr...))
end

⊣(x::NotGrove,y::Grove) = Grove(x) ⊣ y
⊣(x::Grove,y::NotGrove) = x ⊣ Grove(y)
⊣(x::NotGrove,y::NotGrove) = Grove(x) ⊣ Grove(y)
⊣(x::Ar1UI8I,y::Ar1UI8I) = PBTree(x) ⊣ PBTree(y)

"""
    dashv(a::AbstractGrove, b::AbstractGrove)

Returns Grove obtained from a ⊣ b operation
"""
dashv(x::Union{Grove,NotGrove},y::Union{Grove,NotGrove}) = x ⊣ y

# arithmetic (right)

"""
    ⊢(a::AbstractGrove, b::AbstractGrove)

Returns Grove obtained from a ⊢ b operation
"""
function ⊢(x::PBTree,y::PBTree)
    y.degr == 0 && (return Grove(0))
    x.degr == 0 && (return Grove(y))
    sm = x+left(y)
    bry = right(y)
    isempty(sm.Y) && (return Grove(Array{UInt8,1}(0) ∨ bry))
    ls = sm.size
    addr = Grove(Array{UInt8,2}(ls,sm.degr + bry.degr + 1))
    for i ∈ 1:ls
        addr.Y[i,:] = (sm.Y[i,:] ∨ bry).Y
    end
    return addr
end

function ⊢(x::PBTree,y::Grove)
    y.degr == 0 && (return Grove(0))
    x.degr == 0 && (return Grove(y))
    γ = y.size
    gr = Array{Array,1}(γ)
    for i ∈ 1:γ
        gr[i] = (x ⊢ PBTree(y.Y[i,:])).Y
    end
    return Grove(vcat(gr...))
end

function ⊢(x::Grove,y::PBTree)
    y.degr == 0 && (return Grove(0))
    x.degr == 0 && (return Grove(y))
    γ = x.size
    gr = Array{Array,1}(γ)
    for i ∈ 1:γ
        gr[i] = (PBTree(x.Y[i,:]) ⊢ y).Y
    end
    return Grove(vcat(gr...))
end

function ⊢(x::Grove,y::Grove)
    y.degr == 0 && (return Grove(0))
    x.degr == 0 && (return Grove(y))
    γ = x.size
    gr = Array{Array,1}(γ)
    for i ∈ 1:γ
        gr[i] = (PBTree(x.Y[i,:]) ⊢ y).Y
    end
    return Grove(vcat(gr...))
end

⊢(x::NotGrove,y::Grove) = Grove(x) ⊢ y
⊢(x::Grove,y::NotGrove) = x ⊢ Grove(y)
⊢(x::NotGrove,y::NotGrove) = Grove(x) ⊢ Grove(y)
⊢(x::Ar1UI8I,y::Ar1UI8I) = PBTree(x) ⊢ PBTree(y)

"""
    vdash(a::AbstractGrove, b::AbstractGrove)

Returns Grove obtained from a ⊢ b operation
"""
vdash(x::Union{Grove,NotGrove},y::Union{Grove,NotGrove}) = x ⊢ y

# dendriform addition

"""
    +(a::AbstractGrove, b::AbstractGrove)

Returns Grove obtained from a + b operation
"""
function +(x::Grove,y::Grove)
    isempty(x.Y) && (return y)
    isempty(y.Y) && (return x)
    lx = x.size
    ly = y.size
    ij = Array{Array,2}(lx,ly)
    for i ∈ 1:lx
        for j ∈ 1:ly
            l = Grove(PBTree(x.Y[i,:]) ⊣ PBTree(y.Y[j,:]))
            r = Grove(PBTree(x.Y[i,:]) ⊢ PBTree(y.Y[j,:]))
            ij[i,j] = vcat(l.Y,r.Y)
    end; end
    return Grove(vcat(ij...))
end

+(x::Union{Grove,GroveBin,PBTree},y::NotGrove) = x + convert(Grove,y)
+(x::NotGrove,y::Union{Grove,GroveBin,PBTree}) = convert(Grove,x) + y
+(x::Union{GroveBin,PBTree},y::Union{GroveBin,PBTree}) = Grove(x) + Grove(y)

# dendriform multiplication

"""
    *(a::AbstractGrove, b::AbstractGrove)

Returns Grove obtained from a × b operation
"""
function *(x::PBTree,y::Grove)::Grove
    x.degr == 0 && (return Grove(0))
    x.degr == 1 && (return y)
    return (left(x)*y ⊢ y) ⊣ right(x)*y
end

function *(x::Grove,y::Grove)::Grove
    x.degr == 0 && (return Grove(0))
    x.degr == 1 && (return y)
    out = Array{Array,1}(x.size)
    for j ∈ 1:x.size
        out[j] = (x.Y[j,:]*y).Y
    end
    return Grove(vcat(out...))
end

*(x::Union{Grove,PBTree},y::NotGrove) = x*convert(Grove,y)
*(x::GroveBin,y::NotGrove) = Grove(x)*convert(Grove,y)
*(x::Ar1UI8I,y::Union{Grove,PBTree}) = convert(PBTree,x)*y
*(x::Union{Ar1UI8I},y::GroveBin) = convert(PBTree,x)*Grove(y)
*(x::Union{Ar2UI8I,UI8I},y::Union{Grove,PBTree}) = convert(Grove,x)*y
*(x::Union{Ar2UI8I,UI8I},y::GroveBin) = convert(Grove,x)*Grove(y)
*(x::GroveBin,y::Grove) = Grove(x)*y
