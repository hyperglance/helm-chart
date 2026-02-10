# Breaking Changes

**10/02/2026**

\> v8.1.57
   - The values.yaml file has been updated. A number of root parameters have been folded into `hyperglanceEnvVars` which is templated into the configmap instead of manually hard coding each required parameter.

**20/08/2024**

 \> v7.5.9 
    - Within the Hyperglance EKS Fargate section, the base parameter of eks has been renamed to fargate (from eks) to better align with the configuration options purpose.
    - PVC parameters (annotations, storageClassName and resources.requests.storage) were made configurable.