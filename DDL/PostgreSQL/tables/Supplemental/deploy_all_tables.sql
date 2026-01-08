

/*
SELECT 
  schemaname,
  tablename,
  tableowner
FROM pg_tables
WHERE schemaname = 'mon'
  AND (tablename LIKE 'striim_mon_%'
       OR tablename IN ('applicationalertthresholds', 'tablealertthresholds'))
ORDER BY tablename;
*/

/*
SELECT 
  c.relname as table_name,
  d.description
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_description d ON d.objoid = c.oid AND d.objsubid = 0
WHERE n.nspname = 'mon'
  AND c.relkind = 'r'
  AND (c.relname LIKE 'striim_mon_%'
       OR c.relname IN ('applicationalertthresholds', 'tablealertthresholds'))
ORDER BY c.relname;
*/

/*
SELECT 
  table_name,
  COUNT(*) as column_count
FROM information_schema.columns
WHERE table_schema = 'mon'
  AND (table_name LIKE 'striim_mon_%'
       OR table_name IN ('applicationalertthresholds', 'tablealertthresholds'))
GROUP BY table_name
ORDER BY table_name;
*/

SELECT 'PostgreSQL table deployment script ready. Run individual table files in the order specified above.' as status;

