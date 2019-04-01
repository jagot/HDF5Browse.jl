module HDF5Browse

using HDF5
using PrettyTables

function print_block(fun::Function, out=stdout; s="╭", m="│", e="╰")
    io = IOBuffer()
    fun(io)
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
    print_block(io) do io
        for n in names(x)
            hdf5browse(x[n], io)
        end
    end
end

function hdf5browse(x::HDF5Dataset, io::IO=stdout)
    println(io, x)
    hdf5printattrs(x, io)
    data = read(x)
    println(io, eltype(data), " ", size(data))
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
