FROM redhat/ubi10-minimal:latest

ARG TERRAFORM_VERSION=1.16.2
ARG TARGETARCH

# Install unzip to extract the Terraform release archive (curl and coreutils
# are already present in ubi-minimal images)
RUN microdnf install -y unzip ca-certificates && microdnf clean all

WORKDIR /tmp

# Download Terraform and verify it against HashiCorp's published checksums
RUN curl -fsSL -o terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip" \
    && curl -fsSL -o terraform_SHA256SUMS "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" \
    && grep "terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip" terraform_SHA256SUMS | sha256sum -c - \
    && unzip terraform.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/terraform \
    && rm -f terraform.zip terraform_SHA256SUMS

# Remove unzip now that the binary is extracted
RUN microdnf remove -y unzip && microdnf clean all

# Run as non-root user for secure environments
USER 59000:59000

WORKDIR /workspace

ENTRYPOINT ["terraform"]
CMD ["--help"]
