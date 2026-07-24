import uvicorn

def main():
    try:
        print("Starting FootFalls FastAPI Service...")
        uvicorn.run("api.app:app", host="0.0.0.0", port=8000, reload=False)
    except Exception as e:
        print(f"A critical error occurred: {e}")

if __name__ == "__main__":
    main()
