eval "$(direnv hook zsh)"
    export KITCHEN_DATA_BAG_SECRET_PATH="~/.secret"
export KITCHEN_DRIVER=ec2
export AWS_SSH_KEY_ID=grace.petegorsky
export KITCHEN_AMI=ami-41e0b93b
export KITCHEN_CHEF_VERSION=14.14.25
export KITCHEN_SSH_KEY="~/.ssh/id_rsa"
source ~/.saml2aws_utils
if [ -f "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh" ]; then
  __GIT_PROMPT_DIR=$(brew --prefix)/opt/bash-git-prompt/share
  GIT_PROMPT_ONLY_IN_REPO=1
  source "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh"
fi

# we are not multi-region yet
export AWS_DEFAULT_REGION=us-east-1
 
# account IDs (copied from the AWS Okta tile sign in, if you have more/others)
export PCYCLE=106877218800
export PPROD=386675210126
export PSTAGE=486598304777
export PTEST=152245890419
export TKITCH=048438595429
export PES1=429007243955
 
# prefer to get push notifications (switch to Passcode if you like)
export FORCE_MFA="Duo Push"
