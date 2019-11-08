function main_tmb_map_process

%% either high_low or mid is 1
high_low=0;
mid=1;

if high_low==1
    tmb_path='E:\Hongming\projects\tcga-bladder-mutationburden\tmb_blca\';
elseif mid==1
    tmb_path='E:\Hongming\projects\tcga-bladder-mutationburden\tmb_blca\mid\';
else
    disp('impossible!!!')
end

feat_path='E:\Hongming\projects\tcga-bladder-mutationburden\Hongming_codes\step11)_tmb_map_process\features\';

mat_files=dir(strcat(tmb_path,'*.mat'));


pid_entropy=cell(length(mat_files),3);

for i=1:length(mat_files)
    temp_file=mat_files(i).name;
    load(strcat(tmb_path,temp_file));
    
    tmb_level=[];
    for j=1:size(top_left_tumor,1)
        rs=top_left_tumor(j,1);
        cs=top_left_tumor(j,2);
        re=bottom_right_tumor(j,1)-1;
        ce=bottom_right_tumor(j,2)-1;
        %unique(tmb_map(rs:re,cs:ce))
        tmb_level=[tmb_level,mean(mean(tmb_map(rs:re,cs:ce)))];
    end
    
    sh_entropy=shannon_entropy(tmb_level);
    %save(strcat(feat_path,temp_file),'sh_entropy');
    pid_entropy{i,1}=temp_file;
    pid_entropy{i,2}=sh_entropy;
end

label=([pid_entropy{:,2}]>median([pid_entropy{:,2}]));

pid_entropy(:,3)=num2cell(label);

save(strcat(feat_path,'feat_mid','.mat'),'pid_entropy');

% X = [1 2 2 0];
% h2=shannon_entropy(X);

function H=shannon_entropy(X)
% shannon's entropy

% Build the probabilities vector according to X...

X_uni = unique(X);
X_uni_size = numel(X_uni);

P = zeros(X_uni_size,1);

for i = 1:X_uni_size
    P(i) = sum(X == X_uni(i));
end

P = P ./ numel(X);

% Compute the Shannon's Entropy

H = -sum(P .* log2(P)); % 1.5