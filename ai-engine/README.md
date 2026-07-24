# FootFalls AI Engine

The AI Engine for FootFalls is responsible for connecting to camera streams, detecting people using YOLO, tracking them, and counting footfalls (entries and exits).

## Folder Structure
- `main.py`: Entry point for webcam testing.
- `test_yolo.py`: Basic script to verify YOLO model loading and inference.
- `requirements.txt`: Python dependencies list.
- `.env.example`: Template for environment variables.

## Installation Steps

1. **Install Python 3.10+** (if not already installed).
2. **Create a virtual environment**:
   ```bash
   python -m venv venv
   ```
3. **Activate the virtual environment**:
   - Windows: `.\venv\Scripts\activate`
   - Linux/Mac: `source venv/bin/activate`
4. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

## Running the Application
To verify webcam access, run:
```bash
python main.py
```
Press **Q** to exit the video stream.

To verify YOLO detection, run:
```bash
python test_yolo.py
```
