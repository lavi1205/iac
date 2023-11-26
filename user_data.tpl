MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -ex
/etc/eks/bootstrap.sh ${cluster_name} \
  --b64-cluster-ca ${certificate-authority} \
  --apiserver-endpoint ${api-server-endpoint}

--==MYBOUNDARY==--