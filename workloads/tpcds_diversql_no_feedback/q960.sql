WITH cat_agg AS (
    SELECT
        cr_refunded_customer_sk AS cust_sk,
        SUM(cr_refunded_cash) AS total_refunded_cash,
        SUM(cr_net_loss) AS total_cat_net_loss,
        COUNT(*) AS cat_return_cnt
    FROM catalog_returns
    WHERE cr_refunded_cash > 100
      AND cr_returned_date_sk BETWEEN 2450000 AND 2459999
      AND cr_return_quantity >= 1
    GROUP BY cr_refunded_customer_sk
),
store_agg AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_amt) AS total_store_return_amount,
        SUM(sr_net_loss) AS total_store_net_loss,
        COUNT(*) AS store_return_cnt,
        MAX(sr_return_tax) AS max_return_tax
    FROM store_returns
    WHERE sr_return_tax > 5
      AND sr_return_ship_cost < 2000
      AND sr_return_quantity >= 1
      AND sr_returned_date_sk BETWEEN 2450000 AND 2459999
    GROUP BY sr_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_birth_day,
    c.c_current_hdemo_sk,
    ca.total_refunded_cash,
    ca.total_cat_net_loss,
    sa.total_store_return_amount,
    sa.total_store_net_loss,
    ROW_NUMBER() OVER (PARTITION BY c.c_current_hdemo_sk ORDER BY (ca.total_cat_net_loss + sa.total_store_net_loss) DESC) AS rn_by_hdemo,
    RANK() OVER (ORDER BY (ca.total_cat_net_loss + sa.total_store_net_loss) DESC) AS overall_rank,
    CASE
        WHEN (ca.total_cat_net_loss + sa.total_store_net_loss) > 5000 THEN 'High Loss'
        WHEN (ca.total_cat_net_loss + sa.total_store_net_loss) BETWEEN 1000 AND 5000 THEN 'Medium Loss'
        ELSE 'Low Loss'
    END AS loss_category
FROM cat_agg ca
JOIN customer c
    ON ca.cust_sk = c.c_customer_sk
JOIN store_agg sa
    ON sa.sr_customer_sk = c.c_customer_sk
WHERE c.c_birth_day BETWEEN 1 AND 15
  AND c.c_current_hdemo_sk IN (
        SELECT DISTINCT cr_refunded_cdemo_sk
        FROM catalog_returns
        WHERE cr_refunded_cdemo_sk IS NOT NULL
        LIMIT 10
    )
  AND ca.total_refunded_cash > 200
  AND sa.max_return_tax IS NOT NULL
ORDER BY overall_rank
LIMIT 100
