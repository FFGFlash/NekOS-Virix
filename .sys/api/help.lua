local help = api(0, {
  { type = 'api', name = 'program' }
})

function help:execute(args, program, ...)
  if not program then
    print('Welcome to NekOS')
    for name, program in pairs(api.List) do
      if type(program) == 'table' then
        if program.printUsage then
          program:printUsage()
        end
      end
    end
  else
    program = api.List[program]
    if not program then
      print('Unknown prgoram')
      self:execute(args)
    else
      program:printUsage()
    end
  end
end

return help:call(...)
