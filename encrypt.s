# Encrypts data with AES-128-ECB.

.include "common.s"

.text
.globl _start
_start:

    # Read the user key from stdin into %xmm5.
    #
    # It serves as the zeroth round key and also the seed
    # (in %xmm0) for the key expansion procedure.
    call   read_block
    movaps %xmm0, %xmm5

    # Clear %xmm2, which is a precondition for key_expand.
    pxor   %xmm2, %xmm2

    # Compute an encryption key schedule.
    #
    # Use the key_expand macro from common.s, which keeps state
    # between invocations in %xmm0 and %xmm2.  Store round keys in
    # %xmm6 through %xmm15.
    #
    # The immediate "round constants" are basically magic numbers
    # as far as we're concerned, but have some mathematical basis:
    # http://en.wikipedia.org/wiki/Rijndael_key_schedule#Rcon

    key_expand $1,   %xmm6
    key_expand $2,   %xmm7
    key_expand $4,   %xmm8
    key_expand $8,   %xmm9
    key_expand $16,  %xmm10
    key_expand $32,  %xmm11
    key_expand $64,  %xmm12
    key_expand $128, %xmm13
    key_expand $27,  %xmm14
    key_expand $54,  %xmm15

encrypt:
    # Try to read a block of plaintext.
    # Exit on EOF.
    call read_block
    cmp  $16, %rax
    jl   exit

    # Encrypt the block.
    pxor       %xmm5,  %xmm0
    aesenc     %xmm6,  %xmm0
    aesenc     %xmm7,  %xmm0
    aesenc     %xmm8,  %xmm0
    aesenc     %xmm9,  %xmm0
    aesenc     %xmm10, %xmm0
    aesenc     %xmm11, %xmm0
    aesenc     %xmm12, %xmm0
    aesenc     %xmm13, %xmm0
    aesenc     %xmm14, %xmm0
    aesenclast %xmm15, %xmm0

    # Write it to stdout and loop.
    call write_block
    jmp  encrypt

# vim: ft=asm
