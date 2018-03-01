#!/bin/sh

# Rename config.sh.default in config.sh and configure
# there runtime parameters
source ./config.sh

# The name of the bucket where CloudFormation template will be stored
_S3_BUCKET=$S3_BUCKET

# The name of the IAM role with S3 read access to the above bucket
_IAM_ROLE=$IAM_ROLE

# The key pair to use for authentication
_KEY_NAME=$KEY_NAME

# The root volume size
_ROOT_VOLUME_GB=$ROOT_VOLUME_GB

# The name to be attributed to the stack
_CLOUDFORMATION_STACK_NAME=$CLOUDFORMATION_STACK_NAME

_CLOUDFORMATION_TPL="deeplearning_ec2.json"

upload_tpl_if_changed() {
	aws s3 sync \
		--exclude "*" \
		--include $_CLOUDFORMATION_TPL \
		. s3://$_S3_BUCKET
}

validate_tpl() {
	aws cloudformation validate-template \
		--template-url https://$_S3_BUCKET.s3.amazonaws.com/$_CLOUDFORMATION_TPL
}

# Returns 0 if true, otherwise 1
has_stack_been_created() {
	aws cloudformation list-stacks \
		--stack-status-filter CREATE_COMPLETE CREATE_IN_PROGRESS \
		--query StackSummaries[*].StackName \
		--output text \
		| grep $_CLOUDFORMATION_STACK_NAME > /dev/null
}

create_stack() {
	upload_tpl_if_changed
	aws cloudformation create-stack \
		--stack-name $_CLOUDFORMATION_STACK_NAME \
		--template-url https://$_S3_BUCKET.s3.amazonaws.com/$_CLOUDFORMATION_TPL \
		--parameters ParameterKey=IamInstanceProfileParameter,ParameterValue=$_IAM_ROLE ParameterKey=KeyNameParameter,ParameterValue=$_KEY_NAME ParameterKey=VolumeSizeParameter,ParameterValue=$_ROOT_VOLUME_GB \
		> /dev/null
}

delete_stack() {
	aws cloudformation delete-stack \
		--stack-name $_CLOUDFORMATION_STACK_NAME
}

get_ec2_public_ip() {
	aws ec2 describe-instances \
		--filters "Name=tag-key,Values=aws:cloudformation:stack-name" \
			"Name=tag-value,Values=$_CLOUDFORMATION_STACK_NAME" \
		--filters "Name=instance-state-name,Values=running" \
		--query Reservations[0].Instances[0].PublicIpAddress \
		--output text
}

case $1 in
validate)
	validate_tpl
	;;
launch)
	if ! has_stack_been_created; then
		create_stack
		echo Instance launched
	else
		echo Instance already launched
	fi
	;;
halt)
	if has_stack_been_created; then
		delete_stack
	else
		echo Instance not launched
	fi;
	;;
status)
	if has_stack_been_created; then
		echo Instance launched or in progress \(IP $(get_ec2_public_ip)\)
	else
		echo Instance not launched
	fi
	;;
*)
	echo Valid actions are: validate, launch, halt, status
	;;
esac
