ARG K3S_TAG="v1.26.4-k3s1"
FROM rancher/k3s:$K3S_TAG as k3s

FROM nvidia/cuda:11.8.0-base-ubuntu22.04

ARG NVIDIA_CONTAINER_RUNTIME_VERSION
ENV NVIDIA_CONTAINER_RUNTIME_VERSION=$NVIDIA_CONTAINER_RUNTIME_VERSION

RUN apt-get update && \
    apt-get -y install gnupg2 curl nvidia-container-runtime=${NVIDIA_CONTAINER_RUNTIME_VERSION} && \
    chmod 1777 /tmp && \
    mkdir -p /var/lib/rancher/k3s/agent/etc/containerd && \
    mkdir -p /var/lib/rancher/k3s/server/manifests

COPY --from=k3s /bin /bin
COPY --from=k3s /etc /etc

# Provide custom containerd configuration to configure the nvidia-container-runtime
COPY config.toml.tmpl /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl

# Deploy the nvidia driver plugin on startup
COPY device-plugin-daemonset.yaml /var/lib/rancher/k3s/server/manifests/nvidia-device-plugin-daemonset.yaml

VOLUME /var/lib/kubelet
VOLUME /var/lib/rancher/k3s
VOLUME /var/lib/cni
VOLUME /var/log

ENV PATH="$PATH:/bin/aux"
ENV CRI_CONFIG_FILE=/var/lib/rancher/k3s/agent/etc/crictl.yaml

ENTRYPOINT ["/bin/k3s"]
CMD ["agent"]