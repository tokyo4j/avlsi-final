#include <stdio.h>
int fib(void)
{
	int n = 8;		/* compute nth Fibonacci number */
	int f1 = 1, f2 = -1; 	/* last two Fibonacci numbers */
	while (n != 0) { 	/* count down to n = 0 */
		f1 = f1 + f2;
		f2 = f1 - f2;
		n = n - 1;
	}
	return f1;
}
/* 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, ... */
int main()
{
	printf("f1 = %d\n", fib());
	return 0;
}
