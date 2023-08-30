import yaml
import os
import openai
import time
from typing import Union
from openai.error import ServiceUnavailableError

openai.api_key = os.getenv('OPENAI_KEY')

# Load the YAML file
with open('rules.yaml', 'r') as file:
    data: dict[str, dict[str, Union[str, list[str]]]] = yaml.safe_load(file)

def generate_description(rule_details: dict[str, Union[str, list[str]]]) -> str:
    prompt: str = f"Provide a short and precise technical description for the SAST rule with ID '{rule_details['name']}', which also has a pretty name '{rule_details['pretty_name']}'."
    messages: list[dict[str, str]] = [
        {"role": "system", "content": "You are a specialized assistant that generates descriptions for static code analysis scanner rules. Make sure to **never ever** prefix the description with generic, useless, obvious things similar to 'This Static Application Security Testing (SAST) rule', 'This rule is triggered when...', 'This rule flags instances where...', 'Flags scenarios in which...', 'Detects instances...', 'Detects any use...', etc.. Just stick to the point."},
        {"role": "user", "content": "Provide a short and precise technical description for the SAST rule with ID 'ASP_Best_Coding_Practice_Aptca_Methods_Call_Non_Aptca_Methods', which also has a pretty name 'Aptca Methods Call Non Aptca Methods'."},
        {"role": "assistant", "content": "A method marked with AllowPartiallyTrustedCallersAttribute (APTCA) calls a non-APTCA method, potentially leading to privilege escalation risks."},
        {"role": "user", "content": prompt}
    ]
    
    print(f"Processing rule {processed_count + 1}/{total_rules}: {prompt}...")

    retries = 3
    backoff = 2.5  # Initial backoff time in seconds
    while retries > 0:
        try:
            response: dict = openai.ChatCompletion.create(model="gpt-4", messages=messages)
            return response['choices'][0]['message']['content']
        except ServiceUnavailableError:
            retries -= 1
            if retries == 0:
                print(f"Failed to generate description for rule '{rule_details['name']}' after 3 retries.")
                raise  # If all retries are exhausted, raise the error
            print(f"Service unavailable. Retrying in {backoff} seconds...")
            time.sleep(backoff)
            backoff *= 2  # Exponential backoff

# Count rules with description 'TBD'
total_rules = sum(1 for rule in data['rules'].values() if rule['description'] == 'TBD')
print(f"Total rules with description 'TBD': {total_rules}")

# Generate descriptions and update the data
processed_count = 0
for rule_name, rule_details in data['rules'].items():
    if rule_details['description'] == 'TBD':
        description: str = generate_description(rule_details)
        data['rules'][rule_name]['description'] = description
        processed_count += 1
        print(f"--> {description}")
        
        # Write the updated data back to the YAML file
        with open('rules_updated.yaml', 'w') as file:
            yaml.safe_dump(data, file)

print("All rules processed!")
