function unittest() { cd ~/dev/managed-jenkins; bash -xc "find ~/dev/managed-jenkins/cookbooks/peloton-jenkins-${1} -type d -name 'spec' | parallel -j20 'env SPEC_FILE={} chef exec rspec -I. {}' | grep -v -E '^ - '"; cd - }
function dock() { docker ps | grep 'ago' | head -1 | cut -d' ' -f1 }
function de() { docker exec -it $(docker ps | grep 'ago' | head -1 | cut -d' ' -f1) bash }
function pulls() {
  if [[ -z $1 ]]; then
    open "https://github.com/pelotoncycle/$(basename $(pwd))/pulls"
  elif [[ -z $2 ]]; then
    open "https://github.com/pelotoncycle/$1/pulls"
  else
    open "https://github.com/$1/$2/pulls"
  fi
}
function notif() { if [[ '-c' == "${1}" ]]; then osascript -e "display notification \"$(${@:2})\""; else osascript -e "display notification \"${1}\" with title \"${2}\""; fi }
function jira() { open "https://pelotoncycle.atlassian.net/browse/${1}" }

function cook() {
  base_repo="/Users/grace.petegorsky/dev/managed-jenkins"
  get_default_cbook_path() { if [[ -z "${cbook}" ]]; then echo "$(pwd)"; else echo "${cbook}"; fi }
  if [[ "lint" == "${1}" ]]; then
    chef_cmd="cookstyle"
  elif [[ "doc" == "${1}" ]]; then
    chef_cmd="knife cookbook doc"
  elif [[ "unit" == "${1}" ]]; then
    chef_cmd="unittest"
  else
    chef_cmd="kitchen ${1} jenkins-${2}-${3}"
    is_kitchen="true"
  fi

  if [[ -z "${2}" ]] || ([[ "-a" == "${2}" ]] && [[ -z "${3}" ]]); then
    cmd_path="${2} $(get_default_cbook_path)"
  elif [[ -z "${is_kitchen}" ]]; then
    # 3 is empty unless 2 is "-a" for cookstyle
    cmd_path="${2} ${3}"
  fi
  
  if [[ "unittest" == "${chef_cmd}" ]]; then
    cbook_shortname="$(echo ${cmd_path} | rev | cut -d'-' -f1 | rev)"
    $SHELL -xc "chef exec unittest ${cmd_path}"
    return $?
  elif [[ -z "${is_kitchen}" ]]; then
    $SHELL -xc "chef exec ${chef_cmd} ${cmd_path}"
  else
    pushd "${base_repo}"
    $SHELL -xc "chef exec ${chef_cmd} ${cmd_path}"
    popd
  fi
}

function clone() {
  git clone "git@github.com:pelotoncycle/$1.git"
}
