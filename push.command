#!/bin/bash
cd ~/Documents/Repos/icantaffordatherapist
echo "Clearing git locks..."
rm -f .git/index.lock .git/HEAD.lock
echo "Staging all changes..."
git add .
echo "Committing..."
git commit -m "Update index, add scripts, skills, MOLTBOOK, TWITTER docs"
echo "Pushing to GitHub..."
git push
echo ""
echo "Done! Press any key to close."
read -n 1
