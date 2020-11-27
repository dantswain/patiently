# Patiently

[![Elixir CI](https://github.com/dantswain/patiently/workflows/Elixir%20CI/badge.svg)]
[![Module Version](https://img.shields.io/hexpm/v/patiently.svg)](https://hex.pm/packages/patiently)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/patiently/)
[![Total Download](https://img.shields.io/hexpm/dt/patiently.svg)](https://hex.pm/packages/patiently)
[![License](https://img.shields.io/hexpm/l/patiently.svg)](https://hex.pm/packages/patiently)
[![Last Updated](https://img.shields.io/github/last-commit/dantswain/patiently.svg)](https://github.com/dantswain/patiently/commits/main)


Helpers for waiting on asynchronous events.

Patiently is built with testing in mind, but there's nothing in the
code that makes it inappropriate for use elsewhere.

If possible, we should avoid writing code that needs Patiently, but
sometimes we can't avoid situations where the only way to tell that an
event has occurred is to repeatedly call some function.  For example,
we may need to publish a message to a broker and then verify that it has
been consumed.

At the heart of Patiently is a loop with simple behavior:

1. A function is executed at the beginning of each iteration.
2. If the function returns true, we are done.
3. If the function returns false, dwell (sleep) a short time and try again.
4. After a maximum number of tries, return an error or raise an exception.

## Example usage

```
defmodule MyTest do
  use ExUnit.Case
  
  test "wait for some thing to happen" do
    condition = fn -> :random.uniform(10) > 5 end
    
    # non-exception usage
    assert :ok == Patiently.wait_for(condition)

    # raise an exception if an error occurs (which will fail the test)
    Patiently.wait_for!(condition)
    
    # specify the dwell time and maximum number of tries
    Patiently.wait_for!(
      condition,
      dwell: 10, #msec
      max_tries: 100
    )
  end
end
```

## Contributing

The standard Github workflow applies.  Pull requests are welcome!
