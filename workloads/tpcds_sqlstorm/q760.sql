WITH date_info AS (
    SELECT d_date_sk,
           format_datetime(d_date, 'yyyy-MM') AS month_year
    FROM date_dim
),
sales_agg AS (
    SELECT 'catalog' AS channel,
           c.cs_item_sk AS item_sk,
           di.month_year,
           sum(c.cs_quantity) AS total_quantity,
           sum(c.cs_net_paid) AS total_sales_amount,
           sum(c.cs_net_profit) AS total_profit,
           min(p.p_promo_id) AS promo_id,
           sum(p.p_cost) AS total_promo_cost
    FROM catalog_sales c
    LEFT JOIN date_info di ON c.cs_sold_date_sk = di.d_date_sk
    LEFT JOIN promotion p ON c.cs_promo_sk = p.p_promo_sk
    GROUP BY di.month_year, c.cs_item_sk
    UNION ALL
    SELECT 'store' AS channel,
           s.ss_item_sk AS item_sk,
           di.month_year,
           sum(s.ss_quantity) AS total_quantity,
           sum(s.ss_net_paid) AS total_sales_amount,
           sum(s.ss_net_profit) AS total_profit,
           min(p.p_promo_id) AS promo_id,
           sum(p.p_cost) AS total_promo_cost
    FROM store_sales s
    LEFT JOIN date_info di ON s.ss_sold_date_sk = di.d_date_sk
    LEFT JOIN promotion p ON s.ss_promo_sk = p.p_promo_sk
    GROUP BY di.month_year, s.ss_item_sk
    UNION ALL
    SELECT 'web' AS channel,
           w.ws_item_sk AS item_sk,
           di.month_year,
           sum(w.ws_quantity) AS total_quantity,
           sum(w.ws_net_paid) AS total_sales_amount,
           sum(w.ws_net_profit) AS total_profit,
           min(p.p_promo_id) AS promo_id,
           sum(p.p_cost) AS total_promo_cost
    FROM web_sales w
    LEFT JOIN date_info di ON w.ws_sold_date_sk = di.d_date_sk
    LEFT JOIN promotion p ON w.ws_promo_sk = p.p_promo_sk
    GROUP BY di.month_year, w.ws_item_sk
),
returns_agg AS (
    SELECT 'catalog' AS channel,
           cr.cr_item_sk AS item_sk,
           di.month_year,
           sum(cr.cr_return_amount) AS total_return_amount,
           sum(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    LEFT JOIN date_info di ON cr.cr_returned_date_sk = di.d_date_sk
    GROUP BY di.month_year, cr.cr_item_sk
    UNION ALL
    SELECT 'store' AS channel,
           sr.sr_item_sk AS item_sk,
           di.month_year,
           sum(sr.sr_return_amt) AS total_return_amount,
           sum(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    LEFT JOIN date_info di ON sr.sr_returned_date_sk = di.d_date_sk
    GROUP BY di.month_year, sr.sr_item_sk
    UNION ALL
    SELECT 'web' AS channel,
           wr.wr_item_sk AS item_sk,
           di.month_year,
           sum(wr.wr_return_amt) AS total_return_amount,
           sum(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    LEFT JOIN date_info di ON wr.wr_returned_date_sk = di.d_date_sk
    GROUP BY di.month_year, wr.wr_item_sk
),
combined AS (
    SELECT
        COALESCE(s.channel, r.channel) AS channel,
        COALESCE(s.item_sk, r.item_sk) AS item_sk,
        COALESCE(s.month_year, r.month_year) AS month_year,
        COALESCE(s.total_quantity, 0) AS total_quantity,
        COALESCE(s.total_sales_amount, 0) AS total_sales_amount,
        COALESCE(s.total_profit, 0) AS total_sales_profit,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        COALESCE(s.promo_id, NULL) AS promo_id,
        COALESCE(s.total_promo_cost, 0) AS total_promo_cost
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
        ON s.channel = r.channel
        AND s.item_sk = r.item_sk
        AND s.month_year = r.month_year
),
final AS (
    SELECT
        c.month_year,
        i.i_item_id,
        i.i_product_name,
        CONCAT(i.i_item_id, ' - ', i.i_product_name) AS item_desc,
        c.channel,
        c.total_quantity,
        c.total_sales_amount,
        c.total_return_amount,
        c.total_sales_profit,
        c.total_return_loss,
        (c.total_sales_profit - c.total_return_loss) AS net_profit,
        (c.total_sales_amount - c.total_return_amount) AS net_sales,
        c.promo_id,
        c.total_promo_cost,
        (SELECT max(sa.total_sales_amount)
         FROM sales_agg sa
         WHERE sa.month_year = c.month_year
           AND sa.item_sk = c.item_sk) AS max_monthly_sales_amount,
        RANK() OVER (PARTITION BY c.month_year ORDER BY (c.total_sales_profit - c.total_return_loss) DESC) AS profit_rank,
        CASE WHEN i.i_color IS NULL THEN 'UNKNOWN' ELSE i.i_color END AS item_color
    FROM combined c
    LEFT JOIN item i ON c.item_sk = i.i_item_sk
    WHERE
        (c.total_sales_profit - c.total_return_loss) > 0
        AND (i.i_category = 'Electronics' OR i.i_category = 'Books' OR i.i_category IS NULL)
        AND (i.i_color LIKE 'B%' OR i.i_color IS NULL)
        AND c.month_year BETWEEN format_datetime(DATE '2022-01-01', 'yyyy-MM') AND format_datetime(DATE '2022-12-31', 'yyyy-MM')
)
SELECT *
FROM final
ORDER BY month_year, profit_rank
LIMIT 100
