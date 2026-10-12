WITH
    agg_store_sales AS (
        SELECT
            ss_customer_sk,
            SUM(ss_net_paid_inc_tax) AS total_sales,
            SUM(ss_net_profit)      AS total_profit
        FROM store_sales
        WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450200
          AND ss_quantity > 1
          AND ss_coupon_amt < 500
        GROUP BY ss_customer_sk
    ),
    agg_catalog_ret AS (
        SELECT
            cr_returning_customer_sk AS cust_sk,
            SUM(cr_net_loss)          AS cat_net_loss,
            COUNT(*)                  AS cat_ret_cnt
        FROM catalog_returns
        WHERE cr_returned_date_sk BETWEEN 2450000 AND 2450200
          AND cr_return_quantity > 0
          AND cr_fee > 0
        GROUP BY cr_returning_customer_sk
    ),
    agg_store_ret AS (
        SELECT
            sr_customer_sk AS cust_sk,
            SUM(sr_net_loss) AS store_net_loss,
            COUNT(*)          AS store_ret_cnt
        FROM store_returns
        WHERE sr_returned_date_sk BETWEEN 2450000 AND 2450200
          AND sr_return_quantity > 0
          AND sr_fee > 0
        GROUP BY sr_customer_sk
    ),
    agg_web_ret AS (
        SELECT
            wr_returning_customer_sk AS cust_sk,
            SUM(wr_net_loss)         AS web_net_loss,
            COUNT(*)                 AS web_ret_cnt
        FROM web_returns
        WHERE wr_returned_date_sk BETWEEN 2450000 AND 2450200
          AND wr_return_quantity > 0
          AND wr_fee > 0
        GROUP BY wr_returning_customer_sk
    )
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    sm.sm_type                                        AS ship_mode_type,
    r.r_reason_desc                                   AS last_return_reason,
    ss.total_sales,
    ss.total_profit,
    COALESCE(ar.cat_net_loss, 0) +
    COALESCE(sr.store_net_loss, 0) +
    COALESCE(wr.web_net_loss, 0)                     AS total_net_loss,
    CASE
        WHEN COALESCE(ar.cat_net_loss, 0) +
             COALESCE(sr.store_net_loss, 0) +
             COALESCE(wr.web_net_loss, 0) > 10000 THEN 'HIGH'
        WHEN COALESCE(ar.cat_net_loss, 0) +
             COALESCE(sr.store_net_loss, 0) +
             COALESCE(wr.web_net_loss, 0) > 5000  THEN 'MEDIUM'
        ELSE 'LOW'
    END                                              AS loss_category,
    ROW_NUMBER() OVER (
        PARTITION BY cd.cd_gender
        ORDER BY COALESCE(ar.cat_net_loss, 0) +
                 COALESCE(sr.store_net_loss, 0) +
                 COALESCE(wr.web_net_loss, 0) DESC
    )                                               AS gender_loss_rank
FROM agg_store_sales ss
LEFT JOIN agg_catalog_ret ar ON ss.ss_customer_sk = ar.cust_sk
LEFT JOIN agg_store_ret   sr ON ss.ss_customer_sk = sr.cust_sk
LEFT JOIN agg_web_ret     wr ON ss.ss_customer_sk = wr.cust_sk
JOIN customer c
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN catalog_returns cr
    ON c.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr_full
    ON c.c_customer_sk = wr_full.wr_returning_customer_sk
LEFT JOIN web_page wp
    ON wr_full.wr_web_page_sk = wp.wp_web_page_sk
WHERE cd.cd_purchase_estimate >= 5000
  AND ca.ca_country = 'United States'
  AND sm.sm_carrier LIKE 'UPS%'
  AND r.r_reason_desc IS NOT NULL
  AND wp.wp_type = 'content'
ORDER BY total_net_loss DESC
LIMIT 100
