Container Tools
=============

.. image:: https://raw.githubusercontent.com/avkcode/container-tools/refs/heads/main/favicon.svg
   :alt: Container Tools Logo
   :width: 80px
   :align: right

Build minimal, fast, and secure Debian-based images from scratch with debootstrap. Container Tools focuses on reproducible rootfs builds, CI-friendly workflows, and easy validation via container-structure-test.

Why Container Tools?
--------------------

- Eliminate Dockerfile layer bloat and rebuild pain
- Include only the packages you need
- First-class CI support (GitHub Actions)
- Built-in security scan and test automation

Quick Start
-----------

.. code-block:: bash

   git clone https://github.com/avkcode/container-tools.git
   cd container-tools
   make help
   make debian11-java-slim  # Example build target

Use the image:

.. code-block:: bash

   cat debian/dist/debian11-java-slim/debian11-java-slim.tar | docker import - debian11-java-slim
   docker run -it debian11-java-slim /bin/bash

Highlights
----------

GitHub Actions pipeline
~~~~~~~~~~~~~~~~~~~~~~~

- CI builds selected Makefile targets and publishes rootfs/image tarballs under ``debian/dist/...``
- Artifacts are uploaded for download and local validation
- No signing in CI (no secrets); sign locally after download
- Tools detect GitHub Actions and automatically skip signing

Import artifacts or push to a registry:

.. code-block:: bash

   skopeo copy --insecure-policy docker-archive:/path/to/image.tar docker://yourrepo/yourimage:tag

Validate with container-structure-test
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Test image contents, metadata, and commands
- Configs live under ``test/<name>.yaml``
- The test helper imports tarballs automatically when the image tag is missing

.. code-block:: bash

   ./scripts/test.py --image debian11-nodejs-23.11.0 --config test/debian11-nodejs-23.11.0.yaml

Security scanning (Trivy)
~~~~~~~~~~~~~~~~~~~~~~~~~

- Available during builds via ``scripts/security-scan.sh``
- Control via ``CT_DISABLE_SECURITY_SCAN`` (omit/enable script) and ``CT_SKIP_SECURITY_SCAN`` (skip execution)

Popular Targets
---------------

- ``debian11`` (base)
- ``debian11-java`` and ``debian11-java-slim``
- ``debian11-graal`` and ``debian11-graal-slim``
- ``debian11-nodejs-23.11.0``
- ``debian11-cuda-runtime`` (GPU-ready via NVIDIA Container Toolkit)

CUDA quick start:

.. code-block:: bash

   make debian11-cuda-runtime
   docker run --rm -it --gpus all debian11-cuda-runtime nvidia-smi

Configuration (env vars)
------------------------

- ``VARIANT``: container | fakechroot | minbase (default: container)
- ``RELEASE``: Debian codename (default: bullseye)
- ``DIST_DIR``: output directory (default: debian/dist)
- Versions: ``JAVA_VERSION``, ``GRAALVM_VERSION``, ``CORRETTO_VERSION``, ``MAVEN_VERSION``, ``GRADLE_VERSION``, ``NODE_VERSION``, ``PYTHON_VERSION``

Signing options
---------------

Sign and verify locally after CI:

.. code-block:: bash

   ./scripts/gpg.py --directory /path/to/tar/files --gpg-key-id YOUR_KEY_ID
   ./scripts/cosign.py --directory /path/to/tar/files --key cosign.key

Learn more
----------

- Examples: ``examples/`` (Java, Node.js, signing, testing)
- Makefile: all targets and build details
- Scripts: ``scripts/`` for security scan, tests, signing

Contributions welcome via issues and PRs.
