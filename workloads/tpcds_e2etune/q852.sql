WITH sales_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY s.s_store_sk, s.s_store_name, d.d_year, d.d_month_seq, i.i_category
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_category,
        SUM(cr.cr_net_loss) AS total_net_loss,
        SUM(cr.cr_return_quantity) AS total_return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
sites_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        COUNT(DISTINCT w.web_site_sk) AS sites_opened
    FROM web_site w
    JOIN date_dim d ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY d.d_year, d.d_month_seq
)
SELECT
    s.s_store_name,
    s.d_year,
    s.month_seq,
    s.i_category,
    s.total_net_profit,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    COALESCE(se.sites_opened, 0) AS sites_opened,
    CASE WHEN s.total_net_profit = 0 THEN 0
         ELSE COALESCE(r.total_net_loss, 0) / s.total_net_profit END AS loss_ratio,
    RANK() OVER (PARTITION BY s.d_year, s.month_seq ORDER BY CASE WHEN s.total_net_profit = 0 THEN 0 ELSE COALESCE(r.total_net_loss, 0) / s.total_net_profit END DESC) AS loss_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.month_seq = r.month_seq
   AND s.i_category = r.i_category
LEFT JOIN sites_agg se
    ON s.d_year = se.d_year
   AND s.month_seq = se.month_seq
WHERE s.total_net_profit > 0
ORDER BY s.d_year, s.month_seq, loss_rank
LIMIT 100
