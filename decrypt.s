# Decrypts data encrypted with AES-128-ECB.

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

    # Compute a decryption key schedule for the Equivalent Inverse
    # Cipher.
    #
    # Use the key_expand macro from common.s, which keeps state
    # between invocations in %xmm0 and %xmm2.  Store round keys in
    # %xmm6 through %xmm15.
    #
    # The immediate "round constants" are basically magic numbers
    # as far as we're concerned, but have some mathematical basis:
    # http://en.wikipedia.org/wiki/Rijndael_key_schedule#Rcon

    key_expand $1,   %xmm6,  1
    key_expand $2,   %xmm7,  1
    key_expand $4,   %xmm8,  1
    key_expand $8,   %xmm9,  1
    key_expand $16,  %xmm10, 1
    key_expand $32,  %xmm11, 1
    key_expand $64,  %xmm12, 1
    key_expand $128, %xmm13, 1
    key_expand $27,  %xmm14, 1
    key_expand $54,  %xmm15, 0  # No AESIMC on the last round.

decrypt:
    # Try to read a block of ciphertext.
    # Exit on EOF.
    call read_block
    cmp  $16, %rax
    jl   exit

    # Decrypt the block.
    pxor       %xmm15, %xmm0
    aesdec     %xmm14, %xmm0
    aesdec     %xmm13, %xmm0
    aesdec     %xmm12, %xmm0
    aesdec     %xmm11, %xmm0
    aesdec     %xmm10, %xmm0
    aesdec     %xmm9,  %xmm0
    aesdec     %xmm8,  %xmm0
    aesdec     %xmm7,  %xmm0
    aesdec     %xmm6,  %xmm0
    aesdeclast %xmm5,  %xmm0

    # Write it to stdout and loop.
    call write_block
    jmp  decrypt

# vim: ft=asm
