#include "stdio.h"
#include "stdlib.h"
#include "math.h"
#include "string.h"
#include "time.h"

double EPS = 0.001;

double read_data(char *file_name) {
    FILE *istream = fopen(file_name, "r");

    // check if the istream exists
    if (!istream) {
        fprintf(stderr, "Input file isn't found");
        exit(-1);
    }

    //  read the number
    double x;
    fscanf(istream, "%lf", &x);
    fclose(istream);
    return x;
}

void write_data(double x, char *file_name) {
    FILE *ostream = fopen(file_name, "w");

    // check if the ostream exists
    if (!ostream) {
        fprintf(stderr, "Output file isn't found");
        exit(-1);
    }

    // print the data
    fprintf(ostream, "%lf", x);
    fclose(ostream);
}

double generate_random() {
    srand(time(NULL));
    //  generate double in interval [-10, 10]
    double x = (((double)rand() / RAND_MAX) * 20) - 10;

    // if x == 0 then it's not in the domain - regenerate
    if (!x) {
        x = rand() % 10 + 1;
    }

    return x;
}

double calculate(double x) {
    // calculate cth(x) = (e^x + e^(-x))/(e^x - e^(-x))

    // check if x is in the domain
    if (!x) {
        fprintf(stderr, "X is out of domain.");
        exit(-1);
    }

    double exp = 1;     // calculate e^x
    double exp_member = 1; // last member of power serie e^x
    double exp_reverse = 1; // calculate e^(-x)
    double exp_reverse_member = 1; // last member of power serie e^(-x)

    unsigned int step = 0;  // iterations counter
    double prev_result = 0; // result of previous iteration
    double cur_result = 0;  // result of current iteration

    // while differents of two adjancent results >= EPS or 
    // we haven't done at least 2 steps (prev_result is fictitious)
    while (step < 2 || EPS <= fabs(cur_result - prev_result)) {
        ++step;
        //calculate next members of power series & add them to results
        exp_member *= x / step;
        exp_reverse_member *= (-x) / step;

        exp += exp_member;
        exp_reverse += exp_reverse_member;

        // update current result of cth(x)
        prev_result = cur_result;
        cur_result = (exp + exp_reverse) / (exp - exp_reverse);
    }

    return cur_result;
}


int main(int argc, char **argv) {

    //  get all options and arguments from cmd
    if (argc < 3) {
        fprintf(stderr, "At least 2 argements excepted - input file and output file");
        exit(1);
    }
    char *input = argv[1];
    char *output = argv[2];

    char time_flag = 0; // flag for option to measure time
    char random_flag = 0; // flag for option to generate random input data
    //  handle options
    for (size_t i = 3; i < argc; ++i)
    {
        if (!strcmp(argv[i], "--rand")) { // option to generate random data
            random_flag = 1;
        }

        if (!strcmp(argv[i], "--time")) { // option to measure time
            time_flag = 1;
        }
    }

    double x = 0;
    if (random_flag) {
        x = generate_random();
        write_data(x, input);
    } else {
        x = read_data(input);
    }
    clock_t time_start = clock(); // measure a time of start calculating

    double cth = calculate(x);

    // cycle if we have to measure time
    if (time_flag) {
        for (int i = 0; i < 1000000; ++i) {
            calculate(x);
        }
    }
    clock_t time_end = clock(); // measure a time of end calculating

    write_data(cth, output); // write the result into output

    if (time_flag) {    // print time
        double cpu_time_used = ((double)(time_end - time_start)) / CLOCKS_PER_SEC;
        printf("Process time:%f seconds\n", cpu_time_used);
    }

    return 0;
}