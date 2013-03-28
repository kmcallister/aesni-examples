#!/bin/sh -e

printf 'Building... '
for bin in encrypt decrypt; do
    gcc -Wall -nostdlib -o $bin $bin.s
done
printf 'done.\n'

n=$(wc -l < test-vectors)
i=1

# Read test vectors from a file and test them.
#
# These are stored as octal escapes because POSIX printf(1) lacks
# \x syntax.  Never mind that the binaries are for amd64 Linux
# only; the test script must be as portable as possible!
cat test-vectors | while read -r key plaintext ciphertext; do
    printf "\rTesting %3d of %3d" $i $n

    # Using process substitution with <(...) would be nicer
    # here, but it doesn't work reliably (FIXME: why?)

    printf "$plaintext"  > expected_pt
    printf "$ciphertext" > expected_ct

    printf "$key$plaintext"  | ./encrypt > actual_ct
    printf "$key$ciphertext" | ./decrypt > actual_pt

    cmp expected_pt actual_pt
    cmp expected_ct actual_ct

    i=$(expr $i + 1)
done

printf '\rTesting...  done. \n'
rm expected_pt expected_ct actual_pt actual_ct
