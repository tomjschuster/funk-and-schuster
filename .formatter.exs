[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:plug, :ecto],
  locals_without_parens: [
    render: 2,
    render: 3,
    render: 4,
    add: 1,
    add: 2,
    add: 3,
    pipe_through: 1,
    resources: 2,
    resources: 3
  ]
]
