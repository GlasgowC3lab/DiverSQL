WITH cat_ship AS (
    SELECT
        cr.cr_returning_customer_sk AS cust_sk,
        sm.sm_ship_mode_id,
        sm.sm_carrier,
        SUM(cr.cr_return_quantity) AS total_qty
    FROM catalog_returns cr
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451000 AND 2451100
    GROUP BY cr.cr_returning_customer_sk, sm.sm_ship_mode_id, sm.sm_carrier
),
cat_top_ship AS (
    SELECT
        cust_sk,
        sm_ship_mode_id AS ship_mode_id,
        sm_carrier AS ship_carrier,
        total_qty,
        ROW_NUMBER() OVER (PARTITION BY cust_sk ORDER BY total_qty DESC) AS rn
    FROM cat_ship
),
cat_top_ship_filtered AS (
    SELECT cust_sk, ship_mode_id, ship_carrier
    FROM cat_top_ship
    WHERE rn = 1
),
cat_sums AS (
    SELECT
        cr.cr_returning_customer_sk AS cust_sk,
        SUM(cr.cr_net_loss) AS cat_net_loss,
        SUM(cr.cr_return_amount) AS cat_return_amount,
        COUNT(*) AS cat_return_cnt
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk BETWEEN 2451000 AND 2451100
    GROUP BY cr.cr_returning_customer_sk
),
web_agg AS (
    SELECT
        wr.wr_returning_customer_sk AS cust_sk,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(wr.wr_return_amt) AS web_return_amount,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 2451000 AND 2451100
    GROUP BY wr.wr_returning_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(cs.cat_net_loss, 0) + COALESCE(wa.web_net_loss, 0) AS total_net_loss,
    COALESCE(cs.cat_return_amount, 0) + COALESCE(wa.web_return_amount, 0) AS total_return_amount,
    COALESCE(cs.cat_return_cnt, 0) + COALESCE(wa.web_return_cnt, 0) AS total_return_cnt,
    COALESCE(cts.ship_mode_id, 'UNKNOWN') AS top_ship_mode,
    COALESCE(cts.ship_carrier, 'UNKNOWN') AS top_ship_carrier
FROM customer c
LEFT JOIN cat_sums cs ON c.c_customer_sk = cs.cust_sk
LEFT JOIN web_agg wa ON c.c_customer_sk = wa.cust_sk
LEFT JOIN cat_top_ship_filtered cts ON c.c_customer_sk = cts.cust_sk
WHERE cs.cat_net_loss IS NOT NULL OR wa.web_net_loss IS NOT NULL
ORDER BY total_net_loss DESC
LIMIT 10
