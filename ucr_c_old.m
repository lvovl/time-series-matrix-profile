TRAIN = load('UEA_data/Coffee/Coffee_TRAIN'); 
TEST= load('UEA_data/Coffee/Coffee_TEST');

TRAIN=sortrows(TRAIN,1);
TEST=sortrows(TEST,1);

%%
subLen=25;
threshold=0.5;

numcls=unique(TRAIN(:,1));
len=length(numcls);
B=cell(len,1);
for i=1:len
    index=(TRAIN(:,1)==numcls(i));
    B{i}=TRAIN(index,:);
end

%% init diffMatrix

numRow=0;
for i=1:len-1
    for j=i+1:len
        numRow=numRow+size(B{i},1)*size(B{j},1);
    end
end

datalen=size(B{1},2)-1;
diffMatrix=zeros(numRow,datalen - subLen + 3);


%%
tic

% index=1;
% for i=1:len-1  % find group
%     for j=2:len  % find second group
%         for firstIndex=1:size(B{i},1) %data len in 1 group
%               data=B{i}(firstIndex,2:size(B{i},2));
%               [matrixProfileSelf] = V_interactiveMatrixProfile(data,data, subLen);
%             for secondIndex=1:size(B{j},1)  %data len in 2 group
%                  data1=B{j}(secondIndex,2:size(B{j},2));
%                  [matrixProfile] = V_interactiveMatrixProfile(data,data1, subLen);
%                  posDiffMatrixProfile=abs(matrixProfile-matrixProfileSelf);
%                  diffMatrix(index,:)=posDiffMatrixProfile.';
%                  index=index+1;
%             end
%         end
%     end
% end

 index=1;
for i=1:len-1  % find group  
    for firstIndex=1:size(B{i},1) %data len in 1 group
         data=B{i}(firstIndex,2:size(B{i},2));
         [matrixProfileSelf] = V_interactiveMatrixProfile(data,data, subLen);
         for j=i+1:len  % find second group
            for secondIndex=1:size(B{j},1)  %data len in 2 group
                 data1=B{j}(secondIndex,2:size(B{j},2));
                 [matrixProfile] = V_interactiveMatrixProfile(data,data1, subLen);
                 posDiffMatrixProfile=abs(matrixProfile-matrixProfileSelf);
                 tempProfile=[B{i}(firstIndex,1) firstIndex];
                 diffMatrix(index,:)=[tempProfile posDiffMatrixProfile.'];
                 index=index+1;
            end
        end
    end
end

toc
%% generate shapelet
% threshold=0.5;
%[m,n]=find(sss>threshold);

index_Class_Instance=cell(len-1,1);
for i=1:len-1
    index_Class_Instance{i}=cell(size(B{i},1),1);
end

% index=1;
% dl= size(diffMatrix,1);
% for i=1:dl
%     temps=find(diffMatrix(i,3:size(diffMatrix,2))>threshold);
%     index_Class_Instance{diffMatrix(i,1)+1}{diffMatrix(i,2)}=...
%     [index_Class_Instance{diffMatrix(i,1)+1}{diffMatrix(i,2)} temps];
% end


for i=1:size(index_Class_Instance,1)
    for j=1:size(index_Class_Instance{i},1)
         class=diffMatrix(:,1)==i-1;
         instance = diffMatrix(class,:);
         cii=instance(:,2)==j;
         pcim=instance(cii,:);
         cim=pcim(:,3:size(pcim,2));
         insnum=size(cim,1);
         cim=sum(cim);
         cim=cim/insnum;
         m=find(cim>threshold);
         index_Class_Instance{i}{j}=m;
    end
end

slen=0;
for i=1:size(index_Class_Instance,1)
    for j=1:size(index_Class_Instance{i},1)
        slen=slen+length(index_Class_Instance{i}{j});
    end
end

shapelet=cell(slen,1);
sindex=zeros(slen,1);

index=1;
for i=1:size(index_Class_Instance,1)
    tclass=TRAIN(:,1)==i-1;
    tins = TRAIN(tclass,:);
    tins=tins(:,2:size(tins,2));
    for j=1:size(index_Class_Instance{i},1)      
        for x=1:length(index_Class_Instance{i}{j})
            shapelet{index}=tins(j,index_Class_Instance{i}{j}(x):index_Class_Instance{i}{j}(x)+subLen-1);
            sindex(index)=index_Class_Instance{i}{j}(x);
            index=index+1;
        end
    end
end

% dl=size(index_Class_Instance,1);
% for i=1:dl
%     for j=1:size(index_Class_Instance{i},1)
%         index_Class_Instance{i}{j}=unique(index_Class_Instance{i}{j});
%     end
% end
%% use z-normalized euclidean distance to transform the data
D_tr=zeros(size(TRAIN,1),slen);
D_ts=zeros(size(TEST,1),slen);

for i=1:size(TRAIN,1)
    data=TRAIN(i,2:size(TRAIN,2));  
    for j=1:slen
        D_tr(i,j)=norm(data(sindex(j):sindex(j)+subLen-1)-shapelet{j});       
    end
end

for i=1:size(TEST,1)
    data=TEST(i,2:size(TEST,2));  
    for j=1:slen
        D_ts(i,j)=norm(data(sindex(j):sindex(j)+subLen-1)-shapelet{j});       
    end
end

TRAIN_class_labels=TRAIN(:,1);
TEST_class_labels=TEST(:,1);
%% svm classifier

SVMStruct = svmtrain(TRAIN_class_labels,D_tr,'-t 0 -c 100');
 [~,accu,~] = svmpredict(TEST_class_labels,D_ts,SVMStruct);
 acc = accu(1);

%% plot test
plotDiffMatrix(cim);

%% 
tic
data1=TRAIN(3,2:287);
data15=TRAIN(18,2:287); 


[matrixProfile] = V_interactiveMatrixProfile(data1,data15, subLen);


[matrixProfileSelf] =  V_interactiveMatrixProfile(data1,data1, subLen);
toc

%%
%plot minus information 
diffMatrixProfile=matrixProfile-matrixProfileSelf;
posDiffMatrixProfile=abs(diffMatrixProfile);
dataLen = length(data1);
profileLen = dataLen - subLen + 1;

figure
subplot(4,1,1)
hold on
plot(1:dataLen, data1, 'r');
plot(1:dataLen, data15, 'b');

subplot(4,1,2)
hold on
plot(1:profileLen, matrixProfile, 'r');
plot(1:profileLen, matrixProfileSelf, 'b');

subplot(4,1,3)
plot(1:profileLen, diffMatrixProfile, 'b');

subplot(4,1,4)
plot(1:profileLen, posDiffMatrixProfile, 'b');
%% plot train
figure
hold on
l = length(TRAIN(1,2:287));
plot(1:l, TRAIN(1,2:287), 'r');
plot(1:l, TRAIN(3,2:287), 'm');
plot(1:l, TRAIN(24,2:287), 'b');