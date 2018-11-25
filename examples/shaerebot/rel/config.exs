use Mix.Releases.Config,
  default_release: :shaere,
  default_environment: Mix.env()

environment :dev do
  # If you are running Phoenix, you should make sure that
  # server: true is set and the code reloader is disabled,
  # even in dev mode.

  # It is recommended that you build with MIX_ENV=prod and pass
  # the --env flag to Distillery explicitly if you want to use
  # dev mode.

  set(dev_mode: true)
  set(include_erts: false)
  set(cookie: :"Fd%VRKtzn~i4NW)90k,x@rmg}8yzjy$saopt}@*1Y>C.GvuJV_TCkymm~NS9}=E;")
end

environment :prod do
  set(include_erts: true)
  set(include_src: false)
  # TODO
  set(cookie: :"Fx~HtF<Dlm>7&Z6xRp4Uj{/37HPButwI7.XGd8k0S:l6yB9UxoHND4VVzsP%W2Lb")
  set(vm_args: "rel/vm.args")

  set(output_dir: "releases")

  set(
    overlays: [
      {:copy, "rel/etc/shaerebot.service", "etc/shaerebot.service"},
      {:copy, "rel/etc/config.exs", "etc/config.exs"}
      # {:link, "rel/etc/shaerebot.service", "/etc/systemd/system/shaerebot.service"}
    ]
  )

  set(
    config_providers: [
      {Mix.Releases.Config.Providers.Elixir, ["${RELEASE_ROOT_DIR}/etc/config.exs"]}
    ]
  )
end

release :shaerebot do
  set(version: "0.1.0")

  set(
    applications: [
      :runtime_tools,
      core: :permanent,
      tgbot: :permanent,
      web: :permanent
    ]
  )
end
