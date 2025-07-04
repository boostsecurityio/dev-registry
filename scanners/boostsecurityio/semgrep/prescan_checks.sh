#!/bin/bash
local_rules_dst=$(mktemp -d)
if [ -d ".semgrep" ]
then
    mv .semgrep/ "$local_rules_dst"
fi
mkdir -p .semgrep

fetch_remote() {
    file_name="${1##*/}"
    file_name=$(echo $file_name | cut -d '#' -f 1 | cut -d '?' -f 1)
    file_extension="${file_name##*.}"
    if [ "$file_extension" != "yaml" ] && [ "$file_extension" != "yml" ]
    then
        >&2 echo "Semgrep custom rules validation failed."
        >&2 echo " The provided URL do not point to a yaml file: $1."
        rm -rf $local_rules_dst
        exit 1
    fi
  
    dst_file=$(mktemp --suffix=.yml)
    http_code=$(curl -s -L --fail -w '%{http_code}\n' -o $dst_file $1)
    if [ "${http_code}" == "200" ]
    then
        cp $dst_file .semgrep/
        rm -f $dst_file
        return 0
    fi

    >&2 echo "Semgrep custom rules - Cannot fetch $1."
    rm -f $dst_file
    rm -rf $local_rules_dst
    exit 1
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
            >&2 echo "Semgrep custom rules validation failed."
            >&2 echo " The specific file or directory does not exist in the code repository: $rule."
          fi
          cp -R -f "$local_rules_dst/$rule" .semgrep || true
        fi
        ;;
      http://*|https://*)
        fetch_remote $rule
        ;;
      boost/sast/rules/semgrep@*)
        # Boost
        version=$(echo "$rule" | cut -d '@' -f 2)
        # $version is not sanitized since one can provide any URL in the boost config
        fetch_remote "https://assets.build.boostsecurity.io/semgrep-rules/$version/all-sast-rules.yml"
        ;;
      *)
        >&2 echo "Semgrep custom rules validation failed on $rule."
        >&2 echo "  Community rules cannot be used."
        >&2 echo "  Provide a URL or relative path to rules file or leave blank for Boost curated rules."
        rm -rf $local_rules_dst
        exit 1
        ;;
    esac
done

rm -rf $local_rules_dst

if [ "$(find .semgrep -regex '.*\.ya?ml' | wc -l)" == "0" ]
then
  >&2 echo "Semgrep custom rules validation failed for $SEMGREP_RULES."
  >&2 echo "  Missing yaml configuration files"
fi