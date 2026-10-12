WITH sales_union AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        'store' AS sales_channel,
        c.c_customer_id,
        i.i_category,
        ss.ss_net_profit AS net_profit,
        ss.ss_quantity AS quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    UNION ALL
    SELECT
        d.d_year,
        d.d_quarter_name,
        'web' AS sales_channel,
        c.c_customer_id,
        i.i_category,
        ws.ws_net_profit AS net_profit,
        ws.ws_quantity AS quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    UNION ALL
    SELECT
        d.d_year,
        d.d_quarter_name,
        'catalog' AS sales_channel,
        c.c_customer_id,
        i.i_category,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
),
returns_union AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        'store' AS sales_channel,
        c.c_customer_id,
        i.i_category,
        sr.sr_net_loss AS net_loss,
        sr.sr_return_quantity AS return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    UNION ALL
    SELECT
        d.d_year,
        d.d_quarter_name,
        'web' AS sales_channel,
        c.c_customer_id,
        i.i_category,
        wr.wr_net_loss AS net_loss,
        wr.wr_return_quantity AS return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
    UNION ALL
    SELECT
        d.d_year,
        d.d_quarter_name,
        'catalog' AS sales_channel,
        c.c_customer_id,
        i.i_category,
        cr.cr_net_loss AS net_loss,
        cr.cr_return_quantity AS return_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
),
sales_agg AS (
    SELECT
        d_year,
        d_quarter_name,
        sales_channel,
        i_category,
        c_customer_id,
        SUM(net_profit) AS total_profit,
        SUM(quantity) AS total_quantity
    FROM sales_union
    GROUP BY d_year, d_quarter_name, sales_channel, i_category, c_customer_id
),
returns_agg AS (
    SELECT
        d_year,
        d_quarter_name,
        sales_channel,
        i_category,
        c_customer_id,
        SUM(net_loss) AS total_loss,
        SUM(return_quantity) AS total_return_qty
    FROM returns_union
    GROUP BY d_year, d_quarter_name, sales_channel, i_category, c_customer_id
),
combined AS (
    SELECT
        s.d_year,
        s.d_quarter_name,
        s.sales_channel,
        s.i_category,
        s.c_customer_id,
        s.total_profit,
        COALESCE(r.total_loss, 0) AS total_loss,
        s.total_quantity,
        COALESCE(r.total_return_qty, 0) AS total_return_qty
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.d_year = r.d_year
        AND s.d_quarter_name = r.d_quarter_name
        AND s.sales_channel = r.sales_channel
        AND s.i_category = r.i_category
        AND s.c_customer_id = r.c_customer_id
),
summary AS (
    SELECT
        d_year,
        d_quarter_name,
        sales_channel,
        i_category,
        COUNT(DISTINCT c_customer_id) AS unique_customers,
        SUM(total_profit) AS total_profit,
        SUM(total_loss) AS total_loss,
        SUM(total_quantity) AS total_quantity,
        SUM(total_return_qty) AS total_return_qty
    FROM combined
    GROUP BY d_year, d_quarter_name, sales_channel, i_category
    HAVING SUM(total_profit) > 0
)
SELECT
    d_year,
    d_quarter_name,
    sales_channel,
    i_category,
    unique_customers,
    total_profit,
    total_loss,
    total_quantity,
    total_return_qty,
    ROUND((total_loss / NULLIF(total_profit, 0)) * 100, 2) AS loss_to_profit_pct,
    ROW_NUMBER() OVER (PARTITION BY sales_channel ORDER BY total_profit DESC) AS profit_rank_by_channel
FROM summary
ORDER BY d_year, sales_channel, i_category, profit_rank_by_channel
LIMIT 200
