WITH sales_by_state AS (
    SELECT
        ca.ca_state AS state,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY ca.ca_state
),
store_returns_by_state AS (
    SELECT
        ca.ca_state AS state,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_return_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_transactions
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY ca.ca_state
),
catalog_returns_by_state_ship AS (
    SELECT
        ca.ca_state AS state,
        sm.sm_type AS ship_mode,
        SUM(cr.cr_return_amt_inc_tax) AS total_catalog_return_amount,
        SUM(cr.cr_net_loss) AS total_catalog_return_net_loss,
        SUM(cr.cr_return_quantity) AS total_catalog_return_qty,
        COUNT(*) AS catalog_return_transactions
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY ca.ca_state, sm.sm_type
)
SELECT
    s.state,
    c.ship_mode,
    s.total_net_profit,
    s.total_sales_amount,
    COALESCE(r.total_return_amount, 0) AS total_store_return_amount,
    COALESCE(r.total_return_net_loss, 0) AS total_store_return_net_loss,
    COALESCE(c.total_catalog_return_amount, 0) AS total_catalog_return_amount,
    COALESCE(c.total_catalog_return_net_loss, 0) AS total_catalog_return_net_loss,
    s.avg_purchase_estimate,
    (s.total_net_profit - COALESCE(r.total_return_net_loss, 0) - COALESCE(c.total_catalog_return_net_loss, 0)) AS net_profit_after_returns,
    RANK() OVER (ORDER BY (s.total_net_profit - COALESCE(r.total_return_net_loss, 0) - COALESCE(c.total_catalog_return_net_loss, 0)) DESC) AS profit_rank
FROM sales_by_state s
LEFT JOIN store_returns_by_state r
    ON s.state = r.state
LEFT JOIN catalog_returns_by_state_ship c
    ON s.state = c.state
WHERE s.total_net_profit > 5000
ORDER BY net_profit_after_returns DESC
LIMIT 100
