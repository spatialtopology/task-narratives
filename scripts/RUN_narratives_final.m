
% 1. grab participant number 

prompt = 'PARTICIPANT number (in raw number form, e.g. 1, 2,...,98): ';
sub = input(prompt);

prompt = 'RUN number (1, 2, 3, 4): ';
srun = input(prompt);

prompt = 'BIOPAC (YES=1 NO=0) : ';
biopac = input(prompt);

fmri = 0;

narratives_final(sub, srun, biopac, fmri)




