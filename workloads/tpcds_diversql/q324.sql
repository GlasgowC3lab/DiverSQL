WITH base_agg AS (
   SELECT
      d.d_year,
      w.w_city,
      cd.cd_gender,
      SUM(inv.inv_quantity_on_hand) AS total_qty,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(DISTINCT sr.sr_ticket_number) AS return_txn_cnt
   FROM store_returns sr
   JOIN date_dim d
     ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN customer_demographics cd
     ON sr.sr_cdemo_sk = cd.cd_demo_sk
   JOIN inventory inv
     ON inv.inv_date_sk = d.d_date_sk
   JOIN warehouse w
     ON inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE d.d_year BETWEEN 1999 AND 2001
     AND w.w_city IN ('Liberty', 'Shiloh')
     AND cd.cd_dep_employed_count >= 1
     AND cd.cd_dep_college_count <= 5
     AND inv.inv_quantity_on_hand > 0
     AND sr.sr_return_amt > 0
   GROUP BY d.d_year, w.w_city, cd.cd_gender
),
avg_agg AS (
   SELECT
      d_year,
      w_city,
      cd_gender,
      total_qty,
      total_return_amt,
      return_txn_cnt,
      total_return_amt / NULLIF(total_qty, 0) AS avg_return_per_qty
   FROM base_agg
   WHERE total_qty > 1000
),
unioned AS (
   SELECT
      d_year,
      w_city,
      cd_gender,
      total_qty,
      total_return_amt,
      avg_return_per_qty,
      ROW_NUMBER() OVER (PARTITION BY w_city ORDER BY total_return_amt DESC) AS rn
   FROM avg_agg
   UNION
   SELECT
      d_year,
      w_city,
      cd_gender,
      total_qty,
      total_return_amt,
      avg_return_per_qty,
      ROW_NUMBER() OVER (PARTITION BY w_city ORDER BY total_return_amt DESC) AS rn
   FROM avg_agg
)
SELECT
   d_year,
   w_city,
   cd_gender,
   total_qty,
   total_return_amt,
   avg_return_per_qty,
   rn
FROM unioned
ORDER BY rn, total_return_amt DESC
LIMIT 100
