# AES-NI example programs

Intel processors since around 2010 support the [AES-NI][] instruction set,
which provides hardware acceleration for the [AES][] block cipher.

There is plenty of AES-NI code out there, including the [Linux kernel][] and
Intel's own [sample code][].  However I struggled to find a really clear,
self-contained example of how these instructions work.  Eventually I put
together these programs as a test of my understanding, and a demonstration
which may be useful to others.  The programs are very simple, there is little
going on besides AES-NI, and they are thoroughly commented.

This code is available under a BSD-style license; see `LICENSE`.


## Warning

**Do not use this code in any context where actual security is required!** This
is just a demonstration, for learning purposes, of an AES-128 block encryption
/ decryption primitive.  I've expended zero effort at the level of protocol or
application security.  Each block is encrypted the same way regardless of where
it appears in the input stream — this is known as ECB mode and it's [very
insecure][].  Furthermore there may be implementation bugs, side channel
exposures, etc.  Even with a perfect implementation of AES, there are [many
ways to screw up][] using it.

It really should go without saying, but **you should not use assembly programs
from some random person on GitHub in your security-critical systems**.  I take
absolutely no responsibility for what happens if you do (see `LICENSE`).


## Usage

`encrypt` will read a 16-byte AES-128 key from standard input, followed by zero
or more 16-byte plaintext blocks, and will write the corresponding ciphertext
to standard output.  `decrypt` works the same way, with the roles of plaintext
and ciphertext reversed.  Run `build-and-test.sh` to build both programs and
then test them against a few hundred AES-128 test vectors.

Both programs are written in assembly for amd64 Linux, and will run without
needing `libc` or any other libraries.  If you want to port these programs to
another amd64 platform (with a GNU-compatible assembler), all of the
OS-specific code is at the top of `common.s`.

To see if your CPU supports AES-NI, check for `aes` in `/proc/cpuinfo`.

Other caveats: This code doesn't have any error handling.  It assumes it can
always read/write 16 bytes at a time, and doesn't handle `EINTR`.  It doesn't
handle input that is not a multiple of the AES block size, nor does it check
the decrypted plaintext against any kind of padding spec.  It doesn't prevent
key material from being swapped to disk.


## Details

In AES, a single block of data goes through a number of encryption or
decryption rounds, each against a separate round key.  The 16-byte round keys
are derived from the user-specified key (also 16 bytes in AES-128) through a
process called key expansion.

The macro `key_expand` in `common.s` computes a single round key, by invoking
the `AESKEYGENASSIST` instruction and then calling the function `key_combine`
for additional processing.  The actual encryption / decryption rounds are
performed by `AESENC` / `AESDEC` instructions, with a variant used on the last
round.  See the Intel [white paper][] for more details on the individual
instructions.  That document also explains how to use AES-NI with 192- or
256-bit keys, which my code does not support.

In these programs, almost all of the action happens in registers; we only use
memory for calling `read` and `write`.  Conveniently, an AES round key or data
block is the same size as an SSE register.  The user-specified key goes in
`%xmm5` and the other round keys are computed and stored in `%xmm6` through
`%xmm15`.  `%xmm0` through `%xmm2` are used for various scratch purposes;
`%xmm3` and `%xmm4` are unused.

The key expansion code in `encrypt.s` and `decrypt.s` is similar and could be
combined using an additional macro, but I chose to leave them separate for
clarity.

AES-NI itself is very fast.  However, don't expect great performance from these
programs, because they make two system calls per 16 bytes processed.  A
high-throughput version would buffer I/O to reduce system call overhead.

Using AES-NI eliminates the need for AES lookup tables, which have been a
source of [cache-related timing side channel vulnerabilities][] [PDF].  Indeed
my programs have no data-dependent control flow or memory access.  (You can see
this clearly in the disassembly, which is free of the usual `libc` noise and is
actually quite readable.)  However I won't go so far as to claim there are no
timing side channels, especially because I haven't performed any measurements.


[AES]:           http://en.wikipedia.org/wiki/Advanced_Encryption_Standard
[AES-NI]:        http://software.intel.com/en-us/articles/intel-advanced-encryption-standard-instructions-aes-ni
[Linux kernel]:  http://lxr.linux.no/linux+v3.8.5/arch/x86/crypto/aesni-intel_asm.S
[sample code]:   http://software.intel.com/en-us/articles/download-the-intel-aesni-sample-library
[white paper]:   http://software.intel.com/en-us/articles/intel-advanced-encryption-standard-aes-instructions-set
[very insecure]: http://en.wikipedia.org/wiki/Block_cipher_modes_of_operation#Electronic_codebook_.28ECB.29
[many ways to screw up]: http://chargen.matasano.com/chargen/2009/7/22/if-youre-typing-the-letters-a-e-s-into-your-code-youre-doing.html
[cache-related timing side channel vulnerabilities]: http://tau.ac.il/~tromer/papers/cache-joc-20090619.pdf

