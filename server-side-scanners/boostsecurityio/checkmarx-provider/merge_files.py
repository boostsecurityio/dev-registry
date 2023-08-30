import yaml

def merge_yaml_files(descriptions_file, categories_and_groups_file, output_file):
    # Read the rules_with_descriptions.yaml file
    with open(descriptions_file, 'r') as f:
        descriptions_data = yaml.safe_load(f)

    # Read the rules_with_fixed_categories_and_groups.yaml file
    with open(categories_and_groups_file, 'r') as f:
        categories_and_groups_data = yaml.safe_load(f)

    # Update the categories and group values for each rule
    for rule_id, rule_data in descriptions_data['rules'].items():
        if rule_id in categories_and_groups_data['rules']:
            rule_data['categories'] = categories_and_groups_data['rules'][rule_id]['categories']
            rule_data['group'] = categories_and_groups_data['rules'][rule_id]['group']

    # Write the merged data to rules.yaml
    with open(output_file, 'w') as f:
        yaml.safe_dump(descriptions_data, f)

if __name__ == "__main__":
    # File paths
    descriptions_file = 'rules_with_descriptions.yaml'
    categories_and_groups_file = 'rules_with_fixed_categories_and_groups.yaml'
    output_file = 'rules.yaml'
    
    merge_yaml_files(descriptions_file, categories_and_groups_file, output_file)
