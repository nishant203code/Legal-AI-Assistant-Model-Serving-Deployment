import requests

public_url = "https://1d80-115-248-191-25.ngrok-free.app/"  # Replace with your ngrok public URL
prompt_text = "Section for Punishment for the attempt to murder"

try:
    response = requests.post(f"{public_url}/generate/", data={"prompt": prompt_text})
    response.raise_for_status()  # Raise an exception for bad status codes
    result = response.json()
    print(result)
except requests.exceptions.RequestException as e:
    print(f"An error occurred: {e}")
except ValueError:
    print("Failed to decode JSON response.")