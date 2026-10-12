WITH
  -- Aggregate store returns per item (fact table)
  store_agg AS (
    SELECT
      sr.sr_item_sk,
      SUM(sr.sr_return_amt) AS store_return_amt,
      SUM(sr.sr_return_quantity) AS store_return_qty,
      sr.sr_reason_sk,
      sr.sr_customer_sk,
      sr.sr_cdemo_sk,
      sr.sr_hdemo_sk
    FROM store_returns sr
    WHERE sr.sr_return_tax > 5                     -- filter 1
      AND sr.sr_return_quantity > 0               -- filter 2
      AND sr.sr_store_credit < 30                 -- filter 3
    GROUP BY sr.sr_item_sk,
             sr.sr_reason_sk,
             sr.sr_customer_sk,
             sr.sr_cdemo_sk,
             sr.sr_hdemo_sk
  ),

  -- Aggregate web returns per item (fact table)
  web_agg AS (
    SELECT
      wr.wr_item_sk,
      SUM(wr.wr_return_amt) AS web_return_amt,
      SUM(wr.wr_return_quantity) AS web_return_qty,
      wr.wr_reason_sk,
      wr.wr_refunded_customer_sk,
      wr.wr_refunded_cdemo_sk,
      wr.wr_refunded_hdemo_sk
    FROM web_returns wr
    WHERE wr.wr_return_tax > 5                    -- filter 4
      AND wr.wr_return_quantity > 0               -- filter 5
      AND wr.wr_account_credit < 30               -- filter 6
    GROUP BY wr.wr_item_sk,
             wr.wr_reason_sk,
             wr.wr_refunded_customer_sk,
             wr.wr_refunded_cdemo_sk,
             wr.wr_refunded_hdemo_sk
  ),

  -- Customers that appear in BOTH store and web returns and are preferred
  intersect_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
    INTERSECT
    SELECT c.c_customer_sk
    FROM customer c
    JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE c.c_preferred_cust_flag = 'Y'
  ),

  -- Combine dimensions and the two aggregated facts
  joined AS (
    SELECT
      i.i_item_id,
      i.i_category,
      i.i_wholesale_cost,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cd.cd_gender,
      hd.hd_vehicle_count,
      r.r_reason_desc,
      sa.store_return_amt,
      wa.web_return_amt,
      CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_label,
      (COALESCE(sa.store_return_amt, 0) + COALESCE(wa.web_return_amt, 0)) AS total_return_amt,
      c.c_customer_sk
    FROM item i
    RIGHT OUTER JOIN store_agg sa
      ON i.i_item_sk = sa.sr_item_sk                       -- fact → dimension (right outer join)
    LEFT JOIN web_agg wa
      ON i.i_item_sk = wa.wr_item_sk
    LEFT JOIN reason r
      ON COALESCE(sa.sr_reason_sk, wa.wr_reason_sk) = r.r_reason_sk
    LEFT JOIN customer_demographics cd
      ON COALESCE(sa.sr_cdemo_sk, wa.wr_refunded_cdemo_sk) = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
      ON COALESCE(sa.sr_hdemo_sk, wa.wr_refunded_hdemo_sk) = hd.hd_demo_sk
    LEFT JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN customer c
      ON COALESCE(sa.sr_customer_sk, wa.wr_refunded_customer_sk) = c.c_customer_sk
    WHERE i.i_wholesale_cost BETWEEN 2 AND 50                -- filter 7
      AND ib.ib_upper_bound <= 80000                        -- filter 8
      AND hd.hd_vehicle_count >= 0                         -- filter 9
      AND r.r_reason_desc LIKE '%defect%'                  -- filter 10
  )
SELECT *
FROM joined
WHERE c_customer_sk IN (SELECT c_customer_sk FROM intersect_customers)
ORDER BY total_return_amt DESC
LIMIT 100
