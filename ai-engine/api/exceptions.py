from fastapi import HTTPException, status

class CameraUnavailableException(HTTPException):
    def __init__(self, detail: str = "Camera is disconnected or unavailable"):
        super().__init__(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=detail)

class AIEngineNotInitializedException(HTTPException):
    def __init__(self, detail: str = "AI Engine is not initialized"):
        super().__init__(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=detail)

class InvalidConfigurationException(HTTPException):
    def __init__(self, detail: str = "Invalid configuration"):
        super().__init__(status_code=status.HTTP_400_BAD_REQUEST, detail=detail)

class InternalProcessingException(HTTPException):
    def __init__(self, detail: str = "Internal processing error"):
        super().__init__(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=detail)
