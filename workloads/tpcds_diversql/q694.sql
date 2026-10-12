WITH sampled_sales AS (
    SELECT
        ws_order_number,
        ws_web_page_sk,
        ws_ext_sales_price,
        ws_net_profit
    FROM tpcds.web_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ws_ship_hdemo_sk = 4106
),
full_join AS (
    SELECT
        COALESCE(ws.ws_order_number, wr.wr_order_number) AS order_number,
        ws.ws_web_page_sk,
        wr.wr_return_amt,
        CASE WHEN ws.ws_net_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
    FROM tpcds.web_sales ws
    FULL OUTER JOIN tpcds.web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
    WHERE ws.ws_quantity > 5 OR wr.wr_return_quantity > 0
),
anti_page AS (
    SELECT wp.wp_web_page_sk AS wp_web_page_sk
    FROM tpcds.web_page wp
    WHERE wp.wp_web_page_sk NOT IN (
        SELECT ws.ws_web_page_sk
        FROM tpcds.web_sales ws
        WHERE ws.ws_quantity > 10
    )
),
sel_one AS (
    SELECT
        fs.ws_web_page_sk AS web_page_sk,
        fs.ws_ext_sales_price AS amount,
        CASE WHEN fs.ws_ext_sales_price > 1000 THEN 'HIGH' ELSE 'LOW' END AS label
    FROM sampled_sales fs
    JOIN tpcds.web_page wp
        ON fs.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_image_count >= 3
),
sel_two AS (
    SELECT
        fj.ws_web_page_sk AS web_page_sk,
        COALESCE(fj.wr_return_amt, 0) AS amount,
        fj.profit_flag AS label
    FROM full_join fj
    JOIN tpcds.web_page wp
        ON fj.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'content'
),
union_set AS (
    SELECT web_page_sk, amount, label FROM sel_one
    UNION
    SELECT web_page_sk, amount, label FROM sel_two
),
intersect_set AS (
    SELECT web_page_sk FROM union_set
    INTERSECT
    SELECT wp_web_page_sk FROM anti_page
)
SELECT
    u.web_page_sk,
    SUM(u.amount) AS total_amount,
    CASE WHEN SUM(u.amount) > 1500 THEN 'VERY_HIGH' ELSE 'OTHER' END AS amount_category,
    MAX(u.label) AS example_label
FROM union_set u
JOIN intersect_set i
    ON u.web_page_sk = i.web_page_sk
GROUP BY u.web_page_sk
ORDER BY total_amount DESC
LIMIT 100
