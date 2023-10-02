clear all;
%% Read the data
x=csvread('batchnormAFhrv.csv',3,3,[3,3,512,102]);

%% Remove inf; replace with NAN

colmax=100;
rowmax=510;

for col=1:colmax
    for row=1:rowmax
        if isfinite(x(row,col))
        y(row,col)=x(row,col);
        else
        y(row,col)=nan();  
        end
    end
end

%% Remove NAN; replace with column means
colMean = nanmean(y);
[rownan,colnan] = find(isnan(y));
y(isnan(y)) = colMean(colnan);

%% Look for correlations
[rho,pval]=partialcorr(y);

%% make pretty the Rho Table
rho =array2table(rho, ...
    'VariableNames', ...
    {'max1',	'min2',	'mean3',	'median4',	'SDNN5',	'SDANN6',	'NNx7',	'pNNx8',	'RMSSD9',	'SDNNi10',	'meanHR11',	'sdHR12',	'HRVTi13',	'TINN14',	'aVLF15',	'aLF16',	'aHF17',	'aTotal18',	'pVLF19',	'pLF20',	'pHF21',	'nLF22',	'nHF23',	'LFHF24',	'peakVLF25',	'peakLF26',	'peakHF27',	'aVLF28',	'aLF29',	'aHF30',	'aTotal31',	'pVLF32',	'pLF33',	'pHF34',	'nLF35',	'nHF36',	'LFHF37',	'peakVLF38',	'peakLF39',	'peakHF40',	'aVLF41',	'aLF42',	'aHF43',	'aTotal44',	'pVLF45',	'pLF46',	'pHF47',	'nLF48',	'nHF49',	'LFHF50',	'peakVLF51',	'peakLF52',	'peakHF53',	'SD154',	'SD255',	'sampen56',	'alpha57',	'alpha158',	'alpha259',	'aVLF60',	'aLF61',	'aHF62',	'aTotal63',	'pVLF64',	'pLF65',	'pHF66',	'nLF67',	'nHF68',	'LFHF69',	'peakVLF70',	'peakLF71',	'peakHF72',	'rLFHF73',	'aVLF74',	'aLF75',	'aHF76',	'aTotal77',	'pVLF78',	'pLF79',	'pHF80',	'nLF81',	'nHF82',	'LFHF83',	'peakVLF84',	'peakLF85',	'peakHF86',	'rLFHF87',	'aVLF88',	'aLF89',	'aHF90',	'aTotal91',	'pVLF92',	'pLF93',	'pHF94',	'nLF95',	'nHF96',	'LFHF97',	'peakVLF98',	'peakLF99',	'peakHF100'}, ...
    'RowNames',...
    {'max1',	'min2',	'mean3',	'median4',	'SDNN5',	'SDANN6',	'NNx7',	'pNNx8',	'RMSSD9',	'SDNNi10',	'meanHR11',	'sdHR12',	'HRVTi13',	'TINN14',	'aVLF15',	'aLF16',	'aHF17',	'aTotal18',	'pVLF19',	'pLF20',	'pHF21',	'nLF22',	'nHF23',	'LFHF24',	'peakVLF25',	'peakLF26',	'peakHF27',	'aVLF28',	'aLF29',	'aHF30',	'aTotal31',	'pVLF32',	'pLF33',	'pHF34',	'nLF35',	'nHF36',	'LFHF37',	'peakVLF38',	'peakLF39',	'peakHF40',	'aVLF41',	'aLF42',	'aHF43',	'aTotal44',	'pVLF45',	'pLF46',	'pHF47',	'nLF48',	'nHF49',	'LFHF50',	'peakVLF51',	'peakLF52',	'peakHF53',	'SD154',	'SD255',	'sampen56',	'alpha57',	'alpha158',	'alpha259',	'aVLF60',	'aLF61',	'aHF62',	'aTotal63',	'pVLF64',	'pLF65',	'pHF66',	'nLF67',	'nHF68',	'LFHF69',	'peakVLF70',	'peakLF71',	'peakHF72',	'rLFHF73',	'aVLF74',	'aLF75',	'aHF76',	'aTotal77',	'pVLF78',	'pLF79',	'pHF80',	'nLF81',	'nHF82',	'LFHF83',	'peakVLF84',	'peakLF85',	'peakHF86',	'rLFHF87',	'aVLF88',	'aLF89',	'aHF90',	'aTotal91',	'pVLF92',	'pLF93',	'pHF94',	'nLF95',	'nHF96',	'LFHF97',	'peakVLF98',	'peakLF99',	'peakHF100'});
disp(rho);
writetable(rho,'correvals.csv','writeRowNames',true);
pval =array2table(pval, ...
    'VariableNames', ...
    {'max1',	'min2',	'mean3',	'median4',	'SDNN5',	'SDANN6',	'NNx7',	'pNNx8',	'RMSSD9',	'SDNNi10',	'meanHR11',	'sdHR12',	'HRVTi13',	'TINN14',	'aVLF15',	'aLF16',	'aHF17',	'aTotal18',	'pVLF19',	'pLF20',	'pHF21',	'nLF22',	'nHF23',	'LFHF24',	'peakVLF25',	'peakLF26',	'peakHF27',	'aVLF28',	'aLF29',	'aHF30',	'aTotal31',	'pVLF32',	'pLF33',	'pHF34',	'nLF35',	'nHF36',	'LFHF37',	'peakVLF38',	'peakLF39',	'peakHF40',	'aVLF41',	'aLF42',	'aHF43',	'aTotal44',	'pVLF45',	'pLF46',	'pHF47',	'nLF48',	'nHF49',	'LFHF50',	'peakVLF51',	'peakLF52',	'peakHF53',	'SD154',	'SD255',	'sampen56',	'alpha57',	'alpha158',	'alpha259',	'aVLF60',	'aLF61',	'aHF62',	'aTotal63',	'pVLF64',	'pLF65',	'pHF66',	'nLF67',	'nHF68',	'LFHF69',	'peakVLF70',	'peakLF71',	'peakHF72',	'rLFHF73',	'aVLF74',	'aLF75',	'aHF76',	'aTotal77',	'pVLF78',	'pLF79',	'pHF80',	'nLF81',	'nHF82',	'LFHF83',	'peakVLF84',	'peakLF85',	'peakHF86',	'rLFHF87',	'aVLF88',	'aLF89',	'aHF90',	'aTotal91',	'pVLF92',	'pLF93',	'pHF94',	'nLF95',	'nHF96',	'LFHF97',	'peakVLF98',	'peakLF99',	'peakHF100'}, ...
    'RowNames',...
    {'max1',	'min2',	'mean3',	'median4',	'SDNN5',	'SDANN6',	'NNx7',	'pNNx8',	'RMSSD9',	'SDNNi10',	'meanHR11',	'sdHR12',	'HRVTi13',	'TINN14',	'aVLF15',	'aLF16',	'aHF17',	'aTotal18',	'pVLF19',	'pLF20',	'pHF21',	'nLF22',	'nHF23',	'LFHF24',	'peakVLF25',	'peakLF26',	'peakHF27',	'aVLF28',	'aLF29',	'aHF30',	'aTotal31',	'pVLF32',	'pLF33',	'pHF34',	'nLF35',	'nHF36',	'LFHF37',	'peakVLF38',	'peakLF39',	'peakHF40',	'aVLF41',	'aLF42',	'aHF43',	'aTotal44',	'pVLF45',	'pLF46',	'pHF47',	'nLF48',	'nHF49',	'LFHF50',	'peakVLF51',	'peakLF52',	'peakHF53',	'SD154',	'SD255',	'sampen56',	'alpha57',	'alpha158',	'alpha259',	'aVLF60',	'aLF61',	'aHF62',	'aTotal63',	'pVLF64',	'pLF65',	'pHF66',	'nLF67',	'nHF68',	'LFHF69',	'peakVLF70',	'peakLF71',	'peakHF72',	'rLFHF73',	'aVLF74',	'aLF75',	'aHF76',	'aTotal77',	'pVLF78',	'pLF79',	'pHF80',	'nLF81',	'nHF82',	'LFHF83',	'peakVLF84',	'peakLF85',	'peakHF86',	'rLFHF87',	'aVLF88',	'aLF89',	'aHF90',	'aTotal91',	'pVLF92',	'pLF93',	'pHF94',	'nLF95',	'nHF96',	'LFHF97',	'peakVLF98',	'peakLF99',	'peakHF100'});
disp(pval);
writetable(pval,'pvals.csv','writeRowNames',true);
