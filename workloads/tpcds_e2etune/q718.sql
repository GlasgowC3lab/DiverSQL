WITH catalog_agg AS (
    SELECT
        ca.ca_state AS state,
        COUNT(*) AS catalog_return_cnt,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        SUM(cr.cr_return_amt_inc_tax) AS catalog_return_inc_tax,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        AVG(cr.cr_return_quantity) AS avg_catalog_return_qty
    FROM catalog_returns cr
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cr.cr_return_amount > 1000.00
      AND cr.cr_returned_date_sk BETWEEN 1500000 AND 2000000
    GROUP BY ca.ca_state
),
store_agg AS (
    SELECT
        ca.ca_state AS state,
        COUNT(*) AS store_return_cnt,
        SUM(sr.sr_return_amt) AS store_return_amount,
        SUM(sr.sr_return_amt_inc_tax) AS store_return_inc_tax,
        SUM(sr.sr_net_loss) AS store_net_loss,
        AVG(sr.sr_return_quantity) AS avg_store_return_qty
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_return_amt > 500.00
      AND sr.sr_returned_date_sk BETWEEN 1500000 AND 2000000
    GROUP BY ca.ca_state
)
SELECT
    COALESCE(ca.state, sa.state) AS state,
    COALESCE(ca.catalog_return_cnt, 0) AS catalog_return_cnt,
    COALESCE(sa.store_return_cnt, 0) AS store_return_cnt,
    COALESCE(ca.catalog_return_amount, 0) AS catalog_return_amount,
    COALESCE(sa.store_return_amount, 0) AS store_return_amount,
    COALESCE(ca.catalog_net_loss, 0) + COALESCE(sa.store_net_loss, 0) AS total_net_loss,
    COALESCE(ca.catalog_return_amount, 0) + COALESCE(sa.store_return_amount, 0) AS total_return_amount,
    (COALESCE(ca.catalog_return_cnt, 0) + COALESCE(sa.store_return_cnt, 0)) AS total_return_cnt,
    RANK() OVER (ORDER BY (COALESCE(ca.catalog_net_loss, 0) + COALESCE(sa.store_net_loss, 0)) DESC) AS net_loss_rank
FROM catalog_agg ca
FULL OUTER JOIN store_agg sa
    ON ca.state = sa.state
WHERE (COALESCE(ca.catalog_net_loss, 0) + COALESCE(sa.store_net_loss, 0)) > 0
ORDER BY total_net_loss DESC
LIMIT 50
