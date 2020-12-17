#include <stdio.h>
#include <memory.h>
#include <sys/mman.h>
#include <pthread.h>
#include <linux/kvm.h>
#include <fcntl.h>
#include <stdlib.h>
#include <assert.h>
#include <sys/ioctl.h>
#include <unistd.h>

#define KVM_DEVICE "/dev/kvm"
#define RAM_SIZE 512000000
#define CODE_START 0x1000

struct kvm {
	int dev_fd;
	int vm_fd;
	__u64 ram_size;
	__u64 ram_start;
	int kvm_version;
	struct kvm_userspace_memory_region mem;

	struct vcpu *vcpus;
	int vcpu_number;
};

struct vcpu {
	int vcpu_id;
	int vcpu_fd;
	pthread_t vcpu_thread;
	struct kvm_run *kvm_run;
	int kvm_run_mmap_size;
	struct kvm_regs regs;
	struct kvm_sregs sregs;
	void *(*vcpu_thread_func)(void *);
};

void kvm_reset_vcpu(struct vcpu *vcpu)
{
	if (ioctl(vcpu->vcpu_fd, KVM_GET_SREGS, &(vcpu->sregs)) < 0) {
		perror("can not get sregs\n");
		exit(1);
	}

	vcpu->sregs.cs.selector = CODE_START;
	vcpu->sregs.cs.base = CODE_START * 16;
	vcpu->sregs.ss.selector = CODE_START;
	vcpu->sregs.ss.base = CODE_START * 16;
	vcpu->sregs.ds.selector = CODE_START;
	vcpu->sregs.ds.base = CODE_START * 16;
	vcpu->sregs.es.selector = CODE_START;
	vcpu->sregs.es.base = CODE_START * 16;
	vcpu->sregs.fs.selector = CODE_START;
	vcpu->sregs.fs.base = CODE_START * 16;
	vcpu->sregs.gs.selector = CODE_START;

	if (ioctl(vcpu->vcpu_fd, KVM_SET_SREGS, &vcpu->sregs) < 0) {
		perror("can not set sregs");
		exit(1);
	}

	vcpu->regs.rflags = 0x0000000000000002ULL;
	vcpu->regs.rip = 0;
	vcpu->regs.rsp = 0xffffffff;
	vcpu->regs.rbp= 0;

	if (ioctl(vcpu->vcpu_fd, KVM_SET_REGS, &(vcpu->regs)) < 0) {
		perror("KVM SET REGS\n");
		exit(1);
	}
}

void *kvm_cpu_thread(void *data)
{
	struct kvm *kvm = (struct kvm *)data;
	int ret = 0;

	kvm_reset_vcpu(kvm->vcpus);

	while (1) {
		printf("KVM start run\n");
		ret = ioctl(kvm->vcpus->vcpu_fd, KVM_RUN, 0);
		if (ret < 0) {
			fprintf(stderr, "KVM_RUN failed\n");
			exit(1);
		}

		switch (kvm->vcpus->kvm_run->exit_reason) {
			case KVM_EXIT_UNKNOWN:
				printf("KVM_EXIT_UNKNOWN\n");
				break;
			case KVM_EXIT_DEBUG:
				printf("KVM_EXIT_DEBUG\n");
				break;
			case KVM_EXIT_IO:
				printf("KVM_EXIT_IO\n");
				printf("out port: %d, data: %d\n",
						kvm->vcpus->kvm_run->io.port,
						*(int *)((char *)(kvm->vcpus->kvm_run) + kvm->vcpus->kvm_run->io.data_offset));
				/* wait a second */
				sleep(1);
				break;
			case KVM_EXIT_MMIO:
				printf("KVM_EXIT_MMIO\n");
				break;
			case KVM_EXIT_INTR:
				printf("KVM_EXIT_INTR\n");
				break;
			case KVM_EXIT_SHUTDOWN:
				printf("KVM_EXIT_SHUTDOWN\n");
				goto exit_kvm;
				break;
			default:
				printf("KVM PANIC\n");
				goto exit_kvm;
		}
	}

exit_kvm:
	return 0;
}

void load_binary(void *mem, const char *filename)
{
	int  fd;
	int  nr;

	fd = open(filename, O_RDONLY);
	if (fd == -1) {
		fprintf(stderr, "Cannot open %s", filename);
		perror("open");
		exit(1);
	}
	while ((nr = read(fd, mem, 4096)) != -1  &&  nr != 0)
		mem += nr;

	if (nr == -1) {
		perror("read");
		exit(1);
	}
	close(fd);
}

struct kvm *kvm_init(void)
{
	struct kvm *kvm;

	kvm = malloc(sizeof(struct kvm));
	if (kvm == NULL)
	{
		perror("malloc error\n");
		return NULL;
	}

	kvm->dev_fd = open(KVM_DEVICE, O_RDWR);
	if (kvm->dev_fd < 0) {
		perror("open kvm device fault: ");
		return NULL;
	}

	kvm->kvm_version = ioctl(kvm->dev_fd, KVM_GET_API_VERSION, 0);

	return kvm;
}

void kvm_clean(struct kvm *kvm)
{
	assert (kvm != NULL);
	close(kvm->dev_fd);
	free(kvm);
}

int kvm_create_vm(struct kvm *kvm, int ram_size)
{
	int ret = 0;

	kvm->vm_fd = ioctl(kvm->dev_fd, KVM_CREATE_VM, 0);
	if (kvm->vm_fd < 0) {
		perror("can not create vm");
		return -1;
	}

	kvm->ram_size = ram_size;
	kvm->ram_start = (__u64)mmap(NULL, kvm->ram_size,
			PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE,
			-1, 0);
	if ((void *)kvm->ram_start == MAP_FAILED) {
		perror("can not mmap ram");
		return -1;
	}

	kvm->mem.slot = 0;
	kvm->mem.guest_phys_addr = 0;
	kvm->mem.memory_size = kvm->ram_size;
	kvm->mem.userspace_addr = kvm->ram_start;
	ret = ioctl(kvm->vm_fd, KVM_SET_USER_MEMORY_REGION, &(kvm->mem));
	if (ret < 0) {
		perror("can not set user memory region");
		return ret;
	}

	return ret;
}

void kvm_clean_vm(struct kvm *kvm)
{
	close(kvm->vm_fd);
	munmap((void *)kvm->ram_start, kvm->ram_size);
}

struct vcpu *kvm_init_vcpu(struct kvm *kvm, int vcpu_id, void *(*fn)(void *))
{
	struct vcpu *vcpu;

	vcpu = malloc(sizeof(struct vcpu));
	vcpu->vcpu_id = 0;
	vcpu->vcpu_fd = ioctl(kvm->vm_fd, KVM_CREATE_VCPU, vcpu->vcpu_id);
	if (vcpu->vcpu_fd < 0) {
		perror("can not create vcpu");
		return NULL;
	}

	vcpu->kvm_run_mmap_size = ioctl(kvm->dev_fd, KVM_GET_VCPU_MMAP_SIZE, 0);
	if (vcpu->kvm_run_mmap_size < 0) {
		perror("can not get vcpu mmsize");
		return NULL;
	}

	printf("vcpu map size: %d\n", vcpu->kvm_run_mmap_size);

	vcpu->kvm_run = mmap(NULL, vcpu->kvm_run_mmap_size,
			PROT_READ | PROT_WRITE, MAP_SHARED, vcpu->vcpu_fd, 0);
	if (vcpu->kvm_run == MAP_FAILED) {
		perror("can not mmap kvm_run");
		return NULL;
	}

	vcpu->vcpu_thread_func = fn;

	return vcpu;
}

void kvm_clean_vcpu(struct vcpu *vcpu)
{
	munmap(vcpu->kvm_run, vcpu->kvm_run_mmap_size);
	close(vcpu->vcpu_fd);
}

void kvm_run_vm(struct kvm *kvm)
{
	int i = 0;

	for (i = 0; i < kvm->vcpu_number; i++)
	{
		if (pthread_create(&(kvm->vcpus->vcpu_thread),
					(const pthread_attr_t *)NULL, kvm->vcpus[i].vcpu_thread_func, kvm) != 0)
		{
			perror("can not create kvm thread");
			exit(1);
		}
	}

	pthread_join(kvm->vcpus->vcpu_thread, NULL);
}

int main(int argc, char *argv[])
{
	struct kvm *kvm;

	if (argc < 2)
	{
		printf("Usage %s <binary.bin>\n", argv[0]);
		return -1;
	}

	kvm = kvm_init();
	if (kvm == NULL) {
		fprintf(stderr, "kvm init fauilt\n");
		return -1;
	}

	if (kvm_create_vm(kvm, RAM_SIZE) < 0) {
		fprintf(stderr, "create vm fault\n");
		return -1;
	}

	load_binary((void *)kvm->ram_start, argv[1]);

	/* only support one vcpu now */
	kvm->vcpu_number = 1;
	kvm->vcpus = kvm_init_vcpu(kvm, 0, kvm_cpu_thread);

	kvm_run_vm(kvm);

	kvm_clean_vm(kvm);
	kvm_clean_vcpu(kvm->vcpus);
	kvm_clean(kvm);
}
