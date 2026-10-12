WITH
  store_ret_agg AS (
    SELECT
      sr_item_sk,
      sr_reason_sk,
      SUM(sr_return_amt_inc_tax) AS store_return_amt,
      COUNT(*)                AS store_return_cnt
    FROM store_returns
    WHERE sr_return_quantity > 0
      AND sr_return_amt_inc_tax > 20.00
      AND sr_reason_sk IS NOT NULL
    GROUP BY sr_item_sk, sr_reason_sk
  ),
  web_ret_agg AS (
    SELECT
      wr_item_sk,
      wr_reason_sk,
      SUM(wr_return_amt_inc_tax) AS web_return_amt,
      COUNT(*)                 AS web_return_cnt
    FROM web_returns
    WHERE wr_return_quantity > 0
      AND wr_return_amt_inc_tax > 30.00
    GROUP BY wr_item_sk, wr_reason_sk
  ),
  full_ret AS (
    SELECT
      COALESCE(sra.sr_item_sk, wra.wr_item_sk)   AS item_sk,
      COALESCE(sra.sr_reason_sk, wra.wr_reason_sk) AS reason_sk,
      sra.store_return_amt,
      sra.store_return_cnt,
      wra.web_return_amt,
      wra.web_return_cnt
    FROM store_ret_agg sra
    FULL OUTER JOIN web_ret_agg wra
      ON sra.sr_item_sk = wra.wr_item_sk
     AND sra.sr_reason_sk = wra.wr_reason_sk
  ),
  base AS (
    SELECT
      i.i_category,
      i.i_brand,
      r.r_reason_desc,
      SUM(COALESCE(fr.store_return_amt, 0)) AS total_store_return_amt,
      SUM(COALESCE(fr.web_return_amt, 0))   AS total_web_return_amt,
      SUM(COALESCE(ws.ws_ext_sales_price, 0)) AS total_sales_price,
      AVG(ws.ws_ext_discount_amt)           AS avg_discount_amt,
      COUNT(DISTINCT ws.ws_order_number)    AS distinct_sales_orders,
      ROW_NUMBER() OVER (PARTITION BY i.i_category ORDER BY SUM(COALESCE(fr.store_return_amt, 0)) DESC) AS rnk
    FROM full_ret fr
    JOIN item i
      ON i.i_item_sk = fr.item_sk
    JOIN reason r
      ON r.r_reason_sk = fr.reason_sk
    LEFT JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN warehouse w
      ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN customer_demographics cd
      ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE i.i_current_price BETWEEN 20 AND 400
      AND cd.cd_credit_rating = 'Good'
      AND w.w_gmt_offset = -5.00
      AND i.i_item_id NOT IN (
            SELECT i2.i_item_id FROM item i2 WHERE i2.i_current_price > 1000
        )
    GROUP BY i.i_category, i.i_brand, r.r_reason_desc
    HAVING SUM(COALESCE(fr.store_return_amt, 0)) > 50
  )
SELECT
  i_category,
  i_brand,
  r_reason_desc,
  total_store_return_amt,
  total_web_return_amt,
  total_sales_price,
  avg_discount_amt,
  distinct_sales_orders,
  rnk
FROM base
WHERE rnk <= 5
ORDER BY i_category, rnk
LIMIT 100
