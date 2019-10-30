#!/bin/bash
set -euo pipefail
script_dir=$(cd $(dirname "${BASH_SOURCE[0]}"); pwd)

COMBINATIONS="benchmark+gather benchmark+gather+plot gather+plot gather+plot+cleanup benchmark+gather+cleanup benchmark+gather+plot+cleanup"

if [ "$#" != 1 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  echo "Usage: $0 benchmark|gather|plot|cleanup|COMBINATION"
  echo "  benchmark: Runs benchmarks as Kubernetes Jobs on the cluster (starts sequentially with waiting for completion)"
  echo "  gather:    Write the Kubernetes Job output to local CSV files"
  echo "  plot:      Plot all existing CSVs in the current folder as SVGs"
  echo "  cleanup:   Deletes the Kubernetes Jobs (optional cleanup)"
  echo "  (Valid combinations: $COMBINATIONS)"
  echo "Required env variables:"
  echo "  KUBECONFIG: Specifies the cluster to use"
  echo "  ARCH:       Specifies which container image suffix to use (either arm64 or amd64)"
  echo "  COST:       Stores an additional cost/hour value, e.g., 1.0"
  echo "  META:       Stores additional metadata about the benchmark run, use it to provide the location, e.g., sjc1 as the Packet datacenter region"
  echo "Optional env variables:"
  echo "  ITERATIONS=1:                   Number of runs inside a Job"
  echo "  SYSBENCH=\"fileio mem cpu\":      Space-separated list of sysbench benchmarks to run (limited to the named ones)"
  echo "  STRESSNG=\"(default in source)\": Space-separated list of stress-ng benchmarks to run (accepts any valid names)"
  echo "                                  To disable sysbench or stress-ng benchmarks set them to a whitespace string but not"
  echo "                                  an empty string. E.g., STRESSNG=\" \" SYSBENCH=\" \" disables both."
  echo "The benchmark results are stored in the cluster as long as the jobs are not cleaned-up."
  echo "The gather process exports them to local files and combines the result with any existing local files."
  echo "Therefore, the intended usage is to gather the results for various clusters into one directory."
  echo "By keeping the cleanup process of Jobs in the cluster optional, multiple clients can access the results without sharing the CSV files."
  echo "Old results can be cleaned-up to speed up the gathering and they are included in the plotted graphs as long as their CSV files are still in the current folder."
  exit 0
fi
arg="$1"

filtered="$(echo "$arg"; echo valid)"
for a in benchmark gather plot cleanup $COMBINATIONS; do
  filtered="$(echo "$filtered" | grep -v "^$a$")"
done
if [ "$filtered" != "valid" ]; then
  echo "ERROR: Unknown argument"; exit 1
fi

ITERATIONS="${ITERATIONS-1}"

if [ "$arg" != "plot" ]; then
  # Test if required env variables are set
  echo "$KUBECONFIG $ARCH $COST $META" > /dev/null
  # Log them for the user for awareness
  echo "KUBECONFIG=\"$KUBECONFIG\" ARCH=\"$ARCH\" COST=\"$COST\" META=\"$META\" ITERATIONS=\"$ITERATIONS\""
fi

STRESSNG="${STRESSNG-spawn hsearch crypt atomic tsearch qsort shm sem lsearch bsearch vecmath matrix memcpy}"
SYSBENCH="${SYSBENCH-fileio mem cpu}"

# List of benchmarks: JOBTYPE,JOBNAME,PARAMETER,RESULT
# Warning, $JOBTYPE$JOBNAME$PARAMETER should not be a valid prefix for another because of globbing.
VARS=''
for S in $STRESSNG; do
  VARS+="$(printf ' stress-ng,%s,$ONE,bogo-ops/s stress-ng,%s,$CORES,bogo-ops/s stress-ng,%s,$CPUS,bogo-ops/s' "$S" "$S" "$S")"
done
for S in $SYSBENCH; do
  if [ "$S" = cpu ]; then
    COL="Events/s"
  else
    COL="MiB/sec"
  fi
  VARS+="$(printf ' sysbench,%s,$ONE,%s sysbench,%s,$CORES,%s sysbench,%s,$CPUS,%s' "$S" "$COL" "$S" "$COL" "$S" "$COL")"
done

if [ "$(echo "$arg" | grep benchmark)" != "" ]; then
  echo "Deploying helpers"
  kubectl apply -f "${script_dir}"/helpers.yaml
  for VAR in $VARS; do
    IFS=, read -r JOBTYPE JOBNAME PARAMETER RESULT <<< "$VAR"
    MODE="$JOBNAME"
    ID="$(date +%s%4N | tail -c +5)-$RANDOM"
    PARAMETERQUOTE="$(echo "$PARAMETER" | sed -e 's/\$//' | tr '[:upper:]' '[:lower:]')"
    echo "starting $JOBTYPE-$JOBNAME-$PARAMETERQUOTE-$ID"
    export JOBTYPE MODE ID PARAMETER PARAMETERQUOTE RESULT ARCH COST META ITERATIONS
    # Here "export" is needed so that the envubst process can see the variables
    cat "$script_dir/k8s-job.envsubst" | envsubst '$JOBTYPE $MODE $ID $PARAMETER $PARAMETERQUOTE $RESULT $ARCH $COST $META $ITERATIONS' | kubectl apply -f -
    while true; do
      status="$(kubectl get job -n benchmark "$JOBTYPE-$JOBNAME-$PARAMETERQUOTE-$ID" --output=jsonpath='{.status.conditions[0].type}')"
      if [ "$status" = Complete ]; then
        break
      elif [ "$status" = Failed ]; then
        echo "ERROR: Job failed:"
        kubectl get job -n benchmark "$JOBTYPE-$JOBNAME-$PARAMETERQUOTE-$ID"
        exit 1
      fi
      sleep 1
    done
    echo "finished $JOBTYPE-$JOBNAME-$PARAMETERQUOTE"
  done
  echo "done with benchmarking"
fi
if [ "$(echo "$arg" | grep gather)" != "" ]; then
  for VAR in $VARS; do
    IFS=, read -r JOBTYPE JOBNAME PARAMETER RESULT <<< "$VAR"
    PARAMETERQUOTE="$(echo "$PARAMETER" | sed -e 's/\$//' | tr '[:upper:]' '[:lower:]')"
    jobs="$(kubectl get jobs -n benchmark --selector=app="$JOBTYPE-$JOBNAME-$PARAMETERQUOTE" --output=jsonpath='{.items[*].metadata.name}')"
    for j in $jobs; do
      kubectl logs -n benchmark "$(kubectl get pods -n benchmark --selector=job-name="$j" --output=jsonpath='{.items[*].metadata.name}')" |  grep '^CSV:' | cut -d : -f 2- > "$j$ARCH.csv"
    done
  done
  echo "done gathering"
fi
if [ "$(echo "$arg" | grep plot)" != "" ]; then
  for VAR in $VARS; do
    IFS=, read -r JOBTYPE JOBNAME PARAMETER RESULT <<< "$VAR"
    PARAMETERQUOTE="$(echo "$PARAMETER" | sed -e 's/\$//' | tr '[:upper:]' '[:lower:]')"
	{ 	"$script_dir/plot" --parameter --outfile="$JOBTYPE-$JOBNAME-$PARAMETERQUOTE.svg" "$RESULT" "$JOBTYPE-$JOBNAME-$PARAMETERQUOTE"*csv
    	"$script_dir/plot" --parameter --outfile="$JOBTYPE-$JOBNAME-$PARAMETERQUOTE.png" "$RESULT" "$JOBTYPE-$JOBNAME-$PARAMETERQUOTE"*csv
    	"$script_dir/plot" --cost --parameter --outfile="$JOBTYPE-$JOBNAME-$PARAMETERQUOTE-cost.svg" "$RESULT" "$JOBTYPE-$JOBNAME-$PARAMETERQUOTE"*csv
    	"$script_dir/plot" --cost --parameter --outfile="$JOBTYPE-$JOBNAME-$PARAMETERQUOTE-cost.png" "$RESULT" "$JOBTYPE-$JOBNAME-$PARAMETERQUOTE"*csv ; } &
  done
  wait
  echo "done plotting"
fi
if [ "$(echo "$arg" | grep cleanup)" != "" ]; then
  for VAR in $VARS; do
    IFS=, read -r JOBTYPE JOBNAME PARAMETER RESULT <<< "$VAR"
    PARAMETERQUOTE="$(echo "$PARAMETER" | sed -e 's/\$//' | tr '[:upper:]' '[:lower:]')"
    jobs="$(kubectl get jobs -n benchmark --selector=app="$JOBTYPE-$JOBNAME-$PARAMETERQUOTE" --output=jsonpath='{.items[*].metadata.name}')"
    for j in $jobs; do
      kubectl delete job -n benchmark "$j"
    done
  done
  kubectl delete -f "${script_dir}"/helpers.yaml || true
  echo "done with cleanup"
fi
