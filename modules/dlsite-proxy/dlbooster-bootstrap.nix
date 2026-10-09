# The URL always serves the latest release. Run ./update.sh to pin a new one.
{
  fetchurl,
  jq,
  runCommand,
  unzip,
  yq-go,
}:

let
  src = fetchurl {
    url = "https://client-dl-1.dlbooster.com/latest.zip";
    hash = "sha256-CfUKTeOodL7d3tQSlJEyRUNhlPXcQU/ClJC5d7/5M/g=";
  };
in

runCommand "dlbooster-bootstrap"
  {
    nativeBuildInputs = [
      jq
      unzip
      yq-go
    ];
  }
  ''
    mkdir -p $out

    # A JWT is "header.payload.signature", each part base64url-encoded.
    unzip -p ${src} config.yaml \
      | yq '.settings.bootstrap' \
      | tr -d ' \n' \
      | cut -d . -f 2 \
      | jq -R 'gsub("-"; "+") | gsub("_"; "/") | @base64d | fromjson' \
      > $out/bootstrap.json
  ''
