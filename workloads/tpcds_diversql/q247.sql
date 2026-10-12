WITH
    store_sales_agg AS (
        SELECT
            'store_sales' AS source,
            s.s_store_id AS id,
            SUM(ss.ss_net_paid) AS total_amount,
            COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customer_cnt,
            COUNT(DISTINCT ss.ss_item_sk) AS distinct_item_cnt,
            (SELECT MAX(p.p_cost) FROM promotion p WHERE p.p_channel_dmail = 'Y') AS max_dmail_promo_cost,
            ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS rn
        FROM store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        WHERE s.s_state = 'CA'
          AND NOT EXISTS (
                SELECT 1
                FROM catalog_returns cr
                WHERE cr.cr_refunded_customer_sk = c.c_customer_sk
          )
        GROUP BY s.s_store_id, s.s_state
    ),
    catalog_returns_agg AS (
        SELECT
            'catalog_returns' AS source,
            cp.cp_catalog_page_id AS id,
            SUM(cr.cr_return_amount) AS total_amount,
            COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_customer_cnt,
            COUNT(DISTINCT cr.cr_item_sk) AS distinct_item_cnt,
            (SELECT MAX(p.p_cost) FROM promotion p WHERE p.p_channel_dmail = 'Y') AS max_dmail_promo_cost,
            ROW_NUMBER() OVER (ORDER BY SUM(cr.cr_return_amount) DESC) AS rn
        FROM catalog_returns cr
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        WHERE cp.cp_type = 'Electronic'
          AND NOT EXISTS (
                SELECT 1
                FROM catalog_sales cs
                WHERE cs.cs_order_number = cr.cr_order_number
                  AND cs.cs_item_sk = cr.cr_item_sk
          )
        GROUP BY cp.cp_catalog_page_id, cp.cp_type
    )
SELECT source,
       id,
       total_amount,
       distinct_customer_cnt,
       distinct_item_cnt,
       max_dmail_promo_cost,
       rn
FROM store_sales_agg
UNION ALL
SELECT source,
       id,
       total_amount,
       distinct_customer_cnt,
       distinct_item_cnt,
       max_dmail_promo_cost,
       rn
FROM catalog_returns_agg
ORDER BY source, rn
