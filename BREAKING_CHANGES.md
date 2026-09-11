# Breaking Changes

**TBD**

\> vX.X.X
   - `customIngress.metadata`, `customIngress.spec`, `customLoadbalancer.metadata`, and `customLoadbalancer.spec` must now be structured YAML maps in your values file, not pre-formatted strings. If you are using `customIngress.enabled: true` or `customLoadbalancer.enabled: true`, update your values file before upgrading. Example:
     ```yaml
     # Before (string — no longer supported):
     customIngress:
       metadata: "name: my-ingress\nnamespace: default"
     # After (map — required):
     customIngress:
       metadata:
         name: my-ingress
         namespace: default
     ```
   - `servicehttp.port`/`servicehttps.port` below `1024` now require a pod-level `net.ipv4.ip_unprivileged_port_start` sysctl, which the chart adds automatically — except when `fargate.enabled: true`, where support for this sysctl on EKS Fargate is unconfirmed and the chart now fails fast at render instead of deploying a potentially-broken pod. **If you run this chart on EKS Fargate at the default ports (`80`/`443`), you must set both `servicehttp.port` and `servicehttps.port` to `1024` or higher before upgrading**, or the `helm upgrade` will fail with an explicit error. This also changes the ALB's public-facing listener ports (`alb.ingress.kubernetes.io/listen-ports`/`ssl-redirect` now track the same values) — your Fargate deployment's internet-facing endpoint will move off `80`/`443` as a consequence.

**10/02/2026**

\> v8.1.57
   - The values.yaml file has been updated. A number of root parameters have been folded into `hyperglanceEnvVars` which is templated into the configmap instead of manually hard coding each required parameter.

**20/08/2024**

 \> v7.5.9 
    - Within the Hyperglance EKS Fargate section, the base parameter of eks has been renamed to fargate (from eks) to better align with the configuration options purpose.
    - PVC parameters (annotations, storageClassName and resources.requests.storage) were made configurable.