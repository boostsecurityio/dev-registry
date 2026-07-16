#!/bin/bash
local_rules_dst=$(mktemp -d)
if [ -d ".semgrep" ]
then
    mv .semgrep/ "$local_rules_dst"
fi
mkdir -p .semgrep

# err prints a nicely formatted error block to stderr and aborts.
#   $1 = human readable message
#   $2 = offending rule / source (optional)
#   $3 = raw underlying error output, e.g. from curl or git (optional)
err() {
    local message="$1"
    local source="${2:-}"
    local details="${3:-}"
    {
        echo ""
        echo "========================================================================"
        echo " Semgrep custom rules validation failed."
        echo "------------------------------------------------------------------------"
        echo " ${message}"
        if [ -n "$source" ]
        then
            echo " Source : ${source}"
        fi
        if [ -n "$details" ]
        then
            echo "------------------------------------------------------------------------"
            echo " Details:"
            while IFS= read -r line
            do
                echo "   ${line}"
            done <<< "$details"
        fi
        echo "========================================================================"
    } >&2
    rm -rf "$local_rules_dst"
    exit 1
}

fetch_remote() {
    file_name="${1##*/}"
    file_name=$(echo "$file_name" | cut -d '#' -f 1 | cut -d '?' -f 1)
    file_extension="${file_name##*.}"
    if [ "$file_extension" != "yaml" ] && [ "$file_extension" != "yml" ]
    then
        err "The provided URL does not point to a YAML file." "$1"
    fi

    dst_file="$(mktemp).yml"
    curl_output=$(curl -s -S -L --fail -o "$dst_file" "$1" 2>&1)
    curl_status=$?
    if [ "$curl_status" -eq 0 ]
    then
        cp "$dst_file" .semgrep/
        rm -f "$dst_file"
        return 0
    fi

    rm -f "$dst_file"
    err "Cannot fetch the remote rules file (curl exit code ${curl_status})." "$1" "$curl_output"
}

# fetch_git_repo clones a remote git repository and copies every YAML rule file
# it contains into .semgrep/, preserving the repository directory structure.
# Supported forms:
#   git://host/org/repo.git
#   git+https://host/org/repo.git   (also git+http://)
#   https://host/org/repo.git       (also http://)
#   ssh://git@host/org/repo.git , git@host:org/repo.git
# An optional ref (branch, tag or commit) can be appended with '#':
#   https://host/org/repo.git#main
fetch_git_repo() {
    local raw="$1"
    local repo_url ref clone_dir git_output repo_name dest_subdir yaml_count

    # Split off an optional '#ref' fragment (branch / tag / commit).
    case "$raw" in
        *#*)
            ref="${raw##*#}"
            repo_url="${raw%%#*}"
            ;;
        *)
            ref=""
            repo_url="$raw"
            ;;
    esac

    # Normalize the pip-style "git+" prefix to a plain URL git understands.
    case "$repo_url" in
        git+*) repo_url="${repo_url#git+}" ;;
    esac

    if ! command -v git >/dev/null 2>&1
    then
        err "git is required to fetch rules from a git repository but it was not found in PATH." "$raw"
    fi

    clone_dir=$(mktemp -d)

    # Try a shallow clone first, targeting the ref directly when provided.
    if [ -n "$ref" ]
    then
        git_output=$(git clone --quiet --depth 1 --branch "$ref" "$repo_url" "$clone_dir" 2>&1)
    else
        git_output=$(git clone --quiet --depth 1 "$repo_url" "$clone_dir" 2>&1)
    fi

    if [ $? -ne 0 ]
    then
        if [ -n "$ref" ]
        then
            # --branch does not accept commit SHAs; fall back to a full clone + checkout.
            rm -rf "$clone_dir"
            clone_dir=$(mktemp -d)
            git_output=$(git clone --quiet "$repo_url" "$clone_dir" 2>&1)
            if [ $? -ne 0 ]
            then
                rm -rf "$clone_dir"
                err "Unable to clone the git repository." "$raw" "$git_output"
            fi
            git_output=$(git -C "$clone_dir" checkout --quiet "$ref" 2>&1)
            if [ $? -ne 0 ]
            then
                rm -rf "$clone_dir"
                err "Unable to checkout ref '${ref}' from the git repository." "$raw" "$git_output"
            fi
        else
            rm -rf "$clone_dir"
            err "Unable to clone the git repository." "$raw" "$git_output"
        fi
    fi

    # Derive a stable destination sub-directory name from the repository.
    repo_name="${repo_url##*/}"
    repo_name="${repo_name%.git}"
    [ -n "$repo_name" ] || repo_name="git-rules"
    dest_subdir=".semgrep/${repo_name}"

    yaml_count=$(find "$clone_dir" -type f \( -name '*.yml' -o -name '*.yaml' \) -not -path '*/.git/*' | wc -l)
    if [ "$yaml_count" -eq 0 ]
    then
        rm -rf "$clone_dir"
        err "No YAML rule files (*.yml / *.yaml) were found in the git repository." "$raw"
    fi

    mkdir -p "$dest_subdir"
    find "$clone_dir" -type f \( -name '*.yml' -o -name '*.yaml' \) -not -path '*/.git/*' -print0 \
        | while IFS= read -r -d '' f
        do
            rel="${f#"$clone_dir"/}"
            mkdir -p "$dest_subdir/$(dirname "$rel")"
            cp "$f" "$dest_subdir/$rel"
        done

    rm -rf "$clone_dir"
    return 0
}

SEMGREP_RULES=${SEMGREP_RULES:-boost/sast/rules/semgrep@stable}
for rule in $SEMGREP_RULES; do
    case "$rule" in
      .semgrep/*)
        # Local rules are allowed
        if [ "$rule" == ".semgrep/*" ]
        then
          #
          cp -R -f $local_rules_dst/.semgrep/* .semgrep || true
        else
          if [ ! -f "$local_rules_dst/$rule" ]  && [ ! -d  "$local_rules_dst/$rule" ]
          then
            err "The specified file or directory does not exist in the code repository." "$rule"
          fi
          cp -R -f "$local_rules_dst/$rule" .semgrep || true
        fi
        ;;
      git://*|git+http://*|git+https://*|ssh://*|git@*)
        # Remote git repository (git protocol, git+http(s) or ssh)
        fetch_git_repo "$rule"
        ;;
      *.git|*.git#*)
        # Remote git repository served over http(s), e.g. https://host/org/repo.git
        fetch_git_repo "$rule"
        ;;
      http://*|https://*)
        # Single remote YAML rules file
        fetch_remote "$rule"
        ;;
      boost/sast/rules/semgrep@*)
        # Boost
        version=$(echo "$rule" | cut -d '@' -f 2)
        # $version is not sanitized since one can provide any URL in the boost config
        fetch_remote "https://assets.build.boostsecurity.io/semgrep-rules/$version/all-sast-rules.yml"
        ;;
      *)
        err "Community rules cannot be used. Provide a URL, a git repository or a relative path to a rules file, or leave blank for Boost curated rules." "$rule"
        ;;
    esac
done

rm -rf $local_rules_dst

if [ "$(find .semgrep -name '*.yml' | wc -l)" == "0" ] && [ "$(find .semgrep -name '*.yaml' | wc -l)" == "0" ]
then
  err "Missing yaml configuration files." "$SEMGREP_RULES"
fi
