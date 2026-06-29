import base64

from aiohttp import web


async def handle_post(request: web.Request) -> web.Response:
    """Handles incoming POST requests and prints the payload."""
    print(f"\n--- Received POST request to {request.path} ---")

    # Print URL and Query Parameters
    print(f"URL: {request.url}")
    print(f"Query Params: {dict(request.query)}")

    # Print Headers
    print("\nHeaders:")
    for key, value in request.headers.items():
        print(f"  {key}: {value}")
    print("-" * 30)

    # Decode Basic Authentication Header if present
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.lower().startswith("basic "):
        try:
            encoded_credentials = auth_header.split(" ")[1]
            decoded_bytes = base64.b64decode(encoded_credentials)
            decoded_str = decoded_bytes.decode("utf-8")
            username, password = decoded_str.split(":", 1)
            print("Decoded Credentials:")
            print(f"  User: {username}\n  Token/Pass: {password}\n" + "-" * 30)
        except Exception as e:
            print(f"Error parsing Authorization header: {e}\n" + "-" * 30)  # print body

    if request.content_type == "application/json":
        try:
            payload = await request.json()
            print(f"Body (JSON):\n{payload}")
        except Exception as e:
            print(f"Error parsing JSON: {e}")
    else:
        # Fallback to raw text for content-types like text/plain
        payload_text = await request.text()
        print(f"Body ({request.content_type}):\n{payload_text}")

    return web.Response(text="Payload received successfully\n", status=200)


def main():
    app = web.Application()

    # Catch-all route for any POST path
    app.add_routes([web.post("/{tail:.*}", handle_post)])

    print("Starting aiohttp web server on http://localhost:8080...")
    web.run_app(app, host="0.0.0.0", port=8080)


if __name__ == "__main__":
    main()
