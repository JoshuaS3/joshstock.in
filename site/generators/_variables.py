def verify(input_variables, requires):
    for name in requires:
        if not name in input_variables:
            raise KeyError(f"Generator requires variable {name} in inputed variables")
