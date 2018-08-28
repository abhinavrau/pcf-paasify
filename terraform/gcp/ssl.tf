provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = "${tls_private_key.private_key.private_key_pem}"
  email_address   = "none@paasify.org"
}

resource "acme_certificate" "certificate" {
  depends_on = ["null_resource.ssl_blocker"]

  account_key_pem           = "${acme_registration.reg.account_key_pem}"
  common_name               = "${module.gcp.ops_manager_dns}"
  subject_alternative_names = ["*.${module.gcp.apps_domain}", "*.${module.gcp.sys_domain}", "*.uaa.${module.gcp.sys_domain}"]

  dns_challenge {
    provider = "gcloud"

    config = {
      GCE_PROJECT = "fe-nthomson"
    }
  }
}

resource "null_resource" "ssl_blocker" {
  provisioner "local-exec" {
    command = "echo ${module.gcp.dns_managed_zone} && sleep 120"
  }
}

locals {
  cert_full_chain = "${acme_certificate.certificate.certificate_pem}${acme_certificate.certificate.issuer_pem}"
  cert_key        = "${acme_certificate.certificate.private_key_pem}"
}

output "tls_cert" {
  value = "${acme_certificate.certificate.certificate_pem}"
}

output "tls_key" {
  value = "${acme_certificate.certificate.private_key_pem}"
}