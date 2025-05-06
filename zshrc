# Source file if it exists and have a size greater than zero
[[ -s ~/.shell/exports.sh ]] && source ~/.shell/exports.sh
[[ -s ~/.shell/aliases.sh ]] && source ~/.shell/aliases.sh
[[ -s ~/.shell/sourcing.sh ]] && source ~/.shell/sourcing.sh
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
  export PATH=/opt/homebrew/opt/ruby/bin:$PATH
  export PATH=`gem environment gemdir`/bin:$PATH
fi
