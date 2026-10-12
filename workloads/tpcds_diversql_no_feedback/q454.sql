WITH agg AS (
   SELECT
      r.r_reason_sk,
      r.r_reason_id,
      r.r_reason_desc,
      COUNT(sr.sr_ticket_number) AS return_cnt,
      COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amt,
      COALESCE(AVG(sr.sr_return_amt), 0) AS avg_return_amt
   FROM reason r
   RIGHT OUTER JOIN store_returns sr
      ON sr.sr_reason_sk = r.r_reason_sk
      AND sr.sr_return_amt > 100
   WHERE r.r_reason_id LIKE 'AAAA%'
     AND regexp_like(r.r_reason_desc, '(product|size)')
   GROUP BY r.r_reason_sk, r.r_reason_id, r.r_reason_desc
)
SELECT
   r_reason_id,
   r_reason_desc,
   regexp_extract(r_reason_desc, '(product|size)', 1) AS matched_word,
   CONCAT(r_reason_id, '-', r_reason_desc) AS reason_key,
   return_cnt,
   total_return_amt,
   avg_return_amt,
   SUBSTRING(r_reason_desc FROM 1 FOR 15) AS short_desc
FROM agg
ORDER BY total_return_amt DESC
LIMIT 100
