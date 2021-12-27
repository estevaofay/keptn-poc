#!/bin/bash

# Install Docs via Helm charts https://keptn.sh/docs/0.11.x/operate/advanced_install_options/#advanced-install-options-install-keptn-using-the-helm-chart
helm pull https://github.com/keptn/keptn/releases/download/0.11.4/keptn-0.11.4.tgz

tar -xvf keptn-0.11.4.tgz