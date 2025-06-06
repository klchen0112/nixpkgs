{ pkgs, package, ... }:
let
  testPath = pkgs.hello;
in
{
  name = "varnish";
  meta = {
    maintainers = [ ];
  };

  nodes = {
    varnish =
      { config, pkgs, ... }:
      {
        services.nix-serve = {
          enable = true;
        };

        services.varnish = {
          inherit package;
          enable = true;
          http_address = "0.0.0.0:80";
          config = ''
            vcl 4.0;

            backend nix-serve {
              .host = "127.0.0.1";
              .port = "${toString config.services.nix-serve.port}";
            }
          '';
        };

        networking.firewall.allowedTCPPorts = [ 80 ];
        system.extraDependencies = [ testPath ];
      };

    client =
      { lib, ... }:
      {
        nix.settings = {
          require-sigs = false;
          substituters = lib.mkForce [ "http://varnish" ];
        };
      };
  };

  testScript = ''
    start_all()
    varnish.wait_for_open_port(80)

    client.wait_until_succeeds("curl -f http://varnish/nix-cache-info");

    client.wait_until_succeeds("nix-store -r ${testPath}")
    client.succeed("${testPath}/bin/hello")

    output = varnish.succeed("varnishadm status")
    print(output)
    assert "Child in state running" in output, "Unexpected varnishadm response"
  '';
}
