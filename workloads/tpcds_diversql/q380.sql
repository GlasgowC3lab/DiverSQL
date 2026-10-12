WITH
    -- Aggregate store returns per customer (pre‑aggregation as required)
    store_agg AS (
        SELECT
            sr_customer_sk,
            SUM(sr_net_loss)                     AS store_net_loss,
            COUNT(*)                             AS store_return_cnt,
            SUM(sr_return_quantity)              AS store_return_qty
        FROM tpcds.store_returns
        WHERE sr_returned_date_sk BETWEEN 2450646 AND 2450752   -- selective date range
          AND sr_return_quantity > 1                         -- selective predicate
        GROUP BY sr_customer_sk
    ),
    -- Aggregate web returns per refunded customer
    web_agg AS (
        SELECT
            wr_refunded_customer_sk AS c_customer_sk,
            SUM(wr_net_loss)          AS web_net_loss,
            COUNT(*)                  AS web_return_cnt,
            SUM(wr_return_quantity)   AS web_return_qty
        FROM tpcds.web_returns
        WHERE wr_returned_date_sk BETWEEN 2450646 AND 2450752   -- same date window
          AND wr_account_credit > 100.00                        -- selective predicate
        GROUP BY wr_refunded_customer_sk
    ),
    -- Distinct customer keys that appear in store returns
    customers_only_store AS (
        SELECT DISTINCT sr_customer_sk AS c_customer_sk
        FROM tpcds.store_returns
    ),
    -- Distinct customer keys that appear in web returns (refunded side)
    customers_only_web AS (
        SELECT DISTINCT wr_refunded_customer_sk AS c_customer_sk
        FROM tpcds.web_returns
    ),
    -- Customers with store returns but no corresponding web returns (EXCEPT usage)
    store_not_web AS (
        SELECT c_customer_sk
        FROM customers_only_store
        EXCEPT
        SELECT c_customer_sk
        FROM customers_only_web
    )
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_education_status,
    sa.store_net_loss,
    wa.web_net_loss,
    (sa.store_net_loss + COALESCE(wa.web_net_loss, 0))               AS total_net_loss,
    CASE
        WHEN (sa.store_net_loss + COALESCE(wa.web_net_loss, 0)) > 500 THEN 'High'
        ELSE 'Low'
    END                                                               AS loss_category,
    sa.store_return_cnt,
    COALESCE(wa.web_return_cnt, 0)                                   AS web_return_cnt,
    sa.store_return_qty,
    COALESCE(wa.web_return_qty, 0)                                   AS web_return_qty
FROM store_not_web snw
JOIN store_agg sa   ON sa.sr_customer_sk   = snw.c_customer_sk
JOIN tpcds.customer c          ON c.c_customer_sk = sa.sr_customer_sk
JOIN tpcds.customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
LEFT JOIN web_agg wa            ON wa.c_customer_sk = c.c_customer_sk
WHERE c.c_birth_year = 1977                -- selective predicate on birth year
  AND cd.cd_credit_rating = 'Good'         -- selective predicate on credit rating
  AND c.c_preferred_cust_flag = 'Y'        -- selective predicate on preferred flag
  AND sa.store_return_qty > 1              -- additional selective predicate (already filtered in CTE but kept for clarity)
LIMIT 100
