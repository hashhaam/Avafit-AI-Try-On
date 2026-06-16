"""
AvaFit Virtual Try-On Backend
FastAPI server for virtual garment try-on using IDM-VTON
"""

import os
import json
import uuid
import shutil
import tempfile
import asyncio
from typing import Dict, Any
from pathlib import Path

from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from dotenv import load_dotenv
from gradio_client import Client, handle_file
import cloudinary
import cloudinary.uploader
import httpx

# Load environment variables
load_dotenv()

# Initialize FastAPI app
app = FastAPI(title="AvaFit Virtual Try-On API", version="1.0.0")

# Add CORS middleware for Flutter development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure Cloudinary
cloudinary.config(
    cloud_name=os.getenv("CLOUDINARY_CLOUD_NAME"),
    api_key=os.getenv("CLOUDINARY_API_KEY"),
    api_secret=os.getenv("CLOUDINARY_API_SECRET")
)

# Define paths
BASE_DIR = Path(__file__).parent
UPLOADS_DIR = BASE_DIR / "uploads"
GARMENTS_DIR = BASE_DIR / "garments"
OUTPUTS_DIR = BASE_DIR / "outputs"
CATALOG_PATH = GARMENTS_DIR / "catalog.json"

# Ensure directories exist
UPLOADS_DIR.mkdir(exist_ok=True)
OUTPUTS_DIR.mkdir(exist_ok=True)


@app.get("/")
async def health_check() -> Dict[str, str]:
    """Health check endpoint"""
    return {"status": "ok", "app": "AvaFit"}


def find_garment_by_id(catalog: Dict[str, Any], garment_id: str):
    """
    Helper function to find a garment by ID across all brands
    Returns (garment, brand) tuple or (None, None) if not found
    """
    for brand in catalog.get("brands", []):
        for garment in brand.get("garments", []):
            if garment["id"] == garment_id:
                return garment, brand
    return None, None


@app.get("/garments")
async def get_garments() -> Dict[str, Any]:
    """
    Get list of available garments from catalog
    Returns the brand-organized catalog from catalog.json
    """
    try:
        if not CATALOG_PATH.exists():
            raise HTTPException(status_code=404, detail="Catalog file not found")
        
        with open(CATALOG_PATH, "r") as f:
            catalog = json.load(f)
        
        # Return brands array directly
        return {"brands": catalog.get("brands", [])}
    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="Invalid catalog format")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error reading catalog: {str(e)}")


@app.get("/brands/{brand_id}")
async def get_brand(brand_id: str) -> Dict[str, Any]:
    """
    Get a specific brand with all its garments
    Returns 404 if brand_id not found
    """
    try:
        if not CATALOG_PATH.exists():
            raise HTTPException(status_code=404, detail="Catalog file not found")
        
        with open(CATALOG_PATH, "r") as f:
            catalog = json.load(f)
        
        # Find brand by ID
        for brand in catalog.get("brands", []):
            if brand.get("id") == brand_id:
                return brand
        
        raise HTTPException(status_code=404, detail=f"Brand '{brand_id}' not found")
    except HTTPException:
        raise
    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="Invalid catalog format")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error reading catalog: {str(e)}")


@app.post("/tryon")
async def virtual_tryon(
    person_image: UploadFile = File(..., description="User's photo for try-on"),
    garment_id: str = Form(..., description="Garment ID from catalog"),
    side: str = Form("front", description="Which garment side to try on: front or back")
) -> Dict[str, str]:
    """
    Virtual try-on endpoint
    Accepts user photo and garment ID, returns try-on result URL
    """
    person_img_path = None
    garment_tmp_path = None
    
    try:
        # Step 1: Load catalog and find garment
        if not CATALOG_PATH.exists():
            raise HTTPException(status_code=404, detail="Catalog file not found")
        
        with open(CATALOG_PATH, "r") as f:
            catalog = json.load(f)
        
        # Find garment by ID across all brands
        garment, brand = find_garment_by_id(catalog, garment_id)
        
        if not garment:
            raise HTTPException(status_code=404, detail="Garment not found")
        
        # Step 2: Save uploaded person image
        person_filename = f"{uuid.uuid4()}.jpg"
        person_img_path = UPLOADS_DIR / person_filename
        
        with open(person_img_path, "wb") as buffer:
            shutil.copyfileobj(person_image.file, buffer)
        
        # Step 3: Get garment image URL (front by default; back only if explicitly
        # requested AND a back image exists in the images array — otherwise falls
        # back to the front image_url, so existing behavior is never affected).
        garment_image_url = garment.get("image_url")
        normalized_side = (side or "front").strip().lower()
        if normalized_side == "back":
            images = garment.get("images")
            if isinstance(images, list) and len(images) > 1 and images[1]:
                garment_image_url = images[1]
                print(f"🔄 Using BACK garment image: {garment_image_url}")
            else:
                print("ℹ️  Back requested but no back image found — using front image_url")
        if not garment_image_url:
            raise HTTPException(status_code=400, detail="Garment image_url not specified in catalog")
        
        # Check if it's a URL or local path
        if garment_image_url.startswith('http://') or garment_image_url.startswith('https://'):
            # Download from URL to temp file
            print(f"📥 Downloading garment image from URL: {garment_image_url}")
            async with httpx.AsyncClient(timeout=30.0) as client:
                img_response = await client.get(garment_image_url)
                img_response.raise_for_status()
                
                # Create temp file
                garment_tmp = tempfile.NamedTemporaryFile(delete=False, suffix='.jpg')
                garment_tmp.write(img_response.content)
                garment_tmp.close()
                garment_tmp_path = garment_tmp.name
                garment_img_path = Path(garment_tmp_path)
                print(f"✅ Downloaded garment image to: {garment_img_path}")
        else:
            # Local path (for development)
            garment_img_path = Path(garment_image_url)
            if not garment_img_path.is_absolute():
                garment_img_path = BASE_DIR.parent / garment_image_url
            
            if not garment_img_path.exists():
                raise HTTPException(status_code=404, detail=f"Garment image not found: {garment_image_url}")
        
        # Step 4: Call HuggingFace IDM-VTON
        print(f"🎨 Calling HuggingFace IDM-VTON with person: {person_img_path}, garment: {garment_img_path}")
        
        client = Client("yisol/IDM-VTON")
        result = await asyncio.to_thread(
            client.predict,
            dict(
                background=handle_file(str(person_img_path)),
                layers=[],
                composite=None
            ),
            handle_file(str(garment_img_path)),
            "clothing item",  # garment_des
            True,   # is_checked (auto mask)
            False,  # is_checked_crop
            30,     # denoise_steps
            42,     # seed
            api_name="/tryon"
        )
        
        # gradio_client returns tuple (output_image_path, masked_image_path)
        if isinstance(result, tuple) and len(result) > 0:
            result_image_path = result[0]
        else:
            result_image_path = result
        
        print(f"✅ IDM-VTON result: {result_image_path}")
        
        # Read result image bytes
        with open(result_image_path, 'rb') as f:
            result_bytes = f.read()
        
        # Step 5: Upload result to Cloudinary
        print(f"☁️  Uploading result to Cloudinary...")
        upload_result = cloudinary.uploader.upload(
            result_bytes,
            folder="avafit/results",
            public_id=f"tryon_{uuid.uuid4()}"
        )
        
        cloudinary_url = upload_result.get("secure_url")
        print(f"✅ Result uploaded: {cloudinary_url}")
        
        # Step 6: Clean up temp files
        try:
            if person_img_path and person_img_path.exists():
                person_img_path.unlink()
                print(f"🗑️  Cleaned up temp file: {person_img_path}")
            if garment_tmp_path and Path(garment_tmp_path).exists():
                os.unlink(garment_tmp_path)
                print(f"🗑️  Cleaned up temp garment file: {garment_tmp_path}")
        except Exception as cleanup_error:
            print(f"⚠️  Cleanup warning: {cleanup_error}")
        
        # Step 7: Return success response
        return {
            "status": "success",
            "result_url": cloudinary_url
        }
    
    except HTTPException:
        # Clean up on error
        if person_img_path and person_img_path.exists():
            try:
                person_img_path.unlink()
            except:
                pass
        if garment_tmp_path and Path(garment_tmp_path).exists():
            try:
                os.unlink(garment_tmp_path)
            except:
                pass
        raise
    except Exception as e:
        # Clean up on error
        if person_img_path and person_img_path.exists():
            try:
                person_img_path.unlink()
            except:
                pass
        if garment_tmp_path and Path(garment_tmp_path).exists():
            try:
                os.unlink(garment_tmp_path)
            except:
                pass
        print(f"❌ Error in /tryon: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Try-on failed: {str(e)}")


@app.post("/upload-profile-photo")
async def upload_profile_photo(
    photo: UploadFile = File(..., description="User's profile photo")
) -> Dict[str, str]:
    """
    Upload profile photo to Cloudinary
    Returns the Cloudinary URL
    """
    try:
        # Validate file type
        if not photo.content_type or not photo.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="File must be an image")
        
        # Save temporarily
        temp_filename = f"{uuid.uuid4()}.jpg"
        temp_path = UPLOADS_DIR / temp_filename
        
        with open(temp_path, "wb") as buffer:
            shutil.copyfileobj(photo.file, buffer)
        
        # Upload to Cloudinary
        print(f"Uploading profile photo to Cloudinary: {temp_path}")
        upload_result = cloudinary.uploader.upload(
            str(temp_path),
            folder="avafit/profiles",
            public_id=f"profile_{uuid.uuid4()}",
            transformation=[
                {"width": 400, "height": 400, "crop": "fill", "gravity": "face"},
                {"quality": "auto", "fetch_format": "auto"}
            ]
        )
        
        cloudinary_url = upload_result.get("secure_url")
        print(f"Profile photo uploaded: {cloudinary_url}")
        
        # Clean up temp file
        try:
            temp_path.unlink()
        except:
            pass
        
        return {
            "status": "success",
            "photo_url": cloudinary_url
        }
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error uploading profile photo: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")


if __name__ == "__main__":
    # Run the server
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
