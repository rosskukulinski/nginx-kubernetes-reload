# NGINX for Kubernetes

[![Docker Hub](https://img.shields.io/badge/docker-ready-blue.svg)](https://hub.docker.com/r/rosskukulinski/nginx-kubernetes-reload/)
[![Docker Pulls](https://img.shields.io/docker/pulls/rosskukulinski/nginx-kubernetes-reload.svg?maxAge=2592000)]()
[![Docker Stars](https://img.shields.io/docker/stars/rosskukulinski/nginx-kubernetes-reload.svg?maxAge=2592000)]()

This repo provides a containerized NGINX that supports watching for configuration file changes
from Kubernetes Secrets or ConfigMaps.

The primary motivation for this NGINX configuration was to support dynamically updating LetsEncrypt
TLS certificates from [kube-cert-manager](https://github.com/PalmStoneGames/kube-cert-manager) within Kubernetes.

## Why not an Ingress Controller?

An Ingress controller is an application that monitors Ingress resources via the Kubernetes API and updates the configuration of a load balancer in case of any changes.

While the Kubernetes community is slowly moving towards leveraging Ingress as the primary L7 load balancer,
I've consistently run into situations that require a customized NGINX configuration or where the Ingress controllers are missing key features.

To support those instances, I utilize this NGINX Deployment to dynamically handle TLS & ConfigMap changes
while still enabling a completely customized config.

## How it works

As you can see in the [Dockerfile](./Dockerfile):

* Alpine NGINX base image (nginx:1.10-alpine) to [support http2](https://github.com/nginxinc/docker-nginx/issues/76)
* [dumb-init](https://github.com/Yelp/dumb-init) as the PID 1
* [nginx-reload.sh](./nginx-reload.sh) as the init script
* Expose NGINX health stub on port 8080


The key configuration parameter is the environment variable, `WATCH_PATHS`.  nginx-reload.sh uses `inotifywait` to watch the paths defined in `WATCH_PATHS` for changes, additions, or deletions of files.  When a change is identified, `nginx -t` is run to ensure that the new configuration is valid, and if it is, then NGINX is reloaded using `nginx -s reload`.

If the configuration is not valid, NGINX is not reloaded - it will continue to use the last valid configuration.

## Example Deployment

```
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: gateway
  name: gateway
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: gateway
    spec:
      containers:
      - image: rosskukulinski/nginx-kubernetes-reload:v2.0.0
        imagePullPolicy: Always
        name: gateway
        ports:
        - containerPort: 80
          protocol: TCP
        - containerPort: 8080
          protocol: TCP
        env:
          - name: WATCH_PATHS
            value: "/etc/nginx /etc/nginx-ssl/jenkins/"
        volumeMounts:
        - mountPath: /etc/nginx/
          name: gateway-config
        - mountPath: /etc/nginx-ssl/jenkins/
          name: jenkins-tls
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
          timeoutSeconds: 1
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
          timeoutSeconds: 1
      restartPolicy: Always
      volumes:
      - name: gateway-config
        configMap:
          name: gateway-config
      - name: jenkins-tls
        secret:
          secretName: jenkins-tls
```

## Bad-Bots

This Docker image has been pre-loaded with support for [nginx-badbot-blocker](https://github.com/mariusv/nginx-badbot-blocker/tree/master/VERSION_2).

Blacklist.conf has already been loaded, you should apply your whitelist-ips and whitelist-domains accordingly.

## Contact

I'd love to hear your feedback! If you have any suggestions or experience issues with this NGINX configuration, please create an issue or send a pull request on Github.
You can contact me directly via [ross@kukulinski.com](mailto:ross@kukulinski.com).
