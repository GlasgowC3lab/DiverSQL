WITH date_range AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_year = 2000
),
sales_union AS (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_item_sk AS item_sk,
           cs.cs_quantity AS quantity,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT ss.ss_sold_date_sk,
           ss.ss_item_sk,
           ss.ss_quantity,
           ss.ss_net_paid,
           ss.ss_net_profit,
           'store'
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_sold_date_sk,
           ws.ws_item_sk,
           ws.ws_quantity,
           ws.ws_net_paid,
           ws.ws_net_profit,
           'web'
    FROM web_sales ws
),
sales_agg AS (
    SELECT
        su.date_sk,
        su.item_sk,
        SUM(su.quantity) AS total_quantity,
        SUM(su.net_paid) AS total_net_paid,
        SUM(su.net_profit) AS total_net_profit,
        array_join(array_agg(DISTINCT su.channel), ',') AS channels
    FROM sales_union su
    GROUP BY su.date_sk, su.item_sk
),
returns_union AS (
    SELECT cr.cr_returned_date_sk AS date_sk,
           cr.cr_item_sk AS item_sk,
           cr.cr_return_quantity AS return_qty,
           cr.cr_return_amount AS return_amt,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    UNION ALL
    SELECT sr.sr_returned_date_sk,
           sr.sr_item_sk,
           sr.sr_return_quantity,
           sr.sr_return_amt,
           sr.sr_net_loss
    FROM store_returns sr
    UNION ALL
    SELECT wr.wr_returned_date_sk,
           wr.wr_item_sk,
           wr.wr_return_quantity,
           wr.wr_return_amt,
           wr.wr_net_loss
    FROM web_returns wr
),
returns_agg AS (
    SELECT
        item_sk,
        SUM(return_qty) AS total_return_qty,
        SUM(return_amt) AS total_return_amt,
        SUM(net_loss) AS total_return_loss
    FROM returns_union
    GROUP BY item_sk
)

SELECT
    d.d_date AS sale_date,
    i.i_item_id,
    i.i_product_name,
    concat(i.i_product_name,
           CASE WHEN i.i_brand IS NOT NULL THEN concat(' ', i.i_brand) ELSE '' END,
           CASE WHEN i.i_color IS NOT NULL THEN concat(' ', i.i_color) ELSE '' END) AS full_product_name,
    sa.total_quantity,
    sa.total_net_paid,
    sa.total_net_profit,
    COALESCE(ra.total_return_qty, 0) AS total_return_qty,
    COALESCE(ra.total_return_amt, 0) AS total_return_amount,
    (sa.total_net_profit - COALESCE(ra.total_return_loss, 0)) AS net_profit_after_returns,
    CASE
        WHEN sa.total_net_paid = 0 THEN NULL
        ELSE round(((sa.total_net_profit - COALESCE(ra.total_return_loss, 0)) / sa.total_net_paid) * 100, 2)
    END AS profit_margin_percent,
    rank() OVER (PARTITION BY d.d_date ORDER BY (sa.total_net_profit - COALESCE(ra.total_return_loss, 0)) DESC) AS profit_rank,
    (
        SELECT max(p.p_cost)
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
          AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    ) AS max_promo_cost,
    sa.channels AS sales_channels
FROM date_range d
LEFT JOIN sales_agg sa ON d.d_date_sk = sa.date_sk
LEFT JOIN item i ON sa.item_sk = i.i_item_sk
LEFT JOIN returns_agg ra ON i.i_item_sk = ra.item_sk
WHERE sa.total_quantity IS NOT NULL
ORDER BY d.d_date, profit_rank
LIMIT 100
