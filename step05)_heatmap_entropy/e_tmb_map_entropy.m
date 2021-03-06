% purpose: process tmb prediction heatmap to compute shannon entropy

%author: Hongming Xu
%email: mxu@ualberta.ca

function e_tmb_map_entropy

%% either high_low or mid is 1
high_low=1;
mid=0;
tcga_luad=0;

if high_low==1
    tmb_path='.\heatmap_blca\mat_files\high_low\';
elseif mid==1
    tmb_path='.\heatmap_blca\mat_files\mid\';
elseif tcga_luad==1
    tmb_path='..\..\..\tcga-lung-mutationburden\tcga_luad_tmb_predicion\4)plot_figures\heatmaps\';
else
    disp('impossible!!!')
end

feat_path='..\step07)_plot_km_curves\features\';
graymap_path='.\heatmap_blca\gray_maps\';

mat_files=dir(strcat(tmb_path,'*.mat'));

test1=[0.51,0.7,0.8,0.90,0.91,0.93];
%test1=[0.10,0.30,0.50,0.70,0.80,0.90];
H=shannon_entropy_bin(test1);

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
    
    % save gray-scale heatmap
    % temp=strsplit(temp_file,'.');
    % imwrite(tmb_map,strcat(graymap_path,temp{1},'.png'));
    
    sh_entropy=shannon_entropy_bin(tmb_level);
    %save(strcat(feat_path,temp_file),'sh_entropy');
    pid_entropy{i,1}=temp_file(1:23);
    pid_entropy{i,2}=sh_entropy;
end

%label=([pid_entropy{:,2}]>median([pid_entropy{:,2}]));
%pid_entropy(:,3)=num2cell(label);

if high_low==1
    save(strcat(feat_path,'feat_hl','.mat'),'pid_entropy');
elseif mid==1
    save(strcat(feat_path,'feat_mid','.mat'),'pid_entropy');
elseif tcga_luad==1
    save(strcat('..\..\..\tcga-lung-mutationburden\tcga_luad_tmb_predicion\5)survival_analysis\','tcga_luad_entropy','.mat'),'pid_entropy');
else
    disp('undefined selection!!!!!!!')
end

 %X = [0.5 0.5 0.5 0.5 0.5];
 %h2=shannon_entropy(X);

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

function H=shannon_entropy_bin(X)
% shannon's entropy

% Build the probabilities vector according to X...

a=0:1.0:1;
X2=X;

for i=1:length(X)
   temp=abs(X(i)-a);
   [v,ind]=min(temp);
   X2(i)=a(ind);
end
    
X_uni = unique(X2);
X_uni_size = numel(X_uni);

P = zeros(X_uni_size,1);

for i = 1:X_uni_size
    P(i) = sum(X2 == X_uni(i));
end

P = P ./ numel(X);

% Compute the Normalized Entropy

H = -sum(P .* log2(P))/(log2(X_uni_size)+0.00001);