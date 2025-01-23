# KVM OP-TEE Mediator
This project aims to enable KVM guests to interact with OP-TEE in the secure world, which is not possible otherwise.
This repository acts as the primary build system for testing this functionality out. This is done because building a fully functioning machine with TF-A, U-Boot, Linux Kernel and OP-TEE can be quite tedious.

![Screenshot from 2025-01-14 19-52-41](https://github.com/user-attachments/assets/014d0ffa-861f-455c-9ca9-b9241250e5ce)
![Screenshot from 2025-01-14 12-25-21](https://github.com/user-attachments/assets/19516aa7-4d74-4c16-af33-d9c5b8280698)

The code enabling the guest to S-EL1 functionality is placed in the linux/ submodule. The reader is advised to navigate to the linux kernel submodule and switch branches to 'tee_mediator1' and git diff it with the master branch to view the feature.
