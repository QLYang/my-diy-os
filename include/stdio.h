#ifndef	_STDIO_H_
#define	_STDIO_H_

#include "type.h"

#define	PUBLIC
#define	PRIVATE	static

/* the assert macro */
#define ASSERT
#ifdef ASSERT
void assertion_failure(char *exp, char *file, char *base_file, int line);
#define assert(exp)  if (exp) ; \
        else assertion_failure(#exp, __FILE__, __BASE_FILE__, __LINE__)
#else
#define assert(exp)
#endif

/* EXTERN */
#define	EXTERN	extern	/* EXTERN is defined as extern except in global.c */

/* string */
#define	STR_DEFAULT_LEN	1024

#define	O_CREAT		1
#define	O_RDWR		2

#define SEEK_SET	1
#define SEEK_CUR	2
#define SEEK_END	3

#define	MAX_PATH	128

/**
 * @struct time
 * @brief  RTC time from CMOS.
 */
struct time {
	u32 year;
	u32 month;
	u32 day;
	u32 hour;
	u32 minute;
	u32 second;
};

#define  BCD_TO_DEC(x)      ( (x >> 4) * 10 + (x & 0x0f) )

/*========================*
 * printf, printl, printx *
 *========================*
 *
 *   printf:
 *
 *           [send msg]                WRITE           DEV_WRITE
 *                      USER_PROC ------------→ FS -------------→ TTY
 *                              ↖______________↙↖_______________/
 *           [recv msg]             SYSCALL_RET       SYSCALL_RET
 *
 *----------------------------------------------------------------------
 *
 *   printl: variant-parameter-version printx
 *
 *          calls vsprintf, then printx (trap into kernel directly)
 *
 *----------------------------------------------------------------------
 *
 *   printx: low level print without using IPC
 *
 *                       trap directly
 *           USER_PROC -- -- -- -- -- --> KERNEL
 *
 *
 *----------------------------------------------------------------------
 */

/* printf.c */
PUBLIC  int     printf(const char *fmt, ...);
PUBLIC  int     printl(const char *fmt, ...);

/* vsprintf.c */
PUBLIC  int     vsprintf(char *buf, const char *fmt, va_list args);
PUBLIC	int		sprintf(char *buf, const char *fmt, ...);

/*--------*/
/* 库函数 */
/*--------*/

/* lib/open.c */
PUBLIC	int	open		(const char *pathname, int flags);

/* lib/close.c */
PUBLIC	int	close		(int fd);

/* lib/read.c */
PUBLIC int	read		(int fd, void *buf, int count);

/* lib/write.c */
PUBLIC int	write		(int fd, const void *buf, int count);

/* lib/unlink.c */
PUBLIC	int	unlink		(const char *pathname);

/* lib/getpid.c */
PUBLIC int	getpid		();

/* lib/fork.c */
PUBLIC int	fork		();

/* lib/exit.c */
PUBLIC void	exit		(int status);

/* lib/wait.c */
PUBLIC int	wait		(int * status);

/* lib/syslog.c */
PUBLIC	int	syslog		(const char *fmt, ...);


#endif