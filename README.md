# Overview
This is a sample web application created using `start.spring.io tool`. This app only has one endpoint `/` which returns a welcome message.

## Run locally
The app comes with a Dockerfile and can be tested locally easily. The only prerequiste to run this app on local is Docker CLI / Desktop installed. The image is build using **multi stage build** and **alpine** base images for optimal image size.

### Steps to run
- `git clone git@github.com:raheelkhan/app.git`
- `cd app`
- `docker build -t <org>/<app>:<version> .` for example `docker build -t raheel/app:latest`
- `docker run -p 8080:8080 raheel/app`

This will start the app with containe ports exposed on 8080. You can visit the browser `localhost:8080`.

## Deployment Pipeline
The CI/CD pipeline for this application is written using Github Actions. It contains two flows one for CI where it performs mainly code testing and compiling. The other flow is for CD where it deploys the application to a EKS cluster.

### Github Repository Settings
Before running the deployment pipeline the Github repo must meet the below requirements.

1. Two Gtihub environments must be created with names `Stage` and `Prod`
2. The following environment secrets must be provided to each environment 
      - `AWS_IAM_ROLE_ARN` - This value represents the ARN of role in AWS account which will be assumed by Github Actions. We are using AWS Federated Identity for OIDC comatible clients such as Github.
      - `CLUSTER_NAME` - The name of the EKS cluster where the application will be deployed
      - `IMAGE_REGISTRY` - The name of ECR container registery to push container image 
      - `IMAGE_REPOSITORY` - The name of ECR repository
      - `REGION` - The AWS region where EKS cluster is provisioned
3. Both the environment must enable `Protection Rules` because we want approval before running the deployment actions.

### Continuous Integration
There is a workflow `app-ci.yaml` configured which listens to any PR creation or code updates that targets `master` branch. One any code change this flow runs and check for the applicaiton code. Please note that I have moved the steps related to CI (In general code health check such as testing, security scans) to its own reusable workflow in `app-reusable-ci.yaml` because I also need the same steps runs before actual deployment that acts on `master`.

### Continuous Deployment
The deployment is conigured to run when there is a PR merged to master. It also listens to push events but we must enable branch protection for Github settings.

Since I have used reusable workflow, the first thing that runs here is also the `app-reusable-ci.yaml` file.

After that it starts deployment to `Stage` environment. Because I have configured Github environments in the above steps, here the flow will be paused I until I approve it.

The steps that runs the deployment are written in `app-reusable-deploy.yaml` file. The purpose of making it also reusable is that it works for both `Prod` and `Stage` environments both having differnt variables / secrets.

Also notice that the acutal building of container image that is to be deployed is kept out of reusable work flow purposely. Because I wanted to move same image from to `Stage` to `Prod` to avoid any surprises in `Prod`. However the pipeline is currently disabled for `Prod` purposely because I do not provision `Prod` cluster to save cost. This can be seen in `app-cd.yaml` 
```
  Deploy-Prod:
    if: false
```

## Kubernetes Manifests
The applicaiton is very simple hence no complex Kubernetes objects are created of it. But it can be extinsble provided that I have utilized HELM to package the application. The following objects are created in the `app` namespace.

```
kubectl get all -n app
NAME                      READY   STATUS    RESTARTS   AGE
pod/app-bf5576c66-x426l   1/1     Running   0          23h

NAME          TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)    AGE
service/app   ClusterIP   1.1.1.1   <none>        8080/TCP   24h

NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/app   1/1     1            1           24h
```

An `Ingress` resource is also created to expose the application via Application Load Balancer
```
kubectl get ingress -n app
NAME   CLASS   HOSTS   ADDRESS                                                        PORTS   AGE
app    alb     *       ******.us-east-1.elb.amazonaws.com   80      24h
```