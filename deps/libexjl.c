#include <termios.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>

// do not require libuv development headers
extern int uv_fileno(void*, int* fd);


int exjl_set_cloexec(int fd)
{
  return ioctl(fd, FIOCLEX);
}


int exjl_sendeof(void* tty)
{
  struct termios buf;
  int fd, ret;
  uint8_t seq[2];

  if(uv_fileno(tty, &fd))
    return -1;

  // fetch current discipline
  ret = tcgetattr(fd, &buf);
  if(ret != 0) return -1;

  if(!(buf.c_lflag & ICANON) || (buf.c_lflag & (ECHO | ECHONL)))
  {
    // force ICANON processing without ECHO
    buf.c_lflag |= ICANON;
    buf.c_lflag &= ~(ECHO | ECHONL);
    ret = tcsetattr(fd, TCSADRAIN, &buf);
    if(ret != 0) return -1;
  }

  // send NL+EOF
  seq[0] = '\n';
  seq[1] = buf.c_cc[VEOF];
  ret = write(fd, seq, 2);
  if(ret != 2) return -1;

  tcdrain(fd);
  return 0;
}
