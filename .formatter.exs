[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:plug, :phoenix, :ecto],
  locals_without_parens: [
    render: 2,
    render: 3,
    render: 4
  ]
]
