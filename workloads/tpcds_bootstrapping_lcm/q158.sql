WITH daily_page_returns AS (
    SELECT
        d.d_date_id,
        d.d_year,
        d.d_month_seq,
        wp.wp_web_page_id,
        wp.wp_type,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM date_dim d
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    GROUP BY
        d.d_date_id,
        d.d_year,
        d.d_month_seq,
        wp.wp_web_page_id,
        wp.wp_type
)

SELECT
    d.d_year,
    d.d_month_seq,
    s.s_state,
    s.s_city,
    i.inv_item_sk,
    i.inv_quantity_on_hand,
    wp.wp_url,
    wp.wp_type,
    dr.total_return_amt,
    dr.total_return_qty,
    dr.return_cnt,
    CASE
        WHEN dr.total_return_amt > 10000 THEN 'HIGH'
        WHEN dr.total_return_amt > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_severity,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY dr.total_return_amt DESC) AS state_return_rank
FROM date_dim d
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN inventory i ON i.inv_date_sk = d.d_date_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN daily_page_returns dr
    ON dr.d_date_id = d.d_date_id
    AND dr.wp_web_page_id = wp.wp_web_page_id
WHERE d.d_year = 2022
  AND s.s_state = 'CA'
  AND i.inv_quantity_on_hand > 0
ORDER BY dr.total_return_amt DESC
LIMIT 100
