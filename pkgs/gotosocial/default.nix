{ buildGo120Module, fetchFromGitHub }:

{
  default =
    buildGo120Module
      rec {
        pname = "gotosocial";
        version = "0.8.0";

        src = fetchFromGitHub {
          owner = "superseriousbusiness";
          repo = "gotosocial";
          rev = "v${version}";
          sha256 = "sha256-wRo0qg/4nukhpAtC3qRR9zH+G4S7vMtveQueklOZrbM=";
        };

        vendorSha256 = null;

        doCheck = false;

        tags = [ "netgo" "osusergo" "static_build" ];
        ldflags = [ "-s" "-w" "-extldflags '-static'" "-X 'main.Version=${version}'" ];

        postInstall = ''
          cp -r web $out
        '';
      };
}
