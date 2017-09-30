clear all;
%�㷨������ʼ����N��ʾ2Dŷʽ����ͼ���У�ÿ�����ص㽨���ı�������������R��ʾŷʽ���뷧ֵ��ÿ������
%
N=20;
R=25;
R1=25;
MIN=3;
Q=5;
lambda=0.25;
xyloObj  = VideoReader('office.avi');
nFrames = xyloObj.NumberOfFrames;
vidHeight = xyloObj.Height;
vidWidth = xyloObj.Width;
mov(1:nFrames) = ...
    struct('cdata', zeros(vidHeight, vidWidth, 3, 'uint8'),...
    'colormap', []);
% Preallocate movie structure.���ڴ�ŻҶ���Ƶ֡
image(1:nFrames) = ...
    struct('cdata', zeros(vidHeight, vidWidth, 1, 'uint8'),...
    'colormap', []);
for k = 1 : nFrames
    mov(k).cdata = read(xyloObj, k);
    image(k).cdata = rgb2gray(mov(k).cdata );
end
samples=zeros(vidHeight, vidWidth, N, 'uint8');
segMap = zeros(vidHeight, vidWidth, 1, 'uint8');
image0 = zeros(vidHeight, vidWidth, 'uint8');
blink = zeros(vidHeight, vidWidth, 'uint8');
image_blink = zeros(vidHeight, vidWidth, nFrames ,'uint8');
foregroundMatchCount = zeros(vidHeight, vidWidth, 1, 'uint8');
foregroundGoals=zeros(vidHeight, vidWidth, 3);%��¼ǰ��Ŀ���RGBֵ
background=0;
foreground=255;
%��ȡ����
for x = 1 : vidHeight
    for y = 1 : vidWidth
        for k = 1 : nFrames
            n(k)=image(k).cdata(x,y);
        end
        image0(x,y) = median (double(n));
    end
end
%��ʼ��������
for k = 1 : N
    for x=1:vidHeight
        for y=1:vidWidth
            xNG=getRandomNeighbrXCoordinate( x,vidHeight);
            yNG=getRandomNeighbrYCoordinate( y,vidWidth);
            samples(x,y,k)=image0(x,y);
%             samples(x,y,k)=image(1).cdata(xNG,yNG);
        end
    end
end

for k = 1: nFrames
    for x=1:vidHeight
        for y=1:vidWidth
            count=0;
            index=1;
            dist=0;
            while((count<MIN)&&(index<=N))
                dist=abs(double(mov(k).cdata(x,y))-double(samples(x,y,index)));
                
                %�����˸��
                if k>2
                    if(image_blink(x,y,k)==image_blink(x,y,k-1))
                        blink(x,y)=blink(x,y)-1;
                    else
                        blink(x,y)=blink(x,y)+15;
                    end
                end
                if(blink(x,y)>30)
                    if(R<40)
                        R=R1*(1+lambda);
                    end
                else
                    if(R>20)
                        R=R1*(1-lambda);
                    end
                end
                
                if(dist<R)
                    count=count+1;
                end
                index=index+1;
            end
            if(count>=MIN)
                foregroundMatchCount(x,y)=0;
                segMap(x,y)=background;
                foregroundGoals(x,y,:)=0;
                rand=randi([1 Q],1,1);
                if(rand==1)
                    rand=randi([1 N],1,1);
                    samples(x,y,rand)=image(k).cdata(x,y);
                end
                rand=randi([1 Q],1,1);
                if(rand==1)
                    xNG=getRandomNeighbrXCoordinate( x,vidHeight);
                    yNG=getRandomNeighbrYCoordinate( y,vidWidth);
                    rand=randi([1 N],1,1);
                    samples(xNG,yNG,rand)=image(k).cdata(x,y);
                end
            else
                %��Ӱ���
                Hnum=10;Lnum=5;Tb1=3;Tb2=1;Tb3=0.5;Bth=4;Tblve=0;
                k_neighborhood=[struct('x',-1,'y',-1) struct('x',-1,'y',0) struct('x',-1,'y',1) struct('x',0,'y',-1)];
                for i=1:4
                    if(x+k_neighborhood(i).x<=0 || y+k_neighborhood(i).y<=0 || y+k_neighborhood(i).y>vidWidth)
                        continue;
                    end
                    count=0;
                    index=1;
                    dist=0;
                    while((count<MIN)&&(index<=N))
                        dist=abs(double(mov(k).cdata(x,y))-double(samples(x+k_neighborhood(i).x,y+k_neighborhood(i).y,index)));
                        if(dist<R)
                            count=count+1;
                        end
                        index=index+1;
                    end
                    if(count>=0 && count<=Lnum)
                        Tblve=Tblve+Tb3;
                    end
                    if(count>=Lnum && count<Hnum)
                        Tblve=Tblve+Tb2;
                    end
                    if(count>=Hnum)
                        Tblve=Tblve+Tb1;
                    end
                end
                if(Tblve>=Bth)%��ǰ��Ϊ��Ӱ��
                    foregroundMatchCount(x,y)=0;
                    segMap(x,y)=background;
                    foregroundGoals(x,y,:)=0;
                    for i=1:N
                        rand=randi([1 4],1,1);
                        while(x+k_neighborhood(rand).x<=0 || y+k_neighborhood(rand).y<=0 || y+k_neighborhood(rand).y>vidWidth)
                            rand=randi([1 4],1,1);
                        end
                        samples(x,y,i)=samples(x+k_neighborhood(rand).x,y+k_neighborhood(rand).y,randi([1 N],1,1));
                    end
                else
                    %����������������µ����
                    area_24=[struct('x',-2,'y',-2) struct('x',-2,'y',-1) struct('x',-2,'y',0) struct('x',-2,'y',1) struct('x',-2,'y',2)...
                        struct('x',-1,'y',-2) struct('x',-1,'y',-1) struct('x',-1,'y',0) struct('x',-1,'y',1) struct('x',-1,'y',2)...
                        struct('x',0,'y',-2)  struct('x',0,'y',-1)  struct('x',0,'y',1)  struct('x',0,'y',2)...
                        struct('x',1,'y',-2) struct('x',1,'y',-1) struct('x',1,'y',0) struct('x',1,'y',1) struct('x',1,'y',2)...
                        struct('x',2,'y',-2) struct('x',2,'y',-1) struct('x',2,'y',0) struct('x',2,'y',1) struct('x',2,'y',2)];
                    temp_N_th=0;N_th=1;
                    for i=1:24
                        if(x+area_24(i).x>=1 && x+area_24(i).x<=vidHeight && y+area_24(i).y>=1 && y+area_24(i).y<=vidWidth && segMap(x+area_24(i).x,y+area_24(i).y)==foreground)
                            temp_N_th=temp_N_th+1;
                        end
                    end
                    if(temp_N_th>N_th || k==1)%��ʵǰ�����ص�
                        foregroundMatchCount(x,y)= foregroundMatchCount(x,y)+1;
                        segMap(x,y)=foreground;
                        foregroundGoals(x,y,:)=mov(k).cdata(x,y,:);
                        if(foregroundMatchCount(x,y)>nFrames*0.3)
                            foregroundMatchCount(x,y)=0;
                            segMap(x,y)=background;
                            foregroundGoals(x,y,:)=0;
                            %�������±���ģ�͵������������㣬��ֹ��Ӱ���ٴγ���
                            for i=1:2
                                rand=randi([1 N],1,1);
                                samples(x,y,rand)=image(k).cdata(x,y);
                            end
                        end
                    else
                        foregroundMatchCount(x,y)=0;
                        segMap(x,y)=background;
                        foregroundGoals(x,y,:)=0;
                        for i=1:2
                            rand=randi([1 N],1,1);
                            samples(x,y,rand)=image(k).cdata(x,y);
                        end
                    end
                end
            end
        end
    end
    
    %����С�ն�
    L = bwlabel(segMap,8);
    max_L=max(max(L));
    for s = 1:max_L
        [m,n]=find(L==s);
        r=length(m);
        if r<20
            for i=1:r
                L(m(i),n(i))=0;
                foregroundGoals(m(i),n(i),:)=0;
            end
        else
            for j=1:r
                L(m(j),n(j))=255;
            end
        end
    end
    %��̬ѧ��ն�
    se = strel('disk',1);
    L_new = imdilate (L,se);
     
    figure(2);
    clf;
    subplot(1,3,1),imshow(mov(k).cdata);
    subplot(1,3,2),imshow(uint8(L_new));
%     subplot(1,3,2),imshow(uint8(segMap));
    subplot(1,3,3),imshow(uint8(foregroundGoals));
    %��Ƶ����ͼ��
    imwrite(L_new,['.\figure\ǰ��',num2str(k),'(�Ҷ�).jpg']);
    imwrite(mov(k).cdata,['.\figure\ԭʼ֡',num2str(k),'.jpg']);
%     imwrite(segMap,['.\figure\ǰ��',num2str(k),'(�Ҷ�).jpg']);
%     imwrite(uint8(foregroundGoals),['.\figure\ǰ��',num2str(k),'(RGB).jpg']);
end