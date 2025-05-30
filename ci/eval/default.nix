{
  lib,
  runCommand,
  writeShellScript,
  writeText,
  linkFarm,
  time,
  procps,
  nixVersions,
  jq,
  sta,
  python3,
}:

let
  nixpkgs =
    with lib.fileset;
    toSource {
      root = ../..;
      fileset = unions (
        map (lib.path.append ../..) [
          "default.nix"
          "doc"
          "lib"
          "maintainers"
          "nixos"
          "pkgs"
          ".version"
          "ci/supportedSystems.json"
        ]
      );
    };

  nix = nixVersions.nix_2_24;

  supportedSystems = builtins.fromJSON (builtins.readFile ../supportedSystems.json);

  attrpathsSuperset =
    runCommand "attrpaths-superset.json"
      {
        src = nixpkgs;
        nativeBuildInputs = [
          nix
          time
        ];
      }
      ''
        export NIX_STATE_DIR=$(mktemp -d)
        mkdir $out
        export GC_INITIAL_HEAP_SIZE=4g
        command time -f "Attribute eval done [%MKB max resident, %Es elapsed] %C" \
          nix-instantiate --eval --strict --json --show-trace \
            "$src/pkgs/top-level/release-attrpaths-superset.nix" \
            -A paths \
            -I "$src" \
            --option restrict-eval true \
            --option allow-import-from-derivation false \
            --arg enableWarnings false > $out/paths.json
      '';

  singleSystem =
    {
      # The system to evaluate.
      # Note that this is intentionally not called `system`,
      # because `--argstr system` would only be passed to the ci/default.nix file!
      evalSystem,
      # The path to the `paths.json` file from `attrpathsSuperset`
      attrpathFile ? "${attrpathsSuperset}/paths.json",
      # The number of attributes per chunk, see ./README.md for more info.
      chunkSize,
      checkMeta ? true,
      includeBroken ? true,
      # Whether to just evaluate a single chunk for quick testing
      quickTest ? false,
    }:
    let
      singleChunk = writeShellScript "single-chunk" ''
        set -euo pipefail
        chunkSize=$1
        myChunk=$2
        system=$3
        outputDir=$4

        export NIX_SHOW_STATS=1
        export NIX_SHOW_STATS_PATH="$outputDir/stats/$myChunk"
        echo "Chunk $myChunk on $system start"
        set +e
        command time -o "$outputDir/timestats/$myChunk" \
          -f "Chunk $myChunk on $system done [%MKB max resident, %Es elapsed] %C" \
          nix-env -f "${nixpkgs}/pkgs/top-level/release-attrpaths-parallel.nix" \
          --eval-system "$system" \
          --option restrict-eval true \
          --option allow-import-from-derivation false \
          --query --available \
          --no-name --attr-path --out-path \
          --show-trace \
          --arg chunkSize "$chunkSize" \
          --arg myChunk "$myChunk" \
          --arg attrpathFile "${attrpathFile}" \
          --arg systems "[ \"$system\" ]" \
          --arg checkMeta ${lib.boolToString checkMeta} \
          --arg includeBroken ${lib.boolToString includeBroken} \
          -I ${nixpkgs} \
          -I ${attrpathFile} \
          > "$outputDir/result/$myChunk" \
          2> "$outputDir/stderr/$myChunk"
        exitCode=$?
        set -e
        cat "$outputDir/stderr/$myChunk"
        cat "$outputDir/timestats/$myChunk"
        if (( exitCode != 0 )); then
          echo "Evaluation failed with exit code $exitCode"
          # This immediately halts all xargs processes
          kill $PPID
        elif [[ -s "$outputDir/stderr/$myChunk" ]]; then
          echo "Nixpkgs on $system evaluated with warnings, aborting"
          kill $PPID
        fi
      '';
    in
    runCommand "nixpkgs-eval-${evalSystem}"
      {
        nativeBuildInputs = [
          nix
          time
          procps
          jq
        ];
        env = {
          inherit evalSystem chunkSize;
        };
      }
      ''
        export NIX_STATE_DIR=$(mktemp -d)
        nix-store --init

        echo "System: $evalSystem"
        cores=$NIX_BUILD_CORES
        echo "Cores: $cores"
        attrCount=$(jq length "${attrpathFile}")
        echo "Attribute count: $attrCount"
        echo "Chunk size: $chunkSize"
        # Same as `attrCount / chunkSize` but rounded up
        chunkCount=$(( (attrCount - 1) / chunkSize + 1 ))
        echo "Chunk count: $chunkCount"

        mkdir $out

        # Record and print stats on free memory and swap in the background
        (
          while true; do
            availMemory=$(free -b | grep Mem | awk '{print $7}')
            freeSwap=$(free -b | grep Swap | awk '{print $4}')
            echo "Available memory: $(( availMemory / 1024 / 1024 )) MiB, free swap: $(( freeSwap / 1024 / 1024 )) MiB"

            if [[ ! -f "$out/min-avail-memory" ]] || (( availMemory < $(<$out/min-avail-memory) )); then
              echo "$availMemory" > $out/min-avail-memory
            fi
            if [[ ! -f $out/min-free-swap ]] || (( availMemory < $(<$out/min-free-swap) )); then
              echo "$freeSwap" > $out/min-free-swap
            fi
            sleep 4
          done
        ) &

        seq_end=$(( chunkCount - 1 ))

        ${lib.optionalString quickTest ''
          seq_end=0
        ''}

        chunkOutputDir=$(mktemp -d)
        mkdir "$chunkOutputDir"/{result,stats,timestats,stderr}

        seq -w 0 "$seq_end" |
          command time -f "%e" -o "$out/total-time" \
          xargs -I{} -P"$cores" \
          ${singleChunk} "$chunkSize" {} "$evalSystem" "$chunkOutputDir"

        cp -r "$chunkOutputDir"/stats $out/stats-by-chunk

        if (( chunkSize * chunkCount != attrCount )); then
          # A final incomplete chunk would mess up the stats, don't include it
          rm "$chunkOutputDir"/stats/"$seq_end"
        fi

        # Make sure the glob doesn't break when there's no files
        shopt -s nullglob
        cat "$chunkOutputDir"/result/* > $out/paths
        cat "$chunkOutputDir"/stats/* > $out/stats.jsonstream
      '';

  combine =
    {
      resultsDir,
    }:
    runCommand "combined-result"
      {
        nativeBuildInputs = [
          jq
          sta
        ];
      }
      ''
        mkdir -p $out

        # Transform output paths to JSON
        cat ${resultsDir}/*/paths |
          jq --sort-keys --raw-input --slurp '
            split("\n") |
            map(select(. != "") | split(" ") | map(select(. != ""))) |
            map(
              {
                key: .[0],
                value: .[1] | split(";") | map(split("=") |
                  if length == 1 then
                    { key: "out", value: .[0] }
                  else
                    { key: .[0], value: .[1] }
                  end) | from_entries}
            ) | from_entries
          ' > $out/outpaths.json

        # Computes min, mean, error, etc. for a list of values and outputs a JSON from that
        statistics() {
          local stat=$1
          sta --transpose |
            jq --raw-input --argjson stat "$stat" -n '
              [
                inputs |
                  split("\t") |
                  { key: .[0], value: (.[1] | fromjson) }
              ] |
                from_entries |
                {
                  key: ($stat | join(".")),
                  value: .
                }'
        }

        # Gets all available number stats (without .sizes because those are constant and not interesting)
        readarray -t stats < <(jq -cs '.[0] | del(.sizes) | paths(type == "number")' ${resultsDir}/*/stats.jsonstream)

        # Combines the statistics from all evaluations
        {
          echo "{ \"key\": \"minAvailMemory\", \"value\": $(cat ${resultsDir}/*/min-avail-memory | sta --brief --min) }"
          echo "{ \"key\": \"minFreeSwap\", \"value\": $(cat ${resultsDir}/*/min-free-swap | sta --brief --min) }"
          cat ${resultsDir}/*/total-time | statistics '["totalTime"]'
          for stat in "''${stats[@]}"; do
            cat ${resultsDir}/*/stats.jsonstream |
              jq --argjson stat "$stat" 'getpath($stat)' |
              statistics "$stat"
          done
        } |
          jq -s from_entries > $out/stats.json

        mkdir -p $out/stats

        for d in ${resultsDir}/*; do
          cp -r "$d"/stats-by-chunk $out/stats/$(basename "$d")
        done
      '';

  compare = import ./compare {
    inherit
      lib
      jq
      runCommand
      writeText
      supportedSystems
      python3
      ;
  };

  full =
    {
      # Whether to evaluate on a specific set of systems, by default all are evaluated
      evalSystems ? if quickTest then [ "x86_64-linux" ] else supportedSystems,
      # The number of attributes per chunk, see ./README.md for more info.
      chunkSize,
      quickTest ? false,
    }:
    let
      results = linkFarm "results" (
        map (evalSystem: {
          name = evalSystem;
          path = singleSystem {
            inherit quickTest evalSystem chunkSize;
          };
        }) evalSystems
      );
    in
    combine {
      resultsDir = results;
    };

in
{
  inherit
    attrpathsSuperset
    singleSystem
    combine
    compare
    # The above three are used by separate VMs in a GitHub workflow,
    # while the below is intended for testing on a single local machine
    full
    ;
}
