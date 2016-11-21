typealias CppAWSAllocatorType{Size} CppTemplate{
    CppBaseType{
        Symbol("Aws::Allocator")
    },
    Tuple{Size}
}
typealias CppCharTraitType{Size} CppTemplate{
    CppBaseType{
        Symbol("std::__1::char_traits")
    },
    Tuple{Size}
}
typealias CppAWSStringType{Size, QC, QA} CppTemplate{
    CppBaseType{
        Symbol("std::__1::basic_string")
    },
    Tuple{
        UInt8,
        CxxQualType{
            CppCharTraitType{Size},
            QC
        },
        CxxQualType{
            CppAWSAllocatorType{Size},
            QA
        }
    }
}

typealias CppAWSString{Size, QC, QA, QS, V} CppValue{
    CxxQualType{
        CppAWSStringType{Size, QC, QA},
        QS
    },
    V
}

typealias CppAWSStringRef{Size, QC, QA, QS} CppRef{
    CppAWSStringType{Size, QC, QA},
    QS
}

isCppAWSString{Size, QC, QA, QS, V}(as::CppAWSString{Size, QC, QA, QS, V}) = true
isCppAWSString(not_as) = false

isCppAWSStringref{Size, QC, QA, QS}(as::CppAWSStringRef{Size, QC, QA, QS}) = true
isCppAWSStringref(not_as) = false

function Base.convert{Size, QC, QA, QS, V}(::Type{String}, as::CppAWSString{Size, QC, QA, QS, V})
    unsafe_string(@cxx as->c_str())
end
function Base.convert{Size, QC, QA, QS}(::Type{String}, as::CppAWSStringRef{Size, QC, QA, QS})
    unsafe_string(@cxx as->c_str())
end

function Base.promote_rule{Size, QC, QA, QS, V}(::Type{String}, ::Type{CppAWSString{Size, QC, QA, QS, V}})
    String
end
function Base.promote_rule{Size, QC, QA, QS}(::Type{String}, ::Type{CppAWSStringRef{Size, QC, QA, QS}})
    String
end

function Base.:(==){Size, QC, QA, QS, V}(as::CppAWSString{Size, QC, QA, QS, V}, s::AbstractString)
    String(as) == s
end
function Base.:(==){Size, QC, QA, QS}(as::CppAWSStringRef{Size, QC, QA, QS}, s::AbstractString)
    String(as) == s
end

function Base.:(==){Size, QC, QA, QS, V}(s::AbstractString, as::CppAWSString{Size, QC, QA, QS, V})
    as == s
end
function Base.:(==){Size, QC, QA, QS}(s::AbstractString, as::CppAWSStringRef{Size, QC, QA, QS})
    as == s
end

function Base.:(==){Size1, QC1, QA1, QS1, V1, Size2, QC2, QA2, QS2, V2}(
    as1::CppAWSString{Size1, QC1, QA1, QS1, V1},
    as2::CppAWSString{Size2, QC2, QA2, QS2, V2},
)
    (@cxx as1->compare(as2)) == 0
end
function Base.:(==){Size1, QC1, QA1, QS1, Size2, QC2, QA2, QS2, V2}(
    as1::CppAWSStringRef{Size1, QC1, QA1, QS1},
    as2::CppAWSString{Size2, QC2, QA2, QS2, V2},
)
    (@cxx as1->compare(as2)) == 0
end
function Base.:(==){Size1, QC1, QA1, QS1, V1, Size2, QC2, QA2, QS2}(
    as1::CppAWSString{Size1, QC1, QA1, QS1, V1},
    as2::CppAWSStringRef{Size2, QC2, QA2, QS2},
)
    (@cxx as1->compare(as2)) == 0
end
function Base.:(==){Size1, QC1, QA1, QS1, Size2, QC2, QA2, QS2}(
    as1::CppAWSStringRef{Size1, QC1, QA1, QS1},
    as2::CppAWSStringRef{Size2, QC2, QA2, QS2},
)
    (@cxx as1->compare(as2)) == 0
end

function Base.show{Size, QC, QA, QS, V}(io::IO, as::CppAWSString{Size, QC, QA, QS, V})
    print(io, "Aws::String(\"", String(as), "\")")
end
function Base.show{Size, QC, QA, QS}(io::IO, as::CppAWSStringRef{Size, QC, QA, QS})
    print(io, "Aws::String&(\"", String(as), "\")")
end
