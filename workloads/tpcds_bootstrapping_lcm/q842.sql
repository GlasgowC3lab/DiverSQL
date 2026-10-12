WITH
    cat_agg AS (
        SELECT
            cr_returned_date_sk AS date_sk,
            SUM(cr_return_amount) AS total_catalog_return_amount,
            SUM(cr_return_quantity) AS total_catalog_return_qty,
            SUM(cr_net_loss) AS total_catalog_net_loss
        FROM catalog_returns
        GROUP BY cr_returned_date_sk
    ),
    web_agg AS (
        SELECT
            wr_returned_date_sk AS date_sk,
            SUM(wr_return_amt) AS total_web_return_amount,
            SUM(wr_return_quantity) AS total_web_return_qty,
            SUM(wr_net_loss) AS total_web_net_loss
        FROM web_returns
        GROUP BY wr_returned_date_sk
    ),
    inv_agg AS (
        SELECT
            inv_date_sk AS date_sk,
            SUM(inv_quantity_on_hand) AS total_inventory_qty,
            COUNT(DISTINCT inv_warehouse_sk) AS warehouse_count
        FROM inventory
        GROUP BY inv_date_sk
    ),
    store_agg AS (
        SELECT
            s_closed_date_sk AS date_sk,
            SUM(s_number_employees) AS total_employees,
            COUNT(*) AS closed_store_count,
            MIN(s_state) AS example_state
        FROM store
        GROUP BY s_closed_date_sk
    )
SELECT
    d.d_date AS return_date,
    d.d_year,
    d.d_month_seq,
    d.d_quarter_name,
    cat_agg.total_catalog_return_amount,
    web_agg.total_web_return_amount,
    cat_agg.total_catalog_return_amount + web_agg.total_web_return_amount AS total_return_amount,
    cat_agg.total_catalog_return_qty + web_agg.total_web_return_qty AS total_return_qty,
    cat_agg.total_catalog_net_loss + web_agg.total_web_net_loss AS total_net_loss,
    inv_agg.total_inventory_qty,
    store_agg.total_employees,
    CASE
        WHEN inv_agg.total_inventory_qty > 0
        THEN (cat_agg.total_catalog_net_loss + web_agg.total_web_net_loss) / inv_agg.total_inventory_qty
        ELSE NULL
    END AS net_loss_per_inventory_unit,
    ROUND(
        (cat_agg.total_catalog_return_amount + web_agg.total_web_return_amount) /
        NULLIF(inv_agg.total_inventory_qty, 0),
        2
    ) AS return_amount_per_inventory,
    store_agg.closed_store_count AS stores_closed_this_date,
    ROW_NUMBER() OVER (
        PARTITION BY d.d_year
        ORDER BY (cat_agg.total_catalog_net_loss + web_agg.total_web_net_loss) DESC
    ) AS rank_by_year_net_loss
FROM date_dim d
LEFT JOIN cat_agg   ON cat_agg.date_sk   = d.d_date_sk
LEFT JOIN web_agg   ON web_agg.date_sk   = d.d_date_sk
LEFT JOIN inv_agg   ON inv_agg.date_sk   = d.d_date_sk
LEFT JOIN store_agg ON store_agg.date_sk = d.d_date_sk
WHERE d.d_year >= 2000
ORDER BY d.d_date DESC
LIMIT 100
