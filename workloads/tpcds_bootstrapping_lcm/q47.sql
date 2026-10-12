WITH
    returns_agg AS (
        SELECT
            wr_returned_date_sk AS date_sk,
            SUM(wr_net_loss) AS total_net_loss,
            SUM(wr_return_quantity) AS total_return_quantity,
            SUM(wr_return_amt) AS total_return_amount
        FROM web_returns
        GROUP BY wr_returned_date_sk
    ),
    inventory_agg AS (
        SELECT
            inv_date_sk AS date_sk,
            SUM(inv_quantity_on_hand) AS total_inventory_qty
        FROM inventory
        GROUP BY inv_date_sk
    ),
    stores_closed_agg AS (
        SELECT
            s_closed_date_sk AS date_sk,
            COUNT(DISTINCT s_store_sk) AS stores_closed
        FROM store
        GROUP BY s_closed_date_sk
    ),
    sites_opened_agg AS (
        SELECT
            web_open_date_sk AS date_sk,
            COUNT(DISTINCT web_site_sk) AS sites_opened
        FROM web_site
        GROUP BY web_open_date_sk
    ),
    sites_closed_agg AS (
        SELECT
            web_close_date_sk AS date_sk,
            COUNT(DISTINCT web_site_sk) AS sites_closed
        FROM web_site
        GROUP BY web_close_date_sk
    )
SELECT
    d.d_year,
    d.d_month_seq,
    date_trunc('month', d.d_date) AS month_start,
    SUM(COALESCE(r.total_net_loss, 0)) AS total_net_loss,
    SUM(COALESCE(i.total_inventory_qty, 0)) AS total_inventory_qty,
    SUM(COALESCE(sc.stores_closed, 0)) AS stores_closed,
    SUM(COALESCE(so.sites_opened, 0)) AS sites_opened,
    SUM(COALESCE(sc2.sites_closed, 0)) AS sites_closed,
    CASE
        WHEN SUM(COALESCE(i.total_inventory_qty, 0)) > 0
        THEN SUM(COALESCE(r.total_net_loss, 0)) / SUM(COALESCE(i.total_inventory_qty, 0))
        ELSE NULL
    END AS net_loss_per_inventory
FROM date_dim d
LEFT JOIN returns_agg r ON r.date_sk = d.d_date_sk
LEFT JOIN inventory_agg i ON i.date_sk = d.d_date_sk
LEFT JOIN stores_closed_agg sc ON sc.date_sk = d.d_date_sk
LEFT JOIN sites_opened_agg so ON so.date_sk = d.d_date_sk
LEFT JOIN sites_closed_agg sc2 ON sc2.date_sk = d.d_date_sk
WHERE d.d_date BETWEEN DATE '2020-01-01' AND DATE '2023-12-31'
GROUP BY d.d_year, d.d_month_seq, date_trunc('month', d.d_date)
ORDER BY net_loss_per_inventory DESC
LIMIT 10
