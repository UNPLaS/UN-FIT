//#include <stdio.h>
//#include <stdlib.h>
#include <stdint.h>
// #include <math.h>


#define ITER 2000 // Precise 1000 (500 250 100 50 25)
 
 
int main(void) {
 
  double l=0;
    int i;
    unsigned j=0,result;
    
    for (i=1; i<ITER; i++) {       
        j=i+1;
         if (1&j)
            l=l-(1/(double)i);
        else
            l=l+(1/(double)i);
    }
    
    
   result=(int)(l*1000000000);
    return result;
        
      // while(1); 
  }
