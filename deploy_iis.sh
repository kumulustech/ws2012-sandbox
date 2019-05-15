docker run --rm \
	-t $(tty &>/dev/null && echo "-i") \
	-e "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" \
	-e "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" \
	-e "AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}" \
	-e "S3_BUCKET_URI"=${S3_BUCKET_URI}
	-v "$(pwd):/sandbox" \
	alpine:aws_cli
