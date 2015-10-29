strDirDonchin	= '/home/alex/studies/dcclassify/data/donchin';

cPathInfo	= FindFiles(strDirDonchin,'^\d\d\w\w\w\d\d\w{2,3}\.mat');

ifo	= cellfun(@load,cPathInfo);

bGender	= arrayfun(@(s) strcmp(s.subject.gender,'male'),ifo);
age		= arrayfun(@(s) s.subject.age,ifo);