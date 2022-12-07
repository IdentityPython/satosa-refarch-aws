# satosa-refarch-aws

A reference implementation of SATOSA on Amazon Web Services using CloudFormation, CodePipeline, and ECS

## Quick Start

1. Fork this repository or copy it to a supported Git hosting service.

2. Deploy [the CI/CD pipeline](.cloudformation/pipeline.yaml) using CloudFormation.

3. If using a third-party Git hosting service, manually connect it to CodePipeline.

4. The CI/CD pipeline will deploy SATOSA automatically.

## Design

[The first CloudFormation template](.cloudformation/pipeline.yaml) creates a continuous integration/continuous delivery (CI/CD) pipeline and connects it to a Git repository. Repository state changes trigger the pipeline. The pipeline builds a custom SATOSA container from the configuration stored in the repository and deploys it using a second CloudFormation template. The pipeline will keep the container up to date by rebuilding and redeploying it on a weekly basis even if there were no changes to the repository. Internally, the pipeline temporarily stores build artifacts in an S3 bucket. It uses CodeBuild to build the SATOSA container image on an Amazon Linux EC2 instance running in a private VPC, which uploads images to a private ECR repository. If the container image built successfully, the pipeline creates or updates a CloudFormation stack that hosts SATOSA in ECS via EC2 or Fargate (the default).

Because CloudFormation stack parameters are not stored securely, they must not be used to define secrets such as the SAML token signing key-pair. Instead, the pipeline manages keying material using AWS Certificate Manager, AWS Secrets Manager, or AWS Systems Manager Parameter Store. To customize this keying material, specify a certificate ARN at pipeline deployment time (for custom certificates) or overwrite the values of the secrets/parameters created by the pipeline (for custom SAML key-pairs).

[The second CloudFormation template](.cloudformation/service.yaml) performs a [blue/green deployment](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/transform-aws-codedeploybluegreen.html) of a SATOSA container image stored in the CI/CD pipeline's private ECR repository.

## Removal

Always delete the service stack before deleting the pipeline stack.

If the stacks are deleted out of order, the pipeline stack deletion may deadlock on the ACM certificate deletion, as the certificate created by the pipeline stack will still be in use by the service stack. Furthermore, the service stack cannot be deleted in this state because the IAM role used to deploy it will no longer exist. To work around this issue, create a temporary IAM role that trusts the CloudFormation service and has [the AdministratorAccess policy](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_job-functions.html) attached. Update the service stack using the current template, changing the Image URI parameter to `satosa:latest`, the ECR Private Repository ARN parameter to the empty string, and the stack IAM role to the temporary IAM role. The update will fail but the IAM role change will persist, after which point the service stack may be deleted. Once the service stack deletion completes, the pipeline stack deletion will continue (or may be retried). Remove the temporary IAM role when finished.

After deleting the service stack, the following resources will remain:

- CloudWatch log groups for the ECS cluster, ALB instance, and VPC flow logs (if a VPC was reated)

After deleting the pipeline stack, the following resources will remain:

- an S3 bucket containing artifacts for each pipeline phase

- an ECR private repository storing Docker container images

- CloudWatch log groups for the CodeBuild project and VPC flow logs

These resources must be deleted manually if desired or (in some cases) if redeploying the stacks with the same names.

## Developer Notes

To deploy or update the service manually, use the latest successful build artifact.

```sh
echo -n 'Pipeline stack name? '; read PIPELINE
TEMP_DIR=$(mktemp -d)
cd "${TEMP_DIR}"
STACK_NAME=$(aws cloudformation describe-stacks --stack-name ${PIPELINE} --query 'Stacks[-1].Parameters[?contains(ParameterKey, `StackName`)].ParameterValue' --output text)
ARTIFACT_BUCKET=$(aws cloudformation describe-stacks --stack-name ${PIPELINE} --query 'Stacks[-1].Outputs[?OutputKey==`ArtifactBucket`].OutputValue' --output text)
LATEST_BUILD_ARTIFACT=$(aws s3api list-objects --bucket $ARTIFACT_BUCKET --query 'Contents[?contains(Key, `BuildArtif`)] | sort_by(@,& LastModified)[-1].Key' --output text)
(aws s3api get-object --bucket ${ARTIFACT_BUCKET} --key ${LATEST_BUILD_ARTIFACT} /dev/stderr 3>&2 2>&1 1>&3) | bsdtar -x
CFN_ACTION_ROLE_ARN=$(aws cloudformation describe-stacks --stack-name ${PIPELINE} --query 'Stacks[-1].Outputs[?OutputKey==`CloudFormationActionRoleArn`].OutputValue' --output text)
aws cloudformation deploy --template-file service.yaml --stack-name ${STACK_NAME} --parameter-overrides file://config.json --capabilities CAPABILITY_IAM --role-arn ${CFN_ACTION_ROLE_ARN}
```

To export the initial SATOSA configuration without using a volume mount, pipe a base64-encoded tar file to the host.

```sh
docker run -it --rm satosa bash -c \
    'source docker-entrypoint.sh; docker_setup_env; docker_create_config > /dev/null 2>&1; rm *.crt *.key; tar cf - . | openssl base64' \
        | openssl base64 -d | tar xf -
```

## Coding Style

Please follow [the Python Style Guide (PEP8)](https://pep8.org/), [Dockerfile best practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/), [AWS CloudFormation best practices](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/best-practices.html), and [the Home Assistant YAML style guide](https://developers.home-assistant.io/docs/documenting/yaml-style-guide/) as appropriate.

In CloudFormation templates, please follow [the recommended template section ordering](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/template-anatomy.html#template-anatomy-sections).

In shell scripts, indent using single tabs instead of spaces.

## Git Commit Messages

Please follow [Angular Commit Message Conventions](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#-commit-message-format). The following scopes are currently in use:
- **pipeline**: the CloudFormation stack template defining the CI/CD pipeline
- **service**: the CloudFormation stack template defining the service
- **buildspec**: the CodeBuild specification
- **config**: the service stack configuration template
- **generate-key-pair-secret**: a CodeBuild project helper script
- **dockerfile**: the container image definition, including [Dockerfile](Dockerfile)
- **git**: Git repository configuration or GitHub-specific files; includes [.gitignore](.gitignore), [.gitattributes](.gitattributes), and [the GitHub Actions workflows](.github/workflows)
- **proxy_conf**, **saml2_backend**, **saml2_frontend**, etc.: SATOSA/plugin configuration
- **static_content**: a custom SATOSA front end used to serve metadata files
- **license**: software licensing information, specificaly [LICENSE.md](LICENSE.md)
- **readme**: this file
