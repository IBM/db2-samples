These are some sample Ansible playbooks to setup a Db2 DPF instance on a set of VMs.

The Db2 DPF instance uses NFS for the shared instance home directory.

The playbooks assume your storage is also virtualized.
Meaning a VM exists that provides storage (via iSCSI) to the VMs running Db2.

See the [vars.yaml](playbooks/vars.yaml) file for how you can specify things like the IP
addresses of the VMs, the name of the Db2 installation image, the number of MLNs per VM
and more.

With VMs created, the following commands would run the playbooks to setup the DPF instance:

```shell
ansible-playbook -i inventory.ini playbooks/vm_setup.yaml
ansible-playbook -i inventory.ini playbooks/storage_host_setup.yaml
ansible-playbook -i inventory.ini playbooks/storage_client_setup.yaml
ansible-playbook -i inventory.ini playbooks/db2_dpf_setup.yaml
ansible-playbook -i inventory.ini playbooks/db2_storage_setup.yaml
```
