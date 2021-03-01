kube_ps1 () {
    kube_context=$(cat ~/.kube/config | grep "current-context:" | sed "s/current-context: //")
    kube_context="${kube_context:-}"
    kube_namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}')
    kube_namespace="${kube_namespace:-default}"
    echo -ne " [k8s:\e[1;33m${kube_context}\e[0m:\e[1;34m${kube_namespace}\e[0m]"
}

aws_ps1 () {
  if [[ -n "$AWS_OKTA_PROFILE" ]]; then
    echo -en " [aws:\x1B[1;34m$AWS_OKTA_PROFILE\e[0m]"
  elif [[ -n "$SAML2AWS_PROFILE" ]]; then
    if [[ $(gdate +%s) -ge $(gdate -d "$AWS_CREDENTIAL_EXPIRATION" +%s) ]]; then
      echo -en " [aws:\x1B[1;31m$SAML2AWS_PROFILE\e[0m]"
    else
      echo -en " [aws:\x1B[1;34m$SAML2AWS_PROFILE\e[0m]"
    fi
  else
    echo -n ""
  fi
}

function prompt_callback () {
    kube_ps1
    aws_ps1
}

fixvpn () {
    echo "Flushing routes..."
    for i in $(ifconfig | egrep -o "^[a-z].+\d{1}:" | sed 's/://');
    do
        sudo ifconfig "$i" down;
    done;
    sudo route -n flush;
    for i in $(ifconfig | egrep -o "^[a-z].+\d{1}:" | sed 's/://');
    do
        sudo ifconfig "$i" up;
    done
    echo "All done"
}
# START_AWS_SSH_MARKER
function all_instances() {
  aws ec2 describe-instances --filter "Name=tag:chef-environment,Values=$1" "Name=tag:chef-role,Values=$2" | grep InstanceId | cut -f4 -d'"'
}
function find_instance() {
  all_instances $1 $2 | shuf -n 1
}
function aws_ssh() {
  aws ssm start-session --target "$1"
}
function process_cmd() {
  COMMAND_ID=$(echo $1 | grep CommandId | cut -d'"' -f6)
  echo $1 > /tmp/$COMMAND_ID.txt
  aws s3 cp /tmp/$COMMAND_ID.txt s3://peloton-sm-sm-logs/runcommand/$COMMAND_ID/
  echo "Can check to ensure valid targets found here: https://console.aws.amazon.com/systems-manager/run-command/$COMMAND_ID?region=us-east-1"
  echo "Wait here and refresh for results: https://s3.console.aws.amazon.com/s3/buckets/peloton-sm-sm-logs/runcommand/$COMMAND_ID/?region=us-east-1&tab=overview"
}
function send_cmd() {
  OUTPUT=$(aws ssm send-command --targets "Key=tag:chef-environment,Values=$1" "Key=tag:chef-role,Values=$2" --document-name "AWS-RunShellScript" --parameters "commands=$3" --output-s3-bucket-name peloton-sm-sm-logs --output-s3-key-prefix runcommand)
  process_cmd "$OUTPUT"
}
function send_cmd_env() {
  OUTPUT=$(aws ssm send-command --targets "Key=tag:chef-environment,Values=$1" --document-name "AWS-RunShellScript" --parameters "commands=$2" --output-s3-bucket-name peloton-sm-sm-logs --output-s3-key-prefix runcommand)
  process_cmd "$OUTPUT"
}
function send_cmd_ids() {
  OUTPUT=$(aws ssm send-command --instance-ids "$1" --document-name "AWS-RunShellScript" --parameters "commands=$2" --output-s3-bucket-name peloton-sm-sm-logs --output-s3-key-prefix runcommand)
  process_cmd "$OUTPUT"
}
function merge_output() {
  mkdir /tmp/$1
  cd /tmp/$1
  aws s3 sync s3://peloton-sm-sm-logs/runcommand/$1 .
  for n in `find . -type f`; do echo $n >> combined; cat $n >> combined; done;
  echo "Open /tmp/$1/combined to see all the output"
}
function aws_ssh_upgrade() {
  aws s3 cp s3://peloton-sm-sm-logs/mac_setup/smp.sh /tmp/smp.sh
  chmod +x /tmp/smp.sh
  /tmp/smp.sh
}
# END_AWS_SSH_MARKER

function assh() {
  if [[ ! "i" == "$(echo ${1} | cut -d'-' -f1)" ]]; then
    setopt local_options BASH_REMATCH
    [[ "$1" =~ .*([0-9a-f]{17}).* ]] && host="i-${BASH_REMATCH[1]}"
  else
    host="${1}"
  fi
  aws ssm start-session --target "$host"
}
# login to an account if necessary
s2al () { 
  if [[ -z "$1" ]]; then
    saml2aws login --skip-prompt --profile=default --duo-mfa-option "${FORCE_MFA}" --role="arn:aws:iam::${PCYCLE}:role/sre";
  else saml2aws login --skip-prompt --profile=${1} --duo-mfa-option "${FORCE_MFA}" --role="arn:aws:iam::${2}:role/sre";
  fi
}
# inject the active credentials for an account into your env
s2a () { eval $(saml2aws script --shell=zsh --skip-prompt --profile=${1}); }
# shortcut to remember who you are (and which account you are in)
awho () { aws sts get-caller-identity; }
 
# these are the aliases to trigger login (if necessary)
alias apc="s2al pc ${PCYCLE}"
alias atest="s2al test ${PTEST}"
alias astage="s2al stage ${PSTAGE}"
alias aprod="s2al prod ${PPROD}"
 
# these are the aliases to trigger account switch
alias spc="s2a pc"
alias stest="s2a test"
alias sstage="s2a stage"
alias sprod="s2a prod"
 
# these are the aliases to trigger account login (if necessary) and switch
alias jpc="s2al pc ${PCYCLE} && s2a pc"
alias jtest="s2al test ${PTEST} && s2a test"
alias jstage="s2al stage ${PSTAGE} && s2a stage"
alias jprod="s2al prod ${PPROD} && s2a prod"
