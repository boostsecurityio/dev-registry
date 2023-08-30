import yaml
import re


# Allow checkmarx
ALLOWED_CHECKMARX = [
    "checkmarx-android",
    "checkmarx-best-coding-practices",
    "checkmarx-buffer-overflow",
    "checkmarx-cordova",
    "checkmarx-force-com-code-quality",
    "checkmarx-force-com-critical-risk",
    "checkmarx-force-com-serious-risk",
    "checkmarx-gwt",
    "checkmarx-heuristic",
    "checkmarx-high-risk",
    "checkmarx-insecure-credential-storage",
    "checkmarx-integer-overflow",
    "checkmarx-isv-quality-rules",
    "checkmarx-jelly",
    "checkmarx-kony",
    "checkmarx-lightning",
    "checkmarx-low-visibility",
    "checkmarx-medium-threat",
    "checkmarx-misra-cpp",
    "checkmarx-misrac",
    "checkmarx-potential",
    "checkmarx-sapui5",
    "checkmarx-secure-coding-guide",
    "checkmarx-server-side-vulnerability",
    "checkmarx-stored",
    "checkmarx-stored-vulnerabilities",
    "checkmarx-structs",
    "checkmarx-visualforce-remoting",
    "checkmarx-vuln-outdated-version",
    "checkmarx-weak-cryptography",
    "checkmarx-web-config",
    "checkmarx-windows-phone",
    "checkmarx-xs"
]



def filter_cwe_categories(rule):
    """Filter out the non-allowed CWE categories from the rule's categories."""
    if "categories" in rule:
        rule["categories"] = [cat for cat in rule["categories"] if not re.match(r'checkmarx-.*', cat) or cat in ALLOWED_CHECKMARX]
    return rule

def process_yaml(yaml_content):
    """Process and filter the YAML content."""
    data = yaml.safe_load(yaml_content)
    
    # Apply filter function to each rule
    data["rules"] = {rule_id: filter_cwe_categories(rule_data) for rule_id, rule_data in data["rules"].items()}
    
    return yaml.safe_dump(data, default_flow_style=False, sort_keys=False)

def main():
    # Read YAML data from file
    with open('rules.yaml', 'r') as file:
        yaml_data = file.read()

    # Process the YAML data
    filtered_data = process_yaml(yaml_data)

    # Write processed data to output file
    with open('filtered_rules.yaml', 'w') as file:
        file.write(filtered_data)

if __name__ == "__main__":
    main()
