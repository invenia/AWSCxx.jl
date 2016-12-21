typealias CppVectorType{T, QB, QA} CppTemplate{
    CppBaseType{
        Symbol("std::__1::vector")
    },
    Tuple{
        CxxQualType{
            CppBaseType{T},
            QB
        },
        CxxQualType{
            CppAWSAllocatorType{
                CxxQualType{
                    CppBaseType{T},
                    QB
                }
            },
            QA
        }
    }
}

typealias CppVectorRef{T, QB, QA, QS} CppRef{
    CppVectorType{T,QB,QA},
    QS
}

Base.start{T, QB, QA, QS}(vec::CppVectorRef{T,QB,QA,QS}) = 0

function Base.next{T, QB, QA, QS}(vec::CppVectorRef{T,QB,QA,QS}, state)
    return icxx"$vec[$state];", state + 1
end

Base.done{T, QB, QA, QS}(vec::CppVectorRef{T,QB,QA,QS}, state) = state > endof(vec)

Base.endof{T, QB, QA, QS}(vec::CppVectorRef{T,QB,QA,QS}) = length(vec) - 1
Base.length{T, QB, QA, QS}(vec::CppVectorRef{T,QB,QA,QS}) = @cxx vec->size()
