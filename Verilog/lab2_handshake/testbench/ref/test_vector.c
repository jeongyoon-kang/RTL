#include <stdio.h>
#include <stdlib.h>
#include <time.h>

//=============================================================================
// Test Vector Range: 0 to 255
//=============================================================================
// This power-of-8 module outputs 64-bit results. To prevent overflow in the
// 64-bit output (2^64 - 1 max), the input must satisfy input^8 <= 2^64 - 1.
// Solving for the input gives a maximum value of (2^64 - 1)^(1/8) ≈ 255.
// As such, all test vectors are generated in the range [0, 255].
//============================================================================

unsigned long long ipow(unsigned long long x, unsigned long long y){
    if(y<0){
        return 0;
    }

    if(y==0){
        return 1;
    }

    if(y==1){
        return x;
    }

    unsigned long long half = ipow(x, y/2);

    if(y%2 == 0){
        return half*half;
    }
    else{
        return half*half*x;
    }
}

int main(){

    const int num_vectors = 1000;
    FILE *fin = fopen("input.txt", "w");
    FILE *fout = fopen("output.txt", "w");

    if(fin == NULL || fout == NULL){
        fprintf(stderr, "file open error");
        return 1;
    }

    srand((unsigned int)time(NULL));    //random seed

    for(int i=0; i<num_vectors; i++){
        unsigned long long x = rand()%256;
        unsigned long long y = ipow(x, 8);
        fprintf(fin, "%llu\n", x);
        fprintf(fout, "%llu\n", y);
    }

    fclose(fin);
    fclose(fout);

    return 0;
}