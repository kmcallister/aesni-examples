#!/bin/sh -e

printf 'Building... '
for bin in encrypt decrypt; do
    gcc -Wall -nostdlib -o $bin $bin.s
done
printf 'done.\n'

n=`wc -l < test-vectors`
i=1

cat test-vectors | while read -r key plaintext ciphertext; do
    printf "\rTesting %3d of %3d" $i $n

    printf "$plaintext"  > expected_pt
    printf "$ciphertext" > expected_ct

    printf "$key$plaintext"  | ./encrypt > actual_ct
    printf "$key$ciphertext" | ./decrypt > actual_pt

    cmp expected_pt actual_pt
    cmp expected_ct actual_ct

    i=`expr $i + 1`
done

printf '\rTesting...  done. \n'
rm expected_pt expected_ct actual_pt actual_ct
