typealias CppIOStreamType{QC} CppTemplate{
    CppBaseType{
        Symbol("std::__1::basic_iostream")
    },
    Tuple{
        UInt8,
        CxxQualType{
            CppCharTraitType{UInt8},
            QC
        }
    }
}

typealias CppIOStreamRef{QC, QS} CppRef{
    CppIOStreamType{QC},
    QS
}

type CppIOStream{QC,QS} <: IO
    stream::CppIOStreamRef{QC,QS}
end

function Base.read{QC,QS}(io::CppIOStream{QC,QS}, nb::Integer)
    buffer = Vector{UInt8}(nb)
    @cxx io.stream->read(pointer(buffer), nb)
    return buffer
end

Base.read{QC,QS}(io::CppIOStream{QC,QS}, ::Type{UInt8}) = first(read(io, 1))
Base.eof{QC,QS}(io::CppIOStream{QC,QS}) = @cxx io.stream->eof()

Base.position{QC,QS}(io::CppIOStream{QC,QS}) = icxx"(int) $(io.stream).tellg();"
Base.seek{QC,QS}(io::CppIOStream{QC,QS}, n::Integer) = @cxx io.stream->seekg(n)
