WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        d.d_date,
        d.d_year,
        t.t_meal_time,
        i.inv_quantity_on_hand,
        i.inv_item_sk,
        wr.wr_return_amt,
        w.web_name,
        w.web_zip
    FROM catalog_returns cr
    LEFT JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
    LEFT JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
    RIGHT OUTER JOIN web_site w
        ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_meal_time = 'breakfast'
      AND i.inv_quantity_on_hand > 100
      AND w.web_zip = '38048'
      AND cr.cr_return_amount > 50
)
SELECT
    d_date,
    web_name,
    t_meal_time,
    SUM(cr_return_amount) AS total_catalog_return_amount,
    SUM(cr_return_qty) AS total_catalog_return_quantity,
    SUM(wr_return_amt) AS total_web_return_amount,
    SUM(inv_quantity_on_hand) AS total_inventory_quantity,
    COUNT(DISTINCT cr_order_number) AS distinct_catalog_orders
FROM (
    SELECT
        d_date,
        web_name,
        t_meal_time,
        cr_return_amount,
        cr_return_quantity AS cr_return_qty,
        wr_return_amt,
        inv_quantity_on_hand,
        cr_order_number
    FROM base
) agg
GROUP BY d_date, web_name, t_meal_time
ORDER BY total_catalog_return_amount DESC, d_date ASC
LIMIT 100
