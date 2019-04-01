module HDF5Browse

using HDF5
using PrettyTables
using UnicodePlots
using LinearAlgebra
using Statistics

function print_block(fun::Function, out=stdout; s="╭", m="│", e="╰")
    io = IOBuffer()
    ds = displaysize(out)
    fun(IOContext(io, :displaysize=>(ds[1],ds[2]-10)))
    output = String(take!(io))
    isempty(output) && return
    data = split(output, "\n")
    isempty(data[end]) && (data = data[1:end-1])
    if length(data) == 1
        println(out, "[ $(data[1])")
    elseif length(data) > 1
        for (p,dl) in zip(vcat(s, repeat([m], length(data)-2), e),data)
            println(out, "$(p) $(dl)")
        end
    end
    println(out)
end

function hdf5printattrs(x::Union{HDF5File, HDF5Group, HDF5Dataset}, io::IO=stdout)
    xattrs = attrs(x)
    if length(xattrs) != 0
        attr_data = map(names(xattrs)) do an
            a = read(xattrs, an)
            [an typeof(a) a]
        end |> d -> vcat(d...)
        pretty_table(io, attr_data, compact, noheader=true)
    end
end

function hdf5browse(x::Union{HDF5File, HDF5Group}, io::IO=stdout)
    println(io, x)
    hdf5printattrs(x, io)
    for n in names(x)
        print_block(io) do io
            hdf5browse(x[n], io)
        end
    end
end

getPlot(x, y, io::IO; canvas::Type = BrailleCanvas,
        height=cld(displaysize(io)[1],3),
        width=displaysize(io)[2]-15,
        kwargs...) =
    Plot(x, y, canvas; height=height, width=width, kwargs...)

function autolineplot!(plt::Plot, data::AbstractVector{<:Real}, args...; kwargs...)
    # v = if all(abs.(data .- 1.0) .< 0.05)
    #     data .- 1.0
    # else
    #     data
    # end
    v = data
    x = 1:length(v)
    vv = abs.(v)
    # if dot(x,vv)/norm(vv) < 0.3length(v)
    #     x = log.(x)
    # end
    lineplot!(plt, x, v, args...; kwargs...)
    plt
end

autolineplot(data::AbstractVector{<:Real}, io::IO, args...; kwargs...) =
    autolineplot!(getPlot(axes(data,1), data, io), data, args...; kwargs...)

function autolineplot!(plt::Plot, data::AbstractMatrix{<:Real}, args...; kwargs...)
    m,n = size(data)
    if m > n
        for j = 1:n
            autolineplot!(plt, view(data, :, j), args...; kwargs...)
        end
    else
        for i = 1:m
            autolineplot!(plt, view(data, i, :), args...; kwargs...)
        end
    end
    plt
end

function autolineplot(data::AbstractMatrix{<:Real}, io::IO, args...;
                      canvas::Type = BrailleCanvas, kwargs...)
    m,n = size(data)
    plt = m > n ? getPlot(1:m, view(data, :, 1), io) : getPlot(1:n, view(data, 1, :), io)
    autolineplot!(plt, data, args...; kwargs...)
end

function hdf5browse(x::HDF5Dataset, io::IO=stdout)
    println(io, x)
    hdf5printattrs(x, io)
    data = read(x)
    println(io, eltype(data), " ", size(data))
    show(IOContext(io, :limit=>true), data)
    println(io)
    if eltype(data) <: Real
        println(io, displaysize(io))
        plt = autolineplot(data, io)
        show(IOContext(io, :color=>true), plt)
        println()
    end
end

hdf5browse(filename::AbstractString) = h5open(hdf5browse, filename, "r")

usage() = println("hdf5browse <filename>")

function cli()
    if length(ARGS) != 1
        usage()
        exit(1)
    end
    if !isfile(ARGS[1])
        println(stderr, "File $(ARGS[1]) not found")
        exit(2)
    end
    hdf5browse(ARGS[1])
end

end # module
