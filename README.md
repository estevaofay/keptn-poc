# Keptn Proof of Concept

This repository holds information and configuration on how to install a keptn utility in a k8s cluster and how to use it's basic funcionality

To download and extract Keptn helm charts, read and execute `./install.sh`


----

Some noteworthy mentions in the docs

- Within the Helm Charts several Docker Images are referenced (Keptn specific and some third party dependencies). We recommend to pulling, re-tagging and pushing those images to a local registry that the Kubernetes cluster can reach. We are providing a helper script for this in our Git repository: https://github.com/keptn/keptn/blob/master/installer/airgapped/pull_and_retag_images.sh
- We can edit the APIs root domain via the configuration (https://keptn.sh/docs/0.11.x/operate/advanced_install_options/#install-keptn-using-a-root-context)
- There's backup mechanisms for keptn (https://keptn.sh/docs/0.11.x/operate/advanced_install_options/#install-keptn-using-a-root-context)
- Keptn can run in a multi-cluster scenario https://keptn.sh/docs/0.11.x/operate/multi_cluster/#title. In this case the minimum cluster size for the control plane is this https://keptn.sh/docs/0.11.x/operate/k8s_support/#control-plane

---

Running keptn with externally hosted Mongodb

In the docs it says to run this command
```bash
helm upgrade keptn keptn --install -n keptn --create-namespace
--set=control-plane.mongo.enabled=false,
      control-plane.mongo.external.connectionString=<YOUR_MONGODB_CONNECTION_STRING>,
      control-plane.mongo.auth.database=<YOUR_DATABASE_NAME>

```

Meaning we should change the flags under charts/control-plane/values.yaml to equivalent in this command