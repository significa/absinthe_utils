# Absinthe Utils

Collection of utilities for [absinthe](https://hexdocs.pm/absinthe).

[![absinthe_utils in hex.pm](https://img.shields.io/hexpm/v/absinthe_utils?style=flat)][hexpm]

[![absinthe_utils documentation](https://img.shields.io/badge/hex.pm-docs-green.svg?style=flat)][hexdocs]

## Installation

[Available in Hex][hexdocs], the package can be installed
by adding `absinthe_utils` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    # Check the releases page for the desired version (and use sigils accordingly, ex: "~>").
    {:absinthe_utils, ">= 0.0.0"}
  ]
end
```

Documentation can be found in [HexDocs].

# Main Features:

- `AbsintheUtils.Middleware.ArgLoader`: Middleware for loading entities in `field` arguments.
- `AbsintheUtils.Middleware.DeprecatedArgs`: Middleware for handling deprecated or renamed `field`
  arguments (`arg`).
- `AbsintheUtils.Scalars.JSON`: JSON scalar.
- `AbsintheUtils.Scalars.UUID`: UUID scalar.
- `AbsintheUtils.Scalars.StrictNaiveDateTime`: NaiveDatetime that does not accept ISO8601 with offset.

# Code standards / re-usable patterns:

- `AbsintheUtils.Types.DateFilterTypes`: Date `from`/`to` filters.
- `AbsintheUtils.Types.PaginationTypes`: Pagination params and details.

[hexpm]: https://hex.pm/packages/absinthe_utils
[hexdocs]: https://hexdocs.pm/absinthe_utils
