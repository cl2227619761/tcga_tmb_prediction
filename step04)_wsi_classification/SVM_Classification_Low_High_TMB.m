% this function is used for evaluating bladder TMB prediction in the paper
% we test it for 2-class classifications: low TMB vs high TMB
% leave-one-out evaluation is found to be the best

% author: Hongming Xu, Cleveland Clinic, Jan 2019
% you may modify or use it, but you need give the credit for original
% author
% email: mxu@ualberta.ca


function SVM_Classification_Low_High_TMB

clear vars;

%% --- these are the indictors which testing we are performing---%
%  --- for more detail experiments see the paper description ---%
techs={'P_E_TD','P_E_CN','P_InceptionV3','P_Resnet50','P_Xception'};
meth=techs{5}; % 1,2,3,4,5 corresponding different testings

% features of tumor tiles output by pretrained deep learning models
switch meth
    case 'P_E_TD'
        ap_cluster={'E:\Hongming\projects\tcga-bladder-mutationburden\feature_output\P_E_TD\apfreq\'};
        featPath={'E:\Hongming\projects\tcga-bladder-mutationburden\feature_output\P_E_TD\3)xception\'};
    case 'P_E_CN'
        ap_cluster={'E:\Hongming\projects\tcga-bladder-mutationburden\feature_output\P_E_CN\apfreq\'};
        featPath={'E:\Hongming\projects\tcga-bladder-mutationburden\feature_output\P_E_CN\2)xception\'};
    case 'P_InceptionV3'
        ap_cluster={'E:\Hongming\projects\tcga-bladder-mutationburden\feature_output\P_CN_20X\apfreq\'};
        featPath={'E:\Hongming\projects\tcga-bladder-mutationburden\feature_output\P_CN_20X\5)inceptionv3\'};
    case 'P_Resnet50'
        ap_cluster={'E:\Hongming\projects\tcga-bladder-mutationburden\feature_output\P_CN_20X\apfreq\'};
        featPath={'E:\Hongming\projects\tcga-bladder-mutationburden\feature_output\P_CN_20X\2)resnet50\'};
    case 'P_Xception'
        ap_cluster={'E:\Hongming\projects\tcga-bladder-mutationburden\feature_output\P_CN_20X\apfreq\'};
        featPath={'E:\Hongming\projects\tcga-bladder-mutationburden\feature_output\P_CN_20X\4)xception\'};
    otherwise
            disp('impossible options!!!!!!!!!!');
end


%% -- feature organization into a table structure---%%
Ftrain=[];
Ltrain=[];

load('..\step00)_preprocessing\blca_MutBurdens.mat');  % TCGA TMB categories by 1-third percentile
%load('..\blca_MutBurdens_Yunku.mat'); % Yunku provided values
%load('..\blca_MutBurdensII.mat');     % by 5-20 thresholds

patID=[];
ii=1;
tt=[];
for ip=1:length(featPath)
    fp=featPath{ip};
    cp=ap_cluster{ip};
    mats=dir(fullfile(fp,'*.mat'));
    
    for im=1:numel(mats)
        matfilename=strcat(fp,mats(im).name);
        load(matfilename);
        
        patientID=mats(im).name(1:23);
        mats_cc=dir(fullfile(cp,strcat(mats(im).name(1:23),'*.mat')));
        
        if length(mats_cc)==1
            load(strcat(cp,mats_cc.name));
            
            apn=cell2mat(feat_cell(:,2));
            coeff=apn./sum(apn);
            
            coeff00=repmat(coeff,1,size(image_features,2));
            feat_mean=sum(image_features.*coeff00,1); 
            
            temp=strcmp(blca_MutBurdens(:,1),patientID(1:12));
            
            catg=blca_MutBurdens(temp==1,3);
            if strcmp(catg,'Low')
                Llow=1*ones(size(feat_mean,1),1);
                Ltrain=[Ltrain;Llow];
                Ftrain=[Ftrain;feat_mean];
                patID{ii}=patientID;
                ii=ii+1;
                tt=[tt,size(image_features,1)];
            elseif strcmp(catg,'Mid')
                Lmid=3*ones(size(feat_mean,1),1);
                %Ltrain=[Ltrain;Lmid];
                %Ftrain=[Ftrain;feat_mean];
            elseif strcmp(catg,'High')
                Lhigh=3*ones(size(feat_mean,1),1);
                Ltrain=[Ltrain;Lhigh];
                Ftrain=[Ftrain;feat_mean];
                patID{ii}=patientID;
                ii=ii+1;
                tt=[tt,size(image_features,1)];
            else
                disp('wrong!!!!!!');
            end
        else
            disp('impossible~~~~~~');
            break;
        end
    end
end

FT=table(Ftrain,Ltrain);
FT.Properties.VariableNames={'features','classes'};

%saveName=strcat(featmatoutput,'FT.mat');
%save(saveName,'FT')

%% ---SVM training and leave-one-out prediction ---%
labels=Ltrain;
feats=Ftrain;

%KFolds=10;
ACC=[];           % save the final acc
CC=zeros(2,2);    % save the confusion matrix
ItNum=1;          % number of iterations for cross validations
ComNum=100;       % number of PCA components, might be changed for different methods!!!!!!!!!!
PCA_usage=1;      % whether use PCA

SSC=zeros(length(labels),2);
pred50=[];
SPE=[];
SEN=[];

rng(100); % for the same indice we could generate
for cc=1:ItNum
    
    %Indices=crossvalind('Kfold',numel(labels),KFolds);
    Indices=randperm(numel(labels));
    
    validations=labels;
    validationScores=NaN(length(labels),2);
    %for k=1:KFolds
    for k=1:numel(labels)
        OriTest=(Indices==k);
        OriTrain=~OriTest;
        trainingPredictors=feats(OriTrain,:);
        trainingResponse=labels(OriTrain,:);
       
        % predict for each selected tile
        if PCA_usage==1
            
            %% -- PCA by explained variance --%
            %         [pcaCoefficients,pcaScores,~,~,explained,pcaCenters]=pca(trainingPredictors);  %%??
            %         explainedVarianceToKeepAsFraction=95/100;
            %         numComponentsToKeep = find(cumsum(explained)/sum(explained) >= explainedVarianceToKeepAsFraction, 1);
            %         pcaCoefficients = pcaCoefficients(:,1:numComponentsToKeep);
            %         trainingPredictors2=pcaScores(:,1:numComponentsToKeep);                                                                %%??
            
            %% -- PCA by number of components selected --%
            [pcaCoefficients, pcaScores, ~, ~, explained, pcaCenters] = pca(...
                trainingPredictors,'NumComponents', ComNum);
            trainingPredictors=pcaScores(:,:);
        end
        
        template = templateSVM(...
            'KernelFunction', 'Gaussian', ...
            'PolynomialOrder', [], ...
            'KernelScale', 'auto', ...
            'BoxConstraint', 1, ...
            'Standardize', true);
        
        classificationSVM = fitcecoc(...
            trainingPredictors, ...
            trainingResponse, ...
            'Learners', template, ...
            'Coding', 'onevsone', ...
            'ClassNames', [1; 3]);
        
        if PCA_usage==1
            pcaTransformationFcn=@(x)(x-pcaCenters)*pcaCoefficients;
            svmPredictFcn=@(x)predict(classificationSVM,x);
            validationPredictionFcn=@(x)svmPredictFcn(pcaTransformationFcn(x));
        else
            svmPredictFcn=@(x)predict(classificationSVM,x);
            validationPredictionFcn=@(x)svmPredictFcn(x);
        end
        
        testingPredictors=feats(OriTest,:);
        testingResponse=labels(OriTest);
        [foldPrediction,foldScores]=validationPredictionFcn(testingPredictors);
        
        validations(OriTest)=foldPrediction;
        validationScores(OriTest,:)=foldScores;
    end
    
    correctPredictions = (validations == labels);
    ACC=[ACC;sum(correctPredictions)/numel(labels)];                            %72.73
    
    specificity=sum(labels(labels==1)==validations(labels==1))/(sum(labels==1));%75.00
    sensitivity=sum(labels(labels==3)==validations(labels==3))/(sum(labels==3));%70.54
    
    SPE=[SPE;specificity];
    SEN=[SEN;sensitivity];
    
    C = confusionmat(labels,validations); %% confusion matrxi computation
    CC=CC+C;
    
    SSC=SSC+validationScores;
    pred50=[pred50,validations];
end
CC=CC/ItNum;
SSC=SSC./ItNum;
accl=CC(1,1)/sum(CC(1,:));
acci=CC(2,2)/sum(CC(2,:));
accm=mean(ACC);
spem=mean(SPE);
senm=mean(SEN);

pred=ones(length(labels),1);
pred(SSC(:,2)>SSC(:,1))=3;

%save(strcat('..\step06)_plot_figures\tcga_blca_proposed\','p_resnet50_linear.mat'),'labels','SSC');

pred_bladder=cell(length(pred),3);
pred_bladder(:,1)=patID;
pred_bladder(pred==1,2)={'Low'};
pred_bladder(pred==3,2)={'High'};
pred_bladder(labels==1,3)={'Low'};
pred_bladder(labels==3,3)={'High'};

FT2=table(pred_bladder(:,1),pred_bladder(:,2),pred_bladder(:,3));
FT2.Properties.VariableNames={'patient_names','preds','gt_labels'};
%writetable(FT2,'./pid_tmb_pred.xlsx','Sheet',1)






