WITH
    inv_agg AS (
        SELECT
            i.inv_date_sk,
            SUM(i.inv_quantity_on_hand) AS total_qty_on_hand
        FROM inventory i
        JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
        GROUP BY i.inv_date_sk
    ),
    wr_agg AS (
        SELECT
            wr.wr_returned_date_sk,
            wp.wp_type,
            SUM(wr.wr_return_amt_inc_tax) AS sum_return_inc_tax,
            COUNT(*) AS cnt_return
        FROM web_returns wr
        JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
        WHERE d.d_year = 2001
          AND wp.wp_type = 'product'
        GROUP BY wr.wr_returned_date_sk, wp.wp_type
    )
SELECT
    d.d_date,
    ws.web_name,
    cr.cr_return_amount,
    wrag.sum_return_inc_tax,
    iag.total_qty_on_hand,
    (wrag.sum_return_inc_tax / iag.total_qty_on_hand) AS avg_return_per_qty
FROM wr_agg wrag
JOIN inv_agg iag ON wrag.wr_returned_date_sk = iag.inv_date_sk
JOIN date_dim d ON wrag.wr_returned_date_sk = d.d_date_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
WHERE cr.cr_return_amount > 50
  AND cr.cr_store_credit < 100
  AND ws.web_country = 'United States'
  AND d.d_dow IN (1, 2, 3)
  AND wrag.sum_return_inc_tax > (
        SELECT AVG(sum_return_inc_tax) FROM wr_agg
    )
ORDER BY avg_return_per_qty DESC
LIMIT 100
