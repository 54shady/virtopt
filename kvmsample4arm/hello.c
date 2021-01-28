#include "reg.h"

int puts(const char *str)
{
	while (*str)
		*((unsigned int *) UART_BASE) = *str++;

	return 0;
}

int main(int argc, char *argv[])
{
	puts("Hello\n");
	while (1);
}
