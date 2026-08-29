cd /Users/yangguangyu/WorkBuddy/LLMObsidian/studyObsidian
echo "自动化部署最终验证" >> log.md
git add .
git commit -m "Final deploy script test - fix publicindex.html path"
git push ec2 main
