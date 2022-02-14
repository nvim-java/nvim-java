local module = require("module")

describe("my function", function()
  it("works!", function()
    assert.are.equal("my first function", module.my_first_function())
  end)
end)
