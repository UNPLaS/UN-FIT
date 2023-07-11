UN-FIT is a fault injection tool for microprocessors, developed at the Universidad Nacional de Colombia, adaptable to different architectures. The current version of UN-FIT is based on QEMU and allows injection campaigns on ARM and RISC-V ISA based-processors.

The arguments to run UNFIT are:

- File name
- Qemu machine
- Qemu memory
- Number of injections
- Register with the result (or direction address)
- Result size in bytes (0 to result in the register)
- Injection mode
- Number of processes

  UNFIT requires a program execution trace file. A script is supplied to get the trace file.

  
In the example_ARM directory there are the necessary files and instructions for using the tool with an example program on ARM architecture.

Aponte-Moreno, A., Restrepo-Calle, F., & Pedraza, C. (2021). Reliability Evaluation of RISC-V and ARM Microprocessors Through a New Fault Injection Tool. 2021 IEEE 22nd Latin American Test Symposium (LATS), 1–6. https://doi.org/10.1109/LATS53581.2021.9651874
