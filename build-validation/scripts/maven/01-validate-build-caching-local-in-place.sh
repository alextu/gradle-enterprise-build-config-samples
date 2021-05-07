#!/usr/bin/env bash
#
# Runs Experiment 02 - Validate Build Caching - Local - In Place
#
# Invoke this script with --help to get a description of the command line arguments
#
readonly EXP_NAME="Validate Build Caching - Local - In Place"
readonly EXP_DESCRIPTION="Validating that a Maven build is optimized for local in-place build caching"
readonly EXP_NO="01"
readonly EXP_SCAN_TAG=exp1-maven
readonly BUILD_TOOL="Maven"

# Needed to bootstrap the script
readonly SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_DIR="$(cd "$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")" && pwd)"
readonly LIB_DIR="${SCRIPT_DIR}/../lib"

# Include and parse the command line arguments
# shellcheck source=build-validation/scripts/lib/maven/01-cli-parser.sh
source "${LIB_DIR}/maven/${EXP_NO}-cli-parser.sh" || { echo "Couldn't find '${LIB_DIR}/maven/${EXP_NO}-cli-parser.sh' parsing library."; exit 1; }
# shellcheck source=build-validation/scripts/lib/libs.sh
source "${LIB_DIR}/libs.sh" || { echo "Couldn't find '${LIB_DIR}/libs.sh'"; exit 1; }

# These will be set by the config functions (see lib/config.sh)
git_repo=''
project_name=''
git_branch=''
project_dir=''
tasks=''
extra_args=''
enable_ge=''
ge_server=''
interactive_mode=''

main() {
  if [ "${interactive_mode}" == "on" ]; then
    wizard_execute
  else
    execute
  fi
  create_receipt_file
}

execute() {
  print_bl
  validate_required_config

  make_experiment_dir
  make_local_cache_dir
  git_clone_project ""

  print_bl
  execute_first_build
  print_bl
  execute_second_build

  print_bl
  print_summary
  print_bl
}

wizard_execute() {
  print_bl
  print_introduction

  print_bl
  explain_collect_git_details
  print_bl
  collect_git_details

  print_bl
  explain_collect_maven_details
  print_bl
  collect_maven_details

  print_bl
  explain_clone_project
  print_bl
  make_experiment_dir
  git_clone_project ""
  make_local_cache_dir

  print_bl
  explain_first_build
  print_bl
  execute_first_build

  print_bl
  explain_second_build
  print_bl
  execute_second_build

  print_bl
  explain_measure_build_results
  print_bl
  explain_and_print_summary
  print_bl

}

execute_first_build() {
  info "Running first build:"
  execute_build
}

execute_second_build() {
  info "Running second build:"
  execute_build
}

execute_build() {
  info "./mvnw -Dscan.tag.${EXP_SCAN_TAG} -Dscan.value.runId=${RUN_ID} clean ${tasks}$(print_extra_args)"

  #shellcheck disable=SC2086  # we actually want ${tasks} to expand because it may have more than one maven goal
  invoke_maven \
     -Dgradle.cache.local.enabled=true \
     -Dgradle.cache.remote.enabled=false \
     -Dgradle.cache.local.directory="${BUILD_CACHE_DIR}" \
     clean ${tasks}
}

print_summary() {
 read_build_scan_metadata
 print_experiment_info
 print_build_scans
 print_bl
 print_quick_links
}

print_build_scans() {
 summary_row "Build scan first build:" "${build_scan_urls[0]}"
 summary_row "Build scan second build:" "${build_scan_urls[1]}"
}

print_quick_links() {
 info "Investigation Quick Links"
 info "-------------------------"
 summary_row "Goal execution overview:" "${base_urls[0]}/s/${build_scan_ids[1]}/performance/execution"
 summary_row "Executed goals timeline:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?outcome=SUCCESS,FAILED&sort=longest"
 summary_row "Executed cacheable goals:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?cacheability=cacheable,overlapping_outputs,validation_failure&outcome=SUCCESS,FAILED&sort=longest"
 summary_row "Executed non-cacheable goals:" "${base_urls[0]}/s/${build_scan_ids[1]}/timeline?cacheability=any_non-cacheable&outcome=SUCCESS,FAILED&sort=longest"
 summary_row "Build caching statistics:" "${base_urls[0]}/s/${build_scan_ids[1]}/performance/build-cache"
 summary_row "Goal inputs comparison:" "${base_urls[0]}/c/${build_scan_ids[0]}/${build_scan_ids[1]}/task-inputs?cacheability=cacheable"
}

print_introduction() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_introduction_title)

In this experiment, you will validate how well a given Maven project leverages
Gradle Enterprise’s local build cache. A build is considered fully local-cache
enabled if all goals avoid performing any work because:

  * The goals' inputs have not changed since their last invocation and
  * The goals' outputs are present in the local cache

The goal of the experiment is to first identify those goals that do not reuse
outputs from the local cache, to then make an informed decision which of those
tasks are worth improving to make your build faster, to then investigate why
they did not reuse outputs, and to finally fix them once you understand the root
cause.

The experiment can be run on any developer’s machine. It logically consists of
the following steps:

  1. Run the Maven build with the a typical goal invocation including the 'clean' goal
  2. Run the Maven build with the same goal invocation including the 'clean' goal
  3. Determine which goals are still executed in the second run and why
  4. Assess which of the executed goals are worth improving

Step 1 and 2 should be executed with the local build cache enabled.

The script you have invoked automates the execution of step 1 and step 2 without
modifying the project. Build scans support your investigation in step 3 and step
4.

After improving the build to make it leverage the local build cache, you can
push your changes and run the experiment again. This creates a cycle of run →
measure → improve → run.

${USER_ACTION_COLOR}Press <Enter> to get started with the experiment.${RESTORE}
EOF

  print_wizard_text "${text}"
  wait_for_enter
}

explain_first_build() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Run first build${RESTORE}

Now that the project has been checked out, the first build can be run with the
given Maven goals. The build will be invoked with the 'clean' goal included and
local build caching enabled.

To keep the experiment isolated and repeatable, a clean local build cache
directory was created.

${USER_ACTION_COLOR}Press <Enter> to run the first build.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_second_build() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Run second build${RESTORE}

Now that the first build has finished successfully, the second build can be run
with the same Maven goals.

${USER_ACTION_COLOR}Press <Enter> to run the second build.${RESTORE}
EOF
  print_wizard_text "$text"
  wait_for_enter
}

explain_measure_build_results() {
  local text
  IFS='' read -r -d '' text <<EOF
$(print_separator)
${HEADER_COLOR}Measure build results${RESTORE}

Now that the second build has finished successfully, you are ready to measure in
Gradle Enterprise how well your build leverages the local build cache for
the invoked set of Maven goals.

${USER_ACTION_COLOR}Press <Enter> to measure the build results.${RESTORE}
EOF
  print_wizard_text "${text}"
  wait_for_enter
}

explain_and_print_summary() {
  read_build_scan_metadata
  local text
  IFS='' read -r -d '' text <<EOF
The 'Summary' section below captures the configuration of the experiment and the
two build scans that were published as part of running the experiment.  The
build scan of the second build is particularly interesting since this is where
you can inspect what goals were not leveraging the local build cache.

The 'Investigation Quick Links' section below allows quick navigation to the
most relevant views in build scans to investigate what goal outputs were fetched
from the cache and what goals executed in the second build with cache misses,
which of those goals had the biggest impact on build performance, and what
caused the cache misses.

The 'Command Line Invocation' section below demonstrates how you can rerun the
experiment with the same configuration and in non-interactive mode.

$(print_summary)

$(print_command_to_repeat_experiment)

Once you have addressed the issues surfaced in build scans and pushed the
changes to your Git repository, you can rerun the experiment and start over the
cycle of run → measure → improve → run.
EOF
  print_wizard_text "${text}"
}

process_arguments "$@"
main

