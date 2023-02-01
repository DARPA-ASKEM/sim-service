module Settings

from_env(var::String) = get(ENV, var, nothing)

SETTINGS_VARS = [
    "S3_BUCKET"
    "AWS_ACCESS_KEY_ID"
    "AWS_SECRET_ACCESS_KEY"
]

function load(chosen_vars::Vector{String})
    for var in chosen_vars
        name = Symbol(var)
        value = from_env(var)
        eval(:($name = $value))
    end
end

__init__ = () -> load(SETTINGS_VARS)

end
