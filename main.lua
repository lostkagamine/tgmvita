PLATFORM='pc'
function cdofile(f)
    assert(love.filesystem.load(f))()
end

cdofile('index.lua')