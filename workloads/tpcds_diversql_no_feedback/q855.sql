WITH agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        sm.sm_carrier,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        SUM(cs.cs_net_paid) AS catalog_sales,
        SUM(ws.ws_net_paid) AS web_sales,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_returns_cnt,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory,
        MAX(p.p_cost) AS max_promo_cost,
        MIN(cs.cs_sold_date_sk) AS min_sold_date_sk
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_return_time_sk = td.t_time_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE sm.sm_carrier = 'ZOUROS'
      AND sm.sm_code = 'AIR'
      AND r.r_reason_desc LIKE '%price%'
      AND i.i_brand = 'BrandX'
      AND cc.cc_rec_start_date >= DATE '2001-01-01'
      AND cp.cp_start_date_sk BETWEEN 2451025 AND 2451085
    GROUP BY i.i_category, i.i_brand, sm.sm_carrier
)
SELECT
    d.grp,
    a.i_category,
    a.i_brand,
    a.sm_carrier,
    a.catalog_orders,
    a.catalog_sales,
    a.web_sales,
    a.store_returns_cnt,
    a.avg_inventory,
    a.max_promo_cost,
    ROW_NUMBER() OVER (ORDER BY a.catalog_sales DESC) AS sales_rank
FROM agg a
CROSS JOIN (SELECT 'ALL' AS grp UNION ALL SELECT 'SPECIAL' AS grp) d
ORDER BY a.catalog_sales DESC, d.grp
