# KVM OP-TEE Mediator
This addition to the linux kernel allows a KVM guest to interact with OP-TEE.
This is done by trapping guest SMCs, modifying the vCPU state and manipulating guest arguments (such as IPA to PA translations)
before sending it to OP-TEE.

Note: OP-TEE does come with virtualization support for the NS-World (CFG_VIRTUALIZATION).

To understand the code, navigate to the linux submodule and switch to the 'tee_mediator1' branch. You can 'git diff' from there.

![Screenshot from 2025-01-14 19-52-41](https://github.com/user-attachments/assets/f1f59b15-45c4-4641-871d-4d3421615f45)
![Screenshot from 2025-01-14 12-25-21](https://github.com/user-attachments/assets/b637e45d-1980-400d-9875-2616103fdf0f)
