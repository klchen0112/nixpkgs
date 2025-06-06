{
  buildGoModule,
  coreutils,
  fetchFromGitHub,
  git,
  installShellFiles,
  kubectl,
  kubernetes-helm,
  lib,
  makeWrapper,
  yamale,
  yamllint,
}:

buildGoModule rec {
  pname = "chart-testing";
  version = "3.12.0";

  src = fetchFromGitHub {
    owner = "helm";
    repo = "chart-testing";
    rev = "v${version}";
    hash = "sha256-q56ZM+YzL7RRC3RD3xO3K0hIDomKun5xmSKuiDTq1cU=";
  };

  vendorHash = "sha256-kTlqGZVOppf+WMcFw0T9FVbu9eOWAWzotR8fPPyo2Ms=";

  postPatch = ''
    substituteInPlace pkg/config/config.go \
      --replace "\"/etc/ct\"," "\"$out/etc/ct\","
  '';

  ldflags = [
    "-w"
    "-s"
    "-X github.com/helm/chart-testing/v3/ct/cmd.Version=${version}"
    "-X github.com/helm/chart-testing/v3/ct/cmd.GitCommit=${src.rev}"
    "-X github.com/helm/chart-testing/v3/ct/cmd.BuildDate=19700101-00:00:00"
  ];

  nativeBuildInputs = [
    installShellFiles
    makeWrapper
  ];

  postInstall = ''
    install -Dm644 -t $out/etc/ct etc/chart_schema.yaml
    install -Dm644 -t $out/etc/ct etc/lintconf.yaml

    installShellCompletion --cmd ct \
      --bash <($out/bin/ct completion bash) \
      --zsh <($out/bin/ct completion zsh) \
      --fish <($out/bin/ct completion fish) \

    wrapProgram $out/bin/ct --prefix PATH : ${
      lib.makeBinPath [
        coreutils
        git
        kubectl
        kubernetes-helm
        yamale
        yamllint
      ]
    }
  '';

  meta = with lib; {
    description = "Tool for testing Helm charts";
    homepage = "https://github.com/helm/chart-testing";
    license = licenses.asl20;
    maintainers = with maintainers; [ atkinschang ];
    mainProgram = "ct";
  };
}
