WITH base AS (
    SELECT
        s.s_store_name,
        d.d_year,
        i.i_category,
        ws.web_site_id,
        ss.ss_ext_sales_price,
        cr.cr_return_amount,
        inv.inv_quantity_on_hand,
        p.p_cost,
        cc.cc_gmt_offset,
        ss.ss_ticket_number
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#45'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cc.cc_state = 'TX'
      AND ws.web_country = 'USA'
      AND inv.inv_quantity_on_hand > 100
      AND cr.cr_return_quantity > 0
),
agg AS (
    SELECT
        s_store_name,
        d_year,
        i_category,
        web_site_id,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(cr_return_amount) AS total_returns,
        AVG(inv_quantity_on_hand) AS avg_inventory,
        COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
        MAX(p_cost) AS max_promo_cost,
        MIN(cc_gmt_offset) AS min_gmt_offset
    FROM base
    GROUP BY s_store_name, d_year, i_category, web_site_id
    HAVING SUM(ss_ext_sales_price) > 100000
)
SELECT
    s_store_name,
    d_year,
    i_category,
    web_site_id,
    total_sales,
    total_returns,
    avg_inventory,
    distinct_tickets,
    max_promo_cost,
    min_gmt_offset
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_sales DESC) AS rn
    FROM agg
) t
WHERE rn <= 5
ORDER BY total_sales DESC
