#include <avr/io.h>
#include <avr/eeprom.h>
#include <avr/interrupt.h>
#include <avr/wdt.h>
#include <avr/cpufunc.h>
#include <util/atomic.h>
#include <avr/pgmspace.h>

#define F_CPU 8000000UL
#include <util/delay.h>

FUSES =
{
    .low = (LFUSE_DEFAULT|~FUSE_CKDIV8),
    .high = (HFUSE_DEFAULT&FUSE_BODLEVEL1),
    .extended = (EFUSE_DEFAULT),
};

void
main (void)
{
  
}
