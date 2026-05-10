# AvaFit Backend - Virtual Try-On API

FastAPI backend for AvaFit virtual garment try-on using IDM-VTON AI model.

## Features

- Virtual try-on using IDM-VTON AI model
- Cloudinary integration for image storage
- RESTful API endpoints
- CORS enabled for Flutter app

## API Endpoints

### 1. GET /

Health check endpoint

### 2. GET /garments

Get list of available garments

- Returns: JSON with garments array

### 3. POST /tryon

Perform virtual try-on

- Parameters:
  - `person_image` (file): User's photo
  - `garment_id` (string): ID of garment to try on
- Returns: JSON with `result_url` (Cloudinary URL)

### 4. POST /upload-profile-photo

Upload profile photo to Cloudinary

- Parameters:
  - `file` (file): Profile photo
  - `user_id` (string): User ID
- Returns: JSON with `url` (Cloudinary URL)

## Local Development

### Prerequisites

- Python 3.11+
- pip

### Setup

1. Create virtual environment:

```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Create `.env` file:

```bash
cp .env.example .env
```

4. Add your Cloudinary credentials to `.env`:

```
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

5. Run the server:

```bash
python app.py
```

Server will start on `http://localhost:8000`

## Railway Deployment

### Environment Variables (Set in Railway Dashboard)

Required:

- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`

Optional:

- `PORT` (Railway sets this automatically)

### Deploy Steps

1. Push code to GitHub
2. Connect Railway to your GitHub repo
3. Railway will auto-detect Python and deploy
4. Set environment variables in Railway dashboard
5. Deploy!

## Project Structure

```
backend/
├── app.py                 # Main FastAPI application
├── requirements.txt       # Python dependencies
├── Procfile              # Railway/Heroku deployment config
├── runtime.txt           # Python version
├── .env.example          # Example environment variables
├── garments/
│   ├── catalog.json      # Garment catalog
│   └── images/           # Garment images (local only)
└── uploads/              # Temporary upload folder (gitignored)
```

## Dependencies

- **FastAPI**: Web framework
- **Uvicorn**: ASGI server
- **gradio-client**: IDM-VTON AI model client
- **cloudinary**: Image storage
- **python-dotenv**: Environment variables
- **python-multipart**: File upload support

## Notes

- IDM-VTON processing takes 1-2 minutes
- Garment images are stored on Cloudinary
- Temporary files are auto-deleted after processing
- CORS is enabled for all origins (configure for production)

## License

MIT
