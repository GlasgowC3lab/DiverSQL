WITH store_data AS (
    SELECT
        d.d_fy_quarter_seq,
        d.d_holiday,
        p.p_channel_email,
        r.r_reason_desc,
        'store' AS source,
        sr.sr_return_amt + sr.sr_return_tax + sr.sr_return_ship_cost AS total_return,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
    JOIN date_dim d
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN promotion p
        ON d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    WHERE d.d_fy_year = 2022
      AND p.p_discount_active = 'Y'
      AND d.d_weekend = 'N'
),
web_data AS (
    SELECT
        d.d_fy_quarter_seq,
        d.d_holiday,
        p.p_channel_email,
        r.r_reason_desc,
        'web' AS source,
        wr.wr_return_amt + wr.wr_return_tax + wr.wr_return_ship_cost AS total_return,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN promotion p
        ON d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_page
        ON wp.wp_creation_date_sk = d_page.d_date_sk
    WHERE d.d_fy_year = 2022
      AND p.p_discount_active = 'Y'
      AND wp.wp_type = 'product'
      AND d_page.d_fy_year = 2022
      AND d_page.d_weekend = 'N'
)
SELECT
    source,
    d_fy_quarter_seq,
    d_holiday,
    p_channel_email,
    r_reason_desc,
    COUNT(*) AS return_cnt,
    SUM(total_return) AS total_return_amount,
    AVG(net_loss) AS avg_net_loss
FROM (
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM web_data
) t
GROUP BY source, d_fy_quarter_seq, d_holiday, p_channel_email, r_reason_desc
HAVING COUNT(*) > 10
ORDER BY total_return_amount DESC
LIMIT 200
