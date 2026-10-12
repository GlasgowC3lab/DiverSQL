WITH sales_by_channel AS (
    SELECT
        'Catalog' AS channel,
        cs.cs_order_number AS order_number,
        d.d_date AS sold_date,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_item_sk AS item_sk,
        i.i_category AS category,
        i.i_product_name AS product_name,
        cs.cs_net_profit AS net_profit,
        cs.cs_net_paid AS net_paid,
        COALESCE(p.p_discount_active, 'N') AS promo_flag,
        COALESCE(p.p_cost, 0) AS promo_cost,
        cc.cc_name AS entity_name,
        CASE WHEN cs.cs_net_paid = 0 THEN NULL ELSE cs.cs_net_profit / cs.cs_net_paid END AS profit_margin,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY d.d_date DESC) AS rn_item_recent
    FROM catalog_sales cs
    JOIN date_dim d ON d.d_date_sk = cs.cs_sold_date_sk
    JOIN item i ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN promotion p ON p.p_promo_sk = cs.cs_promo_sk
    LEFT JOIN call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
    JOIN customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
), sales_store AS (
    SELECT
        'Store' AS channel,
        ss.ss_ticket_number AS order_number,
        d.d_date AS sold_date,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_item_sk AS item_sk,
        i.i_category AS category,
        i.i_product_name AS product_name,
        ss.ss_net_profit AS net_profit,
        ss.ss_net_paid AS net_paid,
        COALESCE(p.p_discount_active, 'N') AS promo_flag,
        COALESCE(p.p_cost, 0) AS promo_cost,
        s.s_store_name AS entity_name,
        CASE WHEN ss.ss_net_paid = 0 THEN NULL ELSE ss.ss_net_profit / ss.ss_net_paid END AS profit_margin,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY d.d_date DESC) AS rn_item_recent
    FROM store_sales ss
    JOIN date_dim d ON d.d_date_sk = ss.ss_sold_date_sk
    JOIN item i ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN promotion p ON p.p_promo_sk = ss.ss_promo_sk
    LEFT JOIN store s ON s.s_store_sk = ss.ss_store_sk
    JOIN customer c ON c.c_customer_sk = ss.ss_customer_sk
), sales_web AS (
    SELECT
        'Web' AS channel,
        ws.ws_order_number AS order_number,
        d.d_date AS sold_date,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_item_sk AS item_sk,
        i.i_category AS category,
        i.i_product_name AS product_name,
        ws.ws_net_profit AS net_profit,
        ws.ws_net_paid AS net_paid,
        COALESCE(p.p_discount_active, 'N') AS promo_flag,
        COALESCE(p.p_cost, 0) AS promo_cost,
        wp.wp_url AS entity_name,
        CASE WHEN ws.ws_net_paid = 0 THEN NULL ELSE ws.ws_net_profit / ws.ws_net_paid END AS profit_margin,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY d.d_date DESC) AS rn_item_recent
    FROM web_sales ws
    JOIN date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN item i ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN promotion p ON p.p_promo_sk = ws.ws_promo_sk
    LEFT JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
), combined_sales AS (
    SELECT * FROM sales_by_channel
    UNION ALL
    SELECT * FROM sales_store
    UNION ALL
    SELECT * FROM sales_web
), customer_agg AS (
    SELECT
        cs.customer_sk,
        cs.customer_name,
        SUM(cs.net_profit) AS total_profit,
        SUM(cs.net_paid) AS total_paid,
        COUNT(*) AS transaction_count
    FROM combined_sales cs
    WHERE cs.profit_margin IS NOT NULL AND cs.profit_margin > 0.1
    GROUP BY cs.customer_sk, cs.customer_name
    HAVING SUM(cs.net_profit) > 1000
), ranked_customers AS (
    SELECT
        ca.*,
        RANK() OVER (ORDER BY ca.total_profit DESC) AS profit_rank
    FROM customer_agg ca
)
SELECT
    rc.profit_rank,
    rc.customer_name,
    rc.total_profit,
    rc.total_paid,
    rc.transaction_count,
    COALESCE(pa.promotional_sales, 0) AS promotional_sales,
    COALESCE(pa.max_profit_category, 'N/A') AS top_category,
    CASE WHEN rc.total_paid = 0 THEN NULL ELSE rc.total_profit / rc.total_paid END AS overall_profit_margin
FROM ranked_customers rc
LEFT JOIN (
    SELECT
        cs.customer_sk,
        count_if(cs.promo_flag = 'Y') AS promotional_sales,
        (SELECT cs2.category
         FROM combined_sales cs2
         WHERE cs2.customer_sk = cs.customer_sk
           AND cs2.profit_margin IS NOT NULL
         ORDER BY cs2.profit_margin DESC
         LIMIT 1) AS max_profit_category
    FROM combined_sales cs
    GROUP BY cs.customer_sk
) pa ON pa.customer_sk = rc.customer_sk
WHERE rc.profit_rank <= 10
ORDER BY rc.profit_rank
