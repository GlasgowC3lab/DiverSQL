WITH agg AS (
   SELECT
     s.s_store_name AS store_name,
     i.i_category AS category,
     CONCAT(s.s_store_name, ' - ', i.i_category) AS store_category_label,
     SUM(sr.sr_return_amt) AS total_return_amt,
     COUNT(*) AS return_cnt,
     MIN(REGEXP_EXTRACT(r.r_reason_desc, '(\\w+)', 1)) AS sample_reason_word,
     SUM(CASE WHEN REGEXP_LIKE(r.r_reason_desc, '(?i)damaged') THEN 1 ELSE 0 END) AS damaged_cnt
   FROM store_returns sr
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   JOIN item i ON sr.sr_item_sk = i.i_item_sk
   JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
   JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
   WHERE s.s_store_name LIKE '%Market%'
     AND REGEXP_LIKE(i.i_item_desc, '(?i)organic')
   GROUP BY s.s_store_name, i.i_category
)
SELECT
   store_name,
   category,
   store_category_label,
   total_return_amt,
   return_cnt,
   sample_reason_word,
   damaged_cnt
FROM (
   SELECT
     store_name,
     category,
     store_category_label,
     total_return_amt,
     return_cnt,
     sample_reason_word,
     damaged_cnt,
     ROW_NUMBER() OVER (PARTITION BY store_name ORDER BY total_return_amt DESC) AS rn
   FROM agg
) ranked
WHERE rn <= 5
ORDER BY store_name, rn
LIMIT 100
