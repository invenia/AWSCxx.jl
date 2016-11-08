using ResultTypes

typealias CppAWSErrorType{C, I<:Integer} CppTemplate{CppBaseType{Symbol("Aws::Client::AWSError")}, Tuple{CppEnum{C, I}}}
typealias CppAWSError{C, I<:Integer, Q} CppRef{CppAWSErrorType{C, I}, Q}
typealias CppAWSOutcome{R, QR, C, I, QET, QO, V} CppValue{CxxQualType{CppTemplate{CppBaseType{Symbol("Aws::Utils::Outcome")}, Tuple{CxxQualType{R, QR}, CxxQualType{CppAWSErrorType{C, I}, QET}}}, QO}, V}
typealias CppAWSResult{R, Q} CppRef{R, Q}

### AWSError

type AWSError{C, I<:Integer, Q} <: AWSCxxError
    cpp_error::CppAWSError{C, I, Q}
    type_enum::CppEnum{C, I}
    name::String
    message::String
end

function AWSError{C, I, Q}(cpp_error::CppAWSError{C, I, Q})
    AWSError{C, I, Q}(
        cpp_error,
        error_type(cpp_error),
        name(cpp_error),
        message(cpp_error),
    )
end

function name{C, I, Q}(cpp_error::CppAWSError{C, I, Q})
    unsafe_string(@cxx (@cxx cpp_error->GetExceptionName())->c_str())
end

function message{C, I, Q}(cpp_error::CppAWSError{C, I, Q})
    unsafe_string(@cxx (@cxx cpp_error->GetMessage())->c_str())
end

function error_type{C, I, Q}(cpp_error::CppAWSError{C, I, Q})
    @cxx cpp_error->GetErrorType()
end

name(aws_error::AWSError) = aws_error.name
message(aws_error::AWSError) = aws_error.message

function Base.showerror(io::IO, aws_error::AWSError)
    print(io, "AWSError: ", name(aws_error), ": ", message(aws_error))
end

### AWSError

### AWSOutcome

typealias AWSOutcome{R, QR, C, I, QE} Result{CppAWSResult{R, QR}, AWSError{C, I, QE}}

function AWSOutcome{R, QR, C, I, QET, QO, V}(outcome::CppAWSOutcome{R, QR, C, I, QET, QO, V})
    if @cxx outcome->IsSuccess()
        return Result((@cxx outcome->GetResult()), AWSError{C, I, QET})
    else
        return ErrorResult(CppAWSResult{R, QR}, AWSError(@cxx outcome->GetError()))
    end
end

### AWSOutcome
