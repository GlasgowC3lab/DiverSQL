WITH sales_union AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS net_paid,
        'catalog' AS channel,
        cs.cs_call_center_sk AS call_center_sk,
        NULL AS store_sk,
        cs.cs_promo_sk AS promo_sk
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS net_paid,
        'store' AS channel,
        NULL AS call_center_sk,
        ss.ss_store_sk AS store_sk,
        ss.ss_promo_sk AS promo_sk
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS net_paid,
        'web' AS channel,
        NULL AS call_center_sk,
        NULL AS store_sk,
        ws.ws_promo_sk AS promo_sk
    FROM web_sales ws
),
promo_info AS (
    SELECT
        p.p_promo_sk,
        p.p_item_sk,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_discount_active,
        p.p_promo_name
    FROM promotion p
),
sales_with_promo AS (
    SELECT
        su.*,
        pi.p_promo_name,
        pi.p_discount_active,
        CASE
            WHEN pi.p_promo_sk IS NOT NULL
                 AND su.sold_date_sk BETWEEN pi.p_start_date_sk AND pi.p_end_date_sk
            THEN 1
            ELSE 0
        END AS is_promo_active
    FROM sales_union su
    LEFT JOIN promo_info pi
        ON su.promo_sk = pi.p_promo_sk
       AND su.sold_date_sk BETWEEN pi.p_start_date_sk AND pi.p_end_date_sk
),
sales_with_item AS (
    SELECT
        swp.*,
        i.i_category,
        i.i_brand,
        i.i_color,
        i.i_size,
        i.i_product_name,
        i.i_current_price
    FROM sales_with_promo swp
    JOIN item i
        ON swp.item_sk = i.i_item_sk
),
aggregated_raw AS (
    SELECT
        d.d_year,
        swi.i_category,
        swi.i_brand,
        swi.channel,
        swi.call_center_sk,
        swi.store_sk,
        COUNT(DISTINCT d.d_date) AS active_days,
        SUM(swi.quantity) AS total_quantity,
        SUM(swi.net_paid) AS total_net_paid,
        SUM(CASE WHEN swi.is_promo_active = 1 THEN swi.net_paid * 0.9 ELSE swi.net_paid END) AS promo_adjusted_net,
        AVG(swi.net_paid) AS avg_net_paid,
        MAX(CASE WHEN swi.channel = 'store' THEN swi.net_paid END) AS max_store_net,
        MIN(CASE WHEN swi.channel = 'catalog' THEN swi.net_paid END) AS min_catalog_net
    FROM sales_with_item swi
    JOIN date_dim d
        ON swi.sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year,
        swi.i_category,
        swi.i_brand,
        swi.channel,
        swi.call_center_sk,
        swi.store_sk
),
final AS (
    SELECT
        ar.*,
        ROW_NUMBER() OVER (PARTITION BY ar.d_year, ar.i_category ORDER BY ar.total_net_paid DESC) AS category_rank,
        COALESCE(cc.cc_name, 'N/A') AS call_center_name,
        COALESCE(st.s_store_name, 'N/A') AS store_name,
        CONCAT(ar.i_category, '-', ar.i_brand) AS cat_brand,
        CASE WHEN ar.total_quantity > 1000 THEN 'High Volume' ELSE 'Normal Volume' END AS volume_flag,
        (SELECT SUM(b.total_net_paid) FROM aggregated_raw b WHERE b.d_year = ar.d_year) AS year_total_net,
        (SELECT MAX(c.total_net_paid) FROM aggregated_raw c WHERE c.d_year = ar.d_year AND c.i_category = ar.i_category) AS max_category_net
    FROM aggregated_raw ar
    LEFT JOIN call_center cc
        ON ar.call_center_sk = cc.cc_call_center_sk
    LEFT JOIN store st
        ON ar.store_sk = st.s_store_sk
    WHERE ar.d_year BETWEEN 2001 AND 2002
      AND (ar.channel = 'store' OR ar.total_quantity > 10)
      AND COALESCE(ar.i_category, '') LIKE '%Electronics%'
)
SELECT *
FROM final
ORDER BY d_year, category_rank
