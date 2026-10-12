WITH cat_agg AS (
    SELECT
        d.d_year AS year,
        ca.ca_state AS state,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        AVG(cr.cr_return_quantity) AS avg_catalog_return_qty
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, ca.ca_state
),
web_agg AS (
    SELECT
        d.d_year AS year,
        ca.ca_state AS state,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        AVG(wr.wr_return_quantity) AS avg_web_return_qty
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY d.d_year, ca.ca_state
),
store_agg AS (
    SELECT
        d.d_year AS year,
        s.s_state AS state,
        COUNT(DISTINCT s.s_store_sk) AS stores_closed
    FROM store s
    JOIN date_dim d
        ON s.s_closed_date_sk = d.d_date_sk
    GROUP BY d.d_year, s.s_state
)
SELECT
    COALESCE(cat.year, web.year, store.year) AS year,
    COALESCE(cat.state, web.state, store.state) AS state,
    COALESCE(cat.catalog_return_orders, 0) AS catalog_return_orders,
    COALESCE(cat.total_catalog_net_loss, 0) AS total_catalog_net_loss,
    COALESCE(cat.avg_catalog_return_qty, 0) AS avg_catalog_return_qty,
    COALESCE(web.web_return_orders, 0) AS web_return_orders,
    COALESCE(web.total_web_net_loss, 0) AS total_web_net_loss,
    COALESCE(web.avg_web_return_qty, 0) AS avg_web_return_qty,
    COALESCE(store.stores_closed, 0) AS stores_closed
FROM cat_agg cat
FULL OUTER JOIN web_agg web
    ON cat.year = web.year AND cat.state = web.state
FULL OUTER JOIN store_agg store
    ON COALESCE(cat.year, web.year) = store.year
    AND COALESCE(cat.state, web.state) = store.state
ORDER BY year, state
