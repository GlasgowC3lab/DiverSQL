WITH sales_data AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_net_profit AS net_profit,
        cs.cs_quantity AS quantity,
        cs.cs_promo_sk AS promo_sk,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    WHERE cs.cs_net_profit IS NOT NULL
    UNION ALL
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_customer_sk,
        ss.ss_item_sk,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_promo_sk,
        'store' AS sales_channel
    FROM store_sales ss
    WHERE ss.ss_net_profit IS NOT NULL
    UNION ALL
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ws.ws_quantity,
        ws.ws_promo_sk,
        'web' AS sales_channel
    FROM web_sales ws
    WHERE ws.ws_net_profit IS NOT NULL
), enriched_sales AS (
    SELECT
        sd.*,
        d.d_date AS sold_date,
        i.i_category,
        i.i_item_id,
        i.i_product_name,
        COALESCE(p.p_promo_name, 'No Promo') AS promo_name
    FROM sales_data sd
    LEFT JOIN date_dim d ON sd.sold_date_sk = d.d_date_sk
    LEFT JOIN item i ON sd.item_sk = i.i_item_sk
    LEFT JOIN promotion p ON sd.promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1999 AND 2002
), customer_agg AS (
    SELECT
        es.customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        es.i_category,
        COUNT(*) AS purchase_cnt,
        SUM(es.quantity) AS total_quantity,
        SUM(es.net_profit) AS total_net_profit,
        MAX(es.sold_date) AS last_purchase_date,
        COUNT(DISTINCT es.sales_channel) AS channels_used
    FROM enriched_sales es
    JOIN customer c ON es.customer_sk = c.c_customer_sk
    GROUP BY
        es.customer_sk,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name),
        es.i_category
), category_stats AS (
    SELECT
        i_category,
        AVG(total_net_profit) AS avg_category_profit,
        STDDEV_POP(total_net_profit) AS stddev_category_profit
    FROM customer_agg
    GROUP BY i_category
), ranked_customers AS (
    SELECT
        ca.*,
        SUM(ca.total_net_profit) OVER (PARTITION BY ca.customer_sk) AS total_customer_profit,
        ROW_NUMBER() OVER (PARTITION BY ca.customer_sk ORDER BY ca.total_net_profit DESC) AS category_rank,
        cs.avg_category_profit,
        CASE
            WHEN ca.total_net_profit > cs.avg_category_profit + cs.stddev_category_profit THEN 'Above Avg + 1SD'
            WHEN ca.total_net_profit < cs.avg_category_profit - cs.stddev_category_profit THEN 'Below Avg - 1SD'
            ELSE 'Within 1SD'
        END AS profit_category,
        CASE WHEN ca.channels_used > 1 THEN 'Multi' ELSE 'Single' END AS channel_type,
        (SELECT MAX(es3.net_profit)
         FROM enriched_sales es3
         WHERE es3.customer_sk = ca.customer_sk
           AND es3.i_category = ca.i_category) AS max_single_sale_profit
    FROM customer_agg ca
    LEFT JOIN category_stats cs ON ca.i_category = cs.i_category
)
SELECT
    rc.full_name,
    rc.customer_sk,
    rc.i_category,
    rc.total_quantity,
    rc.total_net_profit,
    rc.last_purchase_date,
    rc.channels_used,
    rc.channel_type,
    rc.profit_category,
    rc.category_rank,
    rc.max_single_sale_profit,
    rc.total_customer_profit,
    rc.total_net_profit / NULLIF(rc.total_customer_profit, 0) AS profit_share,
    rc.total_net_profit / NULLIF(rc.total_quantity, 0) AS profit_per_qty,
    CAST(rc.last_purchase_date AS VARCHAR) AS last_purchase_str
FROM ranked_customers rc
WHERE rc.category_rank <= 3
  AND rc.last_purchase_date >= DATE '2000-01-01'
ORDER BY rc.full_name, rc.category_rank
