WITH sales AS (
    SELECT
        i.i_category,
        i.i_brand,
        ws.ws_item_sk,
        ws.ws_net_paid_inc_tax,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        wp.wp_web_page_sk,
        wp.wp_type
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2452000
),
web_ret AS (
    SELECT
        i.i_category,
        i.i_brand,
        wr.wr_item_sk,
        wr.wr_return_amt_inc_tax,
        wp.wp_web_page_sk,
        wp.wp_type
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wr.wr_reason_sk IN (16, 17)
),
catalog_ret AS (
    SELECT
        i.i_category,
        i.i_brand,
        cr.cr_item_sk,
        cr.cr_return_amt_inc_tax
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_reason_sk IN (16, 17)
),
agg AS (
    SELECT
        s.i_category,
        s.i_brand,
        s.wp_type,
        SUM(s.ws_net_paid_inc_tax) AS total_sales_amount,
        SUM(s.ws_net_profit) AS total_profit,
        COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) + COALESCE(SUM(cr.cr_return_amt_inc_tax), 0) AS total_return_amount,
        CASE WHEN SUM(s.ws_net_paid_inc_tax) = 0 THEN 0
             ELSE (COALESCE(SUM(wr.wr_return_amt_inc_tax), 0) + COALESCE(SUM(cr.cr_return_amt_inc_tax), 0)) / SUM(s.ws_net_paid_inc_tax)
        END AS return_rate
    FROM sales s
    LEFT JOIN web_ret wr
        ON s.ws_item_sk = wr.wr_item_sk
        AND s.wp_web_page_sk = wr.wp_web_page_sk
    LEFT JOIN catalog_ret cr
        ON s.ws_item_sk = cr.cr_item_sk
    GROUP BY s.i_category, s.i_brand, s.wp_type
)
SELECT
    i_category,
    i_brand,
    wp_type,
    total_sales_amount,
    total_profit,
    total_return_amount,
    return_rate,
    RANK() OVER (ORDER BY return_rate DESC) AS return_rate_rank
FROM agg
ORDER BY return_rate DESC
LIMIT 50
