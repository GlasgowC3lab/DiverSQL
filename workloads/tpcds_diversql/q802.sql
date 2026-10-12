WITH sr_sample AS (
   SELECT *
   FROM store_returns TABLESAMPLE BERNOULLI (10)
),
sub1 AS (
   SELECT s.s_store_id,
          d.d_year,
          d.d_month_seq,
          SUM(sr.sr_return_amt_inc_tax) AS total_amt_inc_tax
   FROM sr_sample sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   WHERE sr.sr_return_amt_inc_tax > 200
   GROUP BY s.s_store_id, d.d_year, d.d_month_seq
),
sub2 AS (
   SELECT s.s_store_id,
          d.d_year,
          d.d_month_seq,
          SUM(sr.sr_return_amt_inc_tax) AS total_amt_inc_tax
   FROM sr_sample sr
   JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN store s ON sr.sr_store_sk = s.s_store_sk
   WHERE sr.sr_reversed_charge > 0
   GROUP BY s.s_store_id, d.d_year, d.d_month_seq
),
intersected AS (
   SELECT s_store_id, d_year, d_month_seq, total_amt_inc_tax
   FROM sub1
   INTERSECT
   SELECT s_store_id, d_year, d_month_seq, total_amt_inc_tax
   FROM sub2
)
SELECT i.s_store_id,
       i.d_year,
       i.d_month_seq,
       i.total_amt_inc_tax,
       s.s_store_name
FROM intersected i
JOIN store s ON i.s_store_id = s.s_store_id
WHERE EXISTS (
      SELECT 1
      FROM store_returns sr2
      JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
      WHERE sr2.sr_store_sk = s.s_store_sk
        AND d2.d_year = i.d_year
        AND d2.d_month_seq = i.d_month_seq
        AND sr2.sr_fee > 0
)
ORDER BY i.total_amt_inc_tax DESC, i.s_store_id
LIMIT 100
