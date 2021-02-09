
% 1. grab participant number 

prompt = 'PARTICIPANT number (in raw number form, e.g. 1, 2,...,98): ';
sub = input(prompt);

prompt = 'RUN number (1, 2, 3, 4): ';
srun = input(prompt);

prompt = 'BIOPAC (YES=1 NO=0) : ';
biopac = input(prompt);

fmri = 0;

run_t1 = strcat( "narratives(", num2str(sub), "',", num2str(1), "',", num2str(biopac), "',", num2str(fmri), ")");
run_t2 = strcat( "narratives(", num2str(sub), "',", num2str(2), "',", num2str(biopac), "',", num2str(fmri), ")");
run_t3 = strcat( "narratives(", num2str(sub), "',", num2str(3), "',", num2str(biopac), "',", num2str(fmri), ")");
run_t4 = strcat( "narratives(", num2str(sub), "',", num2str(4), "',", num2str(biopac), "',", num2str(fmri), ")");

if srun == 1
eval(run_t1);eval(run_t2);eval(run_t3);eval(run_t4);
elseif srun == 2
eval(run_t2);eval(run_t3);eval(run_t4);
elseif srun == 3
eval(run_t3);eval(run_t4);
elseif srun == 4
eval(run_t4);
end




