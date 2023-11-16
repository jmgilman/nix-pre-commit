# shellcheck disable=2053,2086,2154

link=.pre-commit-config.yaml
hooks="pre-commit pre-merge-commit pre-push prepare-commit-msg commit-msg post-checkout post-commit"

# Check if the link is pointing to the existing derivation result
if ! [[ -L $link && $(readlink $link) == $configFile ]]; then
  if [[ ! -L $link && -f $link ]]; then
    echo >&2 "nix-pre-commit: ERROR refusing to overwrite existing $link"
    exit 1
  fi

  # (Re)link to the new result (which will not exist for fresh install)
  rm -f $link
  ln -s $configFile $link

  # Uninstall all existing hooks
  for hook in $hooks; do
    $pre_commit uninstall -t $hook
  done

  # Install configured hooks
  for stage in $installStages; do
    if [[ "$stage" != "manual" ]]; then
      $pre_commit install -t "$stage"
    fi
  done
fi
