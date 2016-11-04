type AWSCxxConcurrencyError <: AWSCxxError
    msg
end

using Base.Threads

baremodule LockState
    const FREE = 0x00
    const IN_USE = 0x01
    const SHUTTING_DOWN = 0x02
end

const SDK_LOCK = Atomic{UInt8}(LockState.FREE)

type AWSClient
    options

    function AWSClient(options)
        if atomic_cas!(SDK_LOCK, LockState.FREE, LockState.IN_USE) >= LockState.IN_USE
            throw(AWSCxxConcurrencyError(
                "AWSClient already in use (there can only be one)"
            ))
        end

        cl = new(options)
        init(cl)
        finalizer(cl, shutdown)

        return cl
    end
end


function AWSClient()
    o = @cxxnew Aws::SDKOptions()
    return AWSClient(o)
end

function init(cl::AWSClient)
    icxx"Aws::InitAPI(*$(cl.options));"
end

function shutdown(cl::AWSClient)
    if atomic_cas!(SDK_LOCK, LockState.IN_USE, LockState.SHUTTING_DOWN) == LockState.IN_USE
        icxx"Aws::ShutdownAPI(*$(cl.options));"

        atomic_cas!(SDK_LOCK, LockState.SHUTTING_DOWN, LockState.FREE)
    end
end
