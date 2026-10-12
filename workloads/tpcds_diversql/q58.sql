WITH
  sales_agg AS (
    SELECT
      cs_item_sk,
      cs_sold_date_sk,
      cs_sold_time_sk,
      cs_call_center_sk,
      cs_bill_cdemo_sk,
      cs_bill_hdemo_sk,
      SUM(cs_net_paid)   AS total_net_paid,
      SUM(cs_quantity)   AS total_quantity
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_sold_date_sk BETWEEN 2451900 AND 2452000
    GROUP BY cs_item_sk, cs_sold_date_sk, cs_sold_time_sk, cs_call_center_sk, cs_bill_cdemo_sk, cs_bill_hdemo_sk
  ),
  returns_agg AS (
    SELECT
      cr_item_sk,
      cr_returned_date_sk,
      cr_reason_sk,
      SUM(cr_return_amount) AS total_return_amount,
      SUM(cr_return_quantity) AS total_return_qty
    FROM catalog_returns
    WHERE cr_returned_date_sk BETWEEN 2451900 AND 2452000
    GROUP BY cr_item_sk, cr_returned_date_sk, cr_reason_sk
  ),
  store_ret_agg AS (
    SELECT
      sr_item_sk,
      sr_returned_date_sk,
      sr_reason_sk,
      SUM(sr_return_amt)      AS total_store_return_amt,
      SUM(sr_return_quantity) AS total_store_return_qty
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2451900 AND 2452000
    GROUP BY sr_item_sk, sr_returned_date_sk, sr_reason_sk
  )
SELECT
  d.d_date                               AS sale_date,
  i.i_item_id,
  i.i_product_name,
  cc.cc_name                             AS call_center,
  cd.cd_gender,
  hd.hd_buy_potential,
  SUM(sa.total_net_paid)                AS sum_sales_net,
  SUM(ra.total_return_amount)           AS sum_return_amount,
  SUM(sra.total_store_return_amt)       AS sum_store_return_amt,
  SUM(sa.total_net_paid) -
    SUM(ra.total_return_amount) -
    SUM(sra.total_store_return_amt)      AS net_revenue,
  AVG(sa.total_quantity)                AS avg_quantity_sold
FROM sales_agg sa
JOIN returns_agg ra
  ON ra.cr_item_sk = sa.cs_item_sk
 AND ra.cr_returned_date_sk = sa.cs_sold_date_sk
JOIN store_ret_agg sra
  ON sra.sr_item_sk = sa.cs_item_sk
 AND sra.sr_returned_date_sk = sa.cs_sold_date_sk
JOIN item i
  ON i.i_item_sk = sa.cs_item_sk
JOIN date_dim d
  ON d.d_date_sk = sa.cs_sold_date_sk
JOIN call_center cc
  ON cc.cc_call_center_sk = sa.cs_call_center_sk
JOIN customer_demographics cd
  ON cd.cd_demo_sk = sa.cs_bill_cdemo_sk
JOIN household_demographics hd
  ON hd.hd_demo_sk = sa.cs_bill_hdemo_sk
JOIN reason r_ret
  ON r_ret.r_reason_sk = ra.cr_reason_sk
JOIN reason r_store
  ON r_store.r_reason_sk = sra.sr_reason_sk
JOIN time_dim t
  ON t.t_time_sk = sa.cs_sold_time_sk
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#12'
  AND cc.cc_state = 'CA'
  AND hd.hd_buy_potential = '>10000'
  AND sra.sr_reason_sk IN (
        SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%Damaged%'
      )
GROUP BY d.d_date,
         i.i_item_id,
         i.i_product_name,
         cc.cc_name,
         cd.cd_gender,
         hd.hd_buy_potential
HAVING SUM(sa.total_net_paid) > 10000
ORDER BY net_revenue DESC
LIMIT 100
