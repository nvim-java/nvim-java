-- To update JDTLS version map:
-- 1. Visit https://download.eclipse.org/jdtls/milestones/
-- 2. Click on version link in 'Directory Contents' section
-- 3. Find file like: jdt-language-server-X.Y.Z-YYYYMMDDHHSS.tar.gz
-- 4. Extract package version (X.Y.Z) and timestamp (YYYYMMDDHHSS)
-- 5. Add entry: ['X.Y.Z'] = 'YYYYMMDDHHSS'
-- Example: jdt-language-server-1.43.0-202412191447.tar.gz
--          → ['1.43.0'] = '202412191447'
return {
	['1.43.0'] = '202412191447',
	['1.44.0'] = '202501221502',
	['1.45.0'] = '202502271238',
	['1.46.0'] = '202503271314',
	['1.46.1'] = '202504011455',
	['1.47.0'] = '202505151856',
	['1.48.0'] = '202506271502',
	['1.49.0'] = '202507311558',
	['1.50.0'] = '202509041425',
	['1.51.0'] = '202510022025',
	['1.52.0'] = '202510301627',
	['1.53.0'] = '202511192211',
}
