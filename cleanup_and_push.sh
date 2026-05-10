#!/bin/bash

echo "================================================"
echo "🧹 AvaFit Repository Cleanup Script"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo -e "${RED}❌ Error: Not a git repository${NC}"
    exit 1
fi

echo -e "${YELLOW}⚠️  This script will:${NC}"
echo "   1. Create a backup of your current repository"
echo "   2. Remove git history to reduce size"
echo "   3. Create a fresh commit with all current files"
echo "   4. Push to GitHub"
echo ""
echo -e "${YELLOW}⚠️  WARNING: This will rewrite git history!${NC}"
echo ""
read -p "Do you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "📦 Step 1: Creating backup..."
BACKUP_DIR="../Avafit-mobile-app-backup-$(date +%Y%m%d-%H%M%S)"
cp -r . "$BACKUP_DIR"
echo -e "${GREEN}✅ Backup created at: $BACKUP_DIR${NC}"

echo ""
echo "📊 Current repository size:"
du -sh .git

echo ""
echo "🗑️  Step 2: Removing git history..."
rm -rf .git

echo ""
echo "🔧 Step 3: Initializing fresh repository..."
git init
git add .

echo ""
echo "💾 Step 4: Creating initial commit..."
git commit -m "Initial commit: AvaFit mobile app with AI backend

Features:
- Flutter mobile application
- Python FastAPI backend
- Phase 1: Background removal using rembg
- Phase 2: Pose detection using MediaPipe
- Comprehensive documentation and setup guides

Repository cleaned to remove:
- Large build artifacts
- ML model weights (downloaded on setup)
- Virtual environment (recreated from requirements.txt)
- Generated files (uploads, outputs)

See SETUP.md for installation instructions."

echo ""
echo "🌐 Step 5: Adding remote..."
git remote add origin https://github.com/hashhaam/Avafit-mobile-app.git

echo ""
echo "📊 New repository size:"
du -sh .git

echo ""
echo "🚀 Step 6: Pushing to GitHub..."
echo -e "${YELLOW}⚠️  This will force push to main branch${NC}"
read -p "Continue with push? (yes/no): " push_confirm

if [ "$push_confirm" != "yes" ]; then
    echo "Push aborted. Repository is ready but not pushed."
    echo "You can push manually with: git push -u origin main --force"
    exit 0
fi

git branch -M main
git push -u origin main --force

echo ""
echo "================================================"
echo -e "${GREEN}✅ Repository cleanup complete!${NC}"
echo "================================================"
echo ""
echo "📊 Summary:"
echo "   - Backup location: $BACKUP_DIR"
echo "   - Repository size: $(du -sh .git | cut -f1)"
echo "   - Remote: https://github.com/hashhaam/Avafit-mobile-app.git"
echo ""
echo "🎉 Your repository is now clean and pushed to GitHub!"
echo ""
echo "📝 Next steps for team members:"
echo "   1. git clone https://github.com/hashhaam/Avafit-mobile-app.git"
echo "   2. Follow SETUP.md for installation"
echo ""
