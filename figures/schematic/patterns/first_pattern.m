f	= '/home/alex/studies/dcclassify/figures/schematic/patterns/pat_01.bmp';

im		= imread(f);
[h,w]	= size(im);

imBlue	= ind2rgb(im,MakeLUT([0 0 0.5; 1 1 1],255));

fo	= PathAddSuffix(f,'_blue');

imwrite(imBlue,fo);
