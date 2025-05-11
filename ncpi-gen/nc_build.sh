echo "IMG_NAME='raspios'" > config
echo "DEPLOY_COMPRESSION='xz'" >> config


rm -rf ./stage0/SKIP ./stage1/SKIP ./stage2/SKIP ./stage3/SKIP ./stage4/SKIP ./stage5/SKIP
rm -rf ./stage0/SKIP_IMAGES ./stage1/SKIP_IMAGES ./stage2/SKIP_IMAGES ./stage3/SKIP_IMAGES ./stage4/SKIP_IMAGES ./stage5/SKIP_IMAGES

# touch ./stage2/SKIP ./stage3/SKIP ./stage4/SKIP ./stage5/SKIP
# touch ./stage2/SKIP_IMAGES ./stage3/SKIP_IMAGES ./stage4/SKIP_IMAGES ./stage5/SKIP_IMAGES

touch ./stage3/SKIP ./stage4/SKIP ./stage5/SKIP
touch ./stage4/SKIP_IMAGES ./stage5/SKIP_IMAGES

sudo ./build.sh  # or ./build-docker.sh
