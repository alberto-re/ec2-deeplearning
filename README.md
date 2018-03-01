# README #

Automated provisioning of a deeplearning-ready EC2 instance.

This project puts together a CloudFormation template and some helper
scripts providing an easy way to get a running virtual machine with all
the basic software needed in order to run deep learning applications
written in Python on AWS.

# USAGE #

## INSTANCE SETUP ##

First of all create a copy of the configuration example file and call
it 'config.sh':

```bash
cp config.sh.default config.sh
```

Then edit the newly created file properly.

Use the helper script 'mng_ec2.sh' to create the EC2 instance:

```bash
sh mng_ec2 launch
```

After a while the instance public IP address will become available
by running the command:

```bash
sh mng_ec2 status
```

## SOFTWARE SETUP ##

SSH into your newly created instance and clone this repository locally:

```bash
sudo yum update -y
sudo yum install -y git
git clone https://github.com/proud/ec2-deeplearning.git
```

Now run the provisioning script 'setup_aws_p2.sh' to install Tensorflow
and it's dependencies plus some commonly used data science libraries:

```bash
cd ec2-deeplearning
sudo sh setup_aws_p2.sh
```
