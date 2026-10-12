WITH
    catalog_sales_agg AS (
        SELECT
            cs.cs_item_sk,
            d.d_date AS sale_date,
            SUM(cs.cs_quantity) AS total_qty,
            SUM(cs.cs_net_paid) AS total_net_paid,
            SUM(cs.cs_net_profit) AS total_net_profit,
            CASE WHEN SUM(cs.cs_net_paid) = 0 THEN NULL ELSE SUM(cs.cs_net_profit) / SUM(cs.cs_net_paid) END AS profit_margin,
            MAX(cs.cs_order_number) AS max_order_number
        FROM catalog_sales cs
        LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        WHERE cs.cs_quantity BETWEEN 1 AND 1000
          AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
        GROUP BY cs.cs_item_sk, d.d_date
    ),
    store_sales_agg AS (
        SELECT
            ss.ss_item_sk,
            d.d_date AS sale_date,
            SUM(ss.ss_quantity) AS total_qty,
            SUM(ss.ss_net_paid) AS total_net_paid,
            SUM(ss.ss_net_profit) AS total_net_profit,
            CASE WHEN SUM(ss.ss_net_paid) = 0 THEN NULL ELSE SUM(ss.ss_net_profit) / SUM(ss.ss_net_paid) END AS profit_margin,
            MAX(ss.ss_ticket_number) AS max_ticket_number
        FROM store_sales ss
        LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        GROUP BY ss.ss_item_sk, d.d_date
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_item_sk,
            d.d_date AS sale_date,
            SUM(ws.ws_quantity) AS total_qty,
            SUM(ws.ws_net_paid) AS total_net_paid,
            SUM(ws.ws_net_profit) AS total_net_profit,
            CASE WHEN SUM(ws.ws_net_paid) = 0 THEN NULL ELSE SUM(ws.ws_net_profit) / SUM(ws.ws_net_paid) END AS profit_margin,
            MAX(ws.ws_order_number) AS max_order_number
        FROM web_sales ws
        LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        GROUP BY ws.ws_item_sk, d.d_date
    ),
    combined_sales AS (
        SELECT
            COALESCE(ca.cs_item_sk, sa.ss_item_sk, wa.ws_item_sk) AS item_sk,
            COALESCE(ca.sale_date, sa.sale_date, wa.sale_date) AS sale_date,
            COALESCE(ca.total_qty, 0) + COALESCE(sa.total_qty, 0) + COALESCE(wa.total_qty, 0) AS total_qty,
            COALESCE(ca.total_net_paid, 0) + COALESCE(sa.total_net_paid, 0) + COALESCE(wa.total_net_paid, 0) AS total_net_paid,
            COALESCE(ca.total_net_profit, 0) + COALESCE(sa.total_net_profit, 0) + COALESCE(wa.total_net_profit, 0) AS total_net_profit,
            CASE
                WHEN (COALESCE(ca.total_net_paid, 0) + COALESCE(sa.total_net_paid, 0) + COALESCE(wa.total_net_paid, 0)) = 0 THEN NULL
                ELSE (COALESCE(ca.total_net_profit, 0) + COALESCE(sa.total_net_profit, 0) + COALESCE(wa.total_net_profit, 0)) /
                     (COALESCE(ca.total_net_paid, 0) + COALESCE(sa.total_net_paid, 0) + COALESCE(wa.total_net_paid, 0))
            END AS overall_profit_margin,
            GREATEST(COALESCE(ca.max_order_number, 0), COALESCE(sa.max_ticket_number, 0), COALESCE(wa.max_order_number, 0)) AS max_order_id
        FROM catalog_sales_agg ca
        FULL OUTER JOIN store_sales_agg sa ON ca.cs_item_sk = sa.ss_item_sk AND ca.sale_date = sa.sale_date
        FULL OUTER JOIN web_sales_agg wa ON COALESCE(ca.cs_item_sk, sa.ss_item_sk) = wa.ws_item_sk
                                         AND COALESCE(ca.sale_date, sa.sale_date) = wa.sale_date
    ),
    promo_items AS (
        SELECT DISTINCT p.p_item_sk
        FROM promotion p
        WHERE p.p_cost > 0
          AND p.p_discount_active = 'Y'
          AND p.p_response_target > 0
    ),
    recent_customers AS (
        SELECT DISTINCT
            c.c_customer_sk,
            i.i_item_sk,
            MAX(d.d_date) AS last_purchase_date
        FROM customer c
        JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        WHERE i.i_item_sk IN (SELECT p_item_sk FROM promo_items)
          AND d.d_date >= date_add('day', -30, (SELECT MAX(d2.d_date) FROM date_dim d2))
        GROUP BY c.c_customer_sk, i.i_item_sk
    ),
    common_items AS (
        SELECT cs_item_sk AS item_sk FROM catalog_sales_agg
        INTERSECT
        SELECT ss_item_sk FROM store_sales_agg
    ),
    ranked_sales AS (
        SELECT
            cs.item_sk,
            cs.sale_date,
            cs.total_qty,
            cs.total_net_paid,
            cs.total_net_profit,
            cs.overall_profit_margin,
            ROW_NUMBER() OVER (PARTITION BY cs.item_sk ORDER BY cs.overall_profit_margin DESC, cs.sale_date) AS profit_margin_rank_desc,
            ROW_NUMBER() OVER (PARTITION BY cs.item_sk ORDER BY cs.overall_profit_margin ASC, cs.sale_date) AS profit_margin_rank_asc,
            SUM(cs.total_net_profit) OVER (PARTITION BY cs.item_sk ORDER BY cs.sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_net_profit
        FROM combined_sales cs
        INNER JOIN common_items ci ON cs.item_sk = ci.item_sk
    ),
    avg_margin AS (
        SELECT item_sk, AVG(overall_profit_margin) AS avg_margin
        FROM combined_sales
        GROUP BY item_sk
    )
SELECT
    i.i_item_id,
    i.i_product_name,
    rs.sale_date,
    rs.total_qty,
    rs.total_net_paid,
    rs.total_net_profit,
    rs.overall_profit_margin,
    rs.cum_net_profit,
    rs.profit_margin_rank_desc AS rank_within_item,
    NULLIF(rs.total_qty, 0) AS nonzero_qty,
    CONCAT('Item:', i.i_item_id, '_Date:', CAST(rs.sale_date AS VARCHAR), '_Rank:', CAST(rs.profit_margin_rank_desc AS VARCHAR)) AS diagnostic_key,
    (SELECT MAX(rc.last_purchase_date) FROM recent_customers rc WHERE rc.i_item_sk = i.i_item_sk) AS last_recent_customer_purchase,
    CASE WHEN rand() < 0.5 THEN 'A' ELSE 'B' END AS random_path,
    am.avg_margin,
    CASE WHEN i.i_item_sk IN (SELECT p_item_sk FROM promo_items) THEN 'HasPromo' ELSE 'NoPromo' END AS promo_flag
FROM ranked_sales rs
JOIN item i ON rs.item_sk = i.i_item_sk
LEFT JOIN avg_margin am ON i.i_item_sk = am.item_sk
WHERE rs.profit_margin_rank_desc <= 5
  AND rs.overall_profit_margin > 0.05
  AND (i.i_brand IS NOT NULL OR i.i_category IS NOT NULL)
UNION ALL
SELECT
    i.i_item_id,
    i.i_product_name,
    rs.sale_date,
    rs.total_qty,
    rs.total_net_paid,
    rs.total_net_profit,
    rs.overall_profit_margin,
    rs.cum_net_profit,
    rs.profit_margin_rank_asc AS rank_within_item,
    NULLIF(rs.total_qty, 0) AS nonzero_qty,
    CONCAT('Item:', i.i_item_id, '_Date:', CAST(rs.sale_date AS VARCHAR), '_Rank:', CAST(rs.profit_margin_rank_asc AS VARCHAR)) AS diagnostic_key,
    (SELECT MAX(rc.last_purchase_date) FROM recent_customers rc WHERE rc.i_item_sk = i.i_item_sk) AS last_recent_customer_purchase,
    CASE WHEN rand() < 0.5 THEN 'A' ELSE 'B' END AS random_path,
    am.avg_margin,
    CASE WHEN i.i_item_sk IN (SELECT p_item_sk FROM promo_items) THEN 'HasPromo' ELSE 'NoPromo' END AS promo_flag
FROM ranked_sales rs
JOIN item i ON rs.item_sk = i.i_item_sk
LEFT JOIN avg_margin am ON i.i_item_sk = am.item_sk
WHERE rs.profit_margin_rank_asc <= 5
  AND rs.overall_profit_margin < 0
  AND (i.i_brand IS NOT NULL OR i.i_category IS NOT NULL)
ORDER BY i_item_id, rank_within_item, sale_date
LIMIT 200
