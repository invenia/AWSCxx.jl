typealias CppAWSMapType{K, QK, QKC, V, QV} CppTemplate{
    CppBaseType{
        Symbol("std::__1::map")
    },
    Tuple{
        CxxQualType{
            K,
            QK
        },
        CxxQualType{
            V,
            QV
        },
        CxxQualType{
            CppTemplate{
                CppBaseType{
                    Symbol("std::__1::less")
                },
                Tuple{
                    CxxQualType{
                        K,
                        QK
                    }
                }
            },
            (false,false,false)
        },
        CxxQualType{
            CppAWSAllocatorType{
                CxxQualType{
                    CppTemplate{
                        CppBaseType{
                            Symbol("std::__1::pair")
                        },
                        Tuple{
                            CxxQualType{
                                K,
                                QKC  # QK but with const set to true
                            },
                            CxxQualType{
                                V,
                                QV
                            }
                        }
                    },
                    (false,false,false)
                }
            },
            (false,false,false)
        }
    }
}

typealias CppAWSMap{K, QK, QKC, V, QV, QM, VM} CppValue{
    CxxQualType{
        CppAWSMapType{K, QK, QKC, V, QV},
        QM
    },
    VM
}

typealias CppAWSMapRef{K, QK, QKC, V, QV, QM} CppRef{
    CppAWSMapType{K, QK, QKC, V, QV},
    QM
}

function Base.convert{DK, DV, K, QK, QKC, V, QV, QM, VM}(
    ::Type{Dict{DK, DV}},
    aws_map::CppAWSMap{K, QK, QKC, V, QV, QM, VM},
)
    copy!(Dict{DK, DV}(), aws_map)
end

function Base.convert{DK, DV, K, QK, QKC, V, QV, QM}(
    ::Type{Dict{DK, DV}},
    aws_map::CppAWSMapRef{K, QK, QKC, V, QV, QM},
)
    copy!(Dict{DK, DV}(), aws_map)
end

function Base.copy!{AK, AV, K, QK, QKC, V, QV, QM, VM}(
    a::Associative{AK, AV},
    aws_map::CppAWSMap{K, QK, QKC, V, QV, QM, VM},
)
    _copy_from_aws_map!(a, aws_map)
end

function Base.copy!{AK, AV, K, QK, QKC, V, QV, QM}(
    a::Associative{AK, AV},
    aws_map::CppAWSMapRef{K, QK, QKC, V, QV, QM},
)
    _copy_from_aws_map!(a, aws_map)
end

function _copy_from_aws_map!{K, V}(julia_map::Associative{K, V}, aws_map)
    iterator = icxx"$aws_map.cbegin();"
    iterator_end = icxx"$aws_map.cend();"
    while icxx"$iterator != $iterator_end;"
        aws_key = icxx"""
            auto key_item = $iterator->first;
            key_item;
        """
        aws_value = icxx"$iterator->second;"

        setindex!(julia_map, V(aws_value), K(aws_key))

        icxx"(void)(++$iterator);"
    end

    return julia_map
end

function Base.copy!{K, QK, QKC, V, QV, QM, VM}(
    aws_map::CppAWSMap{K, QK, QKC, V, QV, QM, VM},
    julia_pairs,
)
    _copy_to_aws_map!(aws_map, julia_map)
end

function Base.copy!{K, QK, QKC, V, QV, QM}(
    aws_map::CppAWSMapRef{K, QK, QKC, V, QV, QM},
    julia_pairs,
)
    _copy_to_aws_map!(aws_map, julia_map)
end

function _copy_to_aws_map!(aws_map, julia_pairs)
    for p in julia_pairs
        push!(aws_map, p)
    end

    return aws_map
end

function aws_string_map(julia_map)
    aws_map = icxx"Aws::Map<Aws::String, Aws::String>();"

    for (k, v) in julia_map
        aws_key = aws_string(k)
        aws_value = aws_string(v)

        icxx"($aws_map)[$aws_key] = $aws_value;"
    end

    return aws_map
end

### begin setindex!

function Base.setindex!{K, QK, QKC, V, QV, QM, VM}(
    aws_map::CppAWSMap{K, QK, QKC, V, QV, QM, VM},
    aws_value::cxxt"$V",
    aws_key::cxxt"$K",
)
    return _aws_map_setindex!(aws_map, aws_value, aws_key)
end

function Base.setindex!{K, QK, QKC, V, QV, QM}(
    aws_map::CppAWSMapRef{K, QK, QKC, V, QV, QM},
    aws_value::cxxt"$V",
    aws_key::cxxt"$K",
)
    return _aws_map_setindex!(aws_map, aws_value, aws_key)
end

function _aws_map_setindex!(aws_map, aws_value, aws_key)
    icxx"($aws_map)[$aws_key] = $aws_value;"

    return aws_value
end

function Base.setindex!{K, QK, QKC, V, QV, QM, VM}(
    aws_map::CppAWSMap{K, QK, QKC, V, QV, QM, VM},
    value,
    key,
)
    return _aws_map_convert_setindex!(aws_map, value, key)
end

function Base.setindex!{K, QK, QKC, V, QV, QM}(
    aws_map::CppAWSMapRef{K, QK, QKC, V, QV, QM},
    value,
    key,
)
    return _aws_map_convert_setindex!(aws_map, value, key)
end

function _aws_map_convert_setindex!(aws_map, value, key)
    aws_value = convert(cxxt"$V", value)
    aws_key = convert(cxxt"$K", key)

    return Base.setindex!(aws_map, aws_value, aws_key)
end

function Base.push!{K, QK, QKC, V, QV, QM, VM}(
    aws_map::CppAWSMap{K, QK, QKC, V, QV, QM, VM},
    kv,
)
    _aws_map_push!(aws_map, kv)
end

function Base.push!{K, QK, QKC, V, QV, QM}(
    aws_map::CppAWSMapRef{K, QK, QKC, V, QV, QM},
    kv,
)
    _aws_map_push!(aws_map, kv)
end

function _aws_map_push!(aws_map, kv)
    (a, b) = kv

    return Base.setindex!(aws_map, b, a)
end

### end setindex!

### begin getindex

function Base.getindex{K, QK, QKC, V, QV, QM, VM}(
    aws_map::CppAWSMap{K, QK, QKC, V, QV, QM, VM},
    aws_key::cxxt"$K",
)
    return _aws_map_getindex(aws_map, aws_key)
end

function Base.getindex{K, QK, QKC, V, QV, QM}(
    aws_map::CppAWSMapRef{K, QK, QKC, V, QV, QM},
    aws_key::cxxt"$K",
)
    return _aws_map_getindex(aws_map, aws_key)
end

function _aws_map_getindex(aws_map, aws_key)
    icxx"($aws_map)[$aws_key];"

    return aws_value
end

function Base.getindex{K, QK, QKC, V, QV, QM, VM}(
    aws_map::CppAWSMap{K, QK, QKC, V, QV, QM, VM},
    key,
)
    return _aws_map_convert_getindex(aws_map, key)
end

function Base.getindex{K, QK, QKC, V, QV, QM}(
    aws_map::CppAWSMapRef{K, QK, QKC, V, QV, QM},
    key,
)
    return _aws_map_convert_getindex(aws_map, key)
end

function _aws_map_convert_getindex(aws_map, key)
    aws_key = convert(cxxt"$K", key)

    return Base.getindex(aws_map, aws_key)
end

### end getindex
