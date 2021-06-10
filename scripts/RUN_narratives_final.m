
% 1. grab participant number

prompt = 'PARTICIPANT number (in raw number form, e.g. 1, 2,...,98): ';
sub_num = input(prompt);

prompt = 'RUN number (1, 2, 3, 4): ';
run_num = input(prompt);

prompt = 'BIOPAC (YES=1 NO=0) : ';
biopac = input(prompt);

fmri = 0;

run_t1 = strcat( "narratives(", num2str(sub_num), "',", num2str(1), "',", num2str(biopac), "',", num2str(fmri), ")");
run_t2 = strcat( "narratives(", num2str(sub_num), "',", num2str(2), "',", num2str(biopac), "',", num2str(fmri), ")");
run_t3 = strcat( "narratives(", num2str(sub_num), "',", num2str(3), "',", num2str(biopac), "',", num2str(fmri), ")");
run_t4 = strcat( "narratives(", num2str(sub_num), "',", num2str(4), "',", num2str(biopac), "',", num2str(fmri), ")");

% DOUBLE CHECK MSG ______________________________________________________________
%% A. Directories ______________________________________________________________
task_dir                        = pwd;
repo_dir                        = fileparts(fileparts(task_dir));
ses_num = 2;
repo_save_dir = fullfile(repo_dir, 'data', strcat('sub-', sprintf('%04d', sub_num)),'task-narratives');
bids_string                     = [strcat('sub-', sprintf('%04d', sub_num)), ...
    strcat('_ses-',sprintf('%02d', ses_num)),...
    strcat('_task-narratives'),...
    strcat('_run-', sprintf('%02d', run_num))];
repoFileName = fullfile(repo_save_dir,[bids_string,'*_beh.csv' ]);

% 3. if so, "this run exists. Are you sure?" ___________________________________
if isempty(dir(repoFileName)) == 0
    RA_response = input(['\n\n---------------ATTENTION-----------\nThis file already exists in: ', repo_save_dir, '\nDo you want to overwrite?: (YES = 999; NO = 0): ']);
    if RA_response ~= 999 || isempty(RA_response) == 1
        error('Aborting!');
    end
end
% ______________________________________________________________

if run_num == 1
eval(run_t1);eval(run_t2);eval(run_t3);eval(run_t4);
elseif run_num == 2
eval(run_t2);eval(run_t3);eval(run_t4);
elseif run_num == 3
eval(run_t3);eval(run_t4);
elseif run_num == 4
eval(run_t4);
end
